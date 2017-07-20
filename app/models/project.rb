class Project < ActiveRecord::Base
  belongs_to :company

  include Surveyable

  validates_presence_of :company, :owner, :name
  validate :dates

  private

  def dates
    if start_date && end_date && (start_date > end_date)
      errors.add :start_date, "cannot be after end date"
    end
  end
end
