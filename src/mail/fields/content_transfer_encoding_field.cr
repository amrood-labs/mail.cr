require "./named_structured_field"

module Mail
  class ContentTransferEncodingField < NamedStructuredField # :nodoc:
    @@field_name = "Content-Transfer-Encoding"
    class_getter field_name : String

    @element : ContentTransferEncodingElement? = nil

    def self.singular?
      true
    end

    def self.normalize_content_transfer_encoding(value)
      case value
      when /7-?bits?/i
        "7bit"
      when /8-?bits?/i
        "8bit"
      else
        value
      end
    end

    def initialize(value = nil, charset = nil)
      super self.class.normalize_content_transfer_encoding(value), charset
    end

    def element
      @element ||= ContentTransferEncodingElement.new(value)
    end

    def encoding
      @element ? @element.not_nil!.encoding : nil
    end

    private def do_encode
      "#{name}: #{encoding}\r\n"
    end

    private def do_decode
      encoding
    end
  end
end
