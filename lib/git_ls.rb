# frozen_string_literal: true

require_relative 'git_ls/parser'

# Entry point for gem.
# Usage:
#   GitLS.files -> Array of strings as files.
#   This will be identical output to git ls-files
module GitLS
  class Error < StandardError; end

  class << self
    def files(path = ::Dir.pwd)
      path = ::File.join(path, '.git/index') if ::File.directory?(path)
      ::GitLS::Parser.new(::File.new(path)).files
    end
  end
end
