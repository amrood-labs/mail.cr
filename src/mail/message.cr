require "./constants"

module Mail
  class Message
    class_property charset : String = "UTF-8"

    @envelope : Envelope? = nil
    property raw_source : String?

    def initialize(raw_email)
      init_with_string(raw_email)
    end

    # Returns the To value of the mail object as an array of strings of
    # address specs.
    #
    # Example:
    #
    #  mail.to = 'Mikel <mikel@test.lindsaar.net>'
    #  mail.to #=> ['mikel@test.lindsaar.net']
    #  mail.to = 'Mikel <mikel@test.lindsaar.net>, ada@test.lindsaar.net'
    #  mail.to #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
    #
    # Also allows you to set the value by passing a value as a parameter
    #
    # Example:
    #
    #  mail.to 'Mikel <mikel@test.lindsaar.net>'
    #  mail.to #=> ['mikel@test.lindsaar.net']
    #
    # Additionally, you can append new addresses to the returned Array like
    # object.
    #
    # Example:
    #
    #  mail.to 'Mikel <mikel@test.lindsaar.net>'
    #  mail.to << 'ada@test.lindsaar.net'
    #  mail.to #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
    def to(val = nil)
      default "to", val
    end

    # Sets the To value of the mail object, pass in a string of the field
    #
    # Example:
    #
    #  mail.to = 'Mikel <mikel@test.lindsaar.net>'
    #  mail.to #=> ['mikel@test.lindsaar.net']
    #  mail.to = 'Mikel <mikel@test.lindsaar.net>, ada@test.lindsaar.net'
    #  mail.to #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
    def to=(val)
      header["to"] = val
    end

    # Returns the From value of the mail object as an array of strings of
    # address specs.
    #
    # Example:
    #
    #  mail.from = 'Mikel <mikel@test.lindsaar.net>'
    #  mail.from #=> ['mikel@test.lindsaar.net']
    #  mail.from = 'Mikel <mikel@test.lindsaar.net>, ada@test.lindsaar.net'
    #  mail.from #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
    #
    # Also allows you to set the value by passing a value as a parameter
    #
    # Example:
    #
    #  mail.from 'Mikel <mikel@test.lindsaar.net>'
    #  mail.from #=> ['mikel@test.lindsaar.net']
    #
    # Additionally, you can append new addresses to the returned Array like
    # object.
    #
    # Example:
    #
    #  mail.from 'Mikel <mikel@test.lindsaar.net>'
    #  mail.from << 'ada@test.lindsaar.net'
    #  mail.from #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
    def from(val = nil)
      default "from", val
    end

    # Sets the From value of the mail object, pass in a string of the field
    #
    # Example:
    #
    #  mail.from = 'Mikel <mikel@test.lindsaar.net>'
    #  mail.from #=> ['mikel@test.lindsaar.net']
    #  mail.from = 'Mikel <mikel@test.lindsaar.net>, ada@test.lindsaar.net'
    #  mail.from #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
    def from=(val)
      header["from"] = val
    end

    # Returns the default value of the field requested as a symbol.
    #
    # Each header field has a :default method which returns the most common use case for
    # that field, for example, the date field types will return a DateTime object when
    # sent :default, the subject, or unstructured fields will return a decoded string of
    # their value, the address field types will return a single addr_spec or an array of
    # addr_specs if there is more than one.
    def default(str, val = nil)
      if val
        header[str] = val
      elsif field = header ? header.not_nil![str] : nil
        if field.is_a? Array
          field.map { |f| f.default }
        else
          field.default
        end
      end
    end

    def set_envelope(raw_envelope : String)
      @raw_envelope = raw_envelope
      @envelope = Mail::Envelope.parse(raw_envelope) rescue nil
    end

    # Type field that you can see at the top of any email that has come
    # from a mailbox
    def raw_envelope
      @raw_envelope
    end

    def envelope_from
      @envelope ? @envelope.not_nil!.from : nil
    end

    def envelope_date
      @envelope ? @envelope.not_nil!.date : nil
    end

    # Sets the header of the message object.
    #
    # Example:
    #
    #  mail.header = 'To: mikel@test.lindsaar.net\r\nFrom: Bob@bob.com'
    #  mail.header #=> <#Mail::Header
    def header=(value)
      @header = Mail::Header.new(value, self.class.charset)
    end

    # Returns the header object of the message object. Or, if passed
    # a parameter sets the value.
    #
    # Example:
    #
    #  mail = Mail::Message.new('To: mikel\r\nFrom: you')
    #  mail.header #=> #<Mail::Header:0x13ce14 @raw_source="To: mikel\r\nFr...
    #
    #  mail.header #=> nil
    #  mail.header 'To: mikel\r\nFrom: you'
    #  mail.header #=> #<Mail::Header:0x13ce14 @raw_source="To: mikel\r\nFr...
    def header(value = nil)
      value ? self.header = value : @header
    end

    # Provides a way to set custom headers, by passing in a hash
    # def headers(hash = {})
    #   hash.each_pair do |k,v|
    #     header[k] = v
    #   end
    # end

    HEADER_SEPARATOR = /#{Constants::LAX_CRLF}#{Constants::LAX_CRLF}/

    #  2.1. General Description
    #   A message consists of header fields (collectively called "the header
    #   of the message") followed, optionally, by a body.  The header is a
    #   sequence of lines of characters with special syntax as defined in
    #   this standard. The body is simply a sequence of characters that
    #   follows the header and is separated from the header by an empty line
    #   (i.e., a line with nothing preceding the CRLF).
    private def parse_message
      header_part, body_part = raw_source.not_nil!.lstrip.split(HEADER_SEPARATOR, 2)
      self.header = header_part
      # self.body = body_part
    end

    private def set_envelope_header
      raw_string = raw_source.to_s
      if match_data = raw_string.match(/\AFrom\s+([^:\s]#{Constants::TEXT}*)#{Constants::LAX_CRLF}/m)
        set_envelope(match_data[1])
        self.raw_source = raw_string.sub(match_data[0], "")
      end
    end

    private def init_with_string(string)
      self.raw_source = string
      set_envelope_header
      parse_message
      # @separate_parts = multipart?
    end
  end
end
