class Job::SeedInvitations
  extend Resque::Plugins::Heroku
  @queue = :invitations

  def self.perform(options={})

    entity_id = options['entity_id']
    entity_class = options['entity_class']
    maven_id = options['maven_id']
    fully_connected = options['fully_connected']

    # team here could be either Team or Company
    team = options['entity_class'].constantize.find(entity_id)
    maven = User.find(maven_id)

    if fully_connected
      Fixtures::Invitations.seed(team, {})
    else
      Fixtures::Invitations.seed_maven(maven, {})
    end

    message = "Seeded invitations for Team ID #{team_id} from User ID #{maven_id}"
    message = message + " (fully connected)" if fully_connected

    Resque.logger.info message
    Ripple::ActivityLogger.new(channel: '#activity', text: message, icon_emoji: ':link:').log!  

    message
  end
end
