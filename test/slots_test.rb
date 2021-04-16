require "test_helper"

describe Jobrnr::Job::Slots do
  before do
    @size = 4
    @obj = Jobrnr::Job::Slots.new(@size)
  end

  describe "methods" do
    describe "size" do
      it "returns the total number of slots" do
        @obj.size.must_equal @size
      end
    end

    describe "available" do
      it "returns size before allocate" do
        @obj.available.must_equal @size
      end

      it "returns size-1 after one allocate" do
        @obj.allocate
        @obj.available.must_equal @size - 1
      end

      it "returns 0 after size number of allocates" do
        @size.times { @obj.allocate }
        @obj.available.must_equal 0
      end

      it "returns size after allocate + recycling-deallocate" do
        slot = @obj.allocate
        @obj.deallocate(slot, true)
        @obj.available.must_equal @size
      end

      it "returns size after allocate + non-recycling-deallocate" do
        slot = @obj.allocate
        @obj.deallocate(slot, false)
        @obj.available.must_equal @size
      end
    end

    describe "allocate" do
      it "returns 0,1,2,3" do
        @size.times
          .map { @obj.allocate }
          .to_a.must_equal [0, 1, 2, 3]
      end

      it "returns slots in order of dealloc" do
        @size.times { @obj.allocate }
        (0..@size-1).reverse_each { |slot| @obj.deallocate(slot, true) }
        @size.times
          .map { @obj.allocate }
          .to_a.must_equal [3, 2, 1, 0]
      end
    end

    describe "deallocate" do
      describe "recycle" do
        it "recycles slots" do
          slot = 0
          @size.times { slot = @obj.allocate }
          @obj.deallocate(slot, true)
          @obj.allocate.must_equal slot
        end
      end

      describe "non-recycling" do
        it "increments the max slot id" do
          slot = 0
          @size.times { slot = @obj.allocate }
          @obj.deallocate(slot, false)
          @obj.allocate.must_equal slot + 1
        end
      end
    end
  end
end
