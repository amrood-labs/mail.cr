require "../parsers/envelope_from_parser"

# require 'date'

module Mail
  class EnvelopeFromElement # :nodoc:
    getter :date_time, address : String?

    def initialize(string)
      envelope_from = Mail::Parsers::EnvelopeFromParser.parse(string)
      @address = envelope_from.address
      # TODO: Fix date parsing...
      @date_time = Time.now # .parse(envelope_from.ctime_date) if envelope_from.ctime_date
    end

    # RFC 4155:
    #   A timestamp indicating the UTC date and time when the message
    #   was originally received, conformant with the syntax of the
    #   traditional UNIX 'ctime' output sans timezone (note that the
    #   use of UTC precludes the need for a timezone indicator);
    def formatted_date_time
      if date_time
        if date_time.respond_to?(:ctime)
          date_time.ctime
        else
          date_time.strftime "%a %b %e %T %Y"
        end
      end
    end

    def to_s
      if date_time
        "#{address} #{formatted_date_time}"
      else
        address
      end
    end
  end
end
