require "./named_structured_field"
require "../elements/content_type_element"

require "./parameter_hash"

module Mail
  class ContentTypeField < NamedStructuredField # :nodoc:
    @@field_name = "Content-Type"
    class_getter field_name : String

    @main_type : String? = nil
    @sub_type : String? = nil
    @element : ContentTypeElement? = nil
    @parameters : ParameterHash = ParameterHash.new

    setter :parameters

    def self.singular?
      true
    end

    def self.with_boundary(type)
      new "#{type}; boundary=#{generate_boundary}"
    end

    def self.generate_boundary
      "--==_mimepart_#{Random::Secure.hex}"
    end

    def initialize(value = nil, charset = nil)
      if value.is_a? Array
        @main_type = value[0]
        @sub_type = value[1]
        @parameters = ParameterHash.new.merge!(value.last)
      else
        @main_type = nil
        @sub_type = nil
        value = value.to_s
      end

      super ensure_filename_quoted(value), charset
    end

    def element
      @element ||=
        begin
          ContentTypeElement.new(value)
        rescue Field::ParseError
          attempt_to_clean
        end
    end

    def attempt_to_clean
      # Sanitize the value, handle special cases
      ContentTypeElement.new(sanitize(value.to_s))
    rescue Field::ParseError
      # All else fails, just get the MIME media type
      ContentTypeElement.new(get_mime_type(value))
    end

    def main_type
      @main_type ||= element.not_nil!.main_type
    end

    def sub_type
      @sub_type ||= element.not_nil!.sub_type
    end

    def mime_type
      "#{main_type}/#{sub_type}"
    end

    def content_type
      string
    end

    def default
      decoded
    end

    def parameters
      if @parameters.empty?
        element.parameters.each { |p| @parameters.merge!(p) }
      end
      @parameters
    end

    def value
      if @value.is_a? Array
        "#{@main_type}/#{@sub_type}; #{stringify(parameters)}"
      else
        @value
      end
    end

    # TODO: Fix param_encoding...
    def stringify(params)
      # params.map { |k, v| "#{k}=#{Encodings.param_encode(v)}" }.join("; ")
      params.map { |k, v| "#{k}=#{v}" }.join("; ")
    end

    def filename
      @filename ||= parameters["filename"] || parameters["name"]
    end

    # TODO: Fix encoded and decoded...
    def encoded
      p = parameters.size > 0 ? ";\r\n\s#{parameters.encoded}" : ""
      "#{name}: #{content_type}#{p}\r\n"
    end

    def decoded
      p = parameters.size > 0 ? "; #{parameters.decoded}" : ""
      "#{content_type}#{p}"
    end

    private def method_missing(name, *args, &block)
      if name.to_s =~ /(\w+)=/
        self.parameters[$1] = args.first
        @value = "#{content_type}; #{stringify(parameters)}"
      else
        super
      end
    end

    # Various special cases from random emails found that I am not going to change
    # the parser for
    private def sanitize(val)
      # TODO: check if there are cases where whitespace is not a separator
      val = val
        .gsub(/\s*=\s*/, "=") # remove whitespaces around equal sign
        .gsub(/[; ]+/, "; ")  # use '; ' as a separator (or EOL)
        .gsub(/;\s*$/, "")    # remove trailing to keep examples below

      if boundary = val.match(/(boundary=(\S*))/i)
        val = "#{boundary.pre_match.downcase}boundary=#{$2}#{boundary.pre_match.downcase}"
      else
        val = val.downcase
      end

      case
      when val.chomp =~ /^\s*([\w\-]+)\/([\w\-]+)\s*;\s?(ISO[\w\-]+)$/i
        # Microsoft helper:
        # Handles 'type/subtype;ISO-8559-1'
        "#{$1}/#{$2}; charset=#{Utilities.quote_atom($3)}"
      when val.chomp =~ /^text;?$/i
        # Handles 'text;' and 'text'
        "text/plain;"
      when val.chomp =~ /^(\w+);\s(.*)$/i
        # Handles 'text; <parameters>'
        "text/plain; #{$2}"
      when val =~ /([\w\-]+\/[\w\-]+);\scharset="charset="(\w+)""/i
        # Handles text/html; charset="charset="GB2312""
        "#{$1}; charset=#{Utilities.quote_atom($2)}"
      when val =~ /([\w\-]+\/[\w\-]+);\s+(.*)/i
        type = $1
        # Handles misquoted param values
        # e.g: application/octet-stream; name=archiveshelp1[1].htm
        # and: audio/x-midi;\r\n\sname=Part .exe
        params = $2.to_s.split(/\s+/)
        params = params.map { |i| i.to_s.chomp.strip }
        params = params.map { |i| i.split(/\s*\=\s*/, 2) }
        params = params.map { |i| "#{i[0]}=#{Utilities.dquote(i[1].to_s.gsub(/;$/, ""))}" }.join("; ")
        "#{type}; #{params}"
      when val =~ /^\s*$/
        "text/plain"
      else
        val
      end
    end

    private def get_mime_type(val)
      case val
      when /^([\w\-]+)\/([\w\-]+);.+$/i
        "#{$1}/#{$2}"
      else
        "text/plain"
      end
    end
  end
end
