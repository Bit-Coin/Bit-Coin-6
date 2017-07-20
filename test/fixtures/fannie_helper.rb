class FannieHelper

  # For when your fannie needs some help...

  class << self

    def fannie_company
      Company.find_by_stub('fanniemae')
    end

    def make_it_so
      generate_demo_plans
      generate_self_survey
      generate_other_surveys
      fake_up_some_scores
    end

    # Generates UGs and one rippler
    def generate_demo_plans(n=5)
      (n-1).times do |i|
        sp = SurveyPlan.build_from_params({
          receiver: fannie_company.manager,
          email: Faker::Internet.email,
          css: fannie_company.company_survey_series.for_others.first
        })
        sp.activate!
      end

      sub = Ripple::Subscription::CompanySubscription.new(fannie_company.subscriptions.active)
      u = User.create!({
        email: 'bob@ripplecrew.com',
        password: Security::DEMO_PASSWORD,
        password_confirmation: Security::DEMO_PASSWORD,
        first_name: 'Bob',
        last_name: 'Gatewood',
        :confirmed_at => Time.now,
        :type => User::RIPPLER,
        :state => User::ACTIVE,
        :company => fannie_company
      })
      sub.register_user(u)
      cc = Ripple::CompanyConnector.new(fannie_company, nil, 
        fannie_company.company_survey_series.for_others.first)
      cc.join_users(fannie_company.manager, u)
    end

    def generate_self_survey
      cc_self = Ripple::CompanyConnector.new(fannie_company, nil, 
        fannie_company.company_survey_series.for_self.first)
      cc_self.join_self(fannie_company.manager)
    end

    def generate_other_surveys
      Job::CreateCompanySurveys.perform(fannie_company.id)
    end

    def fake_up_some_scores
      all_but_lisa = fannie_company.manager.everyone_else_company.pluck(:id)
      lisa_self_survey = fannie_company.manager.self_surveys.first
      Job::AnswerBot.perform(users: all_but_lisa)
      Job::AnswerBot.perform(surveys: [lisa_self_survey.id])
      Job::UpdateSelfScores.perform(fannie_company.manager.id)
      Job::UpdatePersonalScores.perform(fannie_company.manager.id)
      Job::UpdateCompanyScores.perform(fannie_company.id)
    end
  end
end