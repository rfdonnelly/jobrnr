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

        def dependencies_met?(job)
          job.predecessors.all? { |predecessor| predecessor.state.finished? }
        end

        def done?(job_queue, futures)
          job_queue.size == 0 && futures.size == 0
        end

        def run
          futures = []
          past_futures = []
          slots_available = slots
          job_queue = graph.roots

          while !done?(job_queue, futures)
            completed_futures = futures.select { |f| f.fulfilled? }

            if completed_futures.size == 0 && (job_queue.size == 0 || slots_available == 0)
              # nothing to do in this interval, skip
              sleep TIME_SLICE_INTERVAL
              next
            end

            # process completed job instances
            completed_futures.each do |future|
              job_instance = future.value

              # TODO post process job instance here
              
              message = []
              message << "Finished: '#{job_instance}'"
              message << "iter#{job_instance.iteration}" if job_instance.job.iterations > 1
              message << "in %#.2fs" % job_instance.duration
              AV::Log.info message.join(" ")

              # find new jobs to be queued
              if job_instance.job.state.finished?
                job_instance.job.successors.each do |successor|
                  if !successor.state.queued? && dependencies_met?(successor)
                    successor.state.queue
                    job_queue.push(successor)
                  end
                end
              end
            end

            slots_available += completed_futures.size
            futures = futures.reject { |future| completed_futures.any? { |completed_future| future == completed_future } }

            # launch new job instances
            while job_queue.size > 0 && slots_available > 0
              slots_available -= 1
              job_instance = AV::Jobs::Job::Instance.new(job_queue.first)
              job_queue.shift if job_instance.job.state.scheduled?
              future = Concurrent::Future.execute { job_instance.execute }

              # IMPORTANT: Need to yield to thread scheduler so that we context
              # switch to the future so it can begin execution before we reassign
              # job_inst variable.  Otherwise all futures in this tick will use
              # same job_inst object.
              # FIXME to make more foolproof can we remove sleep, put all job
              # instances in array, and create futures for them all at once?
              sleep 0.001

              message = []
              message << "Running: '#{job_instance}'"
              message << "iter#{job_instance.iteration}" if job_instance.job.iterations > 1
              AV::Log.info message.join(" ")

              futures.push(future)
            end

            sleep TIME_SLICE_INTERVAL
          end
        end
      end
    end
  end
end
