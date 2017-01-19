require 'delayed_job'
module InstrumentAllTheThings
  class InstrumentAllTheThingsPlugin < Delayed::Plugin
    callbacks do |lifecycle|
      lifecycle.after(:enqueue) do |job, *_|
        true
      end
    end
  end

  ::Delayed::Worker.plugins << InstrumentAllTheThingsPlugin
end
