require "./constants"

module Mail
  module Utilities
    extend self

    # If the string supplied has PHRASE unsafe characters in it, will return the string quoted
    # in double quotes, otherwise returns the string unmodified
    # TODO: Fix the quotation of unsafe phrases...
    def quote_phrase(str)
      # if str.respond_to?(:force_encoding)
      #   original_encoding = str.encoding
      #   ascii_str = str.to_s.dup.force_encoding('ASCII-8BIT')
      #   if Constants::PHRASE_UNSAFE === ascii_str
      #     dquote(ascii_str).force_encoding(original_encoding)
      #   else
      #     str
      #   end
      # else
      #   Constants::PHRASE_UNSAFE === str ? dquote(str) : str
      # end
      str
    end

    # Escape parenthesies in a string
    #
    # Example:
    #
    #  str = 'This is (a) string'
    #  escape_paren( str ) #=> 'This is \(a\) string'
    def escape_paren(str)
      re = /(?<!\\)([\(\)])/ # Only match unescaped parens
      str.gsub(re) { |s| '\\' + s }
    end

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

    def self.safe_for_line_ending_conversion?(string)
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
      if typeof(value) == Nil || value.is_a? Nil
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
