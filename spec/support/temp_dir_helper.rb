# typed: false
# frozen_string_literal: true

require 'pathname'
require 'tmpdir'

module TempDirHelper
  module WithinTempDir
    def create_file(*lines, path:, git_add: true)
      path = Pathname.pwd.join(path)
      path.parent.mkpath
      if lines.empty?
        path.write('')
      else
        path.write("#{lines.join("\n").chomp}\n")
      end
      system('git', 'add', path.to_s) if git_add
      path
    end

    def create_file_list(*filenames, git_add: true)
      filenames.each do |filename|
        create_file(path: filename, git_add: false)
      end

      system('git', 'add', *filenames) if git_add
    end
  end

  def within_temp_dir(git_init: true)
    dir = Pathname.new(Dir.mktmpdir)
    original_dir = Dir.pwd
    Dir.chdir(dir)

    extend WithinTempDir
    `git init && git config user.email rspec@example.com && git config user.name "RSpec runner"` if git_init
    yield
  ensure
    Dir.chdir(original_dir)
    dir&.rmtree
  end
end

RSpec.configure do |config|
  config.include TempDirHelper
end
