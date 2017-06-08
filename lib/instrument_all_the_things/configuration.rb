module InstrumentAllTheThings
  class Configuration
    class << self
      def attr_accessor_with_default(meth, default)
        attr_writer meth

        define_method(meth) do
          instance_variable_get("@#{meth}") ||
            instance_variable_set("@#{meth}", default)
        end
      end
    end


    attr_accessor_with_default :stat_prefix, nil
  end
end
