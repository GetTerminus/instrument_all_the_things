Visibility into your application is one of the most critical parts of software development. At best, visibility is typically an afterthought and this is a problem. So what do you do?

![Instrument all the things](./logo.jpg?raw=true)

# InstrumentAllTheThings

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


## Method Instrumentation
Method instrumentation both in APM as well as in simple counts & timings is the bread and butter of visibility, and it
is trivial to implement with IATT.

Each measured metric may be individually disabled, and some may be provided additional configuration. All measurments
default to on, unless otherwise specified. You may disable the specified measurement by providing a falsy value to the
configuration key when calling `instrument`

*Example*
```ruby
class Foo
  include InstrumentAllTheThings

  instrument config_key: {configuration_option: 123}
  def foo
  end
end
```
### Garbage Collection Stats
_Configuration Key `gc_stats`_

Collects the difference between the specified keys during the execution of the method.

Stat diffs are added to the active trace span as a tag, and a stat is emitted with the following format

`klass_name.(instance|class)_methods.(stat_name)_change`

#### Description of default stats
_GC Stats are not thread local, if your app is multi threaded other threads may be contributing to these stats_
| Option                  | Description
| -----                   | ----
| total_allocated_pages   | Total number of memory pages owned by this ruby process. Mature processes tend to see a slowdown in page allocations
| total_allocated_objects | Total number of objects which have not been garbage collected yet
| count                   | Total number of GC runs during this method's exuection

#### Options
| Option       | Description              | Default
| -----        | ----                     | -----
| diffed_stats | Stats to diff and record | [:total_allocated_pages, :total_allocated_objects, :count]

### Error Logging
_Configuration Key `log_errors`_

When set to a non falsy value all errors raised in a span will be logged to the configured IATT logger and re-emitted.
The first traces span where they are seen logs them only, they will not be re-logged by IATT at any future level

By default call stacks are logged without all gem paths (as defined by the `Bundler.bundle_path`)

| Option              | Description                                                                         | Default
| -----               | ----                                                                                | -----
| rescue_class        | The parent error which should be caught and logged                                  | StandardError
| exclude_bundle_path | If truthy, remove all entries from the error backtrace which are in the bundle path | true

### Tracing
_Configuration Key `trace`_

When set to a non falsy value, a span for this method will be created. The defaults are listed below. This hash will
also be passed to the DataDog tracer, and their [options](https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#manual-instrumentation) should also be understood.

| Option    | Description                                                   | Default
| -----     | ----                                                          | -----
| service   | This is the value which shows up on the [first page of the APM screen](https://app.datadoghq.com/apm/home) this should be set at the entry point of your application or process | `nil`
| resource  | How this method will show up when viewing the service in APM. | For instance methods `ClassName.method_name`<br>For class methods `ClassName#method_name`
| span_name | You probably don't want to change this                        | `method.execution`
| span_type | See DD Docs.                                                  | `nil`
| tags      | Set of tags to be added to the span, expected to be a hash    | {}

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

IATT.stat_reporter = IATT::Testing::StatTracker.new

RSpec.configure do |config|
  config.before(:each) do
    IATT::Testing::TraceTracker.tracker.reset!
    IATT.stat_reporter.reset!
  end
end
```

This injects middleware and in the StatsD interface as well as in the Tracer output. By doing this you can start using
some awesome rspec helpers like so:

```ruby
  let(:klass) do
    Class.new do
      include InstrumentAllTheThings::Helpers

      instrument
      def foo
      end

      def self.inspect
        'KlassName'
      end
    end
  end

  it 'traces' do
    expect {
      klass.new.foo

      # Datadog writes trace to the wire and to the test harness asynchronously
      # This helper is provided to force the flush before expectations are stated
      flush_traces
    }.to change{
      emitted_spans(
        filtered_by: {resource: 'KlassName.foo'}
      )
    }.by(1)
  end
end
```

## Configuration
The configuration for IATT is available on the top level  InstrumentAllTheThings module.

| Config Name   | Description                                                                                       | Default
| -----------   | -----------                                                                                       | -------
| stat_prefix   | The string to add to all outbound stats (may not be changed after stat transmiter initialization) | `nil`
| logger        | The logger used to report errors and info                                                         | If the constant `Rails` is set, use `Rails.logger`. <br>If `App` and it responds to `logger` use `App.logger`. Otherwise create a new `Logger` sent to STDOUT
| stat_reporter | The class which receives simple stats                                                             | If [Datadog::Statsd](https://github.com/DataDog/dogstatsd-ruby) is found, use that, otherwise the Blackhole client is used
| tracer        | The instance of a tracer which will handle all traces                                             | If `Datadog` is defined and responds to `tracer`, use the value returned by that. Otherwise use the Blackhole. [Gem](https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md)


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
