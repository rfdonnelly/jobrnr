# frozen_string_literal: true

require "test_helper"

describe Jobrnr::Table do
  describe "render" do
    it "renders" do
      table = Jobrnr::Table.new(
        header: %w[PID Duration Command],
        rows: [
          [1234, 10, "echo hello world"],
          [567, 20, "true"],
          [89, 120, "false"],
        ]
      )

      expect(table.render).must_equal(<<~EOF.chomp)
        PID  Duration Command         
        1234 10       echo hello world
        567  20       true            
        89   120      false           
      EOF
    end

    # Colors affect cell widths
    # Make sure colors are stripped for width calculation
    it "renders colors" do
      table = Jobrnr::Table.new(
        header: %w[PID Status Duration Command],
        rows: [
          ["6050", Pastel.new.yellow("Running"), "1s", "echo true"],
        ]
      )
      expect(table.render).must_equal(<<~EOF.chomp)
        PID  Status  Duration Command  
        6050 #{Pastel.new.yellow("Running")} 1s       echo true
      EOF
    end
  end
end
