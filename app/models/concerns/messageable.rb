module Messageable
  extend ActiveSupport::Concern

  included do
    has_many :messages, as: :messageable
  end

  # Each messageable has to implement a recipient method
  def recipient
    case self.class.to_s
    when "Survey"
      giver
    when "User"
      self
    else
      raise 'Not implemented.'
    end
  end
end
