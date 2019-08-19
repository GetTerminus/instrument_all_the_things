# frozen_string_literal: true

require 'active_support/deprecation'

module InstrumentAllTheThings
  module HelperMethodHelpers
    METHODS_LIST = %i[
      increment
      decrement
      time
      timing
      gauge
      histogram
      set
      count
    ].freeze

    def self.instrumented_method_name(meth)
      "instrumentation_#{meth}"
    end
  end

  module HelperMethods
    def self.included(base)
      base.extend self
    end

    %i[with_tags transmitter normalize_class_name].each do |meth|
      define_method(meth) do |*args, &blk|
        InstrumentAllTheThings.public_send(meth, *args, &blk)
      end
    end

    InstrumentAllTheThings::HelperMethodHelpers::METHODS_LIST.each do |meth|
      full_method_name = HelperMethodHelpers.instrumented_method_name(meth)

      define_method(full_method_name) do |*args, &blk|
        transmitter.public_send(meth, *args, &blk)
      end
    end

    def capture_exception(*args, &blk)
      ExceptionHandler.capture(*args, &blk)
    end

    def time_block
      time1 = Time.now
      yield
      (Time.now - time1) * 1000
    end

    def instrument_allocations(metric_prefix, &blk)
      ret, new_allocations, new_pages = measure_memory_impact(&blk)

      transmitter.histogram("#{metric_prefix}.allocation_increase", new_allocations)
      transmitter.histogram("#{metric_prefix}.page_increase", new_pages)

      ret
    end

    def measure_memory_impact
      starting_allocations = now_allocations
      starting_pages = now_allocations
      ret_value = yield
      ending_allocations = now_allocations
      ending_pages = now_pages
      [
        ret_value,
        ending_allocations - starting_allocations,
        ending_pages - starting_pages
      ]
    end

    def now_allocations
      GC.stat(:total_allocated_objects)
    end

    def now_pages
      GC.stat(:total_allocated_pages)
    end
  end
end
