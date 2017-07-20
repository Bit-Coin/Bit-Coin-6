class Team < ActiveRecord::Base

  self.inheritance_column = :_type_disabled # so we can have a column named 'type'

  belongs_to :company
  # belongs_to :manager, class_name: 'User'
  # has_many :members, class_name: 'User'
  has_many :scores
  has_many :team_members
  has_many :members, :through => :team_members
  # has_many :members, class_name: 'User', foreign_key: 'team_id'

  has_many :managers, -> { where(team_members: { is_manager: true}) }, :through => :team_members



  include Configurable
  inherit_settings_from 'company'

  # legacy
  def self.unique_company_ids
    pluck(:company_id)
  end

  # legacy
  def all_members
    members
  end
  alias_method :employees, :all_members

  def invitations
    Invitation.where('receiver_id in (?)', all_members.pluck(:id))
  end

  def subscription
    company.subscription
  end

  def surveys
    Survey.where('receiver_id in (?) or giver_id in (?)',
      all_members.pluck(:id), all_members.pluck(:id))
  end

end
