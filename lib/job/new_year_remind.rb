class Job::NewYearRemind
  extend Resque::Plugins::Heroku
  @queue = :mailer

  def self.perform(company_ids=[], options={})

    totalhappiness = 0

    if company_ids.any?
      company_ids.each do |id|
        cname = Company.find(id).name
        list = Company.find(id).all_members.ripplers.active
        if list.any?
          happypeople = Ripple::NewYearReminder.new(list).happynewyear!
          message = "We just wished #{happypeople} people a happy new year at #{cname}!"
          Ripple::ActivityLogger.new(channel: '#activity', text: message).log!
          Resque.logger.info message
          totalhappiness = totalhappiness + happypeople
        end
      end
    else
      list = Company.find_by_stub("acme").all_members.ripplers.active

      if list.any?
        happypeople = Ripple::NewYearReminder.new(list).happynewyear!
        message = "We just wished #{happypeople} people a happy new year!"
        Ripple::ActivityLogger.new(channel: '#activity', text: message).log!
        Resque.logger.info message
        totalhappiness = totalhappiness + happypeople
      end
    end

    if totalhappiness > 0
      message = "We wished a total of #{totalhappiness} people a happy new year!"
    else
      message = "There was no one to watch the ball drop with us :("
    end
    
    Resque.logger.info message
    message
  end
end
