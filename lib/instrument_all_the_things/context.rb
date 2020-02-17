# frozen_string_literal: true

module InstrumentAllTheThings
  Context = Struct.new(:klass, :method_name, :instance, keyword_init: true) do
    def stats_name
      @stats_name ||= [
        klass,
        (instance ? 'instance' : 'class') + '_methods',
        method_name
      ].join('.')
    end

    def trace_name
      @trace_name ||= "#{klass}#{instance ? '.' : '#'}#{method_name}"
    end
  end
end
