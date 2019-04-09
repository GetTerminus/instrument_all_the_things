require "set"
require "instrument_all_the_things/version"
require "instrument_all_the_things/configuration"
require "instrument_all_the_things/helper_methods"
require "instrument_all_the_things/controller_action"
require "instrument_all_the_things/transmission"
require "instrument_all_the_things/methods"
require "instrument_all_the_things/sql_query"
require "instrument_all_the_things/rendered_view"
require "instrument_all_the_things/exception_handler"
require "instrument_all_the_things/backend_job"
require "instrument_all_the_things/railtie" if defined?(Rails)

begin
  require 'delayed_jobs'
rescue LoadError
end
require "instrument_all_the_things/delayed_job" if defined?(Delayed::Job)

begin
  require 'hermes_messenger_of_the_gods'
rescue LoadError
end
require "instrument_all_the_things/hermes" if defined?(HermesMessengerOfTheGods)

begin
  require 'level2'
rescue LoadError
end

require "instrument_all_the_things/level2" if defined?(Level2)

if defined?(ExceptionNotifier)
  require "exception_notifier/instrument_all_the_things_notifier"
end

module InstrumentAllTheThings
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
      configuration
    end
    alias config configure

    def normalize_class_name(word)
      # Thanks ActiveSupport!
      word = word.to_s.gsub(/::/, '-')
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.downcase!
      word
    end

    def transmitter
      @transmitter ||= Transmission.new(
        ENV['DATADOG_HOST'] || 'localhost',
        ENV['DATADOG_PORT'] || 8125
      )
    end

    def active_tags=(val)
      Thread.current[:iatt_active_tags] = val
    end

    def active_tags
      Thread.current[:iatt_active_tags] ||= Set.new
    end

    def with_tags(*tags)
      options = tags.last.is_a?(Hash) ? tags.pop : {}
      tags = tags.flatten

      return_value = nil
      self.active_tags = self.active_tags.dup.tap do |_|

        self.active_tags.reject! do |t|
          [*options[:except]].any?{|exclusion| exclusion === t }
        end

        self.active_tags += tags
        return_value = yield if block_given?
      end

      return_value
    end

    def time_block
      time1 = Time.now
      yield
      (Time.now - time1) * 1000
    end
  end
end
