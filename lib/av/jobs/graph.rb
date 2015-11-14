module AV
  module Jobs
    class Graph
      @@jobs = {}

      def self.add_job(job)
        @@jobs[job.id] = job
      end

      def self.jobs
        @@jobs.values
      end

      def self.[](id)
        @@jobs[id]
      end

      def self.roots
        jobs.select { |j| j.predecessors.size == 0 }
      end

      # Generates GraphViz dot format
      def self.to_dot
        lines = jobs.each_with_object([]) do |j, lines|
          if j.successors.empty? && j.predecessors.empty?
            lines << j.id.to_s
          else
            j.successors.each do |s|
              lines << "#{j.id} -> #{s.id}"
            end
          end
        end

        [
          "digraph DependencyGraph {",
          *lines.map { |line| "  #{line};" },
          "}",
        ].join("\n")
      end
    end
  end
end
