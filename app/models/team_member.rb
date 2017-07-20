class TeamMember < ActiveRecord::Base
  belongs_to :team
  belongs_to :manage_team, class_name: 'Team', foreign_key: 'team_id'
  belongs_to :member, class_name: 'User', foreign_key: 'user_id'
  belongs_to :manager, class_name: 'User', foreign_key: 'user_id'
end
