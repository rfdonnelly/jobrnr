module Jobrnr
  module Util
    class DurationParser
      SECONDS = 1
      MINUTES = 60 * SECONDS
      HOURS = 60 * MINUTES
      DAYS = 24 * HOURS

      UNITS = {
        's' => SECONDS,
        'm' => MINUTES,
        'h' => HOURS,
        'd' => DAYS,
      }

      # Parsed duration in seconds
      attr_reader :duration

      def initialize(input)
        @duration = parse(input)
      end

      def parse(input)
        pairs = input.scan(/([[:digit:]]+)([[:alpha:]]+)/)

        begin
	  return Integer(input) if pairs.empty?
        rescue
          raise Jobrnr::ArgumentError, "Unable to parse duration '#{input}'.  " \
            "Duration must be in the form of '<number><unit>[<number><unit>[...]]'.  " \
            "Examples: '1m30s', '100s'"
	end

        pairs.reduce(0) do |duration, (measure, unit)|
          raise Jobrnr::ArgumentError, "Invalid unit '#{unit}' in duration '#{input}'.  " \
            "Unit must be one of '#{UNITS.keys.join(',')}'." unless UNITS.key?(unit)
          duration += Integer(measure) * UNITS[unit]
        end
      end
    end
  end
end
