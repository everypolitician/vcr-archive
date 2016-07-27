# VCR::Archive

Using this gem causes VCR to record all HTTP interactions into separate files in a predictable directory structure. This allows you to maintain an archive of HTTP responses. It also stores the response body in a separate file for easier diffing.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vcr-archive'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vcr-archive

## Usage

```ruby
require 'vcr/archive'
require 'open-uri'

VCR.configure do |config|
  config.hook_into :webmock
  config.cassette_serializers[:vcr_archive] = VCR::Archive::Serializer
  config.cassette_persisters[:vcr_archive] = VCR::Archive::Persister
  config.default_cassette_options = { serialize_with: :vcr_archive, persist_with: :vcr_archive }
end

VCR.use_cassette('vcr_cassettes/readme_example') do
  response = open('http://example.org/').read
  # ...
end
```

After running this the response from http://example.org/ will be archived into the directory given as an argument to `VCR.use_cassette`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/everypolitician/vcr-archive.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
