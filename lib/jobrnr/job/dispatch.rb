module JobRnr
  module Job
    class Dispatch
      require 'concurrent'
      require 'fileutils'
      require 'pastel'

      TIME_SLICE_INTERVAL = 1

      attr_reader :output_directory
      attr_reader :graph
      attr_reader :slots
      attr_reader :stats

      def initialize(output_directory:, graph:, num_slots:)
        @output_directory = JobRnr::Util.expand_envars(output_directory)
        @graph = graph
        @slots = JobRnr::Job::Slots.new(num_slots)
        @stats = JobRnr::Stats.new(graph.roots)
      end

      def dependencies_resolved?(job)
        job.predecessors.all? { |predecessor| predecessor.state.finished? }
      end

      def done?(job_queue, futures)
        job_queue.size == 0 && futures.size == 0
      end

      def nothing_todo?(completed_futures, job_queue, slots)
        completed_futures.size == 0 && (job_queue.size == 0 || slots.available == 0)
      end

      def ready_to_queue(successors)
        successors.select { |successor| !successor.state.queued? && dependencies_resolved?(successor) }
      end

      def run
        futures = []
        job_queue = graph.roots

        FileUtils.mkdir_p(output_directory)

        until done?(job_queue, futures)
          completed_futures = futures.select(&:fulfilled?)

          if nothing_todo?(completed_futures, job_queue, slots)
            # skip this interval
            sleep TIME_SLICE_INTERVAL
            next
          end

          # process completed job instances
          completed_instances = completed_futures.map(&:value)
          completed_instances.each do |job_instance|
            message(job_instance)

            stats.collect(job_instance)

            job_instance.post_process

            # find new jobs to be queued
            if job_instance.success? && job_instance.job.state.finished?
              successors_to_queue = ready_to_queue(job_instance.job.successors)
              successors_to_queue.each { |successor| successor.state.queue }
              job_queue.push(*successors_to_queue)
              stats.queue(successors_to_queue)
            end
          end

          completed_instances.each do |job_instance|
            if job_instance.success?
              slots.free(job_instance.slot)
            else
              slots.reserve(job_instance.slot)
            end
          end
          futures = futures.reject { |future| completed_futures.any? { |completed_future| future == completed_future } }

          # launch new job instances
          while job_queue.size > 0 && slots.available > 0
            slot = slots.allocate
            job_instance = JobRnr::Job::Instance.new(
              job: job_queue.first,
              slot: slot,
              log: File.join(output_directory, 'regr%02d' % slot)
            )
            job_queue.shift if job_instance.job.state.scheduled?

            job_instance.pre_process
            message(job_instance)
            stats.collect(job_instance)
            future = Concurrent::Future.execute { job_instance.execute }

            # IMPORTANT: Need to yield to thread scheduler so that we context
            # switch to the future so it can begin execution before we reassign
            # job_instance variable.  Otherwise all futures in this tick will use
            # same job_instance object.
            # FIXME to make more foolproof can we remove sleep, put all job
            # instances in array, and create futures for them all at once?
            sleep 0.001

            futures.push(future)
          end
          JobRnr::Log.info stats.to_s

          sleep TIME_SLICE_INTERVAL
        end

        stats.failed
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
