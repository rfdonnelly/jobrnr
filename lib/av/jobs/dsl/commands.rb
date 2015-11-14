module AV
  module Jobs
    module DSL
      class Commands
        def prefix_id(prefix, id)
          if prefix.length > 0
            "#{prefix}_#{id}".to_sym
          else
            id
          end
        end

        def job(id, predecessor_ids = nil, &block)
          valid_jobs = AV::Jobs::DSL::Loader.valid_jobs
          prefix = AV::Jobs::DSL::Loader.prefix
          return if valid_jobs && !valid_jobs.any? { |valid_job_id| valid_job_id == id }

          job_builder = AV::Jobs::DSL::JobCommand.new
          job_builder.instance_eval(&block)

          predecessors = Array(predecessor_ids).map { |id| AV::Jobs::Graph[prefix_id(prefix, id)] }
          j = AV::Jobs::Job::Definition.new(prefix_id(prefix, id), predecessors, job_builder.command, job_builder.iterations)
          AV::Jobs::Graph.add_job(j)
        end

        def import(prefix, jobs, filename)
          AV::Jobs::DSL::Loader.evaluate(prefix, jobs, filename)
        end
      end
    end
  end
end
