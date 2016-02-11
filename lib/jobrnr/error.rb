module Jobrnr
  # All errors raised by Jobrnr code shall be Jobrnr::Error or derived
  # from Jobrnr::Error
  class Error < StandardError; end
  class OptionsError < Error; end
  class ImportError < Error; end
  class ArgumentError < Error; end
  class TypeError < Error; end
end
