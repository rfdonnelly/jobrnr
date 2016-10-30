module Jobrnr
  class Log
    VERBOSITY_SEVERITY_MAP = {
      ERROR: -999,
      INFO: 1,
      DEBUG: 2,
    }

    @@verbosity = 0

    def self.verbosity=(verbosity)
      @@verbosity = verbosity
    end

    def self.report(severity, message)
      return unless @@verbosity >= VERBOSITY_SEVERITY_MAP[severity]

      out = (severity == :ERROR) ? STDERR : STDOUT
      prefix = (severity == :INFO) ? '' : "#{severity}: jobrnr: "
      out.puts [prefix, message].join
    end

    def self.error(message)
      report(:ERROR, message)
      exit 1
    end

    def self.info(message)
      report(:INFO, message)
    end

    def self.debug(message)
      report(:DEBUG, message)
    end
  end
end
