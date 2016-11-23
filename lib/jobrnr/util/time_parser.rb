module Jobrnr
  module Util
    require 'time'

    class TimeParser
      attr_reader :time

      def initialize(input)
        @time = parse(input)
        @duration = time - now
      end

      def duration
        time - now
      end

      def now
        Time.now
      end

      def parse(input)
        begin
          Time.parse(input)
        rescue
          raise Jobrnr::ArgumentError, "Unable to parse time '#{input}'"
        end
      end
    end
  end
end
