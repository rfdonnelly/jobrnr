module Jobrnr
  class Log
    def self.error(message)
      abort "jobrnr: ERROR: #{message}"
    end

    def self.info(message)
      puts "#{message}"
    end

    def self.debug(message)
      puts "jobrnr: DEBUG: #{message}"
    end
  end
end
