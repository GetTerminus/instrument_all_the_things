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
require 'instrument_all_the_things/testing/rspec_matchers'

Datadog.configure do |c|
  c.tracer transport_options: proc { |t|
    t.adapter :test, IATT::Testing::TraceTracker.new
  }
end

IATT.stat_reporter = IATT::Testing::StatTracker.new

RSpec.configure do |config|
  config.include InstrumentAllTheThings::Testing::RSpecMatchers
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

## Stat Transmission
InstrumentAllTheThings provides no real functionality on top of the build in Datadog statsd utility. The primary goal
of the IATT library is to allow for easy testing. The following method are provided on the InstrumentAllTheThings module.

### Increment
Examples:
```ruby
expect{
  InstrumentAllTheThings.increment('my.counter')
}.to change{ counter_value('my.counter') }.from(0).to(1)

expect{
  InstrumentAllTheThings.increment('my.counter', by: 5)
}.to change { counter_value('my.counter') }.from(0).to(5)

# You can also filter by tags
expect {
  InstrumentAllTheThings.increment('my.counter', by: 3, tags: ['a:b', 'foo:bar'])
  InstrumentAllTheThings.increment('my.counter', by: 2, tags: ['a:b', 'foo:baz'])
}.to change { counter_value('my.counter') }.from(0).to(5)
  .and change { counter_value('my.counter', with_tags: ['a:b']) }.from(0).to(5)
  .and change { counter_value('my.counter', with_tags: ['foo:bar']) }.from(0).to(3)
  .and change { counter_value('my.counter', with_tags: ['foo:baz']) }.from(0).to(2)
```

### Decrement
See Increment for all examples
```ruby
expect{
  InstrumentAllTheThings.increment('my.counter')
}.to change{ counter_value('my.counter') }.from(0).to(-1)
```

### Count
Count underlies both increment and decrement, and works in a similar way.

```ruby
expect {
  InstrumentAllTheThings.count('my.counter', 3, tags: ['a:b', 'foo:bar'])
  InstrumentAllTheThings.count('my.counter', 2, tags: ['a:b', 'foo:baz'])
}.to change { counter_value('my.counter') }.from(0).to(5)
  .and change { counter_value('my.counter', with_tags: ['a:b']) }.from(0).to(5)
  .and change { counter_value('my.counter', with_tags: ['foo:bar']) }.from(0).to(3)
  .and change { counter_value('my.counter', with_tags: ['foo:baz']) }.from(0).to(2)
```

### Gauge
```ruby
expect {
  InstrumentAllTheThings.gauge('my.gauge', 1)
  InstrumentAllTheThings.gauge('my.gauge', 2)
}.to change { gauge_value('my.gauge') }.from(nil).to(2)

expect {
  InstrumentAllTheThings.gauge('my.gauge', 3, tags: ['a:b', 'foo:bar'])
  InstrumentAllTheThings.gauge('my.gauge', 1, tags: ['a:b', 'foo:bar'])
  InstrumentAllTheThings.gauge('my.gauge', 2, tags: ['a:b', 'foo:baz'])
  InstrumentAllTheThings.gauge('my.gauge', 7, tags: ['a:b'])
}.to change { gauge_value('my.gauge') }.to(7)
  .and change { gauge_value('my.gauge', with_tags: ['a:b']) }.to(7)
  .and change { gauge_value('my.gauge', with_tags: ['foo:bar']) }.to(1)
  .and change { gauge_value('my.gauge', with_tags: ['foo:baz']) }.to(2)
```

### Set
```ruby
expect {
  InstrumentAllTheThings.set('my.set', 1)
  InstrumentAllTheThings.set('my.set', 2)
}.to change { set_value('my.set') }.from(0).to(2)

expect {
  InstrumentAllTheThings.set('my.set', 3, tags: ['a:b', 'foo:bar'])
  InstrumentAllTheThings.set('my.set', 3, tags: ['a:b', 'foo:bar'])
  InstrumentAllTheThings.set('my.set', 5, tags: ['a:b', 'foo:bar'])
  InstrumentAllTheThings.set('my.set', 6, tags: ['a:b', 'foo:baz'])
  InstrumentAllTheThings.set('my.set', 9, tags: ['a:b'])
}.to change { set_value('my.set') }.to(4)
  .and change { set_value('my.set', with_tags: ['a:b']) }.to(4)
  .and change { set_value('my.set', with_tags: ['foo:bar']) }.to(2)
  .and change { set_value('my.set', with_tags: ['foo:baz']) }.to(1)
```

### Histogram
Histogram is a pesudo metric in Datadog based on the StatsD timing metric. InstrumentAllTheThings provides a way to
test the values emitted, not the statistical calculations derived.

```ruby
expect {
  InstrumentAllTheThings.histogram('my.histogram', 1)
  InstrumentAllTheThings.histogram('my.histogram', 2)
}.to change { histogram_values('my.histogram') }.from([]).to([1, 2])

expect {
  InstrumentAllTheThings.histogram('my.histogram', 3, tags: ['a:b', 'foo:bar'])
  InstrumentAllTheThings.histogram('my.histogram', 5, tags: ['a:b', 'foo:bar'])
  InstrumentAllTheThings.histogram('my.histogram', 6, tags: ['a:b', 'foo:baz'])
  InstrumentAllTheThings.histogram('my.histogram', 9, tags: ['a:b'])
}.to change { histogram_values('my.histogram') }.to([3, 5, 6, 9])
  .and change { histogram_values('my.histogram', with_tags: ['a:b']) }.to([3, 5, 6, 9])
  .and change { histogram_values('my.histogram', with_tags: ['foo:bar']) }.to([3, 5])
  .and change { histogram_values('my.histogram', with_tags: ['foo:baz']) }.to([6])
```

### Distribution
```ruby
expect {
  InstrumentAllTheThings.distribution('my.distribution', 1)
  InstrumentAllTheThings.distribution('my.distribution', 2)
}.to change { distribution_values('my.distribution') }.from([]).to([1, 2])

expect {
  InstrumentAllTheThings.distribution('my.distribution', 3, tags: ['a:b', 'foo:bar'])
  InstrumentAllTheThings.distribution('my.distribution', 5, tags: ['a:b', 'foo:bar'])
  InstrumentAllTheThings.distribution('my.distribution', 6, tags: ['a:b', 'foo:baz'])
  InstrumentAllTheThings.distribution('my.distribution', 9, tags: ['a:b'])
}.to change { distribution_values('my.distribution') }.to([3, 5, 6, 9])
  .and change { distribution_values('my.distribution', with_tags: ['a:b']) }.to([3, 5, 6, 9])
  .and change { distribution_values('my.distribution', with_tags: ['foo:bar']) }.to([3, 5])
  .and change { distribution_values('my.distribution', with_tags: ['foo:baz']) }.to([6])
```

### Timing
```ruby
expect {
  InstrumentAllTheThings.timing('my.timing', 1)
  InstrumentAllTheThings.timing('my.timing', 2)
}.to change { timing_values('my.timing') }.from([]).to([1, 2])

expect {
  InstrumentAllTheThings.timing('my.timing', 3, tags: ['a:b', 'foo:bar'])
  InstrumentAllTheThings.timing('my.timing', 5, tags: ['a:b', 'foo:bar'])
  InstrumentAllTheThings.timing('my.timing', 6, tags: ['a:b', 'foo:baz'])
  InstrumentAllTheThings.timing('my.timing', 9, tags: ['a:b'])
}.to change { timing_values('my.timing') }.to([3, 5, 6, 9])
  .and change { timing_values('my.timing', with_tags: ['a:b']) }.to([3, 5, 6, 9])
  .and change { timing_values('my.timing', with_tags: ['foo:bar']) }.to([3, 5])
  .and change { timing_values('my.timing', with_tags: ['foo:baz']) }.to([6])
```

### Time
The time helper wraps a block with reporting to the timing metric time. As such specs should leverage that spec helper.

```ruby
expect {
  InstrumentAllTheThings.time('my.time') {}
  InstrumentAllTheThings.time('my.time') {}
}.to change { timing_values('my.time').length }.from(0).to(2)

expect {
  InstrumentAllTheThings.time('my.time', tags: ['a:b', 'foo:bar']) {}
  InstrumentAllTheThings.time('my.time', tags: ['a:b', 'foo:bar']) {}
  InstrumentAllTheThings.time('my.time', tags: ['a:b', 'foo:baz']) {}
  InstrumentAllTheThings.time('my.time', tags: ['a:b']) {}
}.to change { timing_values('my.time').length }.to(4)
  .and change { timing_values('my.time', with_tags: ['a:b']).length }.to(4)
  .and change { timing_values('my.time', with_tags: ['foo:bar']).length }.to(2)
  .and change { timing_values('my.time', with_tags: ['foo:baz']).length }.to(1)
```
## Performance
Is it slow? That depends quite a bit on your perspective. We keep a benchmark as part of our specs and monitor the
overall cost of instrumentation. The current numbers look roughly like:

```
Calculating -------------------------------------
      uninstrumetned     17.038M (± 3.3%) i/s -     85.164M in   5.004312s
           the_works      7.404k (±12.9%) i/s -     36.936k in   5.100630s
          only_trace     27.968k (±12.7%) i/s -    139.209k in   5.061907s
  only_error_logging    638.098k (± 4.6%) i/s -      3.231M in   5.075275s
       only_gc_stats     12.930k (±13.2%) i/s -     63.865k in   5.070874s
only_execution_counts     9.847k (±11.1%) i/s -     49.088k in   5.073475s
```

All of these calculations are performed against an empty method, which ruby executes in 0.000059ms. If we consider
this the baseline, running all of the included instrumentation in the non-error case has a cost of 0.135ms. If this
is an expensive calculation is directly proportional to the execution duration of the method. If you are tracing a 1ms
method, it represents a 13% overhead, but if you are tracing a 100ms method it is only 0.13%.

The moral of the story, don't blindly add the works to every method in your stack, instead choose methods who's output
will be diagnostically meaningful.

We are also always looking for patches with will reduce execution time and allocations of the instrumentation, so
please open some PRs!

## Configuration
The configuration for IATT is available on the top level  InstrumentAllTheThings module.

| Config Name    | Description                                                                                       | Default
| -----------    | -----------                                                                                       | -------
| stat_namespace | The string to add to all outbound stats (may not be changed after stat transmiter initialization) | `nil`
| logger         | The logger used to report errors and info                                                         | If the constant `Rails` is set, use `Rails.logger`. <br>If `App` and it responds to `logger` use `App.logger`. Otherwise create a new `Logger` sent to STDOUT
| stat_reporter  | The class which receives simple stats                                                             | If [Datadog::Statsd](https://github.com/DataDog/dogstatsd-ruby) is found, use that, otherwise the Blackhole client is used
| tracer         | The instance of a tracer which will handle all traces                                             | If `Datadog` is defined and responds to `tracer`, use the value returned by that. Otherwise use the Blackhole. [Gem](https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md)


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
