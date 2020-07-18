# frozen_string_literal: true

module GitLS
  # Parse a .git/index file
  # Format documented here: https://git-scm.com/docs/index-format
  class Parser
    HEADER = 'A4' + # 4-byte signature:
             # The signature is { 'D', 'I', 'R', 'C' } (stands for "dircache")
             'N' + # 4-byte version number:
             # The current supported versions are 2, 3 and 4.
             'N' # 32-bit number of index entries.

    def initialize(file)
      @file = file
      raise ::GitLS::Error, 'not a git dir or .git/index file' unless valid?
    end

    def files
      headers

      @files = Array.new(length)
      case git_index_version
      when 2 then files_2
      when 3 then files_3
      when 4 then files_4
      else raise ::GitLS::Error, 'Unrecognized git version'
      end
      @files
    end

    private

    def files_2
      @files.map! do
        @file.pos += 62 # skip 62 bytes (40 bytes of stat, 20 bytes of sha, 2 bytes flags)
        ret = @file.readline("\0").chop
        @file.pos += 7 - ((ret.bytesize - 2) % 8) # 1-8 bytes padding of nuls
        ret
      end
    end

    def files_3
      @files.map! do
        @file.pos += 60 # skip 60 bytes (40 bytes of stat, 20 bytes of sha)
        flag = @file.getbyte
        extended_flag_offset = if (flag & 0b0100_0000).positive?
          3 # skip next half of flag + extended flags
        else
          1 # skip next half of flag
        end
        @file.pos += extended_flag_offset

        ret = @file.readline("\0").chop
        @file.pos += 7 - ((ret.bytesize + extended_flag_offset - 3) % 8) # 1-8 bytes padding of nuls
        ret
      end
    end

    def files_4
      prev_entry_path = ""
      @files.map! do
        @file.pos += 60 # skip 60 bytes (40 bytes of stat, 20 bytes of sha)
        flag = @file.getbyte
        @file.pos += if (flag & 0b0100_0000).positive?
          3 # skip next half of flag + extended flags
        else
          1 # skip next half of flag
        end

        # flags = @file.read(2) # 2 bytes flags
        # # skip extend flags if extended flags bit set
        # @file.pos += 2 if flags && (flags.unpack1('n') & 0b0100_0000_0000_0000).positive?

        # documentation for this number from
        # https://git-scm.com/docs/pack-format#_original_version_1_pack_idx_files_have_the_following_format
        # offset encoding:
        #   n bytes with MSB set in all but the last one.
        #   The offset is then the number constructed by
        #   concatenating the lower 7 bit of each byte, and
        #   for n >= 2 adding 2^7 + 2^14 + ... + 2^(7*(n-1))
        #   to the result.
        read_offset = 0
        prev_read_offset = @file.getbyte
        n = 1
        while (prev_read_offset & 0b1000_0000).positive?
          read_offset += (prev_read_offset - 0b1000_0000)
          read_offset += 2**(7 * n)
          n += 1
          prev_read_offset = @file.getbyte
        end
        read_offset += prev_read_offset

        prev_entry_path = prev_entry_path.byteslice(0, prev_entry_path.bytesize - read_offset) + @file.readline("\0").chop
      end
    end

    def headers
      @headers ||= @file.read(12).unpack(::GitLS::Parser::HEADER)
    end

    def valid?
      headers[0] == 'DIRC'
    end

    def git_index_version
      @git_version = headers[1]
    end

    def length
      headers[2]
    end
  end
end
