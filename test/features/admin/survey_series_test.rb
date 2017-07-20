require 'test_helper'

class Admin::SurveySeriesTest < Capybara::Rails::TestCase
  before do
    TestHelper.test_javascript
    TestHelper.seed_admin
    login_as Admin.first, scope: :admin
  end

  describe '#index' do
    it 'displays the list' do
      visit '/admin/survey_series'
      assert_content 'Ripple 50/5-up'
    end
  end

  describe '#new/#create' do
    before do
      visit '/admin/survey_series/new'
    end

    it 'creates with valid input' do
      page.select 'Ripple Effect', from: 'Competency Model'
      fill_in 'Survey Series Name', with: 'If my words did glow...'
      fill_in 'Description', with: '...with the gold of sunshine'
      fill_in 'Default config', with: '{"for_self"=>false, "allow_comments"=>true, "hours_between_surveys"=>2160}'
      find_button('Save').click
      assert_content 'Created'
    end

    it 'errors with invalid input' do
      find_button('Save').click
      assert_content 'Error'
    end

    it 'respects the cancel button' do
      find_button('Cancel').click
      assert_content 'Operation canceled'
    end
  end

  describe '#edit/#update' do
    before do
      visit '/admin/survey_series'
      find("a[href='/admin/survey_series/1/edit']").click
    end

    it 'updates with valid input' do
      fill_in 'Survey Series Name', with: 'If my words did glow...' 
      find_button('Save').click
      assert_content 'Updated'
      assert_content 'If my words did glow...'
    end

    it 'errors with invalid input' do
      fill_in 'Survey Series Name', with: ''
      find_button('Save').click
      assert_content 'Error'
    end
  end

  describe '#destroy' do
    before do
      visit '/admin/survey_series'
    end

    it 'does not destroy when there are company survey series' do
      c = AcmeHelper.generate_acme_company
      c.use_series(1)
      find("a[href='/admin/survey_series/1']").click
      assert_content "This Survey Series is in use.  Delete all Company Survey Series first."
    end

    it 'destroys survey series not in use' do
      CompanySurveySeries.destroy_all
      find("a[href='/admin/survey_series/1']").click
      assert_content 'Deleted'
    end
  end

  describe 'survey sets' do
    before do
      visit '/admin/survey_series'
      find("a[href='/admin/survey_series/1/edit']").click
    end

    describe 'create survey set' do
      before do
        find("a[href='/admin/survey_sets/new?ss=1']").click
      end

      it 'creates with valid input' do
        fill_in 'Survey Set Name', with: 'Ripple Group Z'
        find_button('Save').click
        assert_content 'Created'
      end

      it 'errors with duplicate position' do
        fill_in 'Survey Set Name', with: 'Ripple Group Q'
        fill_in 'Position', with: '1'
        find_button('Save').click
        assert_content 'is not unique for this survey series'        
      end

      it 'errors with nil name' do
        find_button('Save').click
        assert_content 'Error'        
      end

      it 'respects the cancel button' do
        find_button('Cancel').click
        assert_content 'Operation canceled'
      end
    end

    describe 'edit survey set' do
      before do
        find("a[href='/admin/survey_sets/1/edit']").click
      end

      it 'updates with valid input' do
        fill_in 'Survey Set Name', with: 'Blarzophone'
        find_button('Save').click
        assert_content 'Blarzophone'
      end

      it 'errors with invalid input' do
        fill_in 'Position', with: '2'
        find_button('Save').click
        assert_content 'is not unique for this survey series'
      end

      it 'respects the cancel button' do
        find_button('Cancel').click
        assert_content 'Operation canceled'
      end

      describe 'survey set question maintenance' do
        it 'adds questions' do
          find_link('Add').click
          page.select 'I trust #{receiver.first_name}', from: 'Question'
          find_button('Link').click
          assert_content 'Question added to survey set'
        end

        it 'removes questions' do
          ssq = SurveySetQuestion.find(1)
          ssq.question.responses.destroy_all
          find("a[href='/admin/survey_set_questions/#{ssq.id}']").click
          assert_content 'Question removed from survey set'
        end

        it 'does not allow questions with responses to be removed' do
          AcmeHelper.generate_acme_company
          AcmeHelper.generate_acme_users(1)
          AcmeHelper.generate_acme_plans
          AcmeHelper.generate_acme_surveys
          ssq = SurveySetQuestion.find(3) # next question in this set
          find("a[href='/admin/survey_set_questions/#{ssq.id}']").click
          assert_content 'Cannot remove question because surveys exist'
        end
      end
    end

    describe 'destroy survey set' do
      before do
        find("a[href='/admin/survey_sets/1']").click
      end

      it 'soft deletes' do
        assert_content 'Deleted'
        assert_equal 'deleted', SurveySet.find(1).state
        refute_content SurveySet.find(1).name
      end
    end
  end
end
