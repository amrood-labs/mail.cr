require "./8bit"

module Mail
  module Encodings
    # 7bit and 8bit are equivalent. 7bit encoding is for text only.
    class SevenBit < EightBit
      NAME     = "7bit"
      PRIORITY = 1

      # Encodings.register(NAME, self)

      def self.decode(str)
        Utilities.binary_unsafe_to_lf str.to_s
      end

      def self.encode(str)
        Utilities.binary_unsafe_to_crlf str
      end

      # Per RFC 2045 2.7. 7bit Data, No octets with decimal values greater than 127 are allowed.
      def self.compatible_input?(str)
        str.ascii_only? && super
      end
    end
  end
end
