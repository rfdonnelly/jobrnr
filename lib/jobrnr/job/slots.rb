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
        @discards_pending = 0
      end

      def allocate
        raise Jobrnr::Error,
          "allocate called when no slots available" unless available > 0

        @free_slots.shift
      end

      def available
        @free_slots.size - @discards_pending
      end

      def deallocate(slot, recycle)
        if discard?
          discard
        else
          if recycle
            @free_slots.push(slot)
          else
            add_new_slot
          end
        end
      end

      def resize(new_size)
        delta = (new_size - size).abs

        if new_size == size
          return
        elsif new_size > size
          grow(delta)
        else
          shrink(delta)
        end
      end

      def grow(delta)
        take_from_discards_pending = [delta, @discards_pending].min
        @discards_pending -= take_from_discards_pending

        remainder = delta - take_from_discards_pending
        remainder.times { add_new_slot }

        @size += delta
      end

      def shrink(delta)
        @discards_pending += delta

        @size -= delta
      end

      def add_new_slot
        @free_slots.push(@next_slot)
        @next_slot += 1
      end

      def discard?
        @discards_pending > 0
      end

      def discard
        raise Jobrnr::Error,
          "discard called when no discards pending" unless discard?

        @discards_pending -= 1
      end
    end
  end
end
