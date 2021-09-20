# frozen_string_literal: true

require 'datadog/statsd'

module InstrumentAllTheThings
  module Testing
    class StatTracker < Clients::StatReporter::DataDog
      attr_reader :emitted_values
      %i[
      count
      distribution
      gauge
      histogram
      set
      time
      timing
      ].each do |meth|
        define_method(meth) do |*args, &blk|
          opts = args.last.is_a?(Hash) ? args.last : {}
          @emitted_values[meth][args[0]] << {
            args: args[1..-1],
            tags: opts.fetch(:tags, []),
          }

          super(*args, &blk)
        end
      end

      def initialize(*args, **kwargs, &blk)
        super
        reset!
      end

      def reset!
        @emitted_values = Hash.new do |h, k|
          h[k] = Hash.new do |h2, k2|
            h2[k2] = []
          end
        end
      end
    end
  end
end
