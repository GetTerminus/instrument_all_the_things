# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
end

require 'instrument_all_the_things'

require 'instrument_all_the_things/testing/stat_tracker'
require 'instrument_all_the_things/testing/trace_tracker'
require 'instrument_all_the_things/testing/rspec_matchers'

require 'pry'

Datadog.configure do |c|
  c.tracing.transport_options = proc { |t|
    t.adapter :test, IATT::Testing::TraceTracker.tracker
  }
end

IATT.stat_reporter = IATT::Testing::StatTracker.new

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include InstrumentAllTheThings::Testing::RSpecMatchers
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    IATT::Testing::TraceTracker.tracker.reset!
    IATT.stat_reporter.reset!
  end
end
