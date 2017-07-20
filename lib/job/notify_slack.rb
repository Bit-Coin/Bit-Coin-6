class Job::NotifySlack
  extend Resque::Plugins::Heroku
  @queue = :slack
  max_retries = 3
  times_retried = 0

  # TODO: Move the Slack webhook URL into an environment variable

  def self.perform(options={})
    payload = {
      :channel => options['channel'],
      :username => options['username'],
      :text => options['text'],
      :icon_emoji => options['icon_emoji']
    }
    begin
      response = HTTParty.post( 'https://hooks.slack.com/services/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',
        body: {
          :payload => payload.to_json
        }
      )
    rescue  Net::ReadTimeout => e
      Resque.logger.error e.message + " with payload: #{payload}"
    end
  end
end
