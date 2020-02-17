# frozen_string_literal: true

module InstrumentAllTheThings
  module Instrumentors
    DEFAULT_GC_STATS_OPTIONS = {
      diffed_stats: %i[
        total_allocated_pages
        total_allocated_objects
        count
      ].freeze
    }.freeze

    # This is to make it easier to spec since other
    # gems may call this
    GC_STAT_GETTER = -> { GC.stat }

    GC_STATS_WRAPPER = lambda do |opts, context|
      opts = DEFAULT_GC_STATS_OPTIONS.merge(opts)

      report_value = lambda do |stat_name, value|
        IATT.config.stat_reporter.histogram(
          context.stats_name + ".#{stat_name}_change",
          value
        )
      end

      lambda do |next_blk, actual_code|
        starting_values = GC_STAT_GETTER.call.slice(*opts[:diffed_stats])
        next_blk.call(actual_code).tap do
          new_values = GC_STAT_GETTER.call.slice(*opts[:diffed_stats])

          diff = new_values.merge(starting_values) do |_, new_value, starting_value|
            new_value - starting_value
          end

          if (span = IATT.config.tracer.active_span)
            span.set_tag('gc_stats', diff)
          end

          diff.each { |s, v| report_value.call(s, v) }
        end
      end
    end
  end
end
