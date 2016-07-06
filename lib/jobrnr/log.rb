module Jobrnr
  class Log
    def self.report(severity, message)
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
