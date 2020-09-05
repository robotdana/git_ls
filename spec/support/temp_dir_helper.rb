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

    # def create_long_file_path(*lines, path:, git_add: true)
    #   orig_dir = ::Dir.pwd
    #   begin
    #     path.parent.to_s.delete_prefix(orig_dir + '/').split('/').each do |dirname|
    #       ::FileUtils.mkdir_p dirname
    #       ::Dir.chdir dirname
    #     end
    #     if lines.empty?
    #       path.basename.write('')
    #     else
    #       path.basename.write(lines.join("\n").chomp + "\n")
    #     end
    #   ensure
    #     Dir.chdir(orig_dir)
    #   end
    #   system("git", "add", path.to_s) if git_add
    #   path
    # end

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
    `git init` if git_init
    yield
  ensure
    Dir.chdir(original_dir)
    dir&.rmtree
  end
end

RSpec.configure do |config|
  config.include TempDirHelper
end
