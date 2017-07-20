module Ripple
  class OnboardUser

    attr_reader :user

    # Primary point of entry for admins to do all of the following:
    # - Create new contacts
    # - Create new companies and mavens
    # - Create new teams and mavens
    # - Add test drivers

    # Initialize with a user model of type User::PROSPECT, obtained by create_prospect

    def initialize(user)
      @user = user
    end

    # Promote the user to a maven and assign to a newly created company
    # Return the new company record

    def create_company(company_name, domain, stub)
      subscription = Ripple::Subscription::CompanySubscription.create_subscription(company_name, domain, @user, stub)
      subscription.record.company
    end

    # Promote the user to a maven and assign to a newly created team in an existing company
    # Return the new team record

    def create_team(company, team_name)
      team = Team.create!({
        name: team_name,
        company: company,
        manager: @user
      })
      user.update_attributes!({
        :company => company,
        :team => team,
        :type => User::RIPPLER,
        :state => User::ACTIVE
      })
      team
    end

    # Promote the user to a test driver and assign to the Ripple company
    # Return the modified user record
    # @param company: the test drive company, or uses the default (Ripple)
    # @param friends:
    # - nil to connect no one
    # - true to connect default users
    # - array of users to connect specific users

    def test_drive(company=nil, friends=nil)
      company ||= test_drive_company
      user.update_attributes!({
        :company => company,
        :type => User::RIPPLER,
        :state => User::ACTIVE
      })
      if friends
        invite_test_driver(friends.respond_to?(:length) ? friends : test_drive_friends)
        Resque.enqueue(Job::UpdatePersonalScores, user.id)
        Resque.enqueue(Job::UpdateCompanyScores, company.id)
      end
      subscription = Ripple::Subscription::CompanySubscription.new(company.subscriptions.active)
      subscription.register_user(user)
      user
    end

    def invite_test_driver(friends)
      friends.each do |friend|
        receiver_plan = user.default_user_role.invite!(friend)
        receiver_survey = receiver_plan.create_next_survey
        receiver_survey.responses.set_random_scores
        receiver_survey.complete!

        giver_plan = friend.default_user_role.invite!(user)
        giver_plan.create_next_survey
      end

      # receiver_plan = user.default_user_role.invite!(user)
      # receiver_survey = receiver_plan.create_next_survey
      # receiver_survey.responses.set_random_scores
      # receiver_survey.complete!

      # giver_plan = user.default_user_role.invite!(user)
      # giver_plan.create_next_survey


      true
    end

    def test_drive_company
      @tdc ||= Company.find_by_name(Ripple::Globals::TESTDRIVE_COMPANY_NAME)
    end

    def test_drive_friends
      test_drive_company.users.where(:email => Ripple::Globals::TESTDRIVE_AUTO_FRIENDS)
    end

    class << self

      # Primary point of entry for admins creating new contact users
      # Perhaps record an event of some kind eventually

      def create_prospect(first_name, last_name, email, pending_company_name, options={:confirm => true})
        user = User.create!({
          :first_name => first_name,
          :last_name => last_name,
          :email => email,
          :pending_company_name => pending_company_name,
          :password => SecureRandom.password,
          :confirmed_at => options[:confirm] ? ::Time.now : nil,
          :type => User::PROSPECT,
          :state => User::ACTIVE
        })
        user.set_short_path
        user
      end

      # Populate a new company with new ripplers from a CSV file

      # TODO: this needs an option to fully connect everyone with survey_plans

      def create_ripplers_from_csv(company, team, csv, options={})
        subscription = Ripple::Subscription::CompanySubscription.new(company.subscriptions.active)
        prior_users = team ? team.members : company.users

        result = {
          :users => [],
          :survey_plans => [],
          :invalid_rows => []
        }
        csv_options = {
          :headers => true,
          :header_converters => lambda { |f| f.strip },
          :converters => lambda { |f| f ? f.strip : nil }
        }
        user_attrs = {
          :company => company,
          :team => team,
          :type => User::RIPPLER,
          :state => User::ACTIVE,
          :confirmed_at => ::Time.now
        }
        if csv.present?
          CSV.parse(csv) do |r|
            user = User.new
            begin
              user.password = user.password_confirmation ||= SecureRandom.password # do not change existing users' passwds
              user.assign_attributes(user_attrs)
              user.first_name = r[0]
              user.last_name = r[1]
              user.email = r[2]
              user.start_date = r[3]
              user.department = r[4]
              user.sex = r[5]
              user.age = r[6]
              user.save!
            rescue ActiveRecord::RecordInvalid, ActiveRecord::UnknownAttributeError
              result[:invalid_rows] << r
            else # no exception
              CustomDeviseMailer.maven_signed_you_up(user.id).deliver
              subscription.register_user(user)
              Resque.enqueue(Job::CreateUserSurveys, user.id) # to create self survey, which takes so long
              result[:users] << user
            end
            team.team_members.create(user_id: user.id) if team.present?
          end
        end
        # TODO provide select on view to choose which CSS to connect users to
        css_for_other = company.company_survey_series.for_others.order(created_at: :desc)
        result[:users] = result[:users].present? ? result[:users] : prior_users
        new_users = result[:users]
        css_for_other.each do |css_other|
          connector_for_other = Ripple::CompanyConnector.new(company, team, css_other)
          # Survey plans for other users
          if options[:connect_maven]
            result[:survey_plans].concat connector_for_other.join_to_maven(new_users)
          end
          if options[:connect_all]
            result[:survey_plans].concat connector_for_other.join_groups(prior_users, new_users)
          end
        end

        # Survey plans for self
        css_for_self = company.company_survey_series.for_self.order(created_at: :desc)
        css_for_self.each do |css_self|
          connector_for_self = Ripple::CompanyConnector.new(company, team, css_self)
          new_user_plans = []
          new_users.each do |new_user|
            new_user_plans << connector_for_self.join_self(new_user)
          end
          result[:survey_plans].concat new_user_plans
        end
        result
      end

    end # class << self

  end
end

