# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: strict
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/uri_template/all/uri_template.rbi
#
# uri_template-0.7.0

module URITemplate
  def +(other, *args, &block); end
  def /(other, *args, &block); end
  def ==(other, *args, &block); end
  def >>(other, *args, &block); end
  def absolute?; end
  def concat(other, *args, &block); end
  def concat_without_coercion(other); end
  def eq(other, *args, &block); end
  def eq_without_coercion(other); end
  def expand(variables = nil); end
  def expand_partial(variables = nil); end
  def host?; end
  def normalize_variables(variables); end
  def path_concat(other, *args, &block); end
  def path_concat_without_coercion(other); end
  def pattern; end
  def relative?; end
  def remove_double_slash(first_tokens, second_tokens); end
  def scheme?; end
  def scheme_and_host; end
  def self.apply(a, method, b, *args); end
  def self.coerce(a, b); end
  def self.coerce_first_arg(meth); end
  def self.new(*args); end
  def self.resolve_class(*args); end
  def static_characters; end
  def to_s; end
  def tokens; end
  def type; end
  def variables; end
  extend URITemplate::ClassMethods
end
module URITemplate::ClassMethods
  def convert(x); end
  def included(base); end
  def try_convert(x); end
end
module URITemplate::Invalid
end
module URITemplate::InvalidValue
end