module InstrumentAllTheThings
  class Railtie < Rails::Railtie
    SKIPPED_SQL_NAMES = ['SCHEMA', 'ActiveRecord::SchemaMigration Load']
    initializer "instrument_all_the_things.configure_for_rails" do
      ActiveSupport::Notifications.subscribe /start_processing.action_controller/ do |*args|
        return if InstrumentAllTheThings.configuration.exclude_rails_instrumentation

        event = ActiveSupport::Notifications::Event.new(*args)
        InstrumentAllTheThings::ControllerAction.begin_rails_action(event)
      end

      ActiveSupport::Notifications.subscribe /process_action.action_controller/ do |*args|
        return if InstrumentAllTheThings.configuration.exclude_rails_instrumentation

        event = ActiveSupport::Notifications::Event.new(*args)
        InstrumentAllTheThings::ControllerAction.complete_rails_action(event.payload)
      end

      ActiveSupport::Notifications.subscribe /sql.active_record/ do |*args|
        return if InstrumentAllTheThings.configuration.exclude_rails_instrumentation

        event = ActiveSupport::Notifications::Event.new(*args)

        unless event.payload[:name].in? SKIPPED_SQL_NAMES
          InstrumentAllTheThings::SQLQuery.record_query(sql: event.payload[:sql], duration: event.duration)
        end
      end

      ActiveSupport::Notifications.subscribe /render_template.action_view/ do |*args|
        return if InstrumentAllTheThings.configuration.exclude_rails_instrumentation

        event = ActiveSupport::Notifications::Event.new(*args)
        if event.payload[:identifier]
          InstrumentAllTheThings::RenderedView.record_render(file: event.payload[:identifier].gsub("#{Rails.root}/",''), duration: event.duration)
        end
      end
    end
  end
end
