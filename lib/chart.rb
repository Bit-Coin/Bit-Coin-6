module Chart

  SERIES_COLORS = {
    green:  '#2EA84F',
    blue:   '#4E67E8',
    pink:   '#FF426F',
    orange: '#FFC83C'
  }

  def self.demo_data(number=5)
    data = []
    number.times do |i|
      data << OpenStruct.new(
        published_at: (Time.now - (i*3).months).beginning_of_quarter, 
        score: rand(500.0)/100.0 
      )
    end
    data.sort_by { |point| point[:published_at] }
  end
end
