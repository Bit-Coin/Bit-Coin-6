class Job::PostEmail
  extend Resque::Plugins::Heroku
  @queue = :api

  def self.perform(company_id, email)
    c = Company.find(company_id)
    RippleApi::Client.new(c).post_email_sent(email)
  end
end
