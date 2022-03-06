# typed: true
# frozen_string_literal: true

# Usage:
#   GitLS.files -> Array of strings as files.
#   This will be identical output to git ls-files
require 'stringio'

module GitLS # rubocop:disable Metrics/ModuleLength
  module Error; end

  class MissingFileError < ::Errno::ENOENT; include ::GitLS::Error; end

  class TruncatedFileError < ::EOFError; include ::GitLS::Error; end

  class InvalidFileError < ::StandardError; include ::GitLS::Error; end

  class << self
    def files(path = nil)
      path = path ? ::File.join(path, '.git/index') : '.git/index'

      read(path)
    end

    private

    def read(path) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      file = begin
        # reading the whole file into memory is faster than lots of ::File#read
        # the biggest it's going to be is 10s of megabytes, well within ram.
        ::StringIO.new(::File.read(path, mode: 'rb'))
      rescue ::Errno::ENOENT => e
        raise ::GitLS::MissingFileError, "Not a git directory: #{e.message}"
      end

      buf = ::String.new
      # 4-byte signature:
      # The signature is { 'D', 'I', 'R', 'C' } (stands for "dircache")
      # 4-byte version number:
      # The current supported versions are 2, 3 and 4.
      # 32-bit number of index entries.
      file.readpartial(4, buf)
      sig = buf
      raise ::GitLS::InvalidFileError, ".git/index file not found at '#{path}'" unless sig == 'DIRC'

      file.readpartial(4, buf)
      git_index_version = buf.unpack1('N')

      file.readpartial(4, buf)
      entries = buf.unpack1('N').to_i

      files = ::Array.new(entries)
      files = case git_index_version
      when 2 then files_2(files, file)
      when 3 then files_3(files, file)
      when 4 then files_4(files, file)
      else raise ::GitLS::InvalidFileError, "Unrecognized git index version '#{git_index_version}'"
      end

      read_extensions(files, file, path, buf)
    rescue EOFError
      raise ::GitLS::TruncatedFileError, '.git/index file reached EOF unexpectedly'
    end

    def read_extensions(files, file, path, buf) # rubocop:disable Metrics/MethodLength
      extension = file.readpartial(4, buf)
      if extension == 'link'
        read_link_extension(files, file, path, buf)
      elsif extension.match?(/\A[A-Z]{4}\z/)
        size = file.readpartial(4, buf).unpack1('N').to_i
        file.seek(size, 1)
        read_extensions(files, file, path, buf)
      else
        return files if file.seek(16, 1) && file.eof?

        raise ::GitLS::InvalidFileError, "Unrecognized .git/index extension #{extension.inspect}"
      end
    end

    def read_link_extension(files, file, path, buf) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      file.seek(4, 1) # skip size

      sha = file.readpartial(20, buf)

      # @type var split_files: untyped
      # It's Array[String?] here
      # Then after the compact! it's Array[String]
      # it seems like there's no way to redefine the type after compact!
      shared_path = "#{::File.dirname(path)}/sharedindex.#{sha.unpack1('H*')}"
      split_files = read(shared_path)

      ewah_each_value(file, buf) do |pos|
        split_files[pos] = nil
      end

      ewah_each_value(file, buf) do |pos|
        replacement_file = files.shift ||
          raise(::GitLS::InvalidFileError, "There are the wrong number of entries in #{shared_path}")
        # the documentation *implies* that this *may* get a new filename
        # i can't get it to happen though
        # :nocov:
        split_files[pos] = replacement_file unless replacement_file.empty?
        # :nocov:
      end

      split_files.compact!
      split_files.concat(files)
      split_files.sort!

      read_extensions(split_files, file, path, buf)
    end

    # format is defined here:
    # https://git-scm.com/docs/bitmap-format#_appendix_a_serialization_format_for_an_ewah_bitmap
    def ewah_each_value(file, buf) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      uncompressed_pos = 0

      file.seek(4, 1) # skip 4 byte uncompressed_bits_count.
      compressed_bytes = file.readpartial(4, buf).unpack1('N').to_i * 8

      final_file_pos = file.pos + compressed_bytes

      until file.pos == final_file_pos
        run_length_word = file.readpartial(8, buf).unpack1('Q>').to_i
        # 1st bit
        run_bit = run_length_word & 1
        # the next 32 bits, masked, multiplied by 64
        run_length = ((run_length_word / 0b1_0) & 0xFFFF_FFFF) * 64
        # the next 31 bits
        literal_length = (run_length_word / 0b100000000_00000000_00000000_00000000_0)

        if run_bit == 1
          run_length.times do
            yield uncompressed_pos
            uncompressed_pos += 1
          end
        else
          uncompressed_pos += run_length
        end

        next unless literal_length > 0

        file.readpartial(8 * literal_length, buf)
        words = buf.unpack('B64' * literal_length)
        words.each do |word|
          word.to_s.each_char.reverse_each do |char|
            yield(uncompressed_pos) if char == '1'

            uncompressed_pos += 1
          end
        end
      end

      file.seek(4, 1) # bitmap metadata for adding to bitmaps
    end

    def files_2(files, file) # rubocop:disable Metrics/MethodLength
      files.map! do
        file.seek(60, 1) # skip 60 bytes (40 bytes of stat, 20 bytes of sha)

        length = (file.readbyte & 0xF) * 256 + file.readbyte # find the 12 byte length
        if length < 0xFFF
          path = file.readpartial(length)
          # :nocov:
        else
          # i can't test this i just get ENAMETOOLONG a lot
          # I'm not sure it's even possible to get to this path, PATH_MAX is 4096 bytes on linux, 1024 on mac
          # and length is a 12 byte number: 4096 max.
          path = file.readline("\0")
          path.chop!
          file.seek(-1, 1)
          # :nocov:
        end
        file.seek(8 - ((length - 2) % 8), 1) # 1-8 bytes padding of nuls
        path.force_encoding(Encoding::UTF_8)
        path
      end
    end

    def files_3(files, file) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      files.map! do
        file.seek(60, 1) # skip 60 bytes (40 bytes of stat, 20 bytes of sha)
        flags = file.readbyte
        extended_flag = (flags & 0b0100_0000) > 0
        length = (flags & 0xF) * 256 + file.readbyte # find the 12 byte length
        file.seek(2, 1) if extended_flag

        if length < 0xFFF
          path = file.readpartial(length)
          # :nocov:
        else
          # i can't test this i just get ENAMETOOLONG a lot
          # I'm not sure it's even possible to get to this path, PATH_MAX is 4096 bytes on linux, 1024 on mac
          # and length is a 12 byte number: 4096 max.
          path = file.readline("\0")
          path.chop!
          file.seek(-1, 1)
          # :nocov:
        end
        file.seek(8 - ((path.bytesize - (extended_flag ? 0 : 2)) % 8), 1) # 1-8 bytes padding of nuls
        path.force_encoding(Encoding::UTF_8)
        path
      end
    end

    def files_4(files, file) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      prev_entry_path = ''
      files.map! do # rubocop:disable Metrics/BlockLength
        file.seek(60, 1) # skip 60 bytes (40 bytes of stat, 20 bytes of sha)
        flags = file.readbyte
        extended_flag = (flags & 0b0100_0000) > 0
        length = (flags & 0xF) * 256 + file.readbyte # find the 12 byte length
        file.seek(2, 1) if extended_flag

        # documentation for this number from
        # https://git-scm.com/docs/pack-format#_original_version_1_pack_idx_files_have_the_following_format
        # offset encoding:
        #   n bytes with MSB set in all but the last one.
        #   The offset is then the number constructed by
        #   concatenating the lower 7 bit of each byte, and
        #   for n >= 2 adding 2^7 + 2^14 + ... + 2^(7*(n-1))
        #   to the result.
        read_offset = 0
        prev_read_offset = file.readbyte
        n = 1
        while (prev_read_offset & 0b1000_0000) > 0
          read_offset += (prev_read_offset & 0b0111_1111)
          read_offset += Integer(2**(7 * n))
          n += 1
          prev_read_offset = file.readbyte
        end
        read_offset += prev_read_offset

        initial_part_length = prev_entry_path.bytesize - read_offset

        if length < 0xFFF
          rest = +''
          file.readpartial(length - initial_part_length, rest)
          file.seek(1, 1) # the NUL
          # :nocov:
        else
          # i can't test this i just get ENAMETOOLONG a lot
          # I'm not sure it's even possible to get to this path, PATH_MAX is 4096 bytes on linux, 1024 on mac
          # and length is a 12 byte number: 4096 max.
          rest = file.readline("\0").chop!
          file.seek(-1, 1)
          # :nocov:
        end

        prev_entry_path = +"#{prev_entry_path.byteslice(0, initial_part_length)}#{rest}"
        prev_entry_path.force_encoding(::Encoding::UTF_8)
      end
    end
  end
end
