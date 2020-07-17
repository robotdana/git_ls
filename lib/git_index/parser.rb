# frozen_string_literal: true

module GitIndex
  # Parse a .git/index file
  class Parser
    HEADER = 'A4' + # 4-byte signature:
             # The signature is { 'D', 'I', 'R', 'C' } (stands for "dircache")
             'N' + # 4-byte version number:
             # The current supported versions are 2, 3 and 4.
             'N' # 32-bit number of index entries.

    def initialize(file)
      @file = file
      raise ::GitIndex::Error, 'not a git dir or .git/index file' unless valid?
    end

    def files
      headers

      @files = Array.new(length)
      case git_version
      when 2 then files_2
      when 3 then files_3
      when 4 then raise '4 is complicated git version'
      else raise 'Unrecognized git version'
      end
      @files
    end

    private

    def files_2
      @files.map! do
        @file.pos += 62 # skip 62 bytes (40 bytes of stat, 20 bytes of sha, 2 bytes flags)
        ret = @file.readline("\0").chop
        @file.pos += 7 - ((ret.bytesize - 2) % 8)
        ret
      end
    end

    def files_3
      @files.map! do
        @file.pos += 60 # skip 60 bytes (40 bytes of stat, 20 bytes of sha)
        flags = @file.read(2)
        # skip extend flags if extended flags bit set
        @file.pos += 2 if flags && (flags.unpack1('n') & 0b0100_0000_0000_0000).positive?

        ret = @file.readline("\0").chop
        @file.pos += 7 - ((ret.bytesize - 2) % 8)
        ret
      end
    end

    def headers
      @headers ||= @file.read(12).unpack(::GitIndex::Parser::HEADER)
    end

    def valid?
      headers[0] == 'DIRC'
    end

    def git_version
      @git_version = headers[1]
    end

    def length
      headers[2]
    end
  end
end
