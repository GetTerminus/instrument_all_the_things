# frozen_string_literal: true

require 'dry-configurable'
require 'ddtrace'

require 'instrument_all_the_things/version'

require_relative './instrument_all_the_things/helpers'
require_relative './instrument_all_the_things/clients/stat_reporter/datadog'

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

  setting(
    :stat_reporter,
    Clients::StatReporter::DataDog.new(
      ENV.fetch('DATADOG_HOST', 'localhost'),
      ENV.fetch('DATADOG_PORT', 8125)
    )
  )

  setting(:tracer, Datadog.tracer)
end

IATT = InstrumentAllTheThings
