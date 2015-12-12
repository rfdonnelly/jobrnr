module AV
  class Log
    def self.error(exception)
      abort "avjobs: ERROR: #{exception.message}"
    end

    def self.info(message)
      puts "#{message}"
    end

    def self.debug(message)
      puts "avjobs: DEBUG: #{message}"
    end
  end
end

