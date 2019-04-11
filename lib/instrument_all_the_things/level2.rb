module InstrumentAllTheThings
  module Level2
    include HelperMethods

    # store_name: 'SomeName', cache_name: :L1, cache: an_instance_of(ActiveSupport::Cache::MemoryStore)
    ActiveSupport::Notifications.subscribe('multi_layer_cache.read') do |_, start, finish, _, payload|
      instrumentation_increment('cache.read.count', tags: ["store:#{payload[:store_name]}", "layer:#{payload[:cache_name]}" ] )
      instrumentation_timing(
        'cache.read.duration',
        (finish - start) * 1000,
        tags: ["store:#{payload[:store_name]}", "layer:#{payload[:cache_name]}" ]
      )
    end

    ActiveSupport::Notifications.subscribe('multi_layer_cache.write') do |_, start, finish, _, payload|
      instrumentation_increment('cache.write.count', tags: ["store:#{payload[:store_name]}", "layer:#{payload[:cache_name]}" ] )
      instrumentation_timing(
        'cache.write.duration',
        (finish - start) * 1000,
        tags: ["store:#{payload[:store_name]}", "layer:#{payload[:cache_name]}" ]
      )
      InstrumentAllTheThings::Level2.update_memory_stats(payload)
    end

    ActiveSupport::Notifications.subscribe('multi_layer_cache.hit') do |_, start, finish, _, payload|
      instrumentation_increment('cache.hit', tags: ["store:#{payload[:store_name]}", "layer:#{payload[:cache_name]}" ] )
    end

    ActiveSupport::Notifications.subscribe('multi_layer_cache.miss') do |_, start, finish, _, payload|
      instrumentation_increment('cache.miss', tags: ["store:#{payload[:store_name]}", "layer:#{payload[:cache_name]}" ] )
    end

    ActiveSupport::Notifications.subscribe('multi_layer_cache.expired_hit') do |_, start, finish, _, payload|
      instrumentation_increment('cache.expired_hit', tags: ["store:#{payload[:store_name]}", "layer:#{payload[:cache_name]}" ] )
    end

    ActiveSupport::Notifications.subscribe('multi_layer_cache.delete') do |_, start, finish, _, payload|
      instrumentation_increment('cache.delete.count', tags: ["store:#{payload[:store_name]}", "layer:#{payload[:cache_name]}" ] )
      instrumentation_timing(
        'cache.delete.duration',
        (finish - start) * 1000,
        tags: ["store:#{payload[:store_name]}", "layer:#{payload[:cache_name]}" ]
      )
      InstrumentAllTheThings::Level2.update_memory_stats(payload)
    end

    def self.update_memory_stats(payload)
      return unless payload[:cache].is_a?(ActiveSupport::Cache::MemoryStore)

      max_size = payload[:cache].instance_variable_get(:@max_size)
      actual_size = payload[:cache].instance_variable_get(:@cache_size)

      instrumentation_gauge(
        'cache.memory.max',
        max_size,
        tags: ["store:#{payload[:store_name]}", "layer:#{payload[:cache_name]}" ]
      )

      instrumentation_gauge(
        'cache.memory.in_use',
        actual_size,
        tags: ["store:#{payload[:store_name]}", "layer:#{payload[:cache_name]}" ]
      )
    end
  end
end
