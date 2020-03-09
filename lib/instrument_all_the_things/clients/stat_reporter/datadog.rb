# frozen_string_literal: true

require 'datadog/statsd'

module InstrumentAllTheThings
  module Clients
    module StatReporter
      class DataDog < Datadog::Statsd
      end
    end
  end
end
