#
# = Mail Envelope
#
# The Envelope class provides a field for the first line in an
# mbox file, that looks like "From mikel@test.lindsaar.net DATETIME"
#
# This envelope class reads that line, and turns it into an
# Envelope.from and Envelope.date for your use.

module Mail
  class Envelope < NamedStructuredField
    @@field_name = "Envelope-From"
    class_getter field_name : String

    @element : EnvelopeFromElement? = nil

    def element
      @element ||= Mail::EnvelopeFromElement.new(value)
    end

    def from
      element.address
    end

    def date
      element.date_time
    end
  end
end
