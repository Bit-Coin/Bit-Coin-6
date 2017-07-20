require 'test_helper'

class Api::V1::ResponsesControllerTest < ActionController::TestCase
  tests Api::V1::ResponsesController

  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(2)
    AcmeHelper.generate_acme_plans_and_surveys
  end

  test 'can post when signed in' do
    survey = Survey.open.first
    sign_in survey.giver
    id = survey.responses.first.id
    post :survey_response, id: id, response: { score: 3 }
    assert_response :ok
  end

  test 'can post with token' do
    survey = Survey.open.first
    post :survey_response, id: survey.responses.first.id, response: { score: 4 },
         user_email: survey.giver.email, user_token: survey.giver.authentication_token
    assert_response :ok
  end

  test 'cannot post with bad token' do
    survey = Survey.open.first
    post :survey_response, id: survey.responses.first.id, response: { score: 4 },
         user_email: survey.giver.email, user_token: ''
    assert_response 302
  end

  test 'cannot post to another company' do
    survey = Survey.open.first 
    sign_in User.where('id <> ?', survey.giver.id).first
    id = survey.responses.first.id
    post :survey_response, id: id, response: { score: 3 }
    assert_response 404
  end

  test 'cannot update when survey is closed' do
    survey = Survey.open.first
    survey.update_attributes(state: 'scored')
    sign_in survey.giver
    id = survey.responses.first.id
    post :survey_response, id: id, response: { score: 3 }
    assert_response 500
    assert_equal 'response_validation_error', survey.giver.events.last.name
  end
end
