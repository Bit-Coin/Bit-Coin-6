require 'test_helper'

class SurveysControllerTest < ActionController::TestCase
  describe SurveysController do

    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_users(2)
      AcmeHelper.generate_acme_plans_and_surveys
      payload = {"user_email"=>"demo+manager@ripplecrew.com",
                 "user_token"=>"FvxsxiCksXsvmx1sS8JZ",
                 "comments"=>{
                    "0"=>{
                      "response_id"=>"0", 
                      "comment_text"=>"lorem ipsum dolor"
                    },
                    "1"=>{
                      "response_id"=>"4522",
                      "comment_text"=>"a squid eating dough in a polyethelene bag..."
                    }
                  },
                 "action"=>"complete",
                 "controller"=>"api/v1/surveys",
                 "id"=>"705"}
    end

    describe 'finish' do
      before do
        @subject = Survey.open.first
        @subject.responses.update_all(score: 4)
        response_id = @subject.responses.last.id
        @raw_comments = "[{\"response_id\":\"0\",\"comment_text\":\"angie\"},
          {\"response_id\":\"#{response_id}\",\"comment_text\":\"paint it black\"}]"
        sign_in @subject.giver
      end

      it 'completes without comments' do
        put :complete, id: @subject.id, user_email: @subject.giver.email, 
              user_token: @subject.giver.authentication_token
        assert_equal 'complete', @subject.reload.state
      end

      it 'completes with comments' do
        put :complete, id: @subject.id, user_email: @subject.giver.email, 
              user_token: @subject.giver.authentication_token, 
              hidden_comments_input: @raw_comments
        assert_equal 2, Comment.count
        assert_equal 'angie', Comment.first.text
        assert_equal 'paint it black', Comment.last.text
        assert_equal @subject.receiver, Comment.last.receiver
        assert_equal @subject.receiver, Comment.first.receiver
        assert_equal @subject.responses.last, Comment.last.response
        assert_equal @subject, Comment.first.survey
        assert_equal @subject.responses.last.question, Comment.last.question
        assert_equal 'complete', @subject.reload.state
      end
    end

    describe 'get/next' do
      test 'get index redirects' do
        get :index
        assert_redirected_to new_user_session_path
      end

      test 'get edit if authenticated' do
        survey = Survey.open.first
        sign_in survey.giver
        get :edit, id: survey.id
        assert_response :ok
      end

      test 'get edit with token' do
        survey = Survey.open.first
        get :edit, id: survey.id, user_email: survey.giver.email, user_token: survey.giver.authentication_token
        assert_response :ok
        assert survey.giver.sign_in_count == 0
      end

      test 'next_survey with open surveys' do
        survey = Survey.open.first
        get :next_survey, user_email: survey.giver.email, user_token: survey.giver.authentication_token
        assert_redirected_to edit_survey_path(id: survey.giver.surveys.open.newest.id, 
          user_email: survey.giver.email, 
          user_token: survey.giver.authentication_token)
      end

      test 'next_survey without open surveys' do     
        user = Survey.open.first.giver
        user.surveys.destroy_all
        response = get :next_survey, user_email: user.email, user_token: user.authentication_token
        assert_match 'Thank you!', response.body
      end
    end

    describe 'decline' do
      it 'returns 200' do
        survey = Survey.open.first
        sign_in survey.giver
        response = put :decline, id: survey.id
        assert_match 'You will no longer receive surveys for', response.body
        assert_equal 'declined', survey.survey_plan.state
      end
    end
  end
end
