module Scopes::Colleagues
  
  def team_colleagues_including_self
    User.where('team_id = ?', self.team_id)
  end

  def everyone_else_company
    company.all_members.where('users.id <> ?', self.id)
  end

  def everyone_else_team
    team.all_members.where('users.id <> ?', self.id)
  end

  def not_yet_invited_team
    ids = invitations.pluck(:giver_id)
    if ids.any?
      everyone_else_team.invitable.where('id not in (?)', ids)
    else
      everyone_else_team.invitable
    end
  end

  def not_yet_invited_company
    ids = invitations.pluck(:giver_id)
    if ids.any?
      everyone_else_company.invitable.where('id not in (?)', ids)
    else
      everyone_else_company.invitable
    end
  end

  def random_colleague_team
    everyone_else_team.sample
  end

  def random_colleague_company
    everyone_else_company.sample
  end

  def invite_everyone_team!
    not_yet_invited_team.each do |e|
      invitations.create!(giver: e, state: 'pending', reminded_at: Time.now - 1.second)
    end
  end

  def invite_everyone_company!
    not_yet_invited_company.each do |e|
      invitations.create!(giver: e, state: 'pending', reminded_at: Time.now - 1.second)
    end
  end
end