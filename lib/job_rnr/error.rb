module AV
  # All errors raised by AV code shall be AV::Error or derived
  # from AV::Error
  class Error < StandardError; end
  class OptionsError < Error; end
end
