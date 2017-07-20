class Fixtures::Messages

  def self.seed
    puts 'Seeding messages'
    20.times do
      s = Survey.all.sample
      m = Message.create!(
        uuid: "<#{SecureRandom.uuid}@ripplecrew.com>",
        messageable: s,
        to: s.giver.email,
        sender: 'SurveysMailer#new_invitation'
      )
      m.events.create!(
        type: 'dropped',
        detail: {
                "email" => "not an email address",
                "smtp-id" => "<4FB29F5D.5080404@sendgrid.com>",
                "timestamp" => 1386636115,
                "reason" => "Invalid",
                "event" => "dropped",
                "category" => [
                    "category1",
                    "category2",
                    "category3"
                ],
                "id" => "001",
                "purchase" => "PO1452297845",
                "uid" => "123456"
            }
      )
    end
  end
end
