module JobRnr
  module Job
    class Dispatch
      require 'concurrent'
      require 'fileutils'
      require 'pastel'

      TIME_SLICE_INTERVAL = 1

      attr_reader :options
      attr_reader :graph
      attr_reader :slots
      attr_reader :stats
      attr_reader :plugins

      def initialize(options:, graph:, num_slots:)
        @options = options
        @graph = graph
        @slots = JobRnr::Job::Slots.new(num_slots)
        @stats = JobRnr::Stats.new(graph.roots)
        @plugins = JobRnr::Plugins.instance
      end

      def prerequisites_met?(job)
        job.predecessors.all? { |predecessor| predecessor.state.finished? }
      end

      def done?(job_queue, futures)
        job_queue.size == 0 && futures.size == 0
      end

      def nothing_todo?(completed_futures, job_queue, slots)
        completed_futures.size == 0 && (job_queue.size == 0 || slots.available == 0)
      end

      def ready_to_queue(successors)
        successors.select { |successor| !successor.state.queued? && prerequisites_met?(successor) }
      end

      def run
        futures = []
        cummulative_completed_instances = []

        job_queue = graph.roots

        FileUtils.mkdir_p(options.output_directory)

        until done?(job_queue, futures)
          completed_futures = futures.select(&:fulfilled?)

          if nothing_todo?(completed_futures, job_queue, slots)
            # skip this interval
            sleep TIME_SLICE_INTERVAL
            next
          end

          # process completed job instances
          completed_instances = completed_futures.map(&:value)
          cummulative_completed_instances.push(*completed_instances)
          completed_instances.each do |job_instance|
            message(job_instance)
            stats.collect(job_instance)
            plugins.post_instance(JobRnr::PostInstanceMessage.new(job_instance, options))

            # find new jobs to be queued
            if job_instance.success? && job_instance.job.state.finished?
              successors_to_queue = ready_to_queue(job_instance.job.successors)
              successors_to_queue.each { |successor| successor.state.queue }
              job_queue.push(*successors_to_queue)
              stats.queue(successors_to_queue)
            end
          end
          break if options.max_failures > 0 && stats.failed >= options.max_failures

          completed_instances.each do |job_instance|
            if job_instance.success?
              slots.free(job_instance.slot)
            else
              slots.reserve(job_instance.slot)
            end
          end
          futures = futures.reject { |future| completed_futures.any? { |completed_future| future == completed_future } }

          # launch new job instances
          num_jobs_queued = [*job_queue.map(&:state).map(&:to_be_scheduled), 0].reduce(&:+)
          num_to_schedule = [num_jobs_queued, slots.available].min
          new_instances = []

          num_to_schedule.times do
            slot = slots.allocate
            job_instance = JobRnr::Job::Instance.new(
              job: job_queue.first,
              slot: slot,
              log: File.join(options.output_directory, '%s%02d' % [File.basename(options.output_directory), slot])
            )
            job_queue.shift if job_instance.job.state.scheduled?

            plugins.pre_instance(JobRnr::PreInstanceMessage.new(job_instance, options))
            message(job_instance)
            stats.collect(job_instance)

            new_instances.push(job_instance)
          end

          new_futures = new_instances.map do |instance|
            Concurrent::Future.execute { instance.execute }
          end
          futures.push(*new_futures)

          JobRnr::Log.info stats.to_s
          plugins.post_interval(JobRnr::PostIntervalMessage.new(completed_instances, new_instances, stats, options))

          sleep TIME_SLICE_INTERVAL
        end

        status_code = stats.failed
        plugins.post_application(JobRnr::PostApplicationMessage.new(status_code, cummulative_completed_instances, stats, options))

        status_code
      end

      def message(job_instance)
        pastel = Pastel.new

        s = []
        s << 'Running:' if job_instance.state == :pending
        s << (job_instance.success? ? pastel.green('PASSED:') : pastel.red('FAILED:')) if job_instance.state == :finished
        s << "'#{job_instance}'"
        s << File.basename(job_instance.log)
        s << "iter#{job_instance.iteration}" if job_instance.job.iterations > 1
        s << 'in %#.2fs' % job_instance.duration if job_instance.state == :finished
        JobRnr::Log.info s.join(' ')
      end
    end
  end
end
