module InstrumentAllTheThings
  module RenderedView
    class << self
      def record_render(file: , duration: )
        InstrumentAllTheThings.with_tags("view:#{file}") do
          InstrumentAllTheThings.transmitter.increment("views.rended.count")
          InstrumentAllTheThings.transmitter.timing("views.rendred.timings", duration / 1000.0)
        end
      end
    end
  end
end
