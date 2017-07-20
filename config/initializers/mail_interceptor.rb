class MailInterceptor
  def self.delivering_email(message)

    # Detect SMS
    if message.to[0] =~ /^\d+$/ # all digits, no @
      Resque.enqueue(Job::SendSms, {'to' => message.to[0], 'body' => message.body.raw_source})
      message.perform_deliveries = false # black hole the email
    end

    # dev mail goes to mailcatcher. test mail goes to ActionMailer::Base.deliveries
    if ['staging', 'demo'].include? Rails.env 
      message.to = ['mpusey@ripplecrew.com']
      message.subject = "[#{Rails.env}] " + message.subject
      # TODO Record the original to address somewhere (body is not simple)
    end
  end
end

ActionMailer::Base.register_interceptor(MailInterceptor)
