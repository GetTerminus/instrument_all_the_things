require 'datadog/statsd'
require 'logger'
begin
  require 'ddtrace'
rescue LoadError
end

module InstrumentAllTheThings
  class Configuration
    class << self
      def attr_accessor_with_default(meth, default)
        attr_writer meth

        define_method(meth) do
          if instance_variable_defined?("@#{meth}")
            instance_variable_get("@#{meth}")
          else
            instance_variable_set("@#{meth}", default)
          end
        end
      end
    end


    attr_accessor_with_default :stat_prefix, nil
    attr_accessor_with_default :exclude_rails_instrumentation, false
    attr_accessor_with_default :tracer , Datadog.respond_to?(:tracer) ? Datadog.tracer : nil
    attr_accessor_with_default :logger, defined?(Rails) ? Rails.logger : Logger.new(STDOUT).tap{|l| l.level = Logger::INFO }

  end
end
