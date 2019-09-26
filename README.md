# InstrumentAllTheThings

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

### Configuration
Two ENV variables are required to connect InstrumentAllTheThings with DataDog.

1. `DATADOG_HOST` - defaults to localhost
2. `DATADOG_PORT` - defaults to 8125


## Global Configuration
When configuring IATT you can set global configuration options like so:

```ruby
InstrumentAllTheThings.config do |config|
  config.config_options = wassup
end
```

Allowed configuration options:

| Configuration Option          | Default               | Description
| --------------------          | --------------------- | --------------
| stat_prefix                   | nil                   | string to prefix to all outgoing stats
| exclude_rails_instrumentation | false                 | set to true to disable auto instrumentation of the rails stack
| tracer                        | `Datadog.tracer`      | The tracer to use for tracing. If nil warnings will be issued when tracing is attempted.
| logger                        | Rails Logger or STDOUT Logger      | Logger for IATT related issues


### Usage in application code
Within your application code, the `InstrumentAllTheThings::HelperMethods` module
can be included to provide some helper methods.

```ruby
class SomeClass
  include InstrumentAllTheThings::HelperMethods

  instrument
  def foo
     instrumentation_increment('thing.in.progress')
     time('time.me') do
       # Do more work
     end
     instrumentation_decrement('thing.in.progress')
  end

  def bar
    instrumentation_decrement('dowacky') # instrumentation of the entire method is not required
  end
end
```

#### `instrument` options

##### `as`

```
class TestModule::TestClass

  instrument
  def base
  end

  instrument as: "override_foo"
  def foo
  end


  instrument as: -> { "proc_override"}
  def foo_with_proc
  end

  instrument as: -> (m) { m.key_name }
  def foo_with_proc_options
  end

  def key_name
    "key_name_from_proc"
  end
end
```

will create the following metrics:

* `test_module.test_class.instance.base.count`
* `test_module.test_class.instance.base.timing`
* `override_foo.count`
* `override_foo.timing`
* `proc_override.count`
* `proc_override.timing`
* `key_name_from_proc.count`
* `key_name_from_proc.timing`


##### `prefix`

You can also pass a `prefix` option to instrument, which will prefix the key with the provided string. Examples:

```
class TestModule::TestClass
  instrument prefix: 'my_prefix'
  def foo
  end

  instrument prefix: 'my_prefix'
  def self.foo
  end
```

will create the following metrics when called:

* `my_prefix.test_module.test_class.instance.foo.count`
* `my_prefix.test_module.test_class.instance.foo.timing`
* `my_prefix.test_module.test_class.class.foo.count`
* `my_prefix.test_module.test_class.class.foo.timing`

### Instrumentation Helpers
The helpers provided by the HelperMethods module

#### with_tags(*tags, options = {}, &blk)
Any instrumentation method with that block will have those tags appended to it.

Options:
* `except` - an array of strings or regex of active tags to remove from the active tag list

__Example__
```ruby
InstrumentAllTheThings.active_tags += ['foo:bar']

class Foo
  include InstrumentAllTheThings::HelperMethods

  def foo
    with_tags('omg:wassup', 'dude:car?') do
      # Tags are now foo:bar, omg:wassup, dude:car?
      with_tags('baz:nitch', except: [/\Adude:.*/]) do
        # Tags are now foo:bar, omg:wassup, baz:nitch
        with_tags(except: [/\Aomg:.*/]) do
          # Tags are now foo:bar, baz:nitch
        end
        # Tags are back to foo:bar, omg:wassup, baz:nitch
      end
      # Tags are now back to foo:bar, omg:wassup, dude:car?
    end
  end
end
```

#### instrumentation_increment(stat, options = {})
Wrapper for [Datadog::Statsd#instrumentation_increment](http://www.rubydoc.info/github/DataDog/dogstatsd-ruby/master/Datadog%2FStatsd:instrumentation_increment)

#### instrumentation_decrement(stat, options = {})
Wrapper for [Datadog::Statsd#instrumentation_decrement](http://www.rubydoc.info/github/DataDog/dogstatsd-ruby/master/Datadog%2FStatsd:instrumentation_decrement)

#### instrumentation_time(stat, options = {}, &blk)
Wrapper for [Datadog::Statsd#time](http://www.rubydoc.info/github/DataDog/dogstatsd-ruby/master/Datadog%2FStatsd:time)

#### instrumentation_iming(stat, options = {}, &blk)
Wrapper for [Datadog::Statsd#timing](http://www.rubydoc.info/github/DataDog/dogstatsd-ruby/master/Datadog%2FStatsd:timing)

#### instrumentation_guage(stat, value, options = {})
Wrapper for [Datadog::Statsd#guage](http://www.rubydoc.info/github/DataDog/dogstatsd-ruby/master/Datadog%2FStatsd:gauge)

#### instrumentation_histogram(stat,value, options = {})
Wrapper for [Datadog::Statsd#histogram](http://www.rubydoc.info/github/DataDog/dogstatsd-ruby/master/Datadog%2FStatsd:histogram)

#### instrumentation_set(stat,value, options = {})
Wrapper for [Datadog::Statsd#set](http://www.rubydoc.info/github/DataDog/dogstatsd-ruby/master/Datadog%2FStatsd:set)

#### instrumentation_count(stat,value, options = {})
Wrapper for [Datadog::Statsd#count](http://www.rubydoc.info/github/DataDog/dogstatsd-ruby/master/Datadog%2FStatsd:count)

#### instrumentation_event(title, text, options = {})
Wrapper for [Datadog::Statsd#event](http://www.rubydoc.info/github/DataDog/dogstatsd-ruby/master/Datadog%2FStatsd:event)

### Method Instrumentation
Before any method you want to instrument, you just need to add a call to
`instrument` in any class which includes `InstrumentAllTheThings::Methods`

```ruby
instrument
def omg
 # stuff
end

instrument
def self.omg
 # stuff
end
```

These methods will be instrumented with some default behaviors. By default it
counts the number of calls, times the total duration, and captures and registers
any exceptions.

By default the following tags are added to any stats call within
an instrumented method (and down the stack). `method:METHOD_NAME` and
`method_class:CLASS_NAME` the method name is the actual method name, pefixed
with either a `#` or `.` for instance and class method respectivly.

#### Output Instrumentation
By default every method produces a `methods.count` and `methods.timing`. If you
would like to provide a custom naming scheme, you can specify the `:as` option.

__Example__
```ruby
instrument as: 'foo.bar.baz'
def omg
end
```

All calls to `omg` will be instrumented as `foo.bar.baz.count` and
`foo.bar.baz.timing`.


#### Adding more tags
You can append tags to the instrmentation methods by specifying the tag key
as either a array of string, or a proc. The proc will be provided with the
arguments to the method.

If the keyword `instrumentation_context` is provided along with args, the context will be passed in.

__Example__
```ruby

class Foo
  attr_accessor :bar

  instrument tags: ['foo:bar']
  def omg
  end

  instrument tags: ->(args) { ["arg1:#{args[1]}"] }
  def omg
    instrumentation_increment('omg.count')
  end


  instrument tags: ->(*args, instrumentation_context:) { ["arg1:#{args[1]}", "bar.val:#{instrumentation_context.bar}"] }
  def def omg
    instrumentation_increment('omg.count')
  end
end

```

Note: Any instrumentation call that occurs within the method will have the
tags method's tags applied to it. See the docs for `with_tags`

#### Exceptions
If an exception is raised within a method that is instrumented it will be
recorded in `exceptions.count` with all of the method tags defined for that
method. If a custom name is provided via `:as` it will be regsitered as
`custom.name.exceptions.count`

### Method Tracing

```
instrument trace: { as: 'foo' }
def bar
end
```

Options available for tracing are [DataDog Docs](http://gems.datadoghq.com/trace/docs/Datadog/Tracer.html#trace-instance_method)
* +service+: the service name for this span
* +resource+: the resource this span refers, or \name if it's missing
* +span_type+: the type of the span (such as \http, \db and so on)
* +tags+: extra tags which should be added to the span.
* +include_parent_tags+: Appends the tags that were applied from parent spans or
    with a `with_tags` block

Tags provided directly in the `trace` options key are preferred to tags generated
via the `tags` key or from within a `with_tags` block. Tags provided via
`with_tags` or a `tags` parameter to the `instrument` call are ignored unless
`include_parent_tags` is specified.

### Testing Support
IATT comes with some helpers to make testing a little easier for RSpec. If you
include the module, outbound messages will be intercepted at the transmitter.

First you need to require the helpers in your `spec_helper.rb` with
`require 'instrument_all_the_things/testing/setup'`. This will install the
interceptor, and if RSpec is already required it will add a before filter to
clear the stored metrics on each test. You should also add
`config.include InstrumentAllTheThings::Testing::Aggregators` to your RSpec
config to enable the helpers below.


During a test you can get access to the counters and filter them using a few
helpers.

* __get_counter(counter_name)__ - gets an object with all calls to a counter with a given name
* __get_timings(timer_name)__ - gets an object with all calls to timers with a given name

#### Working with stats
The following methods can be used to filter or total the stats that have been
transmitted. Each method modifies the object in-place
* __with_tags(*tag_filters)__ - only takes stats that match ALL of the tag
  filters. Each tag filter can be a string for an exact match, or a regular
  expression. Returns `self`
* __values__ - Returns the raw values actually transmitted.
* __total__ - The sum of all values transmitted

__Example__
```ruby
class Foo
  include InstrumentAllTheThings::HelperMethods

  def bar(entries, old_way)
    if old_way
      with_tags('type:old') do
        instrumentation_increment('did.things', entries.length)
      end
    else
      with_tags('type:new') do
        instrumentation_increment('did.things', entries.length)
      end
    end
  end
end

RSpec.describe Foo do
  let(:instance) { Foo.new }

  context "doing things the old way" do
    it "counts the things" do
      expect {
        instance.bar([1,2], true)
      }.to change {
        get_counter('did.things').with_tags('type:old').total
      }.by(2).and.not_to change {
        get_counter('did.things').with_tags('type:new').total
      }.from(nil)
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/instrument_all_the_things.

