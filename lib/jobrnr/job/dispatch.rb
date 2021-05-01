module Jobrnr
  module Job
    class Dispatch
      require 'fileutils'
      require 'pastel'

      TIME_SLICE_INTERVAL = 1

      attr_reader :options
      attr_reader :graph
      attr_reader :slots
      attr_reader :pool
      attr_reader :stats
      attr_reader :plugins

      attr_reader :ctrl_c

      def initialize(options:, graph:, num_slots:)
        @options = options
        @graph = graph
        @slots = Jobrnr::Job::Slots.new(num_slots)
        @stats = Jobrnr::Stats.new(graph.roots)
        @plugins = Jobrnr::Plugins.instance
        @ctrl_c = false

        @pool = Jobrnr::Job::Pool.new
      end

      def prerequisites_met?(job)
        job.predecessors.all? { |predecessor| predecessor.state.finished? && predecessor.state.passed? }
      end

      def done?(job_queue, job_pool)
        (job_queue.empty? || stop_submission?) && job_pool.empty?
      end

      def stop_submission?
        max_failures_reached || ctrl_c
      end

      def nothing_todo?(completed, job_queue, slots)
        completed.size == 0 && (
          job_queue.size == 0 ||
          slots.available == 0 ||
          stop_submission?
        )
      end

      def ready_to_queue(successors)
        successors.select { |successor| !successor.state.queued? && prerequisites_met?(successor) }
      end

      def run
        cummulative_completed_instances = []

        job_queue = graph.roots

        FileUtils.mkdir_p(options.output_directory)

        # Handle Ctrl-C
        #
        # On first Ctrl-C, stop submitting new jobs and allow current jobs to
        # finish. On second Ctrl-C, terminate immediately.
        trap "SIGINT" do
          if !ctrl_c
            Jobrnr::Log.info ""
            Jobrnr::Log.info "Stopping job submission. Allowing active jobs to finish."
            Jobrnr::Log.info "Ctrl-C again to terminate immediately."
            @ctrl_c = true
          else
            Jobrnr::Log.info ""
            Jobrnr::Log.info "Terminating"
            exit 130
          end
        end

        until done?(job_queue, pool)
          completed = pool.remove_completed

          if nothing_todo?(completed, job_queue, slots)
            # skip this interval
            sleep TIME_SLICE_INTERVAL
            next
          end

          # process completed job instances
          cummulative_completed_instances.push(*completed)
          completed.each do |job_instance|
            message(job_instance)
            stats.collect(job_instance)
            plugins.post_instance(Jobrnr::PostInstanceMessage.new(job_instance, options))

            # find new jobs to be queued
            if job_instance.success? && job_instance.job.state.finished?
              successors_to_queue = ready_to_queue(job_instance.job.successors)
              successors_to_queue.each { |successor| successor.state.queue }
              job_queue.push(*successors_to_queue)
              stats.queue(successors_to_queue)
            end

            slots.deallocate(job_instance.slot, options.recycle && job_instance.success?)
          end

          # launch new job instances
          new_instances = stop_submission? ? [] : process_queue(job_queue)
          pool.add_and_start(new_instances)

          Jobrnr::Log.info stats.to_s
          plugins.post_interval(Jobrnr::PostIntervalMessage.new(completed, new_instances, stats, options))

          sleep TIME_SLICE_INTERVAL
        end

        status_code = stats.failed
        plugins.post_application(Jobrnr::PostApplicationMessage.new(status_code, cummulative_completed_instances, stats, options))

        Jobrnr::Log.info 'Early termination due to reaching maximum failures' if max_failures_reached && !job_queue.empty?

        status_code
      end

      def max_failures_reached
        options.max_failures > 0 && stats.failed >= options.max_failures
      end

      def process_queue(job_queue)
        num_jobs_queued = [*job_queue.map(&:state).map(&:to_be_scheduled), 0].reduce(&:+)
        num_to_schedule = [num_jobs_queued, slots.available].min
        new_instances = []

        num_to_schedule.times do
          slot = slots.allocate
          job_instance = Jobrnr::Job::Instance.new(
            job: job_queue.first,
            slot: slot,
            log: log_filename(slot)
          )

          # remove job from queue if all instances scheduled otherwise send to
          # the back of the queue to play fair with other jobs
          if job_instance.job.state.scheduled?
            job_queue.shift
          else
            job_queue.rotate!
          end

          plugins.pre_instance(Jobrnr::PreInstanceMessage.new(job_instance, options))
          message(job_instance)
          stats.collect(job_instance)

          new_instances.push(job_instance)
        end

        new_instances
      end

      def log_filename(slot)
        File.join(
          options.output_directory,
          '%s%02d' % [File.basename(options.output_directory), slot]
        )
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
        Jobrnr::Log.info s.join(' ')
      end
    end
  end
end
