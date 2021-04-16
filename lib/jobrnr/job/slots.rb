# frozen_string_literal: true

module Jobrnr
  module Job
    # Manages the maximum number of concurrent jobs
    class Slots
      attr_reader :size

      def initialize(size)
        @size = size
        @next_slot = size
        @slots = *(0..(size - 1))
      end

      def allocate
        raise Jobrnr::Error,
          "allocate called when no slots available" unless available > 0

        @slots.shift
      end

      def available
        @slots.size
      end

      def deallocate(slot, recycle)
        if recycle
          @slots.push(slot)
        else
          @slots.push(@next_slot)
          @next_slot += 1
        end
      end
    end
  end
end
