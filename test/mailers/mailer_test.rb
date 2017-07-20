require 'test_helper'

class MailerTest < ActiveSupport::TestCase
  test 'interceptor' do
    ActionMailer::Base.deliveries.clear
    TestMailer.test.deliver
    assert_equal ['not_dev@ripplecrew.com'], ActionMailer::Base.deliveries.last.to
  end
end
