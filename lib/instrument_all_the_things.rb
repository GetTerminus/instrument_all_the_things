require "instrument_all_the_things/version"
require "instrument_all_the_things/controller_action"
require "instrument_all_the_things/railtie" if defined?(Rails)

module InstrumentAllTheThings
  class << self
    def normalize_class_name(word)
      # Thanks Rails!
      word = word.to_s.gsub(/::/, '-')
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.downcase!
      word
    end
  end
end
