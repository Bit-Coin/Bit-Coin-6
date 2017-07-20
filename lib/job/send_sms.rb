class Job::SendSms
  extend Resque::Plugins::Heroku

  TWILIO_TEST_FROM = '15005550006'
  TWILIO_FROM = '17817804241'

  @queue = :sms
  @from = Rails.env.production? ? TWILIO_FROM : TWILIO_TEST_FROM

  # GOTCHA Use strings as hash keys for Resque!
  # Send {'to' => 'blah', 'body' => 'blah'}
  # not {to: 'blah', body: 'blah'}
  def self.perform(options={})
    options['from'] ||= @from
    raise 'Missing/malformatted mobile number' unless options['to'] =~ /^\d+/
    raise 'No body' if options['body'].blank?
    client = Twilio::REST::Client.new
    client.messages.create(
      from: options['from'],
      to: options['to'],
      body: options['body']
    )
  end
end
