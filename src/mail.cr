# For keeping consistency...
struct UInt8
  def ord
    self
  end
end

require "./mail/elements"
require "./mail/message"
require "./mail/header"
require "./mail/field"
require "./mail/field_list"
require "./mail/envelope"
require "./mail/mail"

# TODO: Write documentation for `Mail`
module Mail
  VERSION = "0.1.0"
end
