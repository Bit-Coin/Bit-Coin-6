class ResponseSet < ActiveRecord::Base
  store_accessor :values
  has_many :questions

  validates_presence_of :description, :values

  def ordered_values
    cast = HashWithIndifferentAccess.new
    values.each_pair { |k,v| cast[k] = Integer(v) rescue v }
    HashWithIndifferentAccess.new cast.sort_by {|key, value| value}.to_h
  end
end
