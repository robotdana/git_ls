# GitLS.files

Parses the .git/index file like `git ls-files` does.

- for small repos (as in, anything smaller than rails),
  it can be faster than doing the system call to git
- still takes less than half a second for very large repos e.g. the linux repo
- doesn't require git to be installed

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'git_ls'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install git_ls

## Usage

`GitLS.files` returns an array of filenames, equivalent to `` `git ls-files -z`.split("\0") ``
`GitLS.files("path/to/repo")` if the repo is not $PWD.

## Development

Have a look in the bin dir for some useful tools.
To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/robotdana/git_ls.
If you're comfortable, please attach `.git/index` (and `.git/sharedindex.<sha>` if applicable) and the output of `git ls-files` where it doesn't match.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
# git_ls
