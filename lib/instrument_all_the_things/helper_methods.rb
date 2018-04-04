require 'active_support/deprecation'

module InstrumentAllTheThings
  module HelperMethodHelpers
    METHODS_LIST = [
      :increment,
      :decrement,
      :time,
      :timing,
      :gauge,
      :histogram,
      :set,
      :count,
    ].freeze

    def self.instrumented_method_name(meth)
      "instrumentation_#{meth}"
    end
  end

  module HelperMethods
    def self.included(base)
      base.extend self
    end

    %i{with_tags transmitter normalize_class_name}.each do |meth|
      define_method(meth) do |*args, &blk|
        InstrumentAllTheThings.public_send(meth, *args, &blk)
      end
    end

    InstrumentAllTheThings::HelperMethodHelpers::METHODS_LIST.each do |meth|
      full_method_name = HelperMethodHelpers.instrumented_method_name(meth)

      define_method(meth) do |*args, &blk|
        ActiveSupport::Deprecation.warn("IATT #{meth} is deprecated and will be replaced with #{full_method_name}")
        transmitter.public_send(meth, *args, &blk)
      end

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
  end
end

