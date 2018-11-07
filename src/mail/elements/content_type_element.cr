require "../parsers/content_type_parser"

module Mail
  class ContentTypeElement # :nodoc:
    property main_type : String?, sub_type : String?,
      parameters : Array(Hash(String, String))

    def initialize(string)
      content_type = Parsers::ContentTypeParser.parse(cleaned(string))
      @main_type = content_type.main_type
      @sub_type = content_type.sub_type
      @parameters = content_type.parameters
    end

    private def cleaned(string)
      if match = string.to_s.match /;\s*$/
        match.pre_match
      else
        string
      end
    end
  end
end
