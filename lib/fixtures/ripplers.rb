class Fixtures::Ripplers
  def self.seed_pending(count=8)
    count.times do
      User.create!({
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        type: 'prospect',
        state: 'active',
        email: Faker::Internet.email,
        pending_company_name: Faker::Company.name,
        password: SecureRandom.password,
        confirmed_at: Time.now
      })
    end
  end

  def self.direct_add_ripplers!(id, klass, csv)
    if klass == Team
      team = Team.find(id)
      company = team.company
    elsif klass == Company
      team = nil
      company = Company.find(id)
    end

    team = Team.where('id = ?', team_id).first
    company = Company.where('id = ?', team_id).first
    subscription = company.subscriptions.active_state.first
    companysub = Ripple::Subscription::CompanySubscription.new(subscription)

    bogus = []

    CSV.parse(csv, headers: true) do |r|
      next if team.all_members.pluck(:email).include?(r['email']) # skip any already set up
      password = SecureRandom.password
      u = User.find_by_email(r['email']) || team.members.new
   
      r.headers.each do |h|
        u.send("#{h}=", r[h])
      end
   
      u.company = team.parent_team_id == nil ? company : Company.find(team.parent_team_id)
      u.team = team
      u.password = password
      u.password_confirmation = password
      u.type = 'rippler'
      u.state = 'active'
      u.confirmed_at = Time.now

      if u.save!
        CustomDeviseMailer.maven_signed_you_up(u.id).deliver
        companysub.register_user(u)
      else
        bogus << r['email']
      end
    end
    bogus
  end

  def self.just_fix_my_damn_email(user_id, email)
    u = User.find(user_id)
    oldemail = u.email
    u.skip_reconfirmation!
    u.email = email
    u.save!

    message = "User ID #{u.id}'s email was silently changed from #{oldemail} to #{email}"
    Ripple::ActivityLogger.new(text: message, icon_emoji: ':hammer:').log!
    message
  end
end