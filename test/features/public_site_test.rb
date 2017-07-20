require 'test_helper'

class PublicSiteTest < Capybara::Rails::TestCase
  describe 'viewing the public site' do

    # before
    #   super
    # end

    it 'renders' do
      visit root_path
      assert page.has_content? 'Ripple improves employee self-awareness by 
        enabling anonymous, authentic and timely feedback from co-workers'
    end

    it 'take you to login' do
      visit dashboard_path
      assert page.has_content? 'You need to sign in or sign up before continuing.'
    end

    it 'swallows bad favicon requests' do
      paths = %w(favicon favicon.ico apple-touch-icon-precomposed apple-touch-icon-precomposed.png
        apple-touch-icon apple-touch-icon.png)
      paths.each do |p|
        visit '/' + p
        assert_equal 404, page.status_code, "Should have gotten 404 for /#{p}"
      end
      refute SystemEvent.any?
    end
  end

  describe 'clicking the CTA' do
    it 'takes me to the register page' do
      TestHelper.test_javascript
      visit root_path
      find('#cta').click
      assert page.has_content? 'Sign Up for Ripple'
    end
  end
end
