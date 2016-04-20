module Jobrnr
  require 'singleton'

  class Graph
    include Singleton

    def initialize
      @jobs = {}
    end

    def add_job(job)
      @jobs[job.id] = job
    end

    def jobs
      @jobs.values
    end

    def ids
      @jobs.keys
    end

    def id?(id)
      @jobs.key?(id)
    end

    def [](id)
      @jobs[id]
    end

    def roots
      jobs.select { |j| j.predecessors.size == 0 }
    end

    # Generates GraphViz dot format
    def to_dot
      lines = jobs.each_with_object([]) do |j, lines|
        if j.successors.empty? && j.predecessors.empty?
          lines << "#{j.id}"
        else
          j.successors.each do |s|
            lines << "#{j.id} -> #{s.id}"
          end
        end

        lines << '%s -> %s [ label = "%d" ]' % [j.id, j.id, j.iterations] if j.iterations > 1
      end

      [
        'digraph DependencyGraph {',
        *lines.map { |line| "  #{line};" },
        '}',
      ].join("\n")
    end
  end
end
