require 'delayed_job'
module InstrumentAllTheThings
  class InstrumentAllTheThingsPlugin < Delayed::Plugin
    include HelperMethods

    def self.valid_for_plugin?(job)
      job.payload_object && (
        !defined?(ActiveJob::Base) || !job.payload_object.is_a?(ActiveJob::Base)
      )
    rescue => e
      STDERR.puts "Exception in DJ Handler for InstrumentAllTheThings: #{e.message}"
      false
    end

    def self.base_job_keys(job)
      {job: job, job_klass: job.payload_object.class}
    end

    callbacks do |lifecycle|
      lifecycle.after(:enqueue) do |job, *_|
        BackendJob.enqueue(base_job_keys(job)) if valid_for_plugin?(job)
      end

      lifecycle.around(:perform) do |worker, job, *args, &blk|
        if valid_for_plugin?(job)
          BackendJob.start(
            base_job_keys(job).merge(expected_start_time: job.run_at)
          ) do
            blk.call(worker, job, *args, &blk)
          end
        else
          blk.call(worker, job, *args, &blk
        end
      end

      lifecycle.after(:error) do |_, job, *args|
        if valid_for_plugin?(job)
          BackendJob.error(base_job_keys(job).merge(exception: job.error))
        end
      end

      lifecycle.after(:failure) do |_, job|
        if valid_for_plugin?(job)
          BackendJob.error(base_job_keys(job).merge(log_error: false, final: true))
        end
      end
    end
  end

  ::Delayed::Worker.plugins << InstrumentAllTheThingsPlugin
end
