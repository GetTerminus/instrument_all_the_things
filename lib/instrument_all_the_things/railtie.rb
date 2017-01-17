module InstrumentAllTheThings
  class Railtie < Rails::Railtie
    initializer "instrument_all_the_things.configure_for_rails" do
      ActiveSupport::Notifications.subscribe /start_processing.action_controller/ do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        InstrumentAllTheThings::Controller.begin_rails_action(event)
      end

      ActiveSupport::Notifications.subscribe /process_action.action_controller/ do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        InstrumentAllTheThings::ControllerAction.comple_rails_action(event.payload)
      end
    end
  end
end
