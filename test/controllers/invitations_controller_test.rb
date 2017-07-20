require 'test_helper'

class InvitationsControllerTest < ActionController::TestCase
  tests InvitationsController

  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(2)
    AcmeHelper.generate_acme_plans    
  end

  subject { SurveyPlan.for_others.active.first }

  describe '#update' do
    before do
      sign_in subject.receiver
    end

    it 'updates relationship_type' do
      put :update, id: subject.id, survey_plan: { relationship_type: 'Mortal Enemy' }
      assert_equal 'Mortal Enemy', subject.reload.relationship_type
    end
  end
end
