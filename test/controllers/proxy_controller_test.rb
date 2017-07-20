require 'test_helper'

class ProxyControllerTest < ActionController::TestCase
  describe ProxyController do
    before do
      TestHelper.seed_admin
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_users(1)
    end
    
    describe 'POST become_proxy' do
      before do
        @request.env["devise.mapping"] = Devise.mappings[:admin]
        @admin = Admin.first
        @user = User.first
      end
    
      describe 'by an admin' do
        before do
          sign_in(:admin, @admin)
          post :become_proxy, :user_id => @user.id
        end
      
        it 'signs out the current admin' do
          assert @controller.current_admin.nil?, 'admin is not signed out'
        end
      
        it 'signs in the user' do
          assert (@controller.current_user == @user), 'user is not signed in'
        end

        it 'does not increment sign_in_count' do
          assert_equal 0, @user.sign_in_count
        end
      
        it 'sets the proxy and proxy_secret on the user' do
          assert (@controller.current_user.proxy == @admin ), 'user proxy is not set to admin'
        end
      
        it 'sets the proxy_secret on the user' do
          assert (@controller.current_user.proxy_secret.length > 0), 'user proxy_secret is not set'
        end
        
        it 'sets the proxy_secret on the user session' do
          assert (session[:proxy_secret] == @controller.current_user.proxy_secret), 'session proxy_secret is not set'
        end
      end
    
      after do
        @user.discard_proxy!
      end
    end
  
    describe 'POST become_admin' do
      before do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        @admin = Admin.first
        @user = User.first
      end
    
      describe 'by an admin signed in as a proxy' do
        before do
          @user.set_proxy!(@admin)
          sign_in(:user, @user)
          session[:proxy_secret] = @user.proxy_secret
          post :become_admin, {}
        end
      
        it 'signs out the current user' do
          assert @controller.current_user.nil?, 'user is not signed out'
        end
      
        it 'signs in the admin' do
          assert (@controller.current_admin == @admin), 'admin is not signed in'
        end
      
        it 'clears the proxy_id and proxy_secret on the user' do
          @user.reload
          assert @user.proxy.nil?, 'user proxy is not cleared'
          assert @user.proxy_secret.nil?, 'user proxy_secret is not cleared'
        end
        
        it 'redirects to the admin home' do
          assert_redirected_to admin_path
        end
      end
    
      describe 'by a regular signed in user' do
        before do
          sign_in(:user, @user)
          post :become_admin
        end
      
        it 'does not sign in and redirects to the log in page' do
          assert @controller.current_admin.nil?, 'admin is signed in'
          assert @controller.current_user.nil?, 'user is signed in'
          assert_redirected_to new_admin_session_path
        end
      end
    
      after do
        @user.discard_proxy!
      end
    end
  end
end