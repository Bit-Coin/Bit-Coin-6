class Payment 

  # Payment is a view model that is just used to form_for the payment form
  # There is no database record
 
  include ActiveModel::Model
  attr_accessor :plan_id, :card_number, :cvc, :expiration_month, :expiration_year

  def expiration_month_options
    {
      '' => '',
      '01' => '01 Jan',
      '02' => '02 Feb',
      '03' => '03 Mar',
      '04' => '04 Apr',
      '05' => '05 May',
      '06' => '06 Jun',
      '07' => '07 Jul',
      '08' => '08 Aug',
      '09' => '09 Sep',
      '10' => '10 Oct',
      '11' => '11 Nov',
      '12' => '12 Dec'
    }.invert
  end
  
  def expiration_year_options
    (DateTime.now.year..(DateTime.now.year + 10)).to_a.unshift('')
  end

end