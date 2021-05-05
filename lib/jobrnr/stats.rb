# frozen_string_literal: true

module Jobrnr
  # Collects statistics
  class Stats
    attr_accessor :failed
    attr_accessor :passed
    attr_accessor :queued
    attr_accessor :running

    def initialize
      @running = 0
      @failed = 0
      @passed = 0
      @queued = 0
    end

    def pre_instance
      @running += 1
      @queued -= 1
    end

    def post_instance(inst)
      @running -= 1

      if inst.success?
        @passed += 1
      else
        @failed += 1
      end
    end

    def enqueue(*jobs)
      @queued += [0, *jobs.map(&:iterations)].reduce(:+)
    end

    def completed
      passed + failed
    end

    def to_s
      "Running:#{running} Queued:#{queued} Completed:#{completed}" \
        " Passed:#{passed} Failed:#{failed}"
    end
  end
end
