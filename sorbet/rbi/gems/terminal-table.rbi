# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: strict
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/terminal-table/all/terminal-table.rbi
#
# terminal-table-2.0.0

module Terminal
end
class Terminal::Table
  def <<(array); end
  def ==(other); end
  def add_row(array); end
  def add_separator; end
  def align_column(n, alignment); end
  def cell_padding; end
  def cell_spacing; end
  def column(n, method = nil, array = nil); end
  def column_width(n); end
  def column_widths; end
  def column_with_headings(n, method = nil); end
  def columns; end
  def columns_width; end
  def headings; end
  def headings=(arrays); end
  def headings_with_rows; end
  def initialize(options = nil, &block); end
  def length_of_column(n); end
  def number_of_columns; end
  def recalc_column_widths; end
  def render; end
  def require_column_widths_recalc; end
  def rows; end
  def rows=(array); end
  def style; end
  def style=(options); end
  def title; end
  def title=(title); end
  def title_cell_options; end
  def to_s; end
  def yield_or_eval(&block); end
end
class Terminal::Table::Cell
  def align(val, position, length); end
  def alignment; end
  def alignment=(val); end
  def alignment?; end
  def colspan; end
  def escape(line); end
  def initialize(options = nil); end
  def lines; end
  def render(line = nil); end
  def to_s(line = nil); end
  def value; end
  def value_for_column_width_recalc; end
  def width; end
end
class Terminal::Table::Row
  def <<(item); end
  def [](index); end
  def add_cell(item); end
  def cells; end
  def height; end
  def initialize(table, array = nil); end
  def number_of_columns; end
  def render; end
  def table; end
end
class Terminal::Table::Separator < Terminal::Table::Row
  def render; end
end
class Terminal::Table::Style
  def alignment; end
  def alignment=(arg0); end
  def all_separators; end
  def all_separators=(arg0); end
  def apply(options); end
  def border_bottom; end
  def border_bottom=(arg0); end
  def border_i; end
  def border_i=(arg0); end
  def border_top; end
  def border_top=(arg0); end
  def border_x; end
  def border_x=(arg0); end
  def border_y; end
  def border_y=(arg0); end
  def initialize(options = nil); end
  def margin_left; end
  def margin_left=(arg0); end
  def on_change(attr); end
  def padding_left; end
  def padding_left=(arg0); end
  def padding_right; end
  def padding_right=(arg0); end
  def self.defaults; end
  def self.defaults=(options); end
  def width; end
  def width=(arg0); end
end
module Terminal::Table::TableHelper
  def table(headings = nil, *rows, &block); end
end
