# frozen_string_literal: true

RSpec.describe GitLS do
  it 'has a version number' do
    expect(GitLS::VERSION).not_to be nil
  end

  shared_examples "git ls-files" do
    context "with basic files" do
      before do
        create_file_list 'foo/bar', 'foo/foo', 'bar/foo', 'bar/bar', 'baz'
      end

      it 'matches git-ls output' do
        expect(GitLS.files).to eq(`git ls-files -z`.split("\0"))
          .and(eq(["bar/bar", "bar/foo", "baz", "foo/bar", "foo/foo"]))
      end

      it 'can be given the .git/index file directly' do
        expect(GitLS.files('.git/index')).to eq(`git ls-files -z`.split("\0"))
          .and(eq(["bar/bar", "bar/foo", "baz", "foo/bar", "foo/foo"]))
      end

      context 'with sparse checkout' do
        before do
          system("git commit -m COMMIT")
          system("git sparse-checkout init")
        end

        it 'matches git-ls output' do
          expect(::File.exist?('bar/bar')).to be false

          expect(GitLS.files).to eq(`git ls-files -z`.split("\0"))
            .and(eq(["bar/bar", "bar/foo", "baz", "foo/bar", "foo/foo"]))
        end
      end
    end

    context "with intent to add file" do
      before do
        create_file 'x', path: 'foo', git_add: false
        system("git add -N foo")
      end

      it 'matches git-ls output' do
        expect(GitLS.files).to eq(`git ls-files -z`.split("\0"))
          .and(eq(["foo"]))
      end
    end

    context "with file with newline in name" do
      before do
        create_file path: "foo\nbar"
      end

      it 'matches git-ls output' do
        expect(GitLS.files).to eq(`git ls-files -z`.split("\0"))
          .and(eq(["foo\nbar"]))
      end
    end

    context "with file with space in name" do
      before do
        create_file path: "foo bar"
      end

      it 'matches git-ls output' do
        expect(GitLS.files).to eq(`git ls-files -z`.split("\0"))
          .and(eq(["foo bar"]))
      end
    end

    context "with file with long name" do
      before do
        create_file_list "foo/bar", "foo/#{'bar' * 60}", "foo/baz"
      end

      it 'matches git-ls output' do
        expect(GitLS.files).to eq(`git ls-files -z`.split("\0"))
          .and(eq(["foo/bar", "foo/#{'bar' * 60}", "foo/baz"]))
      end
    end
  end

  describe '.files' do
    context 'with no git' do
      around do |example|
        within_temp_dir(git_init: false) { example.run }
      end

      it 'raises an error' do
        expect { GitLS.files }.to raise_error(GitLS::Error)
      end

      it 'raises an error when .git/index file is empty' do
        create_file '', path: '.git/index'

        expect { GitLS.files }.to raise_error(GitLS::Error)
      end

      it 'raises an error when .git/index file is a non recognized version' do
        create_file "DIRC\0\0\0\x5\0\0\0\0", path: '.git/index'

        expect { GitLS.files }.to raise_error(GitLS::Error)
        expect(GitLS::Parser.new(::File.new('.git/index')).send(:git_index_version)).to eq 5
      end
    end

    context 'with git' do
      around do |example|
        within_temp_dir { example.run }
      end

      describe 'index version 2' do
        before { system("git update-index --index-version=2") }

        it_behaves_like 'git ls-files'
      end

      describe 'index version 3' do
        before { system("git update-index --index-version=3") }

        it_behaves_like 'git ls-files'
      end

      describe 'index version 4' do
        before { system("git update-index --index-version=4") }

        it_behaves_like 'git ls-files'
      end
    end
  end
end
