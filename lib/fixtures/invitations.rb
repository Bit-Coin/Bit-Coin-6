class Fixtures::Invitations

  # TODO deprecated, remove
  
  def self.seed(entity, options={}) # entity could be Company or Team

    members = entity.all_members.to_a
    while members.size > 1
      current_member = members.shift

      members.each do |other_member|
        Invitation.create!(receiver: current_member, 
          giver: other_member, 
          state: 'active', 
          hold_until: Time.now, 
          reminded_at: Time.now)
        Invitation.create!(giver: current_member, 
          receiver: other_member, 
          state: 'active', 
          hold_until: Time.now, 
          reminded_at: Time.now)
      end
    end

    entity_ids = entity.class == Team ? [entity.id] : []
    Resque.enqueue(Job::CreateSurveys, entity_ids, { :clobber => true }) 
  end

  def self.seed_maven(maven, options={})
    maven.everyone_else_team.each do |e|
      maven.invitations.create!({ state: 'active', giver: e, 
        hold_until: Time.now, reminded_at: Time.now })
      end
    
    Resque.enqueue(Job::CreateSurveys, [maven.team.id], { :clobber => true }) 
  end

  def self.staleify(invitation)
    invitation.update_attributes(state: 'notified', created_at: 4.days.ago.to_time)
    invitation.surveys.last.update_attributes(state: 'open')
  end

  def self.reset!
    Invitation.update_all(hold_until: Time.now)
  end
end