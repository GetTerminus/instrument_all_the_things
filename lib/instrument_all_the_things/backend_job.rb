module InstrumentAllTheThings
  module BackendJob
    include HelperMethods

    class << self
      def tags_for_job(job, klass)
        [ "backend_job_class:#{normalize_class_name(klass)}" ].tap do |arr|
          if queue = queue_name(job, klass)
            arr << "backend_job_queue:#{queue}"
          end
        end
      end

      def queue_name(job, klass)
        if job.respond_to?(:queue) && job.queue && !(job.queue =~ /\A\s*\Z/)
          job.queue
        end || 'UNKNOWN'
      end

      def enqueue(job:, job_klass: nil)
        job_klass ||= job.class

        with_tags(tags_for_job(job, job_klass)) do
          increment("backend_jobs.count")
          increment("backend_jobs.enqueue.count")
        end
      end

      def start(job: , job_klass: nil, expected_start_time: nil, &blk)
        job_klass ||= job.class

        with_tags(tags_for_job(job, job_klass)) do
          if expected_start_time
            duration = Time.now - expected_start_time
            timing('backend_jobs.run_time_delay', duration * 1000)
          end

          if blk
            time = time_block do
              blk.call()
            end

            completed(job: job, job_klass: job_klass, duration: time)
          end
        end
      end

      def completed(job:, job_klass: nil, duration:)
        job_klass ||= job.class

        with_tags(tags_for_job(job, job_klass)) do
          decrement("backend_jobs.count")
          increment("backend_jobs.completed.count")
          timing("backend_jobs.duration", duration)
        end
      end

      def error(job:, job_klass: nil, exception: nil, final: false, log_error: true)
        job_klass ||= job.class

        with_tags(tags_for_job(job, job_klass)) do
          decrement("backend_jobs.count") if final
          if log_error && exception
            increment(
              "backend_jobs.errors",
              tags: [
                "backend_job_exception:#{normalize_class_name(exception)}"
              ]
            )
          end
        end
      end
    end
  end
end
