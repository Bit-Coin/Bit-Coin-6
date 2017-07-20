class Job::ConvertTestDriverToMaven
  extend Resque::Plugins::Heroku
  @queue = :users

  # Pass in the user ID of a maven; the job finds all other users who have
  # been invited by that maven and all other users who have been invited
  # by those users (and so forth, all the way down) to build a complete list
  # of user IDs that need to be migrated to the new company. It then 
  # creates a new company, assigns the maven as the manager, and migrates
  # every other user who was found by the ID search to the new company.

  def self.find_friends(friends=[])
    friends.each do |f|
      friends = friends + User.find(f).crew.invitable.pluck(:id)
    end

    friends.uniq
  end

  def self.perform(options={})

    maven_id = options[:maven] || []

    maven = User.where('id = ?', maven_id).first

    # Step 0: Remove "fake friends" from the maven

    Resque.enqueue(Job::RemoveFakeFriends, { :users => [maven.id] })    

    # Step 1: Find the complete list of users that we need to migrate

    friends = self.find_friends(maven.crew_ids)

    done = false
    until done do 
      friends_of_friends = self.find_friends(friends)
      delta = friends_of_friends - friends
      if delta == []
        done = true
      else
        friends = friends + friends_of_friends
        friends = friends.uniq
      end
    end

    message = "Found the following list of users to migrate: #{friends}"

    Resque.logger.info message
    Ripple::ActivityLogger.new(channel: '#activity', text: message, 
      username: 'Maven Conversion ' + Rails.env, icon_emoji: ':family:').log!

    message
  end
end