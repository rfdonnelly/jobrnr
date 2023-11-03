# frozen_string_literal: true

module Jobrnr
  require "singleton"

  # Tracks job dependencies
  class Graph
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
      jobs.select { |j| j.predecessors.empty? }
    end

    # Generates GraphViz dot format
    def to_dot
      relations = jobs.each_with_object([]) do |j, array|
        if j.successors.empty? && j.predecessors.empty?
          array << j.id.to_s
        else
          j.successors.each { |s| array << "#{j.id} -> #{s.id}" }
        end

        if j.iterations > 1
          array << format('%<id>s -> %<id>s [ label = "%<iterations>d" ]', id: j.id, iterations: j.iterations)
        end
      end

      [
        "digraph DependencyGraph {",
        *relations.map { |line| "  #{line};" },
        "}",
      ].join("\n")
    end
  end
end
