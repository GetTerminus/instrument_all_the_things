module InstrumentAllTheThings
  class ControllerAction
    attr_accessor :controller, :action, :format, :method, :status, :runtimes

    class << self
      def request
        @request ||= new
      end

      def begin_rails_action(event)
        payload = event.payload
        payload[:format] = 'all' if payload[:format].nil? || payload[:format] == '*/*'

        begin_request(payload)
      end

      def complete_rails_action(event)
        complete_request(
          status: event[:status],
          runtimes: {
            view_runtime: event[:view_runtime],
            db_runtime: event[:db_runtime]
          }
        )
      end

      def begin_request(controller:, action:, format:, method:, **options)
        request.reset!
        request.ingest_settings(controller: controller, action: action, format: format, method: method)
      end

      def complete_request(status:, runtimes:, **options)
        request.ingest_settings(status: status, runtimes: runtimes)
        request.complete_request!
      end
    end

    def reset!
      InstrumentAllTheThings.active_tags -= current_tags

      self.controller = self.action = self.format = self.method =
        self.status = self.runtimes = nil
    end

    def ingest_settings(settings)
      self.controller = InstrumentAllTheThings.normalize_class_name(settings[:controller])

      %i{action format method status runtimes}.each do |method|
        self.public_send("#{method}=", settings[method]) if settings.has_key?(method)
      end

      InstrumentAllTheThings.active_tags += current_tags
    end

    def current_tags
      return [] unless in_request?

      [
        "controller:#{self.controller}",
        "controller_action:#{self.action}",
        "controller_format:#{self.format}",
        "controller_method:#{self.method}",
        "controller_status:#{self.status}",
      ]
    end

    def complete_request!
      InstrumentAllTheThings.transmitter.increment("controller_action.requests.count")

      self.runtimes ||= {}
      self.runtimes.each do |type, time|
        InstrumentAllTheThings.transmitter.timing("controller_action.timings.#{type}", time)
      end

      unless self.runtimes.has_key? "total"
        InstrumentAllTheThings.transmitter.timing(
          "controller_action.timings.total",
          self.runtimes.values.compact.inject(&:+)
        )
      end

      reset!
    end

    def in_request?
      self.controller
    end
  end
end
