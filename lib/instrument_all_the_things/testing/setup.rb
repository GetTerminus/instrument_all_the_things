require 'instrument_all_the_things/testing/rspec' if defined?(RSpec)

module InstrumentAllTheThings
  class Transmission
    attr_accessor :counts, :timings, :histogram

    def initialize(*args, &blk)
      reset!
      super
    end

    def reset!
      self.counts    = Hash.new{|h,k| h[k] = [] }
      self.timings   = Hash.new{|h,k| h[k] = [] }
      self.histogram = Hash.new{|h,k| h[k] = [] }
    end

    alias _original_count_old _original_count
    def _original_count(stat, change, options = {})
      self.counts[stat] << { value: change, tags: options[:tags] || [] }
      _original_count_old(stat, change, options)
    end

    alias _original_timing_old _original_timing
    def _original_timing(stat, ms, options = {})
      self.timings[stat] << { value: ms, tags: options[:tags] || [] }
      _original_timing_old(stat, ms, options)
    end

    alias _original_histogram_old _original_histogram
    def _original_histogram(stat, ms, options = {})
      self.histograms[stat] << { value: ms, tags: options[:tags] || [] }
      _original_histogram_old(stat, ms, options)
    end

    def send_stats(*_)
      # Don't do anything
    end
  end
end
