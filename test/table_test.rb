# frozen_string_literal: true

require "test_helper"

describe Jobrnr::Table do
  before do
    @obj = Jobrnr::Table.new(
      header: %w[PID Duration Command],
      rows: [
        [1234, 10, "echo hello world"],
        [567, 20, "true"],
        [89, 120, "false"],
      ]
    )
  end

  describe "render" do
    it "renders" do
      expect(@obj.render).must_equal(<<~EOF.chomp)
        PID  Duration Command         
        1234 10       echo hello world
        567  20       true            
        89   120      false           
      EOF
    end
  end
end
