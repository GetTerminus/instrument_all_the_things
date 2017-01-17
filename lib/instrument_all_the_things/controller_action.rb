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

      def complet_rails_action(event)
      end

      def begin_request(controller:, action:, format:, method:, **options)
        request.reset!
        request.ingest_settings(controller: controller, action: action, format: format, method: method)
      end

      def complete_request(status:, runtimes:, **options)
        request.ingest_settings(status: status, runtimes: runtimes)
      end
    end

    def reset!
      self.controller = self.action = self.format = self.method =
        self.status = self.runtimes = nil
    end

    def ingest_settings(settings)
      %i{controller action format method status runtimes}.each do |method|
        self.public_send("#{method}=", settings[method]) if settings.has_key?(method)
      end
    end
  end
end
