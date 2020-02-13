# frozen_string_literal: true

require 'dry-configurable'

require 'instrument_all_the_things/version'

require_relative './instrument_all_the_things/helpers'

module InstrumentAllTheThings
  class Error < StandardError; end

  extend Dry::Configurable

  setting(:stat_prefix)

  setting(:logger,
          if defined?(Rails)
            Rails.logger
          elsif defined?(App) && App.respond_to?(:logger)
            App.logger
          else
            require 'logger'
            Logger.new(STDOUT)
          end)

  setting(:stat_reporter,
          if defined?(Datadog::Statsd)
            require_relative './clients/stat_reporter/datadog'
            Clients::StatReporter::DataDog.new(
              ENV.fetch('DATADOG_HOST', 'localhost'),
              ENV.fetch('DATADOG_PORT', 8125)
            )
          else
            require 'instrument_all_the_things/clients/stat_reporter/blackhole'
            Clients::StatReporter::Blackhole.new
          end)

  setting(:tracer,
          if defined?(Datadog) && Datadog&.tracer
            Datadog.tracer
          else
            require 'instrument_all_the_things/clients/tracer/blackhole'
            BlackholeTracer.new
          end)
end

IATT = InstrumentAllTheThings
