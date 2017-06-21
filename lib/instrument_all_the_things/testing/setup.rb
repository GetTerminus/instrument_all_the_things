require 'instrument_all_the_things/testing/rspec' if defined?(RSpec)

module InstrumentAllTheThings
  class Transmission
    attr_accessor :counts, :timings

    def initialize(*args, &blk)
      reset!
      super
    end

    def reset!
      self.counts  = Hash.new{|h,k| h[k] = [] }
      self.timings = Hash.new{|h,k| h[k] = [] }
    end

    def _original_count(stat, change, options = {})
      self.counts[stat] << { value: change, tags: options[:tags] || [] }
    end

    def _original_timing(stat, ms, options = {})
      self.timings[stat] << { value: ms, tags: options[:tags] || [] }
    end
  end
end
