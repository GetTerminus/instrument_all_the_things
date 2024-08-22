# frozen_string_literal: true

require 'instrument_all_the_things'
require 'benchmark/ips'

# Datadog.configure do |c|
#   c.tracing.transport_options = proc { |t| t.adapter :test }
# end

class Instrumented
  include InstrumentAllTheThings

  def uninstrumetned; end

  instrument
  def the_works; end

  instrument trace: true, error_logging: false, execution_counts_and_timing: false
  def only_trace; end

  instrument trace: false, error_logging: true, execution_counts_and_timing: false
  def only_error_logging; end

  instrument trace: false, error_logging: false, execution_counts_and_timing: true
  def only_execution_counts; end
end

instance = Instrumented.new
Benchmark.ips do |x|
  x.report('uninstrumetned') { instance.uninstrumetned }
  x.report('the_works') { instance.the_works }
  x.report('only_trace') { instance.only_trace }
  x.report('only_error_logging') { instance.only_error_logging }
  x.report('only_execution_counts') { instance.only_execution_counts }
end
