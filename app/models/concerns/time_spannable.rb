module TimeSpannable
  extend ActiveSupport::Concern

  def included
    validates_presence_of :start_at
    validates_presence_of :end_at
    validate :start_at_before_end_at
  end
  
  def expired_time?
    end_at < DateTime.now
  end
  
  def active_time?
    start_at < DateTime.now && end_at > DateTime.now
  end
  
  def start_at_before_end_at
    if start_at > end_at
      errors.add(:start_at, 'must be before end_at')
      errors.add(:end_at, 'must be after start_at')
    end
  end
end
