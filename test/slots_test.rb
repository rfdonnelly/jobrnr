require "test_helper"

describe Jobrnr::Job::Slots do
  before do
    @size = 4
    @obj = Jobrnr::Job::Slots.new(@size)
  end

  describe "methods" do
    describe "size" do
      it "returns the total number of slots" do
        expect(@obj.size).must_equal @size
      end
    end

    describe "available" do
      it "returns size before allocate" do
        expect(@obj.available).must_equal @size
      end

      it "returns size-1 after one allocate" do
        @obj.allocate
        expect(@obj.available).must_equal @size - 1
      end

      it "returns 0 after size number of allocates" do
        @size.times { @obj.allocate }
        expect(@obj.available).must_equal 0
      end

      it "returns size after allocate + recycling-deallocate" do
        slot = @obj.allocate
        @obj.deallocate(slot, true)
        expect(@obj.available).must_equal @size
      end

      it "returns size after allocate + non-recycling-deallocate" do
        slot = @obj.allocate
        @obj.deallocate(slot, false)
        expect(@obj.available).must_equal @size
      end
    end

    describe "allocate" do
      it "returns 0,1,2,3" do
        actual =
          @size
          .times
          .map { @obj.allocate }
          .to_a
        expect(actual).must_equal [0, 1, 2, 3]
      end

      it "returns slots in order of dealloc" do
        @size.times { @obj.allocate }
        (0..@size-1).reverse_each { |slot| @obj.deallocate(slot, true) }
        actual =
          @size
          .times
          .map { @obj.allocate }
          .to_a
        expect(actual).must_equal [3, 2, 1, 0]
      end
    end

    describe "deallocate" do
      describe "recycle" do
        it "recycles slots" do
          slot = 0
          @size.times { slot = @obj.allocate }
          @obj.deallocate(slot, true)
          expect(@obj.allocate).must_equal slot
        end
      end

      describe "non-recycling" do
        it "increments the max slot id" do
          slot = 0
          @size.times { slot = @obj.allocate }
          @obj.deallocate(slot, false)
          expect(@obj.allocate).must_equal slot + 1
        end
      end
    end
  end
end
