class Job::RemoveFakeFriends
  extend Resque::Plugins::Heroku
  @queue = :surveys

  # Pass in a list of user IDs; this job will delete all surveys completed by 
  # all users listed in Globals::TESTDRIVE_AUTO_FRIENDS (config/application.rb)

  def self.perform(options={})

    users = options[:users] || []

    num_unfriended = 0

    # First destroy all the survey responses, then the surveys, then the invite

    User.where('id in (?)', users).each do |u|
      User.where('email in (?)', Ripple::Globals::TESTDRIVE_AUTO_FRIENDS).each do |ff|
        Survey.for_pair(ff, u).open.each do |s|
          Response.where('survey_id = ?', s.id).each do |r|
            Resque.logger.info "Destroying response id #{r.id}"
            r.destroy
          end # Response
          Resque.logger.info "Destroying survey id #{s.id}"
          s.destroy
        end # Survey (fake friend giving to user)

        Invitation.for_pair(ff, u).active.each do |i|
          Resque.logger.info "Destroying invitation id #{i.id}"
          i.destroy
        end # Invitation (fake friend giving to user)

        Survey.for_pair(u, ff).open.each do |s|
          Response.where('survey_id = ?', s.id).each do |r|
            Resque.logger.info "Destroying response id #{r.id}"
            r.destroy
          end # Response
          Resque.logger.info "Destroying survey id #{s.id}"
          s.destroy
        end # Survey (user giving to fake friend)

        Invitation.for_pair(u, ff).active.each do |i|
          Resque.logger.info "Destroying invitation id #{i.id}"
          i.destroy
        end # Invitation (user giving to fake friend)
      
        Resque.logger.info "User ID #{ff.id} has been unfriended from User ID #{u.id}"
        num_unfriended = num_unfriended + 1
      end # User (fake friends)
    end # User (real)

    if num_unfriended > 0      
      message = "A total of #{num_unfriended} fake friendships were ruined"
    else
      message = "Job::RemoveFakeFriends did not find anybody that it was able to unfriend"
    end

    Resque.logger.info message
    Ripple::ActivityLogger.new(channel: '#activity', text: message, 
      username: 'UnfriendBot ' + Rails.env, icon_emoji: ':no_good:').log!

    message
  end
end