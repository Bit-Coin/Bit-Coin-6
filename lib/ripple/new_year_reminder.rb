class Ripple::NewYearReminder

  def initialize(users)
    @users = users
  end

  def happynewyear!
    happypeople = 0
    @users.each do |u|
      next if u.do_not_contact?
      CustomDeviseMailer.happy_new_year(u.id).deliver
      happypeople += 1
    end

    return happypeople
  end
end
