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
        path.write(lines.join("\n").chomp + "\n")
      end
      system("git", "add", path.to_s) if git_add
      path
    end

    def create_symlink(**arg)
      git_add = arg.delete(:git_add)

      link, target = arg.to_a.first

      link_path = Pathname.pwd.join(link)
      link_path.parent.mkpath

      FileUtils.ln_s(Pathname.pwd.join(target), link_path.to_s)
      system("git", "add", link_path.to_s) if git_add

      link_path.to_s
    end

    def create_file_list(*filenames, git_add: true)
      filenames.each do |filename|
        create_file(path: filename, git_add: false)
      end

      system("git", "add", *filenames) if git_add
    end
  end

  def within_temp_dir(git_init: true)
    dir = Pathname.new(Dir.mktmpdir)
    original_dir = Dir.pwd
    Dir.chdir(dir)

    extend WithinTempDir
    system("git init") if git_init
    yield
  ensure
    Dir.chdir(original_dir)
    dir&.rmtree
  end
end

RSpec.configure do |config|
  config.include TempDirHelper
end
