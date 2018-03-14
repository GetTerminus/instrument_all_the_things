module InstrumentAllTheThings
  module RenderedView
    include HelperMethods
    class << self
      def record_render(file: , duration: )
        with_tags("view:#{file}") do
          instrumentation_increment("views.rended.count")
          instrumentation_timing("views.rendred.timings", duration)
        end
      end
    end
  end
end
