module InstrumentAllTheThings
  class MethodInstrumentor
    attr_accessor :trace
    def initialize(trace: true)
      self.trace = trace
      freeze
    end

    def invoke
      InstrumentAllTheThings.config.tracer.trace('method.execution') do
        yield
      end
    end
  end
end
