module Mail
  # Extends each field parser with utility methods.
  module ParserTools # :nodoc:
    def chars(data, from_bytes, to_bytes)
      data[from_bytes.not_nil!, (from_bytes.not_nil!..to_bytes).size]
    end
  end
end
