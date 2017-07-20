require 'test_helper'

class SurveyFrequencyTest < ActiveSupport::TestCase
  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(2)
    AcmeHelper.generate_acme_plans
    AcmeHelper.generate_acme_surveys
  end

  subject { User.first }

  it 'works at default (weekly) speed' do
    assert subject.surveys.for_others.open.any?
    AcmeHelper.complete_all_surveys!(subject)
    refute subject.surveys.for_others.open.any?

    # Right away
    Job::CreateSurveys.perform
    refute subject.surveys.for_others.open.any?

    # One hour later
    Timecop.freeze(Time.now + 1.hour)
    Job::CreateSurveys.perform
    refute subject.surveys.for_others.open.any?

    # One day later
    Timecop.freeze(Time.now + 1.day)
    Job::CreateSurveys.perform
    refute subject.surveys.for_others.open.any? 

    # Next week
    Timecop.freeze(Time.now + 1.week)
    assert SurveyPlan.due.any?, "Expected due plan"
    Job::CreateSurveys.perform
    assert subject.surveys.for_others.any?, "Expecting some surveys"
  end

  it 'works at accelerated (daily) speed' do
    subject.company.company_survey_series.for_others.first.set_config({hours_between_surveys: 24})
    assert subject.surveys.for_others.open.any?
    AcmeHelper.complete_all_surveys!(subject)
    refute subject.surveys.for_others.open.any?
    subject.survey_plans.each { |sp| sp.update_attributes(next_due: sp.send('set_next_due')) }

    # Right away
    Job::CreateSurveys.perform
    refute subject.surveys.for_others.open.any?

    # One hour later
    Timecop.freeze(Time.now + 1.hour)
    Job::CreateSurveys.perform
    refute subject.surveys.for_others.open.any?    

    # One day later
    Timecop.freeze(Time.now + 1.day)
    assert SurveyPlan.due.any?, "Expected due plan"
    Job::CreateSurveys.perform
    assert subject.surveys.for_others.any?, "Expecting some surveys"
  end

  it 'works at hyperspeed (2 hours)' do
    subject.company.company_survey_series.for_others.first.set_config({hours_between_surveys: 2})
    assert subject.surveys.for_others.open.any?
    AcmeHelper.complete_all_surveys!(subject)
    refute subject.surveys.for_others.open.any?
    subject.survey_plans.each { |sp| sp.update_attributes(next_due: sp.send('set_next_due')) }

    # Right away
    Job::CreateSurveys.perform
    refute subject.surveys.for_others.open.any?

    # One hour later
    Timecop.freeze(Time.now + 1.hour)
    Job::CreateSurveys.perform
    refute subject.surveys.for_others.open.any?    

    # Two hours later
    Timecop.freeze(Time.now + 2.hours)
    assert SurveyPlan.due.any?, "Expected due plan"
    Job::CreateSurveys.perform
    assert subject.surveys.for_others.any?, "Expecting some surveys"
  end
end
