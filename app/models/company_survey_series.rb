class CompanySurveySeries < ActiveRecord::Base
  belongs_to :company 
  belongs_to :survey_series
  has_many :survey_plans

  validate :uniqueness
  validates_presence_of :company_id, :survey_series_id, :config

  scope :active, -> { where('state = ?', 'active') }

  class << self
    def for_self
      where('config @> ?', {for_self: true}.to_json)
    end

    def for_others
      where('config @> ?', {for_self: false}.to_json)
    end

    # legacy support
    def ripple50_others
      where('survey_series_id = ?', 1).first
    end

    def ripple50_self
      where('survey_series_id = ?', 2).first
    end
  end # class << self

  def set_config(new_config)
    config.merge!(new_config)
    save!
  end

  def for_others?
    !config['for_self']
  end

  def for_self?
    config['for_self']
  end

  def surveys
    # TODO expensive
    ssids = survey_series.survey_sets.pluck(:id)
    company.feedback.where('survey_set_id in (?)', ssids)
  end

  def options_for_select
    SurveySeries.all.map { |ss| ["#{ss.name}: #{ss.description}", ss.id] }
  end

  private

  def uniqueness
    suspects = self.class.where(company: company, survey_series: survey_series, 
      state: state)
    if suspects.any?
      # can't figure out how to compare jsonb columns directly
      suspects.each do |s|
        if s.config == self.config
          errors.add :survey_series_id, "is not unique for this company" and return
        end
      end
    end
  end

end
