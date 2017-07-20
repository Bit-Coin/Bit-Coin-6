require 'test_helper'

class Admin::CompetencyModelTest < Capybara::Rails::TestCase
  before do
    TestHelper.test_javascript
    TestHelper.seed_admin
    login_as Admin.first, scope: :admin
  end

  describe '#index' do
    it 'lists the default models' do
      visit admin_characteristics_path
      assert_content "Ripple Effect"
    end
  end

  describe '#new/#create' do
    before do
      visit admin_characteristics_path
      find_link('New').click
    end

    it 'renders question & component Add buttons disabled' do
      page.all('a', text: 'Add').each do |link|
        assert_equal 'disabled', link[:disabled]
      end
    end

    it 'saves a new complete record' do
      fill_in 'Competency model name', with: 'Messiah'
      fill_in 'Score name', with: 'Messiah Score'
      fill_in 'Survey name', with: 'Messiah Survey'
      fill_in 'Icon', with: 'fa-users'
      find_button('Save').click
      assert_content 'Messiah'
    end

    it 'returns validation errors' do
      find_button('Save').click
      assert_content 'Error'
    end

    it 'cancels' do
      find_button('Cancel').click
      assert_content 'Operation canceled'
    end
  end

  describe '#edit/#update' do
    before do
      visit admin_characteristics_path
      find('a[href="/admin/characteristics/1/edit"]').click
    end

    it 'allows valid update' do
      fill_in 'Competency model name', with: 'Messiah'
      fill_in 'Score name', with: 'Messiah Score'
      fill_in 'Survey name', with: 'Messiah Survey'
      fill_in 'Icon', with: 'fa-users'
      find_button('Save').click
      assert_content 'Messiah'      
    end

    it 'does not allow invalid update' do
      fill_in 'Competency model name', with: ''
      find_button('Save').click
      assert_content 'Error'
    end

    it 'respects the cancel button' do
      find_button('Cancel').click
      assert_content 'Operation canceled'
    end
  end

  describe '#destroy' do
    before do
      visit admin_characteristics_path
    end

    it 'does not allow deletion of competency models' do
      find('a[href="/admin/characteristics/1"]').click
      assert_content 'Not yet implemented.  Contact dev.'
    end

    it 'does not allow deletion of component with questions' do
      find('a[href="/admin/characteristics/1/edit"]').click
      find('a[href="/admin/characteristics/2"]').click
      assert_content 'Cannot delete characteristic with questions'
    end

    it 'allows deletion of component without questions' do
      find('a[href="/admin/characteristics/1/edit"]').click
      Question.where('characteristic_id = 2').destroy_all
      find('a[href="/admin/characteristics/2"]').click
      assert_content 'Component was deleted'
    end
  end
end
