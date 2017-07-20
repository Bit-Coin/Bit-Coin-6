require 'test_helper'

class SendgridToolkitTest < ActiveSupport::TestCase
  before do
    stub_request(:post, /.*api\.sendgrid\.com/).to_return(:status => 200, :body => "", :headers => {})
  end
  
  # This tests nothing LOL
  
  test 'can connect to api' do 
    assert_equal Net::HTTPOK, SendgridToolkit::InvalidEmails.new.retrieve.response.class
  end
end
