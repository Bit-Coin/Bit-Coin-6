class AcmeHelper

  class << self

    def acme_company
      Company.where(:name => 'Acme Demo, Inc.').first
    end
  
    def acme_team
      acme_company
    end

    def acme_subscription
      acme_company.subscriptions.active
    end

    def generate_acme_company_data(n=7)
      puts 'Generating Acme Demo, Inc. data'
      generate_acme_company
      generate_acme_users(n)
      generate_acme_subscription
      generate_acme_plans
      generate_acme_surveys
      generate_acme_comments
      generate_acme_responses
      generate_acme_scores
      generate_random_shizzle
    end

    def duplicate_acme_user_in_ripple_company
      load Rails.root.join('test','fixture_scripts','ripple_analytics.rb')
      ripple = Company.find_by_stub('ripple')      
      orig_user = acme_company.members.first
      dup_user = orig_user.dup
      dup_user.company = ripple
      dup_user.password = Security::DEMO_PASSWORD
      dup_user.save!
      [orig_user.reload, dup_user.reload]
    end
    
    def generate_acme_company
      company = Company.create!({
        name: 'Acme Demo, Inc.', 
        ripple_api_key: 'acme', 
        ripple_api_token: 'xlxT90kjG81I5hmrVE7Gt08tA9z7pxNhaxDrCMWhi4E',
        domain: 'example.com',
        stub: 'acme'
      })
      company.use_series(1, {allow_comments: true}) # others
      company.use_series(2) # self 50
      company
    end

    def use_project_role_series
      acme_company.use_series(3, {})
      acme_company.use_series(4, {allow_comments: true})
      acme_company.use_series(4, {for_self: true})
    end

    def generate_acme_teams
      Team.create!({
        name: 'Business Development',
        company_id: acme_company.id
      })
    end

    def generate_acme_users(n=2)
      team = Team.first
      users = [
        {
          email: 'demo+ceo@ripplecrew.com',
          password: Security::DEMO_PASSWORD,
          cohort: 'Executive',
          first_name: 'Daryl',
          last_name: 'Boxwood'
        },{
          email: 'demo+bizdev@ripplecrew.com', 
          password: Security::DEMO_PASSWORD,
          cohort: 'Manager', 
          first_name: 'Rheinhold', 
          last_name: 'Elmore',
          confirmed_at: Time.now,
          team: team
        },{
          email: 'demo+manager@ripplecrew.com',
          password: Security::DEMO_PASSWORD,
          cohort: 'Manager',
          first_name: 'Noel',
          last_name: 'Nagbody'
        },{
          email: 'demo+finance@ripplecrew.com',
          password: Security::DEMO_PASSWORD,
          cohort: 'Associate',
          first_name: 'Randy',
          last_name: 'Checkbox',
        },{      
          email: 'demo+sales@ripplecrew.com',
          password: Security::DEMO_PASSWORD,
          cohort: 'Associate',
          first_name: 'Linda',
          last_name: 'Shoeleather'
        },{
          email: 'demo+engineer@ripplecrew.com',
          password: Security::DEMO_PASSWORD,
          cohort: 'Associate',
          first_name: 'Bert',
          last_name: 'Ashpy',
        },{      
          email: 'demo+hr@ripplecrew.com',
          password: Security::DEMO_PASSWORD,
          cohort: 'Manager',
          first_name: 'Ellen',
          last_name: 'Serendipity',
        }
      ]
    
      company = acme_company
      defs = {
        :confirmed_at => Time.now,
        :type => 'rippler',
        :state => 'active'
      }
      n.times do |i|
        u = company.users.create!(users[i].merge(defs))
        3.times { u.set_short_path }
        u.short_paths.last.update_attributes(created_at: Time.now - 29.days)
        u.short_paths.first.update_attributes(created_at: Time.now - 57.days)
      end
      company.update_attributes({
        :manager => company.users.first
      })
    end

    def generate_acme_user_of_type(type)
      company = acme_company
      defs = {
        email: "demo+#{rand(10000)}@ripplecrew.com",
        password: Security::DEMO_PASSWORD,
        cohort: 'Manager',
        first_name: 'Name',
        last_name: 'Name',
        :confirmed_at => Time.now,
        :type => type,
        :state => 'active'
      }
      
      u = company.users.create(defs)
      u.set_short_path
      true
    end
    
    def generate_acme_subscription(plan_id=1)
      company = acme_company
      start_date = (Date.today - 60.days).to_datetime
      subscription = company.subscriptions.create({
        plan_id: plan_id,
        start_at: start_date,
        end_at: Subscription::FOREVER,
        state: Subscription::ACTIVE,
        owner: company.users.first
      })
      
      company.users.each do |u|
        subscription.subscription_users.create({
          user: u,
          start_at: start_date,
          end_at: Subscription::FOREVER
        })
      end
    end

    # DOES NOT GENERATE SELF SURVEY
    def generate_acme_plans_and_surveys
      company = acme_company
      css = company.company_survey_series.ripple50_others

      all_members = company.users.to_a
      all_members.each do |current_member|
        all_members.each do |other_member|
          if current_member != other_member   
            p = SurveyPlan.create!({
              user_role_id: current_member.user_roles.first.id,
              company_survey_series: css,
              giver_id: other_member.id,
              state: 'active',
              next_due: Time.now,
              last_reminded_at: nil
            })
            p.create_next_survey
          end
        end
      end
    end
    
    # TODO pretty redundant w/ generate plans and surveys
    def generate_acme_plans(state='active')
      company = acme_company
      others_css = company.company_survey_series.ripple50_others
      self_css = company.company_survey_series.ripple50_self
      
      all_members = company.users.to_a
      all_members.each do |current_member|
        # Self
        SurveyPlan.create!({
          user_role_id: current_member.user_roles.first.id,
          company_survey_series: self_css,
          giver_id: current_member.id,
          state: state,
          next_due: Time.now,
          last_reminded_at: nil
        })

        all_members.each do |other_member|
          if current_member != other_member        
            SurveyPlan.create!({
              user_role_id: current_member.user_roles.first.id,
              company_survey_series: others_css,
              giver_id: other_member.id,
              state: state,
              next_due: Time.now,
              last_reminded_at: nil
            })
          end
        end
      end
    end

    def generate_many_to_one_graph
      company = acme_company
      others_css = company.company_survey_series.ripple50_others
      self_css = company.company_survey_series.ripple50_self
      
      givers = company.users
      receiver = company.users.first
      SurveyPlan.create!({
        user_role_id: receiver.user_roles.first.id,
        company_survey_series: self_css,
        giver_id: receiver.id,
        state: 'active',
        next_due: Time.now,
        last_reminded_at: nil
      })
      givers.each do |giver|
        next if giver == receiver       
        SurveyPlan.create!({
          user_role_id: receiver.user_roles.first.id,
          company_survey_series: others_css,
          giver_id: giver.id,
          state: 'active',
          next_due: Time.now,
          last_reminded_at: nil
        })
      end
    end

    def generate_acme_unregistered_givers(n=1)
      company = acme_company
      receiver = company.all_members.rippler.first
      n.times do
        params = {receiver: receiver, email: Faker::Internet.email}
        sp = SurveyPlan.build_from_params(params)
        sp.save!
        sp.generate_next_survey
        sp.notify!
      end
    end
  
    def generate_acme_surveys
      acme_company.company_survey_series.each do |css|
        css.survey_plans.each do |sp|
          sp.create_next_survey
        end
      end
    end
  
    def generate_acme_responses
      company = acme_company
      ActiveRecord::Base.transaction do
        all_surveys = company.feedback.pluck(:id).shuffle
        Response.where('survey_id in (?)', all_surveys).update_all('score = trunc(random()*2 + random()*2 + 2)')
        company.survey_plans.update_all(next_due: Time.now + 168.hours)
        company.feedback.update_all(state: 'complete', completed_at: Time.now)
      end
    end

    def complete_all_surveys!(giver)
      giver.surveys.open.each do |s|
        s.responses.update_all(score: 5)
        s.complete!
      end
    end

    def generate_acme_comments
      survey = Survey.open.last
      Comment.create!({
        state: 'published',
        receiver: survey.receiver,
        response: survey.responses.last,
        survey: survey,
        text: Faker::Lorem.sentence
      })
      Comment.create!({
        state: 'published',
        receiver: survey.receiver,
        response: nil,
        survey: survey,
        text: Faker::Lorem.sentence
      })
    end

    def generate_acme_scores
      acme_company.users.rippler.each do |user|
        Job::UpdatePersonalScores.perform(user.id)
        Job::UpdateSelfScores.perform(user.id)
      end
      Job::UpdateCompanyScores.perform(acme_company.id)
    end
    
    def generate_random_shizzle      
      team = acme_team
      company = acme_company
    
      company.survey_plans.update_all({:next_due => Time.now - 1.second})
      Job::CreateSurveys.perform

      # Create some misc invitations and fire associated email events
      generate_acme_unregistered_givers(5)
      # NB these UGs have no surveys yet

      # Posting email events
      rippler = User.rippler.first
      sg_ids = []
      emails = rippler.survey_plans.created_or_notified.sample(4).map do |sp|
        sp.create_next_survey
        ReminderMailer.reminder(sp.giver_id).deliver
        sp.surveys.first.giver.messages.last.update_attributes(sg_message_id: sp.id.to_s)
        sg_ids << sp.id.to_s
        sp.giver.email
      end

      Job::ParseEmailEvents.perform([{
          "email" => emails[0],
          "sg_message_id" => sg_ids[0],
          "sg_event_id" => '',
          "event" => "open"
        },{
          "email" => emails[1],
          "sg_message_id" => sg_ids[1],
          "sg_event_id" => '',
          "event" => "click"
        },{
          "email" => emails[2],
          "event" => "bounce"
        },{
          "email" => emails[3],
          "event" => "unsubscribe"
        }
      ])
    end
  
    # ...
  end
  
end