require 'datadog/statsd'
module InstrumentAllTheThings
  class Transmission < Datadog::Statsd
    %i{count gauge histogram set time timing}.each do |meth|
      alias_method "_original_#{meth}", meth

      define_method(meth) do |*args, &blk|
        options = args.last.is_a?(Hash) ? args.pop : {}
        unless options.delete :skip_global_tags
          options[:tags] ||= []
          options[:tags] += InstrumentAllTheThings.active_tags.to_a
        end
        options[:tags] = options[:tags].to_a.uniq if options[:tags]
        args << options

        if InstrumentAllTheThings.config.stat_prefix && args.first.is_a?(String)
          args[0] = "#{InstrumentAllTheThings.config.stat_prefix}.#{args[0]}" unless meth == :time
        end

        send("_original_#{meth}", *args, &blk)
      end
    end
  end
end
