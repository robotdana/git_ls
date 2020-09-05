# frozen_string_literal: true

# Usage:
#   GitLS.files -> Array of strings as files.
#   This will be identical output to git ls-files
module GitLS # rubocop:disable Metrics/ModuleLength
  class Error < StandardError; end

  class << self
    def files(path = ::Dir.pwd)
      read(path, false)
    end

    def headers(path = ::Dir.pwd)
      read(path, true)
    end

    private

    def read(path, return_headers_only) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      path = ::File.join(path, '.git/index') if ::File.directory?(path)
      file = ::File.new(path)
      buf = ::String.new
      # 4-byte signature:
      # The signature is { 'D', 'I', 'R', 'C' } (stands for "dircache")
      # 4-byte version number:
      # The current supported versions are 2, 3 and 4.
      # 32-bit number of index entries.
      sig, git_index_version, length = file.read(12, buf).unpack('a4NN')
      raise ::GitLS::Error, ".git/index file not found at #{path}" unless sig == 'DIRC'

      return { git_index_version: git_index_version, length: length } if return_headers_only

      files = ::Array.new(length)
      case git_index_version
      when 2 then files_2(files, file)
      when 3 then files_3(files, file)
      when 4 then files_4(files, file)
      else raise ::GitLS::Error, 'Unrecognized git index version'
      end

      extensions(files, file, buf)
      files
    rescue ::Errno::ENOENT => e
      raise ::GitLS::Error, "Not a git directory: #{e.message}"
    ensure
      # :nocov:
      # coverage tracking for branches in ensure blocks is weird
      file&.close
      # :nocov:
      files
    end

    def extensions(files, file, buf)
      case file.read(4, buf)
      when 'link' then link_extension(files, file, buf)
      when /[A-Z]{4}/ then ignored_extension(files, file, buf)
      else
        return if (file.pos += 16) && file.eof?

        raise ::GitLS::Error, "Unrecognized .git/index extension #{buf.inspect}"
      end
    end

    def ignored_extension(files, file, buf)
      size = file.read(4, buf).unpack1('N')
      file.pos += size
      extensions(files, file, buf)
    end

    def link_extension(files, file, buf) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      file.pos += 4 # size = file.read(4, buf).unpack1('N')

      sha = file.read(20, buf)

      new_files = files.dup

      files.replace files("#{::File.dirname(file.path)}/sharedindex.#{sha.unpack1('H*')}")

      ewah_each_value(file, buf) do |pos|
        files[pos] = nil
      end

      ewah_each_value(file, buf) do |pos|
        replacement_file = new_files.shift
        # the documentation *implies* that this *may* get a new filename
        # i can't get it to happen though
        # :nocov:
        files[pos] = replacement_file unless replacement_file.empty?
        # :nocov:
      end

      files.compact!
      files.concat(new_files)
      files.sort!

      extensions(files, file, buf)
    end

    # format is defined here:
    # https://git-scm.com/docs/bitmap-format#_appendix_a_serialization_format_for_an_ewah_bitmap
    def ewah_each_value(file, buf) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      uncompressed_pos = 0
      file.pos += 4 # uncompressed_bits_count = file.read(4, buf).unpack1('N')
      compressed_bytes = file.read(4, buf).unpack1('N') * 8

      final_file_pos = file.pos + compressed_bytes

      until file.pos == final_file_pos
        run_length_word = file.read(8, buf).unpack1('Q>')
        # 1st bit
        run_bit = run_length_word & 1
        # the next 32 bits, masked, multiplied by 64 (which is shifted by 6 places)
        run_length = ((run_length_word >> 1) & 0xFFFF_FFFF) << 6
        # the next 31 bits
        literal_length = (run_length_word >> 33)

        if run_bit == 1
          run_length.times do
            yield uncompressed_pos
            uncompressed_pos += 1
          end
        else
          uncompressed_pos += run_length
        end

        literal_length.times do
          word = file.read(8, buf).unpack1('B*').reverse
          word.each_char do |char|
            yield(uncompressed_pos) if char == '1'

            uncompressed_pos += 1
          end
        end
      end

      file.pos += 4 # bitmap metadata for adding to bitmaps
    end

    def files_2(files, file) # rubocop:disable Metrics/MethodLength
      files.map! do
        file.pos += 60 # skip 60 bytes (40 bytes of stat, 20 bytes of sha)
        length = ((file.getbyte & 0b0000_1111) << 8) + file.getbyte # find the 12 byte length
        if length < 0xFFF
          path = file.read(length)
          # :nocov:
        else
          # i can't test this i just get ENAMETOOLONG a lot
          path = file.readline("\0").chop
          file.pos -= 1
          # :nocov:
        end
        file.pos += 8 - ((length - 2) % 8) # 1-8 bytes padding of nuls
        path
      end
    end

    def files_3(files, file) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      files.map! do
        file.pos += 60 # skip 60 bytes (40 bytes of stat, 20 bytes of sha)

        flags = file.getbyte * 256 + file.getbyte
        extended_flag = (flags & 0b0100_0000_0000_0000).positive?
        file.pos += 2 if extended_flag

        length = flags & 0b0000_1111_1111_1111
        if length < 0xFFF
          path = file.read(length)
          # :nocov:
        else
          # i can't test this i just get ENAMETOOLONG a lot
          path = file.readline("\0").chop
          file.pos -= 1
          # :nocov:
        end

        file.pos += 8 - ((path.bytesize - (extended_flag ? 0 : 2)) % 8) # 1-8 bytes padding of nuls
        path
      end
    end

    def files_4(files, file) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      prev_entry_path = ''
      files.map! do
        file.pos += 60 # skip 60 bytes (40 bytes of stat, 20 bytes of sha)
        flags = file.getbyte * 256 + file.getbyte
        file.pos += 2 if (flags & 0b0100_0000_0000_0000).positive?

        length = flags & 0b0000_1111_1111_1111

        # documentation for this number from
        # https://git-scm.com/docs/pack-format#_original_version_1_pack_idx_files_have_the_following_format
        # offset encoding:
        #   n bytes with MSB set in all but the last one.
        #   The offset is then the number constructed by
        #   concatenating the lower 7 bit of each byte, and
        #   for n >= 2 adding 2^7 + 2^14 + ... + 2^(7*(n-1))
        #   to the result.
        read_offset = 0
        prev_read_offset = file.getbyte
        n = 1
        while (prev_read_offset & 0b1000_0000).positive?
          read_offset += (prev_read_offset - 0b1000_0000)
          read_offset += 2**(7 * n)
          n += 1
          prev_read_offset = file.getbyte
        end
        read_offset += prev_read_offset

        initial_part_length = prev_entry_path.bytesize - read_offset

        if length < 0xFFF
          rest = file.read(length - initial_part_length)
          file.pos += 1 # the NUL
          # :nocov:
        else
          # i can't test this i just get ENAMETOOLONG a lot
          rest = file.readline("\0").chop
          # :nocov:
        end

        prev_entry_path = prev_entry_path.byteslice(0, initial_part_length) + rest
      end
    end
  end
end
