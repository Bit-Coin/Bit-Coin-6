require 'test_helper'

class ConfigurableTest < ActiveSupport::TestCase
  describe 'company-level' do
    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_teams
      AcmeHelper.generate_acme_users
    end

    subject { Company.first }

    it 'has default settings' do
      assert Company.default_settings
    end

    it 'has instance settings' do
      assert HashWithIndifferentAccess, subject.settings.class
    end

    it 'has the setting :months_between_self_surveys' do
      assert_equal 12, subject.settings[:months_between_self_surveys]
    end

    it 'can change the default and change it back' do
      subject.set_config(:months_between_self_surveys, 6)
      assert_equal 6, subject.settings[:months_between_self_surveys]
      assert_equal 1, subject.configurations.count
      subject.reload
      subject.set_config(:months_between_self_surveys, 12)
      assert_equal 12, subject.settings[:months_between_self_surveys]
      assert_equal 0, subject.configurations.count
    end

    it 'lends its settings to descendants' do
      assert_equal subject.teams.first.settings, subject.settings
    end

    it 'scopes correctly' do
      assert Company.has_config(:months_between_self_surveys, 12).include?(subject),
        "Subject not in scope"
    end
  end

  describe 'team-level' do
    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_teams
      AcmeHelper.generate_acme_users
    end

    subject { Team.first }

    it 'inherits values from parent' do
      assert_equal subject.company.settings[:months_between_self_surveys], 
        subject.settings[:months_between_self_surveys]
    end

    it 'overrides the company setting which cascades to descendants' do
      refute_equal 6, subject.settings[:months_between_self_surveys]
      subject.set_config(:months_between_self_surveys, 6)
      assert_equal 6, subject.settings[:months_between_self_surveys]
      user = subject.company.all_members.first
      user.update_attributes(team: subject)
      user.reload
      assert_equal 6, user.settings[:months_between_self_surveys]
    end

    it 'even works for relationship tags!' do
      assert_equal subject.company.settings[:relationship_tags],
        subject.settings[:relationship_tags]
      subject.company.set_config(:relationship_tags, "Friend,Foe")
      subject.reload
      assert_equal "Friend,Foe", subject.settings[:relationship_tags]
      subject.set_config(:relationship_tags, "BFFL,Friend With Benefits")
      assert_equal "BFFL,Friend With Benefits", subject.settings[:relationship_tags]
    end
  end

  describe 'user-level' do
    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_users
      AcmeHelper.generate_acme_teams
    end

    subject { User.first }

    it 'inherits from team which inherits from company' do
      assert_equal Ripple::Time.default_reminder_hour, subject.settings[:reminder_hour]
    end

    it 'overrides the team and company settings' do
      subject.set_config(:reminder_hour, 11)
      assert_equal 11, subject.settings[:reminder_hour]
      assert_equal 1, subject.configurations.count

      subject.set_config(:reminder_hour, :default)
      subject.reload
      assert_equal Ripple::Time.default_reminder_hour, subject.settings[:reminder_hour]
      refute subject.configurations.any?
      assert_equal User.count, 
        User.has_config(:reminder_hour, Ripple::Time.default_reminder_hour).count
    end

    it 'works for relationship_types with a team' do
      subject.update_attributes(team: subject.company.teams.first)
      assert_equal [nil, "Colleague","Peer", "Manager", "Direct Report", "Report"], subject.relationship_type_options
      subject.company.set_config(:relationship_types, 'Captor,Hostage')
      assert_equal [nil, "Captor","Hostage"], subject.relationship_type_options
      subject.team.set_config(:relationship_types, 'Overlord,Underling')
      assert_equal [nil, "Overlord","Underling"], subject.relationship_type_options
    end

    it 'works for relationship_types without a team' do
      assert_equal [nil, "Colleague","Peer", "Manager", "Direct Report", "Report"], subject.relationship_type_options
      subject.company.set_config(:relationship_types, 'Captor,Hostage')
      assert_equal [nil, "Captor","Hostage"], subject.relationship_type_options
    end
  end
end
