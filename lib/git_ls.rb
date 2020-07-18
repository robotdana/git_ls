# frozen_string_literal: true

# Usage:
#   GitLS.files -> Array of strings as files.
#   This will be identical output to git ls-files
module GitLS
  class Error < StandardError; end

  class << self
    def files(path = ::Dir.pwd)
      read(path, false)
    end

    def headers(path = ::Dir.pwd)
      read(path, true)
    end

  private

    def read(path, return_headers_only)
      path = ::File.join(path, '.git/index') if ::File.directory?(path)
      file = ::File.new(path)
      # 4-byte signature:
      # The signature is { 'D', 'I', 'R', 'C' } (stands for "dircache")
      # 4-byte version number:
      # The current supported versions are 2, 3 and 4.
      # 32-bit number of index entries.
      sig, git_index_version, length = file.read(12).unpack('A4NN')
      raise ::GitLS::Error, 'not a git dir or .git/index file' unless sig == 'DIRC'

      return { git_index_version: git_index_version, length: length } if return_headers_only

      files = Array.new(length)
      case git_index_version
      when 2 then files_2(files, file)
      when 3 then files_3(files, file)
      when 4 then files_4(files, file)
      else raise ::GitLS::Error, 'Unrecognized git index version'
      end
      files
    rescue Errno::ENOENT => e
      raise GitLS::Error, "Not a git directory: #{e.message}"
    ensure
      # :nocov:
      # coverage tracking for branches in ensure blocks is weird
      file&.close
      # :nocov:
      files
    end

    private

    def files_2(files, file)
      files.map! do
        file.pos += 60 # skip 60 bytes (40 bytes of stat, 20 bytes of sha)
        length = (file.getbyte & 0b0000_1111) * 256 + file.getbyte # find the 12 byte length
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

    def files_3(files, file)
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

    def files_4(files, file)
      prev_entry_path = ""
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
