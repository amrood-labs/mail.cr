require "./constants"

module Mail
  class Message
    class_property charset : String = "UTF-8"

    @envelope : Envelope? = nil
    @body_raw : String? = nil
    @header : Header = Header.new("", @@charset)
    @text_part : Part? = nil
    @separate_parts : Bool = false
    @charset : String = @@charset
    property raw_source : String = ""

    def initialize(raw_source = "", @body : Body = Body.new)
      # @html_part = nil
      # @errors = nil

      if !Utilities.blank? raw_source
        init_with_string(raw_source)
      end
    end

    # def initialize(raw_source = "", @body : Body = Body.new, &block)
    #   initialize(raw_source, @body)
    #   if block_given?
    #     yield self
    #   end
    # end

    def content_type(val = nil)
      default "content_type", val
    end

    def content_type=(val)
      header["content_type"] = val
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
      elsif field = header[str]
        if field.is_a? Array
          field.map { |f| f.default }
        else
          field.default
        end
      end
    end

    # Sets the body object of the message object.
    #
    # Example:
    #
    #  mail.body = 'This is the body'
    #  mail.body #=> #<Mail::Body:0x13919c @raw_source="This is the bo...
    #
    # You can also reset the body of an Message object by setting body to nil
    #
    # Example:
    #
    #  mail.body = 'this is the body'
    #  mail.body.encoded #=> 'this is the body'
    #  mail.body = nil
    #  mail.body.encoded #=> ''
    #
    # If you try and set the body of an email that is a multipart email, then instead
    # of deleting all the parts of your email, mail will add a text/plain part to
    # your email:
    #
    #  mail.add_file 'somefilename.png'
    #  mail.parts.length #=> 1
    #  mail.body = "This is a body"
    #  mail.parts.length #=> 2
    #  mail.parts.last.content_type.content_type #=> 'This is a body'
    def body=(value)
      body_lazy(value)
    end

    # Returns the body of the message object. Or, if passed
    # a parameter sets the value.
    #
    # Example:
    #
    #  mail = Mail::Message.new('To: mikel\r\n\r\nThis is the body')
    #  mail.body #=> #<Mail::Body:0x13919c @raw_source="This is the bo...
    #
    #  mail.body 'This is another body'
    #  mail.body #=> #<Mail::Body:0x13919c @raw_source="This is anothe...
    def body(value = nil)
      if value
        self.body = value
      else
        process_body_raw if @body_raw
        @body
      end
    end

    # Returns the main content type
    def main_type
      content_type = header["content_type"]
      content_type.responds_to?(:main_type) ? content_type.main_type : nil
    end

    def has_content_type?
      !!main_type
    end

    # Returns the content type parameters
    def content_type_parameters
      has_content_type? ? header["content_type"].parameters : nil
    end

    # Returns the character set defined in the content type field
    def charset
      has_content_type? ? content_type_parameters["charset"] : @charset
    end

    # Sets the charset to the supplied value.
    def charset=(value)
      @charset = value
      @header.charset = value
    end

    # Returns true if the message is multipart
    def multipart?
      has_content_type? ? !!(main_type =~ /^multipart$/i) : false
    end

    # Returns the current boundary for this message part
    def boundary
      content_type_parameters ? content_type_parameters["boundary"] : nil
    end

    # Returns a parts list object of all the parts in the message
    def parts
      body.parts
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

    # Accessor for text_part
    def text_part
      # puts @text_part
      # puts parts.size
      @text_part || find_first_mime_type("text/plain")
    end

    def text_part(&block)
      self.text_part = Part.new(&block)
    end

    # Helper to add a text part to a multipart/alternative email.  If this and
    # html_part are both defined in a message, then it will be a multipart/alternative
    # message and set itself that way.
    def text_part=(msg)
      # Assign the text part and set multipart/alternative if there's an html part.
      if msg
        msg = Part.new(body: Body.new(msg)) if !msg.is_a?(Message)

        @text_part = msg
        @text_part.not_nil!.content_type = "text/plain" unless @text_part.not_nil!.has_content_type?
        # add_multipart_alternate_header if html_part
        add_part @text_part

        # If nil, delete the text part and back out of multipart/alternative.
        # elsif @text_part
        #   parts.delete_if { |p| p.object_id == @text_part.object_id }
        #   @text_part = nil
        #   if html_part
        #     self.content_type = nil
        #     body.boundary = nil
        #   end
      end
    end

    # Adds a part to the parts list or creates the part list
    def add_part(part)
      if !body.multipart? && !Utilities.blank?(self.body.decoded)
        @text_part = Part.new(raw_source: "Content-Type: text/plain;")
        @text_part.not_nil!.body = body.decoded.to_s
        self.body << @text_part
        # add_multipart_alternate_header
      end
      # add_boundary
      self.body << part
    end

    HEADER_SEPARATOR = /#{Constants::LAX_CRLF}#{Constants::LAX_CRLF}/

    #  2.1. General Description
    #   A message consists of header fields (collectively called "the header
    #   of the message") followed, optionally, by a body.  The header is a
    #   sequence of lines of characters with special syntax as defined in
    #   this standard. The body is simply a sequence of characters that
    #   follows the header and is separated from the header by an empty line
    #   (i.e., a line with nothing preceding the CRLF).
    private def parse_message
      header_part, body_part = raw_source.lstrip.split(HEADER_SEPARATOR, 2)
      self.header = header_part
      self.body = body_part
    end

    # see comments to body=. We take data and process it lazily
    def body_lazy(value)
      process_body_raw if @body_raw && value
      case
      when value == nil || value.size <= 0
        @body = Mail::Body.new("")
        @body_raw = nil
        # add_encoding_to_body
      when @body && @body.multipart?
        self.text_part = value
      else
        @body_raw = value
      end
    end

    def all_parts
      parts.map { |p| [p, p.all_parts] of Mail::Part | Array(Mail::Part) }.flatten
    end

    def find_first_mime_type(ct)
      # TODO: Add this check as well => && !p.attachment?
      all_parts.find { |p| p.content_type == ct }
    end

    private def process_body_raw
      @body = Body.new(@body_raw)
      @body_raw = nil
      # separate_parts if @separate_parts

      # add_encoding_to_body
    end

    private def separate_parts
      body.split!(boundary)
    end

    private def set_envelope_header
      raw_string = raw_source
      if match_data = raw_string.match(/\AFrom\s+([^:\s]#{Constants::TEXT}*)#{Constants::LAX_CRLF}/m)
        set_envelope(match_data[1])
        self.raw_source = raw_string.sub(match_data[0], "")
      end
    end

    private def init_with_string(string)
      self.raw_source = string
      set_envelope_header
      parse_message
      @separate_parts = multipart?
    end
  end
end
