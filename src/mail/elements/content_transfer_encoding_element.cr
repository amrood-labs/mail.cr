require "../parsers/content_transfer_encoding_parser"

module Mail
  class ContentTransferEncodingElement # :nodoc:
    property encoding : String

    def initialize(string)
      content_transfer_encoding = Parsers::ContentTransferEncodingParser.parse(string)
      @encoding = content_transfer_encoding.encoding
    end
  end
end
