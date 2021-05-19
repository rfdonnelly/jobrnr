# frozen_string_literal: true

require "minitest/autorun"

require "jobrnr"

def speedup(&block)
  ENV["JOBRNR_TIME_SLICE_INTERVAL"] = "0"
  block.call
  ENV.delete("JOBRNR_TIME_SLICE_INTERVAL")
end
