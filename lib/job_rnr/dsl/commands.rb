module JobRnr
  module DSL
    class Commands
      require 'docile'

      attr_reader :options

      def initialize
        @options = Struct.new(:directory).new
      end

      def job(id, predecessor_ids = nil, &block)
        valid_jobs = JobRnr::DSL::Loader.valid_jobs
        prefix = JobRnr::DSL::Loader.prefix
        return if valid_jobs && !valid_jobs.any? { |valid_job_id| valid_job_id == id }

        predecessors = Array(predecessor_ids).map { |id| JobRnr::Graph[prefix_id(prefix, id)] }
        builder = JobRnr::DSL::JobBuilder.new(
          id: prefix_id(prefix, id),
          predecessors: predecessors
        )
        job = Docile.dsl_eval(builder, &block).build
        JobRnr::Graph.add_job(job)
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
