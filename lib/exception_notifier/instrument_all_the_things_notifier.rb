require 'exception_notifier'

#TODO Add version check 4.2 or greater
module ExceptionNotifier
  class InstrumentAllTheThingsNotifier < BaseNotifier
    def call(exception, options = {})
      message = ""

      send_notice(exception, options, message) do |msg, _|
        InstrumentAllTheThings::ExceptionHandler.register(exception)
      end
    end
  end
end
