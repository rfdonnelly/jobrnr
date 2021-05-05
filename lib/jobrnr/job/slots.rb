# frozen_string_literal: true

module Jobrnr
  module Job
    # Manages the maximum number of concurrent jobs
    class Slots
      attr_reader :size

      def initialize(size:)
        @size = size
        @next_slot = size
        @free_slots = *(0..(size - 1))
        @discards_pending = 0
      end

      def allocate
        unless available.positive?
          raise(
            Jobrnr::Error,
            "allocate called when no slots available"
          )
        end

        @free_slots.shift
      end

      def available
        @free_slots.size - @discards_pending
      end

      def deallocate(slot, recycle)
        if discard?
          discard
        elsif recycle
          @free_slots.push(slot)
        else
          add_new_slot
        end
      end

      def resize(new_size)
        delta = (new_size - size).abs

        return if new_size == size

        if new_size > size
          grow(delta)
        else
          shrink(delta)
        end
      end

      def grow(delta)
        # Grow by first taking from discards_pending
        take_from_discards_pending = [delta, @discards_pending].min
        @discards_pending -= take_from_discards_pending

        # Then grow by adding slots
        remainder = delta - take_from_discards_pending
        remainder.times { add_new_slot }

        @size += delta
      end

      def shrink(delta)
        # We don't shrink immediately. Instead, we shrink by
        # discarding slots as they are deallocated. This tracks how
        # many we should discard on deallocate.
        @discards_pending += delta

        # However, we do reduce the advertised size immediately
        @size -= delta
      end

      def add_new_slot
        @free_slots.push(@next_slot)
        @next_slot += 1
      end

      def discard?
        @discards_pending.positive?
      end

      def discard
        unless discard?
          raise(
            Jobrnr::Error,
            "discard called when no discards pending"
          )
        end

        @discards_pending -= 1
      end
    end
  end
end
