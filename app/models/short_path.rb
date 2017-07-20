class ShortPath < ActiveRecord::Base

  belongs_to :user

  validates :path, presence: true
  validates :user, presence: true

  before_validation :set_path

  def self.active
    where('created_at >= ?', Time.now - Ripple::Globals::MAX_DAYS_TO_RESPOND.days) \
      .order(created_at: :desc).first
  end

  def active?
    Time.now >= active_from && Time.now <= active_until
  end

  def active_from
    created_at
  end

  def active_until
    created_at + Ripple::Globals::MAX_DAYS_TO_RESPOND.days
  end

  def active_for_in_days # test helper
    ((active_until - active_from)/(60 * 60 * 24)).round
  end

  protected

  def set_path
    self.path = SecureRandom.string(6)
  end
end
