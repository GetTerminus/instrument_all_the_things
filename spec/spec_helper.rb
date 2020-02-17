# frozen_string_literal: true

require 'bundler/setup'
require 'instrument_all_the_things'

require 'instrument_all_the_things/testing/stat_tracker'
require 'instrument_all_the_things/testing/trace_tracker'
require 'instrument_all_the_things/testing/rspec_matchers'

Datadog.configure do |c|
  c.tracer transport_options: proc { |t|
    t.adapter :test, IATT::Testing::TraceTracker.tracker
  }
end

IATT.config.stat_reporter = IATT::Testing::StatTracker.new

RSpec.configure do |config|
  config.before(:each) do
    IATT::Testing::TraceTracker.tracker.reset!
    IATT.config.stat_reporter.reset!
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include InstrumentAllTheThings::Testing::RSpecMatchers
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
