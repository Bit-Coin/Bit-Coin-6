module Security

  DEMO_PASSWORD = 'notSecure!123'
  ENCRYPTED_DEMO_PASSWORD = User.new(password: DEMO_PASSWORD).encrypted_password
  
end
