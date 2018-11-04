require "./structured_field"

module Mail
  class NamedStructuredField < StructuredField # :nodoc:
    def initialize(value = nil, charset = nil)
      super value, charset
    end
  end
end
