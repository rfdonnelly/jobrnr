module AV
  module Jobs
    module Job
      class Dispatch
        require 'concurrent'

        TIME_SLICE_INTERVAL = 1

        attr_reader :graph
        attr_reader :slots

        def initialize(graph, slots)
          @graph = graph
          @slots = slots
        end

        def dependencies_resolved?(job)
          job.predecessors.all? { |predecessor| predecessor.state.finished? }
        end

        def done?(job_queue, futures)
          job_queue.size == 0 && futures.size == 0
        end

        def nothing_todo?(completed_futures, job_queue, slots_available)
          completed_futures.size == 0 && (job_queue.size == 0 || slots_available == 0)
        end

        def ready_to_queue(successors)
          successors.select { |successor| !successor.state.queued? && dependencies_resolved?(successor) }
        end

        def run
          futures = []
          past_futures = []
          slots_available = slots
          job_queue = graph.roots

          while !done?(job_queue, futures)
            completed_futures = futures.select { |f| f.fulfilled? }

            if nothing_todo?(completed_futures, job_queue, slots_available)
              # skip this interval
              sleep TIME_SLICE_INTERVAL
              next
            end

            # process completed job instances
            completed_instances = completed_futures.map { |future| future.value }
            completed_instances.each do |job_instance|
              # TODO post process job instance here
              
              message('Finsihed:', job_instance)

              # find new jobs to be queued
              if job_instance.job.state.finished?
                ready_to_queue(job_instance.job.successors).each do |successor|
                    successor.state.queue
                    job_queue.push(successor)
                end
              end
            end

            slots_available += completed_futures.size
            futures = futures.reject { |future| completed_futures.any? { |completed_future| future == completed_future } }

            # launch new job instances
            while job_queue.size > 0 && slots_available > 0
              slots_available -= 1
              job_instance = AV::Jobs::Job::Instance.new(job_queue.first, '/dev/null')
              job_queue.shift if job_instance.job.state.scheduled?
              future = Concurrent::Future.execute { job_instance.execute }

              # IMPORTANT: Need to yield to thread scheduler so that we context
              # switch to the future so it can begin execution before we reassign
              # job_inst variable.  Otherwise all futures in this tick will use
              # same job_inst object.
              # FIXME to make more foolproof can we remove sleep, put all job
              # instances in array, and create futures for them all at once?
              sleep 0.001

              message('Running:', job_instance)

              futures.push(future)
            end

            sleep TIME_SLICE_INTERVAL
          end
        end

        def message(prefix, job_instance)
          s = []
          s << prefix
          s << "'#{job_instance}'"
          s << "iter#{job_instance.iteration}" if job_instance.job.iterations > 1
          s << "in %#.2fs" % job_instance.duration if job_instance.duration > 0
          AV::Log.info s.join(" ")
        end
      end
    end
  end
end
