# GitLS.files

Parses the .git/index file like `git ls-files` does.

- faster than doing the system call to git
- doesn't require git to be installed
- tested against ruby 2.4 - 3.4.1 and jruby

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'git_ls'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install git_ls

And require
```ruby
require 'git_ls'
```

## Usage

`GitLS.files` reads the `.git/index` file to return an array of file paths, equivalent to `` `git ls-files`.split("\n") ``, but faster, and without requiring git being installed.

`GitLS.files("path/to/repo")` if the repo is not $PWD.

Strictly speaking it's equivalent to `` `git ls-files -c core.quotepath=off -z`.split("\0") ``, handling file paths with spaces and non-ascii characters, and returning file paths as UTF-8 strings.

## Development

- Have a look in the bin dir for some useful tools.
- To install this gem onto your local machine, run `bundle exec rake install`.
- Run `rake` to run all tests & linters.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/robotdana/git_ls.
If you're comfortable, please attach `.git/index` (and `.git/sharedindex.<sha>` if applicable) and the output of `git ls-files` where it doesn't match.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
