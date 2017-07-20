module PasswordComplexable # ridiculous
  extend ActiveSupport::Concern

  included do
    validate :password_complexity
  end

  private 

  def password_complexity
    if password.present? and not password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)./)
      errors.add :password, "must include at least one lowercase letter, one uppercase letter, and one digit"
    end
  end
end
