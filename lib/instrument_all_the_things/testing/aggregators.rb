
module InstrumentAllTheThings
  module Testing
    module Aggregators
      def get_counter(counter_name)
        BaseAggregator.new(
          InstrumentAllTheThings.transmitter.counts[counter_name]
        )
      end

      def get_timings(timer_name)
        BaseAggregator.new(
          InstrumentAllTheThings.transmitter.timings[timer_name]
        )
      end

      def get_histogram(hist_name)
        BaseAggregator.new(
          InstrumentAllTheThings.transmitter.histogram[hist_name]
        )
      end

      class BaseAggregator
        attr_accessor :metrics

        def initialize(metrics)
          self.metrics = metrics
        end

        def total
          values.inject(&:+)
        end

        def values
          self.metrics.map{|i| i[:value] }
        end

        def with_tags(*tags)
          self.metrics = self.metrics.select do |value|
            tags.all? do |a|
              value[:tags].any?{|tag| a === tag }
            end
          end

          self
        end
      end
    end
  end
end
