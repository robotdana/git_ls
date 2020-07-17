# frozen_string_literal: true

require_relative 'git_index/parser'

# Entry point for gem.
# Usage:
#   GitIndex.files -> Array of strings as files.
#   This will be identical output to git ls-files
module GitIndex
  class Error < StandardError; end

  class << self
    def files(path = ::Dir.pwd)
      path = ::File.join(path, '.git/index') if ::File.directory?(path)
      ::GitIndex::Parser.new(::File.new(path)).files
    end
  end
end
