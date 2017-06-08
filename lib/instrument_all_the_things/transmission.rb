require 'datadog/statsd'
module InstrumentAllTheThings
  class Transmission < Datadog::Statsd
    %i{count gauge histogram set time timing}.each do |meth|
      define_method(meth) do |*args, &blk|
        options = args.last.is_a?(Hash) ? args.pop : {}
        unless options.delete :skip_global_tags
          options[:tags] ||= []
          options[:tags] += InstrumentAllTheThings.active_tags.to_a
        end
        options[:tags] = options[:tags].to_a.uniq if options[:tags]
        args << options
        err = "Logging with tags: #{options[:tags].join(',')} args: #{args.inspect}"
        if defined?(Rails)
          Rails.logger.info err
        else
          STDERR << err
        end
        super(*args, &blk)
      end
    end
  end
end
