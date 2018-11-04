require "./named_structured_field"

module Mail
  # TODO: Fix container class...
  # class AddressContainer < Array(String) # :nodoc:

  #   setter field : CommonAddressField? = nil

  #   def <<(address : String)
  #     self.push address
  #   end
  # end

  class CommonAddressField < NamedStructuredField # :nodoc:

    @element : AddressList? = nil

    def self.singular?
      true
    end

    def initialize(value = nil, charset = nil)
      super encode_if_needed(value, charset), charset
    end

    def element # :nodoc:
      @element ||= AddressList.new(value)
    end

    # Allows you to iterate through each address object in the address_list
    def each
      element.addresses.each do |address|
        yield(address)
      end
    end

    def default
      addresses
    end

    def address
      addresses.first
    end

    # Returns the address string of all the addresses in the address list
    def addresses
      element.addresses.map { |a| a.address }
    end

    # Returns the formatted string of all the addresses in the address list
    def formatted
      element.addresses.map { |a| a.format }
    end

    # Returns the display name of all the addresses in the address list
    def display_names
      element.addresses.map { |a| a.display_name }
    end

    # Returns the actual address objects in the address list
    def addrs
      element.addresses.map { |a| a }
    end

    # Returns a hash of group name => address strings for the address list
    def groups
      element.addresses_grouped_by_group
    end

    # Returns the addresses that are part of groups
    def group_addresses
      decoded_group_addresses
    end

    # Returns a list of decoded group addresses
    def decoded_group_addresses
      groups.map { |k, v| v.map { |a| a.decoded } }.flatten
    end

    # Returns a list of encoded group addresses
    def encoded_group_addresses
      groups.map { |k, v| v.map { |a| a.encoded } }.flatten
    end

    # Returns the name of all the groups in a string
    def group_names # :nodoc:
      element.group_names
    end

    def <<(val)
      case
      when val.nil?
        raise ArgumentError, "Need to pass an address to <<"
      when Utilities.blank?(val)
        self
      else
        self.value = [self.value, encode_if_needed(val)].reject { |a| Utilities.blank?(a) }.join(", ")
      end
    end

    def encode_if_needed(val, val_charset = charset) # :nodoc:
      case val
      when nil
        val
        # Need to join arrays of addresses into a single value
      when Array
        val.compact.map { |a| encode_if_needed a, val_charset }.join(", ")
        # Pass through UTF-8; encode non-UTF-8.
      else
        utf8_if_needed(val, val_charset) # || Encodings.encode_non_usascii(val, val_charset)
      end
    end

    # Pass through UTF-8 addresses
    def utf8_if_needed(val, val_charset)
      if val_charset =~ /\AUTF-?8\z/i
        val
      elsif val.valid_encoding?
        val
      elsif !val.is_a?(String)
        String.new val
      end
    end

    def do_encode
      return "" if Utilities.blank?(value)
      address_array = element.addresses.reject { |a| encoded_group_addresses.includes?(a.encoded) }.compact.map { |a| a.encoded }
      address_text = address_array.join(", \r\n\s")
      group_array = groups.map { |k, v| "#{k}: #{v.map { |a| a.encoded }.join(", \r\n\s")};" }
      group_text = group_array.join(" \r\n\s")
      return_array = [address_text, group_text].reject { |a| Utilities.blank?(a) }
      "#{name}: #{return_array.join(", \r\n\s")}\r\n"
    end

    def do_decode
      return nil if Utilities.blank?(value)
      address_array = element.addresses.reject { |a| decoded_group_addresses.includes?(a.decoded) }.map { |a| a.decoded }
      address_text = address_array.join(", ")
      group_array = groups.map { |k, v| "#{k}: #{v.map { |a| a.decoded }.join(", ")};" }
      group_text = group_array.join(" ")
      return_array = [address_text, group_text].reject { |a| Utilities.blank?(a) }
      return_array.join(", ")
    end

    def get_group_addresses(group_list)
      if group_list.respond_to?(:addresses)
        group_list.addresses.map do |address|
          Address.new(address)
        end
      else
        [] of Address
      end
    end
  end
end
