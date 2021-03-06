require "./fields"
require "./constants"

module Mail
  # Provides a single class to call to create a new structured or unstructured
  # field.  Works out per RFC what field of field it is being given and returns
  # the correct field of class back on new.
  #
  # ===Per RFC 2822
  #
  #  2.2. Header Fields
  #
  #     Header fields are lines composed of a field name, followed by a colon
  #     (":"), followed by a field body, and terminated by CRLF.  A field
  #     name MUST be composed of printable US-ASCII characters (i.e.,
  #     characters that have values between 33 and 126, inclusive), except
  #     colon.  A field body may be composed of any US-ASCII characters,
  #     except for CR and LF.  However, a field body may contain CRLF when
  #     used in header "folding" and  "unfolding" as described in section
  #     2.2.3.  All field bodies MUST conform to the syntax described in
  #     sections 3 and 4 of this standard.
  #
  class Field
    include Comparable(Field)

    STRUCTURED_FIELDS = %w[bcc cc content-description content-disposition
      content-id content-location content-transfer-encoding
      content-type date from in-reply-to keywords message-id
      mime-version received references reply-to
      resent-bcc resent-cc resent-date resent-from
      resent-message-id resent-sender resent-to
      return-path sender to]

    KNOWN_FIELDS = STRUCTURED_FIELDS + ["comments", "subject"]

    FIELDS_MAP = {
      "to" => ToField,
      # "cc" => CcField,
      # "bcc" => BccField,
      # "message-id" => MessageIdField,
      # "in-reply-to" => InReplyToField,
      # "references" => ReferencesField,
      # "subject" => SubjectField,
      # "comments" => CommentsField,
      # "keywords" => KeywordsField,
      # "date" => DateField,
      "from" => FromField,
      # "sender" => SenderField,
      # "reply-to" => ReplyToField,
      # "resent-date" => ResentDateField,
      # "resent-from" => ResentFromField,
      # "resent-sender" =>  ResentSenderField,
      # "resent-to" => ResentToField,
      # "resent-cc" => ResentCcField,
      # "resent-bcc" => ResentBccField,
      # "resent-message-id" => ResentMessageIdField,
      # "return-path" => ReturnPathField,
      # "received" => ReceivedField,
      # "mime-version" => MimeVersionField,
      "content-transfer-encoding" => ContentTransferEncodingField,
      # "content-description" => ContentDescriptionField,
      # "content-disposition" => ContentDispositionField,
      "content-type" => ContentTypeField,
      # "content-id" => ContentIdField,
      # "content-location" => ContentLocationField,
    }

    macro process_fields_name_map
      FIELD_NAME_MAP = {
        {% for key, value in FIELDS_MAP %}
          "{{key.id}}" => {{value.id}}.field_name,
        {% end %}
      }
    end

    process_fields_name_map()

    # Generic Field Exception
    class FieldError < Exception
    end

    # Raised when a parsing error has occurred (ie, a StructuredField has tried
    # to parse a field that is invalid or improperly written)
    class ParseError < FieldError # :nodoc:
      property value : String, reason : String

      def initialize(element, value, reason)
        # @element = element
        @value = value
        @reason = reason
        super("#{element} can not parse |#{@value}|: #{@reason}")
      end
    end

    class IncompleteParseError < ParseError # :nodoc:
      def initialize(element, original_text, unparsed_index)
        parsed_text = original_text[0...unparsed_index]
        super element, original_text, "Only able to parse up to #{parsed_text.inspect}"
      end
    end

    # Raised when attempting to set a structured field's contents to an invalid syntax
    class SyntaxError < FieldError # :nodoc:
    end

    # Parse a field from a raw header line:
    #
    #  Mail::Field.parse("field-name: field data")
    #  # => #<Mail::Field …>
    def self.parse(field : String, charset = "UTF-8")
      name, value = split(field)
      if name && value
        new name, value, charset
      end
    end

    def self.split(raw_field) # :nodoc:
      if raw_field.index(Constants::COLON)
        name, value = raw_field.split(Constants::COLON, 2)
        name = name.rstrip
        if name =~ /\A#{Constants::FIELD_NAME}\z/
          [name.rstrip, value.strip]
        else
          # Kernel.warn "WARNING: Ignoring unparsable header #{raw_field.inspect}: invalid header name syntax: #{name.inspect}"
          [nil, nil]
        end
      else
        [raw_field.strip, nil]
      end
    rescue error
      # warn "WARNING: Ignoring unparsable header #{raw_field.inspect}: #{error.class}: #{error.message}"
      [nil, nil]
    end

    @name : String
    @field : CommonField? = nil
    @field_order_id : Int32? = nil
    property unparsed_value : String? = nil

    # Create a field by name and optional value:
    #
    #  Mail::Field.new("field-name", "value")
    #  # => #<Mail::Field …>
    #
    # Values that aren't strings or arrays are coerced to Strings with `#to_s`.
    #
    #  Mail::Field.new("field-name", 1234)
    #  # => #<Mail::Field …>
    #
    #  Mail::Field.new('content-type', ['text', 'plain', {:charset => 'UTF-8'}])
    #  # => #<Mail::Field …>
    def initialize(name, value = nil, charset = "UTF-8")
      case
      when name.index(Constants::COLON)
        raise ArgumentError.new "Passing an unparsed header field to Mail::Field.new is not supported in Mail 2.8.0+. Use Mail::Field.parse instead."
      when Utilities.blank?(value)
        @name = name
        @unparsed_value = nil
        @charset = charset
      else
        @name = name
        @unparsed_value = value
        @charset = charset
      end
      @name = FIELD_NAME_MAP[@name.to_s.downcase] rescue @name
    end

    def field=(field)
      @field = field
    end

    def field
      @field ||= create_field(@name, @unparsed_value, @charset)
    end

    def name
      @name
    end

    def value
      field.value
    end

    def value=(val)
      @field = create_field(name, val, @charset)
    end

    def to_s
      field.to_s
    end

    # def inspect
    #   "#<#{self.class.name} 0x#{(object_id * 2).to_s(16)} #{instance_variables.map do |ivar|
    #                                                           "#{ivar}=#{instance_variable_get(ivar).inspect}"
    #                                                         end.join(" ")}>"
    # end

    def same(other)
      other.kind_of?(self.class) && Utilities.match_to_s(other.name, name)
    end

    def ==(other)
      same(other) && Utilities.match_to_s(other.value, value)
    end

    def responsible_for?(field_name)
      name.to_s.compare(field_name.to_s, true) == 0
    end

    def <=>(other)
      field_order_id <=> other.field_order_id
    end

    def field_order_id
      @field_order_id ||= FIELD_ORDER_LOOKUP.fetch(self.name.to_s.downcase, 100)
    end

    # def parameters
    #   if typeof(field).is_a? ContentTypeField
    #     field.not_nil!.parameters
    #   else
    #     raise NoMehtodError.new "This field should be a ContentTypeField to have a parameters function."
    #   end
    # end

    macro method_missing(call)
      if field.not_nil!.responds_to? :{{call.name.id}}
        field.not_nil!.{{call.name.id}}({{*call.args}})
      end
    end

    FIELD_ORDER_LOOKUP = %w[
      return-path received
      resent-date resent-from resent-sender resent-to
      resent-cc resent-bcc resent-message-id
      date from sender reply-to to cc bcc
      message-id in-reply-to references
      subject comments keywords
      mime-version content-type content-transfer-encoding
      content-location content-disposition content-description
    ].each_with_index.to_h

    private def create_field(name, value, charset)
      parse_field(name, value, charset)
    rescue e : Field::ParseError
      field = UnstructuredField.new(name, value)
      field.errors << [name.to_s, value.to_s, e]
      field
    end

    private def parse_field(name, value, charset)
      value = unfold(value) if value.is_a?(String)

      if klass = field_class_for(name)
        klass.parse(value, charset)
      end
    end

    private def field_class_for(name)
      FIELDS_MAP[name.to_s.downcase]
    rescue KeyError
      OptionalField
    end

    # 2.2.3. Long Header Fields
    #
    #  The process of moving from this folded multiple-line representation
    #  of a header field to its single line representation is called
    #  "unfolding". Unfolding is accomplished by simply removing any CRLF
    #  that is immediately followed by WSP.  Each header field should be
    #  treated in its unfolded form for further syntactic and semantic
    #  evaluation.
    private def unfold(string)
      string.gsub(Constants::UNFOLD_WS, "\1")
    end
  end
end
