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

    %i{increment time timing}.each do |meth|
      define_method(meth) do |*args, &blk|
        transmitter.public_send(meth, *args, &blk)
      end
    end
  end
end
