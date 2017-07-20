class Admin < ActiveRecord::Base

  # WARNING Before trying to use confirmable or recoverable,
  # you must tell CustomDeviseMailer you're an Admin
  devise :database_authenticatable, :rememberable, :trackable, 
    :validatable, :registerable
  include PasswordComplexable

  def full_name
    first_name + ' ' + last_name
  end

  # Support for admins becoming proxies for a user
   
  has_many :proxied_users, :class_name => 'User'
  
  def is_proxy?
    !!proxied_users.count > 0
  end
  
  def is_proxy_for?(user)
    user.proxy_id == self.id
  end

end
