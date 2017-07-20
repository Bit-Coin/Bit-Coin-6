class Invoice < ActiveRecord::Base
  
  belongs_to :company
  belongs_to :subscription
  
  validates_uniqueness_of :stripe_invoice_id
  
  scope :ordered, -> { order(:id) }
  
  def date
    DateTime.strptime(body['date'].to_s, '%s').to_date
  end
  
  def quantity
    body['lines']['data'][0]['quantity'].to_i rescue 0
  end
  
  def subtotal 
    body['subtotal'].to_i
  end
  
  def total
    body['total'].to_i / 100 # Stripe likes integer cents
  end
  
  def paid
    body['paid']
  end
  
  def closed
    body['closed']
  end
  
  def amount_due
    body['amount_due'].to_i
  end 
end

