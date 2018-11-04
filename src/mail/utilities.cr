require "./constants"

module Mail
  module Utilities
    extend self

    # Removes any \-escaping.
    #
    # Example:
    #
    #  string = 'This is \"a string\"'
    #  unescape(string) #=> 'This is "a string"'
    #
    #  string = '"This is \"a string\""'
    #  unescape(string) #=> '"This is "a string""'
    def unescape(str)
      str.gsub(/\\(.)/, "\1")
    end

    TO_CRLF_REGEX = Regex.new("(?<!\r)\n|\r(?!\n)")

    def self.binary_unsafe_to_crlf(string) # :nodoc:
      string.gsub(TO_CRLF_REGEX, Constants::CRLF)
    end

    def self.safe_for_line_ending_conversion?(string) # :nodoc:
      string.valid_encoding?
    end

    # Convert line endings to \r\n unless the string is binary. Used for
    # encoding 8bit and base64 Content-Transfer-Encoding and for convenience
    # when parsing emails with \n line endings instead of the required \r\n.
    def self.to_crlf(string)
      string = string.to_s
      if safe_for_line_ending_conversion? string
        binary_unsafe_to_crlf string
      else
        string
      end
    end

    # Swaps out all underscores (_) for hyphens (-) good for stringing from symbols
    # a field name.
    #
    # Example:
    #
    #  string = :resent_from_field
    #  dasherize( string ) #=> 'resent-from-field'
    def dasherize(str)
      str.gsub(Constants::UNDERSCORE, Constants::HYPHEN)
    end

    # Returns true if the object is considered blank.
    # A blank includes things like '', '   ', nil,
    # and arrays and hashes that have nothing in them.
    #
    # This logic is mostly shared with ActiveSupport's blank?
    def blank?(value)
      if typeof(value) == Nil
        true
      elsif typeof(value) == String
        value !~ /\S/
      else
        value.not_nil!
        value.responds_to?(:empty?) ? value.empty? : !value
      end
    end
  end
end
