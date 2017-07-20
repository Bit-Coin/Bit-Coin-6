require 'test_helper'

class RippleCompanyConnectorTest < ActiveSupport::TestCase
  describe Ripple::CompanyConnector do
    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_users(4)      
    end
    
    let(:company) { AcmeHelper.acme_company }
    
    subject { Ripple::CompanyConnector.new(company) }
    let(:left_users) { company.users.slice(0, 2) }
    let(:right_users) { company.users.slice(2, 2) }

    describe '#join_groups' do   
      it 'creates reciprocal survey plans between two two-user groups' do
        result = subject.join_groups(left_users, right_users)
        assert_equal 8, result.length
      end
    end

    describe '#join_all' do
      it 'does not join deleted users' do
        company.users.last.delete!
        assert_equal 6, subject.join_all.length
      end
    end
    
    describe '#join_users' do
      let(:left_user) { company.users[1] }
      let(:right_user) { company.users[2] }
      
      it 'creates invitations between the left and right users' do
        result = subject.join_users(left_user, right_user)
        assert_equal 2, result.length
      end
      
      it 'does not connect a user to himself' do
        result = subject.join_users(left_user, left_user)
        assert_equal 0, result.length
      end

      it 'allows giver-receiver plans for different company survey series' do
        subject.join_users(left_user, right_user)
        AcmeHelper.use_project_role_series
        other_css = CompanySurveySeries.for_others.last
        new_connector = Ripple::CompanyConnector.new(company, nil, other_css)
        result = new_connector.join_users(left_user, right_user)
        assert_equal 2, result.length
      end
      
      it 'does not duplicate an existing plan' do
        right_user.default_user_role.invite!(left_user)
        result = subject.join_users(left_user, right_user)
        assert_equal 1, result.length
      end
      
    end

    describe '#join_self' do
      let(:user) { company.users[1] }
      it 'connects a user to himself' do
        result = subject.join_self(user)
        assert_equal SurveyPlan, result.class
      end
    end
  end
end

