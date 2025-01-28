# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
linters = %i{spec}

if RUBY_PLATFORM != 'java'
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
  linters << :rubocop

  require 'spellr/rake_task'
  Spellr::RakeTask.generate_task
  linters << :spellr

  require 'leftovers/rake_task'
  Leftovers::RakeTask.generate_task
  linters << :leftovers
end

linters << :build

desc 'Run all linters'
task default: linters
