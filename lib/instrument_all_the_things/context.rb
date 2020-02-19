# frozen_string_literal: true

module InstrumentAllTheThings
  Context = Struct.new(:method_name, :instance, keyword_init: true) do
    def stats_name(klass_or_instance)
      @stats_name ||= [
        class_name(klass_or_instance),
        (instance ? 'instance' : 'class') + '_methods',
        method_name
      ].join('.')
    end

    def trace_name(klass_or_instance)
      @trace_name ||= "#{class_name(klass_or_instance)}#{instance ? '.' : '#'}#{method_name}"
    end

    private
    def class_name(klass_or_instance)
      klass_or_instance.is_a?(Class) ? klass_or_instance.to_s : klass_or_instance
    end
  end
end
