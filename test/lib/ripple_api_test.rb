require 'test_helper'

class RippleApiTest < ActiveSupport::TestCase
  test 'bombs without creds' do
    assert_raises(RuntimeError) { RippleApi::Client.new(Company.new) }
  end

  test 'get events_schemas' do
    skip
    c = Company.first
    assert (c.ripple_api_key && c.ripple_api_token)
    api = RippleApi::Client.new(c)
    response = JSON.parse(api.get_events_schemas)
    assert response['schemas']
  end

  test 'post email_sent' do
    skip
    c = Company.first
    assert (c.ripple_api_key && c.ripple_api_token)
    api = RippleApi::Client.new(c)
    response = JSON.parse(api.post_email_sent(RippleApi::TestEmail.new))
    assert_equal 'ok', response['status']
  end
end
