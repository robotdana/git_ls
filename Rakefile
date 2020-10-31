# frozen_string_literal: true

# typed: false

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

if RUBY_PLATFORM == 'java'
  task default: %i{spec build}
else
  require 'rubocop/rake_task'
  require 'spellr/rake_task'
  require 'leftovers/rake_task'
  RuboCop::RakeTask.new
  Spellr::RakeTask.generate_task
  Leftovers::RakeTask.generate_task

  task :sorbet do
    exit 1 unless system('bundle exec srb tc')
  end

  task default: %i{spec sorbet rubocop spellr leftovers build}
end
