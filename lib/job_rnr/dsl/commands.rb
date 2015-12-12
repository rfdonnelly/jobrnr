module JobRnr
  module DSL
    class Commands
      attr_reader :options

      def initialize
        @options = Struct.new(:directory).new
      end

      def job(id, predecessor_ids = nil, &block)
        valid_jobs = JobRnr::DSL::Loader.valid_jobs
        prefix = JobRnr::DSL::Loader.prefix
        return if valid_jobs && !valid_jobs.any? { |valid_job_id| valid_job_id == id }

        job_builder = JobRnr::DSL::JobCommand.new
        job_builder.instance_eval(&block)

        predecessors = Array(predecessor_ids).map { |id| JobRnr::Graph[prefix_id(prefix, id)] }
        j = JobRnr::Job::Definition.new(prefix_id(prefix, id), predecessors, job_builder.command, job_builder.iterations)
        JobRnr::Graph.add_job(j)
      end

      def import(prefix, jobs, filename)
        JobRnr::DSL::Loader.evaluate(prefix, jobs, filename)
      end

      def prefix_id(prefix, id)
        if prefix.length > 0
          "#{prefix}_#{id}".to_sym
        else
          id
        end
      end
    end
  end
end
