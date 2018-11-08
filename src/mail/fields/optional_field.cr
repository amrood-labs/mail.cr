require "./unstructured_field"

module Mail
  # The field names of any optional-field MUST NOT be identical to any
  # field name specified elsewhere in this standard.
  #
  # optional-field  =       field-name ":" unstructured CRLF
  class OptionalField < UnstructuredField # :nodoc:
    @@field_name = "OptionalField"
    class_getter field_name : String

    private def do_encode
      "#{wrapped_value}\r\n"
    end
  end
end
