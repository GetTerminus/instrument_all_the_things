# frozen_string_literal: true

require 'datadog/tracing/transport/io/client'

module InstrumentAllTheThings
  module Testing
    class TraceTracker < Datadog::Tracing::Transport::IO::Client
      attr_reader :traces

      def self.tracker
        @tracker ||= new(
          StringIO.new,
          Datadog::Core::Encoding::JSONEncoder,
        )
      end

      def initialize(...)
        super
        reset!
      end

      def reset!
        @traces = []
      end

      def write_data(_, val)
        body = JSON.parse(val)
        @traces.concat(body.fetch('traces', []).flatten)
      end
    end
  end
end
