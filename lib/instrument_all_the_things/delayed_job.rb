require 'delayed_job'
module InstrumentAllTheThings
  class InstrumentAllTheThingsPlugin < Delayed::Plugin
    include HelperMethods

    def self.valid_for_plugin?(job)
      job.payload_object && (
        !defined?(ActiveJob::Base) || !job.payload_object.is_a?(ActiveJob::Base)
      )
    end

    def self.base_job_keys(job)
      {job: job, job_klass: job.payload_object.class}
    end

    callbacks do |lifecycle|
      lifecycle.after(:enqueue) do |job, *_|
        return unless valid_for_plugin?(job)
        BackendJob.enqueue(base_job_keys(job))
      end

      lifecycle.around(:perform) do |_, job, *args, &blk|
        return unless valid_for_plugin?(job)

        time = time_block do
          blk.call(job, *args)
        end

        BackendJob.completed(base_job_keys(job).merge(duration: time))
      end

      lifecycle.after(:error) do |_, job, *args|
        return unless valid_for_plugin?(job)
        BackendJob.error(base_job_keys(job).merge(exception: job.error))
      end

      lifecycle.after(:failure) do |_, job|
        return unless valid_for_plugin?(job)
        BackendJob.error(base_job_keys(job).merge(log_error: false, final: true))
      end

    end
  end

  ::Delayed::Worker.plugins << InstrumentAllTheThingsPlugin
end
