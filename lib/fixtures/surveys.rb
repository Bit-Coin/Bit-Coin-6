class Fixtures::Surveys

  def self.seed(team, options={})
    team.invitations.update_all(hold_until: Time.now - 1.second) \
      if options[:force]
    Job::CreateSurveys.perform [team.id], options
    team.surveys.pending.update_all(state: 'open')
  end

  def self.create_self_surveys(team)
    team.all_members.rippler.each do |r|
      r.create_self_surveys
    end
  end
end
