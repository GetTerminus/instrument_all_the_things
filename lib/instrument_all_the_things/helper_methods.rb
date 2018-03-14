module InstrumentAllTheThings
  module HelperMethods
    IATT_HELPER_METHODS = [
        :increment,
        # :decrement,
        # :time,
        # :timing,
        # :guage,
        # :histogram,
        # :set,
        # :count,
      ].freeze

    def self.included(base)
      base.extend self

      base.class_eval do
        IATT_HELPER_METHODS.each do | meth |
          alias_method meth, "instrumentation_#{meth}".to_sym unless base.instance_methods.include?(meth)
        end
      end
    end

    %i{with_tags transmitter normalize_class_name}.each do |meth|
      define_method(meth) do |*args, &blk|
        InstrumentAllTheThings.public_send(meth, *args, &blk)
      end
    end

    IATT_HELPER_METHODS.each do |meth|
      full_method_name = "instrumentation_#{meth}"
      define_method(full_method_name) do |*args, &blk|
        transmitter.public_send(meth, *args, &blk)
      end

      # if (defined?(meth) == nil)
      #   alias meth full_method_name 
      # end
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
