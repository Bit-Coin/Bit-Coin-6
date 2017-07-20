class UserRole < ActiveRecord::Base
  belongs_to :role
  belongs_to :user
  belongs_to :surveyable, polymorphic: true
  has_many :survey_plans
  rails_admin do
    list do
      field :id
      field :created_at
      field :updated_at
      field :surveyable_id
      field :surveyable_type
    end
  end

  validates_presence_of :user, :surveyable, :role
  validate :company_consistency

  def invite!(giver, options={})
    state = options[:state] || 'created'
    css = options[:company_survey_series] || guess_company_survey_series(giver)
    survey = survey_plans.build({company_survey_series: css, giver: giver, state: state})
    survey.save if survey.valid? && !giver.feedback_type.try(:include?, 'giver')
  end

  def guess_company_survey_series(giver)
    if user == giver
      css = user.company.company_survey_series.ripple50_self
    else
      css = user.company.company_survey_series.ripple50_others
    end
    raise "Cannot guess company survey series.  Must pass record to #invite!" \
      if css.blank?
    css
  end

  private

  def company_consistency
    if surveyable_type == 'Company' && (surveyable_id != user.company_id)
      errors.add :surveyable_id, "does not match user.company_id"
    end
  end
end
