module Errors
  class InvalidToken          < StandardError; end
  class Unauthorized          < StandardError; end
  class SsoVerificationFailed < StandardError; end
end
