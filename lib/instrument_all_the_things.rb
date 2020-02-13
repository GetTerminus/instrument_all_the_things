# frozen_string_literal: true

require 'dry-configurable'

require 'instrument_all_the_things/version'

require_relative './instrument_all_the_things/helpers'

module InstrumentAllTheThings
  class Error < StandardError; end

  extend Dry::Configurable

  setting(:logger,
          if defined?(Rails)
            Rails.logger
          elsif defined?(App) && App.respond_to?(:logger)
            App.logger
          else
            require 'logger'
            Logger.new(STDOUT)
          end)

  setting(:stats_transmitter,
          if defined?(Datadog::Statsd)
            require_relative './clients/datadog'
            Clients::DataDog.new(
              ENV.fetch('DATADOG_HOST', 'localhost'),
              ENV.fetch('DATADOG_PORT', 8125)
            )
          else
            require_relative './instrument_all_the_things/clients/blackhole'
            Clients::Blackhole.new
          end)
end

IATT = InstrumentAllTheThings
