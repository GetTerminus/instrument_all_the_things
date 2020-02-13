# InstrumentAllTheThings

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/instrument_all_the_things`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'instrument_all_the_things'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install instrument_all_the_things

## Usage

TODO: Write usage instructions here


### Configuration
The configuration for IATT is available through the InstrumentAllTheThings.config helpers.

| Config Name | Description                               | Default
| ----------- | -----------                               | -------
| logger      | The logger used to report errors and info | If the constant `Rails` is set, use `Rails.logger`. If `App` and it responds to `logger` use `App.logger`. Otherwise create a new `Logger` sent to STDOUT
| stats_transmitter | The logger used to report errors and info | If the constant `Rails` is set, use `Rails.logger`. If `App` and it responds to `logger` use `App.logger`. Otherwise create a new `Logger` sent to STDOUT

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/instrument_all_the_things.
