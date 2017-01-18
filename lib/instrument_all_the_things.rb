require "set"
require "instrument_all_the_things/version"
require "instrument_all_the_things/controller_action"
require "instrument_all_the_things/transmission"
require "instrument_all_the_things/methods"
require "instrument_all_the_things/railtie" if defined?(Rails)

module InstrumentAllTheThings
  class << self
    attr_writer :active_tags
    def normalize_class_name(word)
      # Thanks ActiveSupport!
      word = word.to_s.gsub(/::/, '-')
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.downcase!
      word
    end

    def transmitter
      @transmitter ||= Transmission.new('localhost', 8125)
    end

    def active_tags
      @active_tags ||= Set.new
    end

    def with_tags(*tags)
      tags = tags.flatten
      self.active_tags = self.active_tags.dup.tap do |_|
        self.active_tags += tags
        yield if block_given?
      end
    end
  end
end
