module InstrumentAllTheThings
  module Hermes
    include HelperMethods

    ActiveSupport::Notifications.subscribe('hermes_messenger_of_the_gods.worker.run_job') do |_, start, finish, _, payload|
      with_tags("hermes_class:#{normalize_class_name(payload[:job].class)}") do
        if payload[:exception].present?
          BackendJob.error(job: payload[:job], exception: payload[:exception_object].class)
        else
          BackendJob.completed(job: payload[:job], duration: finish - start)
        end
      end
    end
  end
end
