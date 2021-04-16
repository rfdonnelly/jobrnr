# frozen_string_literal: true

module Jobrnr
  module Job
    # Manages the maximum number of concurrent jobs
    class Slots
      attr_reader :size

      def initialize(size)
        @size = size
        @next_slot = size
        @free_slots = *(0..(size - 1))
      end

      def allocate
        raise Jobrnr::Error,
          "allocate called when no slots available" unless available > 0

        @free_slots.shift
      end

      def available
        @free_slots.size
      end

      def deallocate(slot, recycle)
        if recycle
          @free_slots.push(slot)
        else
          @free_slots.push(@next_slot)
          @next_slot += 1
        end
      end
    end
  end
end
