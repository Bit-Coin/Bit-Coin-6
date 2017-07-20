require 'test_helper'

class RippleOnboardUserTest < ActiveSupport::TestCase
  describe Ripple::OnboardUser do
    describe '.create_prospect' do
      subject { Ripple::OnboardUser }
      
      let(:attrs) {
        { :fn => 'Joe', :ln => 'Duck', :e => 'jd@example.com', :pcn => 'Ducks Inc' }
      }
      
      it 'creates a new invited prospect' do
        user = subject.create_prospect(attrs[:fn], attrs[:ln], attrs[:e], attrs[:pcn], {:confirm => true})
        assert_equal user.first_name, attrs[:fn]
        assert_equal user.last_name, attrs[:ln]
        assert_equal user.email, attrs[:e]
        assert_equal user.type, User::PROSPECT
        assert_equal user.state, User::ACTIVE
        assert user.confirmed?
      end
    end
    
    describe '.create_ripplers_from_csv' do
      describe 'with a company' do
        let(:owner) {
          Ripple::OnboardUser.create_prospect('Joe', 'Duck', 'jd@example.com', 'Ducks Inc')
        }
        let(:company) {
          c = Ripple::OnboardUser.new(owner).create_company('Ducks Inc', 'example.com', 'ducks')
          c.use_series(1)
          c.use_series(2)
          c
        }
        let(:team) {
          Team.create({
            :name => 'Guys', :manager => owner, :company => company
          })
        }
        subject { Ripple::OnboardUser }
        
        describe 'with valid csv rows' do
          let(:csv) {
            %Q{first_name, last_name, email
            Firstname1,Lastname1,e1@example.com
            Firstname2,Lastname2,e2@example.com
            Firstname3,Lastname3,e3@example.com              
            }
          } # watch the whitespace
          
          before do
            @result = subject.create_ripplers_from_csv(company, team, csv)
          end
          
          it 'creates ripplers' do
            assert_equal @result[:users].length, 3
            @result[:users].each do |u|
              assert u.first_name.present?
              assert u.last_name.present?
              assert u.company.present?
              assert u.team.present?
            end
            assert_equal @result[:invalid_rows].length, 0
          end
        end
        
        describe 'with invalid csv rows' do
          let(:csv) {
            %Q{first_name, last_name, email
            ,,
            xxx,yyy,
            xxx,Lastname3,not_an_email
            }            
          } # watch the whitespace
          
          before do
            @result = subject.create_ripplers_from_csv(company, team, csv)
          end
          
          it 'returns the invalid rows and does not create ripplers' do
            assert_equal @result[:users].length, 0
            assert_equal @result[:invalid_rows].length, 3
            refute ActionMailer::Base.deliveries.any?, "Should not send mail"
          end
        end
        
        describe 'with connect_maven option' do
          let(:csv) {
            %Q{first_name, last_name, email
            Firstname1,Lastname1,e1@example.com
            Firstname2,Lastname2,e2@example.com
            Firstname3,Lastname3,e3@example.com              
            }
          } # watch the whitespace
          
          before do
            @result = subject.create_ripplers_from_csv(company, nil, csv, {:connect_maven => true})
          end
          
          it 'creates invitations between all new users to the maven' do
            assert_equal @result[:survey_plans].length, 9
          end
        end
        
        describe 'with connect_all option' do
          let(:csv) {
            %Q{first_name, last_name, email
            Firstname1,Lastname1,e1@example.com
            Firstname2,Lastname2,e2@example.com
            Firstname3,Lastname3,e3@example.com              
            }
          } # watch the whitespace
          
          before do
            @result = subject.create_ripplers_from_csv(company, nil, csv, {:connect_all => true})
          end
          
          it 'creates invitations from all new users to each other and existing users' do
            assert_equal 15, @result[:survey_plans].length # C(4, 2) x 2
          end
        end
        
      end
    end
    
    describe '#create_company' do
      let(:owner) {
        Ripple::OnboardUser.create_prospect('Joe', 'Duck', 'jd@example.com', 'Ducks Inc')
      }
      
      subject {
        Ripple::OnboardUser.new(owner)
      }
      
      before do
        @company = subject.create_company('Ducks Inc', 'example.com', 'ducks')
      end
      
      it 'creates a company record' do
        assert @company.is_a?(Company)
        assert_equal @company.name, 'Ducks Inc'
        assert_equal @company.domain, 'example.com'
      end
      
      it 'creates a subscription' do
        @subscription = @company.subscriptions.active
        assert @subscription.is_a?(Subscription)
        assert_equal @subscription.owner, owner
      end

      it 'does not assign survey series by default' do
        refute @company.company_survey_series.any?, "Should not be any company survey series"
      end
      
      it 'makes the user a rippler and assigns as manager' do
        assert_equal owner.type, User::RIPPLER
        assert_equal owner.state, User::ACTIVE
        assert_equal owner.company, @company
        assert_equal @company.manager, owner
      end
    end
    
    describe '#create_team' do
      let(:ceo) {
        Ripple::OnboardUser.create_prospect('Joe', 'CEO', 'ceo@example.com', 'Ducks Inc')
      }
      let(:manager) {
        Ripple::OnboardUser.create_prospect('Joe', 'Manager', 'jm@example.com', 'Ducks Inc')
      }
      
      subject {
        Ripple::OnboardUser.new(owner)
      }
      
      before do
        @company = Ripple::OnboardUser.new(ceo).create_company('Ducks Inc', 'example.com', 'ducks')
        @team = Ripple::OnboardUser.new(manager).create_team(@company, 'Cool Kids')
      end
      
      it 'creates a new team inside the company' do
        assert @team.is_a?(Team)
        assert_equal @team.name, 'Cool Kids'
        assert_equal @team.company, @company
      end
      
      it 'makes the user a rippler and assigns as manager of the team' do
        assert_equal manager.company, @company
        assert_equal manager.team, @team
        assert_equal manager.type, User::RIPPLER
        assert_equal manager.state, User::ACTIVE
        assert_equal @team.manager, manager
      end
    end
    
    describe '#test_drive' do
      before do
        AcmeHelper.generate_acme_company
        AcmeHelper.generate_acme_users(2)  
        AcmeHelper.generate_acme_subscription
      end
      
      describe 'with a test drive company and users' do
        let(:company) { AcmeHelper.acme_company }
        let(:friends) { AcmeHelper.acme_company.users.where("email != 'jd@example.com'") }
        let(:prospect) { Ripple::OnboardUser.create_prospect('Joe', 'Duck', 'jd@example.com', 'Ducks Inc') }
        
        subject { Ripple::OnboardUser.new(prospect) }
        
        before do
          subject.test_drive(company, friends)
        end
        
        it 'makes the prospect a rippler and adds to the company' do
          assert_equal prospect.company, company
          assert_equal company.subscriptions.active.subscription_users.last.user, prospect
        end
        
        it 'creates plans for the test drive friends' do
          friends.each do |friend|
            assert friend.survey_plans.where(:giver => prospect).exists?
            assert prospect.survey_plans.where(:giver => friend).exists?
          end
        end
        
        it 'creates surveys and responses for the test drive friends' do
          friends.each do |friend|
            assert friend.survey_plans.where(:giver => prospect).first.surveys.any?
            assert friend.survey_plans.where(:giver => prospect).first.surveys.first.responses.any?
            assert prospect.survey_plans.where(:giver => friend).first.surveys.any?
          end
        end
      end
    end
    
  end
end