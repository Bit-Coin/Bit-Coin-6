module RippleApi

  class Client
    include HTTParty
    base_uri 'api.ripplecrew.com'

    def initialize(company)
      raise 'Missing key and auth tokens' unless company.ripple_api_key && company.ripple_api_token
      @auth = { username: company.ripple_api_key, password: company.ripple_api_token }
    end

    def get_events_schemas
      self.class.get('/events/schemas', basic_auth: @auth)
    end

    def post_email_sent(email)
      self.class.post(
        '/events', 
        body: email.to_json, 
        basic_auth: @auth,
        headers: {}
      )
    end
  end

  # RippleApi::Client.new(Company.first).post_email_sent(RippleApi::TestEmail.new)
  class TestEmail
    def initialize
      @event_type = 'email_sent'
      @event_data = { sent_at: Time.now.to_s,
                      from: 'dev@ripplecrew.com',
                      to: ['dev@ripplecrew.com'] }
    end
  end
end
