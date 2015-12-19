module JobRnr
  class Log
    def self.error(exception)
      abort "jobrnr: ERROR: #{exception.message}"
    end

    def self.info(message)
      puts "#{message}"
    end

    def self.debug(message)
      puts "jobrnr: DEBUG: #{message}"
    end
  end
end

