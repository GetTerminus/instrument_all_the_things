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

### Configuration
Two ENV variables are required to connect InstrumentAllTheThings with DataDog.

1. `DATADOG_HOST` - defaults to localhost
2. `DATADOG_PORT` - defaults to 8125

### Usage in application code
Within your application code, the `InstrumentAllTheThings::HelperMethods` moddule
can be included to provide some helper methods.

```ruby
class SomeClass
  include InstrumentAllTheThings::HelperMethods
end
```

before any method you want to instrument, you just needto add a call to
`instrument`

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
count the number of calls, time the total duration, and capture and register
any exceptions.

By default the following tags are added to any stats call within an
an instrumented method (and down the stack). `method:METHOD_NAME` and
`method_class:CLASS_NAME` the method name is the actual method name, pefixed
with either a `#` or `.` for instance and class method respectivly.

#### Adding more tags
You can append tags to the instrmentation methods by specifying the tag key
as either a array of string, or a proc. The proc will be provided with the
arguments to the method.

```ruby
instrument tags: ['foo:bar']
def omg
end

instrument tags: ->(args) { ["arg1:#{args[1]}"] }
def omg
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/instrument_all_the_things.

