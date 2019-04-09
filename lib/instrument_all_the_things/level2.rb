module InstrumentAllTheThings
  module Hermes
    include HelperMethods

    # store_name: 'SomeName', cache_name: :L1, cache: an_instance_of(ActiveSupport::Cache::MemoryStore)
    ActiveSupport::Notifications.subscribe('multi_layer_cache.read') do |_, start, finish, _, payload|
      instrumentation_increment('read.count', tags: ["store:#{payload['store_name']}", "layer:#{paylaod['cache_name']}" ] )
      instrumentation_timing(
        'read.duration',
        (finish - start) * 1000,
        tags: ["store:#{payload['store_name']}", "layer:#{paylaod['cache_name']}" ]
      )
    end

    ActiveSupport::Notifications.subscribe('multi_layer_cache.write') do |_, start, finish, _, payload|
      instrumentation_increment('write.count', tags: ["store:#{payload['store_name']}", "layer:#{paylaod['cache_name']}" ] )
      instrumentation_timing(
        'write.duration',
        (finish - start) * 1000,
        tags: ["store:#{payload['store_name']}", "layer:#{paylaod['cache_name']}" ]
      )
    end

    ActiveSupport::Notifications.subscribe('multi_layer_cache.hit') do |_, start, finish, _, payload|
      instrumentation_increment('cache_hit', tags: ["store:#{payload['store_name']}", "layer:#{paylaod['cache_name']}" ] )
    end

    ActiveSupport::Notifications.subscribe('multi_layer_cache.miss') do |_, start, finish, _, payload|
      instrumentation_increment('cache_miss', tags: ["store:#{payload['store_name']}", "layer:#{paylaod['cache_name']}" ] )
    end

    ActiveSupport::Notifications.subscribe('multi_layer_cache.expired_hit') do |_, start, finish, _, payload|
      instrumentation_increment('expired_hit', tags: ["store:#{payload['store_name']}", "layer:#{paylaod['cache_name']}" ] )
    end

    ActiveSupport::Notifications.subscribe('multi_layer_cache.delete') do |_, start, finish, _, payload|
      instrumentation_increment('delete.count', tags: ["store:#{payload['store_name']}", "layer:#{paylaod['cache_name']}" ] )
      instrumentation_timing(
        'delete.duration',
        (finish - start) * 1000,
        tags: ["store:#{payload['store_name']}", "layer:#{paylaod['cache_name']}" ]
      )
    end

    def update_memory_stats(payload)
      return unless payload[:cache].is_a?(ActiveSupport::Cache::MemoryStore)

      max_size = payload[:cache].instance_variable_get(:@max_size)
      actual_size = payload[:cache].instance_variable_get(:@cache_size)
      instrumentation_set(
        'cache_memory.max',
        max_size,
        tags: ["store:#{payload['store_name']}", "layer:#{paylaod['cache_name']}" ]
      )
      instrumentation_set(
        'cache_memory.in_use',
        actual_size,
        tags: ["store:#{payload['store_name']}", "layer:#{paylaod['cache_name']}" ]
      )
    end
  end
end
