SecureRandom.class_eval do
  def self.string(length=6)
    arr = Array.new
    source = [*"A".."Z", *"a".."z", *"0".."9"]
    length.times do
      arr << source[rand(source.size)]
    end
    arr.join
  end

  def self.password(length=8)
    arr = Array.new
    uppers = [*"A".."Z"]
    lowers = [*"a".."z"]
    numbers = [*"0".."9"]
    specials = ['!','#','$','%','&','*']
    all = uppers + lowers + numbers
    arr = [uppers[rand(uppers.size)] + lowers[rand(lowers.size)] + 
            numbers[rand(numbers.size)]]
    (length - 3).times do
      arr << all[rand(all.size)]
    end
    arr.join
  end
end
