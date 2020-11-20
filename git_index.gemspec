# frozen_string_literal: true

require_relative 'lib/git_ls/version'

Gem::Specification.new do |spec|
  spec.name = 'git_ls'
  spec.version = GitLS::VERSION
  spec.authors = ['Dana Sherson']
  spec.email = ['robot@dana.sh']

  spec.summary = 'Read a .git/index file and list the files'
  spec.homepage = 'https://github.com/robotdana/git_ls'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = spec.homepage
    spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(bin|test|spec|features)/}) }
  end

  spec.require_paths = ['lib']

  spec.add_development_dependency 'benchmark-ips'
  spec.add_development_dependency 'bundler', '>= 2'
  spec.add_development_dependency 'fast_ignore', '>= 0.15.1'
  spec.add_development_dependency 'leftovers', '>= 0.4.0'
  spec.add_development_dependency 'pry', '> 0'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop', '= 0.93.1'
  spec.add_development_dependency 'rubocop-performance', '>= 1.8.1'
  spec.add_development_dependency 'rubocop-rspec', '= 1.44.1'
  spec.add_development_dependency 'simplecov', '~> 0.18.5'
  spec.add_development_dependency 'simplecov-console'
  spec.add_development_dependency 'sorbet'
  spec.add_development_dependency 'spellr'
end
