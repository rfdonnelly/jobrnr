module Jobrnr
  class Stats
    attr_accessor :running, :failed, :passed, :queued

    def initialize(jobs)
      @running = 0
      @failed = 0
      @passed = 0
      @queued = 0

      queue(jobs)
    end

    def collect(job_instance)
      if job_instance.state == :pending
        @running += 1
        @queued -= 1
      else
        @running -= 1

        if job_instance.success?
          @passed += 1
        else
          @failed += 1
        end
      end
    end

    def queue(jobs)
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
