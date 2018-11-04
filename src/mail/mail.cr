module Mail
  def self.new(raw_email)
    Message.new(raw_email)
  end
end
