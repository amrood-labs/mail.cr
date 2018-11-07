require "./identity"

module Mail
  module Encodings
    class Binary < Identity
      NAME     = "binary"
      PRIORITY = 5
      # Encodings.register(NAME, Binary)
    end
  end
end
