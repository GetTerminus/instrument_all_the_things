module InstrumentAllTheThings
  class MethodInstrumentor
    attr_accessor :trace
    def initialize(trace: true)
      self.trace = trace
      build_invoke_method
      freeze
    end

    def build_invoke_method
      instance_eval <<~EOS
        define_singleton_method(:invoke) do
          yield
        end
      EOS
    end
  end
end
