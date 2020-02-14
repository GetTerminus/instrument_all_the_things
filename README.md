# InstrumentAllTheThings

Visibility into your application is one of the most critical parts of software development. At best, visibility is typically an afterthought and this is a problem. So what do you do?

![Instrument all the things](./logo.jpg?raw=true)

At Terminus we use DataDog for our application visibility. InstrumentAllTheThings provides simple ways to quickly and unobtrusively add detailed instrumentation to Datadog metrics and Datadog APM.

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
*Note:* For convenience the InstrumentAllTheThings constant is aliased to IATT.



## Testing Support

You can setup your test environment by running the following setup:

```ruby
require 'instrument_all_the_things/testing/stat_tracker'
require 'instrument_all_the_things/testing/trace_tracker'

Datadog.configure do |c|
  c.tracer transport_options: proc { |t|
    t.adapter :test, IATT::Testing::TraceTracker.new
  }
end

IATT.config.stat_reporter = IATT::Testing::StatTracker.new
```

This injects middleware and in the StatsD interface as well as in the Tracer output. By doing this you can start using
some awesome rspec helpers like so:

```ruby
let(:klass) do
  Class.new do
    include InstrumentAllTheThings::Helpers
  end
end
```

## Configuration
The configuration for IATT is available through the InstrumentAllTheThings.config helpers.

| Config Name   | Description                                           | Default
| -----------   | -----------                                           | -------
| stat_prefix   | The string to add to all outbound stats               | `nil`
| logger        | The logger used to report errors and info             | If the constant `Rails` is set, use `Rails.logger`. <br>If `App` and it responds to `logger` use `App.logger`. Otherwise create a new `Logger` sent to STDOUT
| stat_reporter | The class which receives simple stats                 | If [Datadog::Statsd](https://github.com/DataDog/dogstatsd-ruby) is found, use that, otherwise the Blackhole client is used
| tracer        | The instance of a tracer which will handle all traces | If `Datadog` is defined and responds to `tracer`, use the value returned by that. Otherwise use the Blackhole. [Gem](https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md)


### Stats Reporters
#### Datadog
The default client if the constant `Datadog::Statsd` is found.

Initialized with environment variables
* `DATADOG_HOST` if set, otherwise `localhost`
* `DATADOG_POST` if set, otherwise `8125`

### Tracers
#### Datadog
The default client if the constant `Datadog` is found and has a non-null value for `tracer`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/instrument_all_the_things.
