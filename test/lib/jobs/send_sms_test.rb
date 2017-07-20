require 'test_helper'

class SendSmsTest < ActiveSupport::TestCase
  describe 'Job::SendSms' do
    before do
      twilio_response_json = '{
          "sid": "SMfe36c03cb02a4deda542bc0520650584",
          "date_created": "Wed, 25 Feb 2015 19:12:40 +0000",
          "date_updated": "Wed, 25 Feb 2015 19:12:40 +0000",
          "date_sent": null,
          "account_sid": "AC0c5b970f90f92be53e1d01daa3dfccea",
          "to": "+17815551212",
          "from": "15005550006",
          "body": "testing testing",
          "status": "queued",
          "num_segments": "1",
          "num_media": "0",
          "direction": "outbound-api",
          "api_version": "2010-04-01",
          "price": null,
          "price_unit": "USD",
          "uri": "/2010-04-01/Accounts/AC0c5b970f90f92be53e1d01daa3dfccea/Messages/SMfe36c03cb02a4deda542bc0520650584.json",
          "subresource_uris": {
              "media": "/2010-04-01/Accounts/AC0c5b970f90f92be53e1d01daa3dfccea/Messages/SMfe36c03cb02a4deda542bc0520650584/Media.json"
          }
      }'
      
      stub_request(
        :post, /.*api\.twilio\.com.*/
      ).to_return(
        :status => 200, :body => twilio_response_json, :headers => {}
      )
    end
    
    describe '.perform' do
      it 'does not raise an exception' do 
        assert_nothing_raised Twilio::REST::RequestError do
          Job::SendSms.perform({'to' => '17815551212', 'body' => 'testing testing'})
        end
      end
    end
  end
end
