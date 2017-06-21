module InstrumentAllTheThings
  module HelperMethods
    def self.included(base)
      base.extend self
    end

    %i{with_tags transmitter normalize_class_name}.each do |meth|
      define_method(meth) do |*args, &blk|
        InstrumentAllTheThings.public_send(meth, *args, &blk)
      end
    end

    %i{
      decrement
      increment
      time
      timing
      guage
      histogram
      set
      count
    }.each do |meth|
      define_method(meth) do |*args, &blk|
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
