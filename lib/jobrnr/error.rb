module Jobrnr
  # All errors raised by Jobrnr code shall be Jobrnr::Error or derived
  # from Jobrnr::Error
  class Error < StandardError; end
  class UsageError < Error; end
  class OptionsError < Error; end
  class ImportError < Error; end
  class ArgumentError < Error; end
  class TypeError < Error; end
  class SyntaxError < Error; end

  class HelpException < StandardError; end
end
