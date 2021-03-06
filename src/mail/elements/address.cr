require "../parsers/address_lists_parser"
require "../constants"
require "../utilities"

module Mail
  # Mail::Address handles all email addresses in Mail.  It takes an email address string
  # and parses it, breaking it down into its component parts and allowing you to get the
  # address, comments, display name, name, local part, domain part and fully formatted
  # address.
  #
  # Mail::Address requires a correctly formatted email address per RFC2822 or RFC822.  It
  # handles all obsolete versions including obsolete domain routing on the local part.
  #
  #  a = Address.new('Mikel Lindsaar (My email address) <mikel@test.lindsaar.net>')
  #  a.format       #=> 'Mikel Lindsaar <mikel@test.lindsaar.net> (My email address)'
  #  a.address      #=> 'mikel@test.lindsaar.net'
  #  a.display_name #=> 'Mikel Lindsaar'
  #  a.local        #=> 'mikel'
  #  a.domain       #=> 'test.lindsaar.net'
  #  a.comments     #=> ['My email address']
  #  a.to_s         #=> 'Mikel Lindsaar <mikel@test.lindsaar.net> (My email address)'
  class Address
    @parsed : Bool? = nil
    @data : Parsers::AddressListsParser::AddressStruct?
    @display_name : String? = nil

    def initialize(value = nil)
      if value.nil?
        @parsed = false
        @data = nil
      else
        parse(value)
      end
    end

    # Returns the raw input of the passed in string, this is before it is passed
    # by the parser.
    def raw
      @data.nil? ? nil : @data.not_nil!.raw
    end

    # Returns a correctly formatted address for the email going out.  If given
    # an incorrectly formatted address as input, Mail::Address will do its best
    # to format it correctly.  This includes quoting display names as needed and
    # putting the address in angle brackets etc.
    #
    #  a = Address.new('Mikel Lindsaar (My email address) <mikel@test.lindsaar.net>')
    #  a.format #=> 'Mikel Lindsaar <mikel@test.lindsaar.net> (My email address)'
    def format(output_type = :decode)
      parse unless @parsed
      if @data.nil?
        Constants::EMPTY
      elsif name = display_name(output_type)
        [Utilities.quote_phrase(name), "<#{address(output_type)}>", format_comments].compact.join(Constants::SPACE)
      elsif a = address(output_type)
        [a, format_comments].compact.join(Constants::SPACE)
      else
        raw
      end
    end

    # Returns the address that is in the address itself.  That is, the
    # local@domain string, without any angle brackets or the like.
    #
    #  a = Address.new('Mikel Lindsaar (My email address) <mikel@test.lindsaar.net>')
    #  a.address #=> 'mikel@test.lindsaar.net'
    def address(output_type = :decode)
      parse unless @parsed
      if d = domain(output_type)
        "#{local(output_type)}@#{d}"
      else
        local(output_type)
      end
    end

    # Provides a way to assign an address to an already made Mail::Address object.
    #
    #  a = Address.new
    #  a.address = 'Mikel Lindsaar (My email address) <mikel@test.lindsaar.net>'
    #  a.address #=> 'mikel@test.lindsaar.net'
    def address=(value)
      parse(value)
    end

    # Returns the display name of the email address passed in.
    #
    #  a = Address.new('Mikel Lindsaar (My email address) <mikel@test.lindsaar.net>')
    #  a.display_name #=> 'Mikel Lindsaar'
    def display_name(output_type = :decode)
      parse unless @parsed
      @display_name ||= get_display_name
      # TODO: Fix encoding issus...
      # Encodings.decode_encode(@display_name.to_s, output_type) if @display_name
    end

    # Provides a way to assign a display name to an already made Mail::Address object.
    #
    #  a = Address.new
    #  a.address = 'mikel@test.lindsaar.net'
    #  a.display_name = 'Mikel Lindsaar'
    #  a.format #=> 'Mikel Lindsaar <mikel@test.lindsaar.net>'
    def display_name=(str)
      @display_name = str.nil? ? nil : str.dup # in case frozen
    end

    # Returns the local part (the left hand side of the @ sign in the email address) of
    # the address
    #
    #  a = Address.new('Mikel Lindsaar (My email address) <mikel@test.lindsaar.net>')
    #  a.local #=> 'mikel'
    def local(output_type = :decode)
      parse unless @parsed
      "#{@data.nil? ? nil : @data.not_nil!.obs_domain_list}#{get_local.to_s.strip}"
      # TODO: Fix encoding issus...
      # Encodings.decode_encode("#{@data.obs_domain_list}#{get_local.strip}", output_type) if get_local
    end

    # Returns the domain part (the right hand side of the @ sign in the email address) of
    # the address
    #
    #  a = Address.new('Mikel Lindsaar (My email address) <mikel@test.lindsaar.net>')
    #  a.domain #=> 'test.lindsaar.net'
    def domain(output_type = :decode)
      parse unless @parsed
      # TODO: Fix encoding issus...
      strip_all_comments(get_domain.to_s)
      # Encodings.decode_encode(strip_all_comments(get_domain), output_type) if get_domain
    end

    # Returns an array of comments that are in the email, or nil if there
    # are no comments
    #
    #  a = Address.new('Mikel Lindsaar (My email address) <mikel@test.lindsaar.net>')
    #  a.comments #=> ['My email address']
    #
    #  b = Address.new('Mikel Lindsaar <mikel@test.lindsaar.net>')
    #  b.comments #=> nil

    def comments
      parse unless @parsed
      comments = get_comments
      if comments.nil? || comments.none?
        nil
      else
        comments.map { |c| c.squeeze(Constants::SPACE) }
      end
    end

    # Sometimes an address will not have a display name, but might have the name
    # as a comment field after the address.  This returns that name if it exists.
    #
    #  a = Address.new('mikel@test.lindsaar.net (Mikel Lindsaar)')
    #  a.name #=> 'Mikel Lindsaar'
    def name
      parse unless @parsed
      get_name
    end

    # Returns the format of the address, or returns nothing
    #
    #  a = Address.new('Mikel Lindsaar (My email address) <mikel@test.lindsaar.net>')
    #  a.format #=> 'Mikel Lindsaar <mikel@test.lindsaar.net> (My email address)'
    def to_s
      parse unless @parsed
      format
    end

    # Shows the Address object basic details, including the Address
    #  a = Address.new('Mikel (My email) <mikel@test.lindsaar.net>')
    #  a.inspect #=> "#<Mail::Address:14184910 Address: |Mikel <mikel@test.lindsaar.net> (My email)| >"
    def inspect
      parse unless @parsed
      "#<#{self.class}:#{self.object_id} Address: |#{to_s}| >"
    end

    def encoded
      format :encode
    end

    def decoded
      format :decode
    end

    def group
      @data.nil? ? nil : @data.not_nil!.group
    end

    private def parse(value = nil)
      @parsed = true
      @data = nil

      case value
      when Parsers::AddressListsParser::AddressStruct
        @data = value
      when String
        unless Utilities.blank?(value)
          address_list = Parsers::AddressListsParser.parse(value)
          @data = address_list.addresses.first
        end
      end
    end

    private def strip_all_comments(string : String)
      unless Utilities.blank?(comments)
        comments.not_nil!.each do |comment|
          string = string.gsub("(#{comment})", Constants::EMPTY)
        end
      end
      string.strip
    end

    private def strip_domain_comments(value)
      unless Utilities.blank?(comments)
        comments.not_nil!.each do |comment|
          if @data.nil? ? nil : @data.not_nil!.domain && @data.not_nil!.domain.to_s.includes?("(#{comment})")
            value = value.gsub("(#{comment})", Constants::EMPTY)
          end
        end
      end
      value.to_s.strip
    end

    private def get_display_name
      if display_name = @data.nil? ? nil : @data.not_nil!.display_name
        str = strip_all_comments(display_name.to_s)
      elsif @data.nil? ? nil : @data.not_nil!.comments && @data.not_nil!.domain
        str = strip_domain_comments(format_comments.to_s)
      end
      str unless Utilities.blank?(str)
    end

    private def get_name
      if display_name
        str = display_name
      elsif comments
        str = "(#{comments.join(Constants::SPACE).squeeze(Constants::SPACE)})"
      end

      Utilities.unparen(str) unless Utilities.blank?(str)
    end

    private def format_comments
      if comments
        comment_text = comments.not_nil!.map { |c| Utilities.escape_paren(c) }.join(Constants::SPACE).squeeze(Constants::SPACE)
        @format_comments ||= "(#{comment_text})"
      else
        nil
      end
    end

    private def get_local
      @data.nil? ? nil : @data.not_nil!.local
    end

    private def get_domain
      @data.nil? ? nil : @data.not_nil!.domain
    end

    private def get_comments
      @data.nil? ? nil : @data.not_nil!.comments
    end
  end
end
