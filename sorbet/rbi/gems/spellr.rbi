# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: true
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/spellr/all/spellr.rbi
#
# spellr-0.8.7

module Spellr
  def config; end
  def exit(status = nil); end
  def pwd; end
  def pwd_s; end
  def self.config; end
  def self.exit(status = nil); end
  def self.pwd; end
  def self.pwd_s; end
end
class Spellr::ConfigLoader
  def [](value); end
  def config_file; end
  def initialize(config_file = nil); end
  def load_config; end
  def load_yaml(path); end
  def merge_config(default, project); end
end
class Spellr::File < Pathname
  def first_line; end
  def insert(string, range); end
  def read_write; end
  def relative_path; end
end
class Spellr::LineLocation
  def byte_offset; end
  def char_offset; end
  def file; end
  def initialize(file = nil, line_number = nil, char_offset: nil, byte_offset: nil); end
  def line_number; end
  def to_s; end
end
class Spellr::ColumnLocation
  def absolute_byte_offset; end
  def absolute_char_offset; end
  def byte_offset; end
  def char_offset; end
  def coordinates; end
  def file; end
  def initialize(char_offset: nil, byte_offset: nil, line_location: nil); end
  def inspect; end
  def line_location; end
  def line_location=(arg0); end
  def line_number; end
  def to_s; end
end
module Spellr::StringFormat
  def aqua(text); end
  def bold(text); end
  def green(text); end
  def key(label); end
  def lighten(text); end
  def normal(text = nil); end
  def pluralize(word, count); end
  def red(text); end
  def self.aqua(text); end
  def self.bold(text); end
  def self.green(text); end
  def self.key(label); end
  def self.lighten(text); end
  def self.normal(text = nil); end
  def self.pluralize(word, count); end
  def self.red(text); end
end
class String
  def spellr_normalize; end
end
class Spellr::Token < String
  def byte_range; end
  def char_range; end
  def coordinates; end
  def file_byte_range; end
  def file_char_range; end
  def highlight(range = nil); end
  def initialize(string, line: nil, location: nil); end
  def inspect; end
  def line; end
  def line=(new_line); end
  def location; end
  def replace(replacement); end
  def replacement; end
end
class Spellr::Wordlist
  def <<(term); end
  def clean(file = nil); end
  def clear_cache; end
  def each(&block); end
  def exist?; end
  def include?(term); end
  def initialize(file, name: nil); end
  def insert_sorted(term); end
  def inspect; end
  def length; end
  def name; end
  def path; end
  def to_a; end
  def touch; end
  def words; end
  def write(content); end
  include Enumerable
end
class Spellr::Language
  def addable?; end
  def default_wordlists; end
  def fast_ignore; end
  def gem_wordlist; end
  def initialize(name, key: nil, includes: nil, hashbangs: nil, locale: nil, addable: nil); end
  def key; end
  def locale_wordlists; end
  def matches?(file); end
  def name; end
  def project_wordlist; end
  def wordlists; end
end
module Spellr::Validations
  def errors; end
  def self.included(base); end
  def valid?; end
end
module Spellr::Validations::ClassMethods
  def validate(method); end
  def validations; end
end
class Spellr::ConfigValidator
  def checker_and_reporter_coexist; end
  def interactive_is_interactive; end
  def keys_are_single_characters; end
  def languages_with_conflicting_keys; end
  def only_has_one_key_per_language; end
  def valid?; end
  extend Spellr::Validations::ClassMethods
  include Spellr::Validations
end
class Spellr::Output
  def <<(other); end
  def counts; end
  def exit_code; end
  def exit_code=(value); end
  def increment(counter); end
  def print(str); end
  def puts(str); end
  def stderr; end
  def stderr?; end
  def stdin; end
  def stdout; end
  def stdout?; end
  def warn(str); end
end
class Spellr::Config
  def checker; end
  def checker=(arg0); end
  def config_file; end
  def config_file=(value); end
  def default_checker; end
  def default_reporter; end
  def dry_run; end
  def dry_run=(arg0); end
  def dry_run?; end
  def dry_run_checker; end
  def excludes; end
  def includes; end
  def initialize; end
  def key_heuristic_weight; end
  def key_minimum_length; end
  def languages; end
  def languages_for(file); end
  def output; end
  def reporter; end
  def reporter=(arg0); end
  def reset!; end
  def suppress_file_rules; end
  def suppress_file_rules=(arg0); end
  def valid?; end
  def word_minimum_length; end
  def wordlists_for(file); end
end
class Spellr::Error < StandardError
end
class Spellr::Wordlist::NotFound < Spellr::Error
end
class Spellr::Config::NotFound < Spellr::Error
end
class Spellr::Config::Invalid < Spellr::Error
end
class Spellr::InvalidByteSequence < ArgumentError
  def self.===(error); end
end