require 'test_helper'

class CompanySurveySeriesTest < ActiveSupport::TestCase
  before do
    AcmeHelper.generate_acme_company
  end

  it 'finds self/others' do
    assert_equal 1, Company.first.company_survey_series.for_self.active.count
    assert_equal 1, Company.first.company_survey_series.for_others.active.count
  end

  it 'returns proper records for ripple50 scopes' do
    assert_equal CompanySurveySeries.for_others.first, 
      AcmeHelper.acme_company.company_survey_series.ripple50_others
    assert_equal CompanySurveySeries.for_self.first, 
      AcmeHelper.acme_company.company_survey_series.ripple50_self
  end

  let(:fannie) do
    require_relative '../fixtures/fannie_helper.rb'
    FannieHelper.fannie_company
  end

  it 'returns nil for non-RES companies' do
    load 'db/script/one_time/set_up_fannie_mae.rb'
    refute fannie.company_survey_series.ripple50_self, "Should return nil"
    ss = SurveySeries.find_by_name('EAL/20-up')
    assert_equal ss.id, fannie.company_survey_series.for_others.first.survey_series_id
    assert_equal ss.id, fannie.company_survey_series.for_self.first.survey_series_id
  end
end
