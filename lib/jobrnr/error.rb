module JobRnr
  # All errors raised by JobRnr code shall be JobRnr::Error or derived
  # from JobRnr::Error
  class Error < StandardError; end
  class OptionsError < Error; end
  class ImportError < Error; end
end
