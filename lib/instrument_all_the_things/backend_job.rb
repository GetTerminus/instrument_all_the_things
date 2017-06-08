module InstrumentAllTheThings
  module BackendJob
    include HelperMethods
    class << self
      def tags_for_job(job, klass)
        [
          "backend_job_class:#{normalize_class_name(klass)}",
          ("backend_job_queue:#{job.queue || "UNKNOWN"}" if job.respond_to?(:queue))
        ].compact
      end

      def enqueue(job:, job_klass: nil)
        job_klass ||= job.class

        with_tags(tags_for_job(job, job_klass)) do
          increment("backend_jobs.count")
          increment("backend_jobs.enqueue.count")
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
