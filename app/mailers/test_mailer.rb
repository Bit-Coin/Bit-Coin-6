class TestMailer < BaseMailer
  
  def test(to='not_dev@ripplecrew.com') # Don't send to dev so we can test the interceptor
    mail( to: to, subject: 'Testy test')
  end
end
