require "./constants"
require "./utilities"

module Mail
  # Provides access to a header object.
  #
  # ===Per RFC2822
  #
  #  2.2. Header Fields
  #
  #   Header fields are lines composed of a field name, followed by a colon
  #   (":"), followed by a field body, and terminated by CRLF.  A field
  #   name MUST be composed of printable US-ASCII characters (i.e.,
  #   characters that have values between 33 and 126, inclusive), except
  #   colon.  A field body may be composed of any US-ASCII characters,
  #   except for CR and LF.  However, a field body may contain CRLF when
  #   used in header "folding" and  "unfolding" as described in section
  #   2.2.3.  All field bodies MUST conform to the syntax described in
  #   sections 3 and 4 of this standard.
  class Header
    # include Enumerable

    # Large amount of headers in Email might create extra high CPU load
    # Use this parameter to limit number of headers that will be parsed by
    # mail library.
    # Default: 1000
    class_property maximum_amount : Int64 = 1000

    @charset : String
    @raw_source : String
    @fields : FieldList
    getter! raw_source, charset

    # Creates a new header object.
    #
    # Accepts raw text or nothing.  If given raw text will attempt to parse
    # it and split it into the various fields, instantiating each field as
    # it goes.
    #
    # If it finds a field that should be a structured field (such as content
    # type), but it fails to parse it, it will simply make it an unstructured
    # field and leave it alone.  This will mean that the data is preserved but
    # no automatic processing of that field will happen.  If you find one of
    # these cases, please make a patch and send it in, or at the least, send
    # me the example so we can fix it.
    def initialize(header_text : String, charset : String)
      @charset = charset
      @raw_source = Utilities.to_crlf(header_text).lstrip
      @fields = FieldList.new
      split_header if !Utilities.blank? header_text
    end

    # def initialize_copy(original)
    #   super
    #   @fields = @fields.dup
    #   @fields.map!(&:dup)
    # end

    # Returns an array of all the fields in the header in order that they
    # were read in.
    def fields
      @fields ||= FieldList.new
    end

    #  3.6. Field definitions
    #
    #   It is important to note that the header fields are not guaranteed to
    #   be in a particular order.  They may appear in any order, and they
    #   have been known to be reordered occasionally when transported over
    #   the Internet.  However, for the purposes of this standard, header
    #   fields SHOULD NOT be reordered when a message is transported or
    #   transformed.  More importantly, the trace header fields and resent
    #   header fields MUST NOT be reordered, and SHOULD be kept in blocks
    #   prepended to the message.  See sections 3.6.6 and 3.6.7 for more
    #   information.
    #
    # Populates the fields container with Field objects in the order it
    # receives them in.
    #
    # Acceps an array of field string values, for example:
    #
    #  h = Header.new
    #  h.fields = ['From: mikel@me.com', 'To: bob@you.com']
    def fields=(unfolded_fields)
      if unfolded_fields.size > self.class.maximum_amount
        # Kernel.warn "WARNING: More than #{self.class.maximum_amount} header fields; only using the first #{self.class.maximum_amount} and ignoring the rest"
        unfolded_fields = unfolded_fields[0...self.class.maximum_amount]
      end

      unfolded_fields.each do |field|
        if field = Field.parse(field, charset)
          @fields.add_field field
        end
      end
    end

    # def errors
    #   @fields.map(&:errors).flatten(1)
    # end

    #  3.6. Field definitions
    #
    #   The following table indicates limits on the number of times each
    #   field may occur in a message header as well as any special
    #   limitations on the use of those fields.  An asterisk next to a value
    #   in the minimum or maximum column indicates that a special restriction
    #   appears in the Notes column.
    #
    #   <snip table from 3.6>
    #
    # As per RFC, many fields can appear more than once, we will return a string
    # of the value if there is only one header, or if there is more than one
    # matching header, will return an array of values in order that they appear
    # in the header ordered from top to bottom.
    #
    # Example:
    #
    #  h = Header.new
    #  h.fields = ['To: mikel@me.com', 'X-Mail-SPAM: 15', 'X-Mail-SPAM: 20']
    #  h['To']          #=> 'mikel@me.com'
    #  h['X-Mail-SPAM'] #=> ['15', '20']
    def [](name)
      fields.get_field(Utilities.dasherize(name))
    end

    # Sets the FIRST matching field in the header to passed value, or deletes
    # the FIRST field matched from the header if passed nil
    #
    # Example:
    #
    #  h = Header.new
    #  h.fields = ['To: mikel@me.com', 'X-Mail-SPAM: 15', 'X-Mail-SPAM: 20']
    #  h['To'] = 'bob@you.com'
    #  h['To']    #=> 'bob@you.com'
    #  h['X-Mail-SPAM'] = '10000'
    #  h['X-Mail-SPAM'] # => ['15', '20', '10000']
    #  h['X-Mail-SPAM'] = nil
    #  h['X-Mail-SPAM'] # => nil
    def []=(name, value)
      name = name.to_s
      if name.includes?(Constants::COLON)
        raise ArgumentError.new "Header names may not contain a colon: #{name.inspect}"
      end

      name = Utilities.dasherize(name)

      # Assign nil to delete the field
      if value.nil?
        fields.delete_field name
      else
        fields.add_field Field.new(name.to_s, value, charset)

        # TODO: Fix parameters in content-type....
        # ISSUE: undefined method 'parameters' for Array(Mail::Field) (compile-time type is (Array(Mail::Field) | Mail::Field))
        # Update charset if specified in Content-Type
        # if name == "content-type" && !self["content_type"].is_a?(Array)
        #   params = self["content_type"].not_nil!.parameters
        #   @charset = params["charset"] if params["charset"]
        # end
      end
    end

    # TODO: Fix parameters in content-type....
    # ISSUE: undefined method 'parameters' for Array(Mail::Field) (compile-time type is (Array(Mail::Field) | Mail::Field))
    def charset=(val)
      # params = self["content_type"].parameters rescue nil
      # if params
      #   params["charset"] = val
      # end
      @charset = val
    end

    # def encoded
    #   buffer = String.new
    #   buffer.force_encoding('us-ascii') if buffer.responds_to?(:force_encoding)
    #   fields.each do |field|
    #     buffer << field.encoded
    #   end
    #   buffer
    # end

    # def to_s
    #   encoded
    # end

    # def decoded
    #   raise NoMethodError, 'Can not decode an entire header as there could be character set conflicts. Try calling #decoded on the various fields.'
    # end

    # def field_summary
    #   fields.summary
    # end

    # # Returns true if the header has a Message-ID defined (empty or not)
    # def has_message_id?
    #   fields.has_field? 'Message-ID'
    # end

    # # Returns true if the header has a Content-ID defined (empty or not)
    # def has_content_id?
    #   fields.has_field? 'Content-ID'
    # end

    # # Returns true if the header has a Date defined (empty or not)
    # def has_date?
    #   fields.has_field? 'Date'
    # end

    # # Returns true if the header has a MIME version defined (empty or not)
    # def has_mime_version?
    #   fields.has_field? 'Mime-Version'
    # end

    # Splits an unfolded and line break cleaned header into individual field
    # strings.
    private def split_header
      self.fields = @raw_source.split(Constants::HEADER_SPLIT)
    end

    private def select_fields_for(name)
      fields.select_fields { |f| f.responsible_for?(name) }
    end

    # Enumerable support. Yield each field in order.
    # private def each(&block)
    #   fields.each(&block)
    # end
  end
end
