require 'test_helper'

class StripeWebhooksControllerTest < ActionController::TestCase
  describe StripeWebhooksController do

    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_subscription(2)
    end
    
    describe 'POST invoice_events' do
      
      let(:event_id)               { 'evt_123456789' }
      let(:stripe_subscription_id) { 'sub_123456789' }
      let(:stripe_customer_id)     { 'cu_1234567890' }
      let(:stripe_invoice_id)      { 'in_1234567890' } 
      let(:total)                  { '1200' }
      
      let(:company)      { AcmeHelper.acme_company }
      let(:subscription) { AcmeHelper.acme_subscription }
      
      let(:default_invoice) {
        JSON.load(File.read(File.join(Rails.root, 'test/fixtures/stripe_webhook_invoice_created.json')))['data']['object']
      }
      
      before do
        subscription.update_attributes({
          :stripe_subscription_id => stripe_subscription_id,
          :stripe_customer_id => stripe_customer_id
        })
      end
      
      describe 'with a new subscription' do
        describe 'invoice.created hook' do
          before do
            params = {
              'id' => event_id, 
              'object' => 'event', 
              'type' => 'invoice.created', 
              'data' => {
                'object' => default_invoice.merge({
                  'id' => stripe_invoice_id,
                  'subscription' => stripe_subscription_id,
                  'customer' => stripe_customer_id,
                  'total' => total
                })
              }
            }
            post :invoice_events, params, :format => :json
          end
          
          it 'creates an Invoice record with the data sent' do
            record = company.invoices.last
            assert record.is_a? Invoice
            assert record.stripe_invoice_id === stripe_invoice_id, 'Stripe invoice id is incorrect'
            assert record.body['total'] === total, 'Total is incorrect'
          end
          
          it 'creates a SubscriptionEvent record for the new invoice' do
            record = company.subscriptions.first.subscription_events.last
            assert record.name === SubscriptionEvent::CREATED
          end
          
          it 'does not change the state of the subscription' do
            assert subscription.state === Subscription::ACTIVE
          end
        end
      end
      
      describe 'with an existing invoice' do      
        before do
          @invoice = Invoice.create({
            :subscription_id => subscription.id,
            :company_id => company.id,
            :stripe_invoice_id => stripe_invoice_id,
            :body => default_invoice
          })
        end
        
        let(:new_total) { '2350' }
        
        describe 'invoice.updated hook' do
          before do
            params = {
              'id' => event_id, 
              'object' => 'event', 
              'type' => 'invoice.updated', 
              'data' => {
                'object' => default_invoice.merge({
                  'id' => stripe_invoice_id,
                  'subscription' => stripe_subscription_id,
                  'customer' => stripe_customer_id,
                  'total' => new_total
                })
              }
            }
            post :invoice_events, params, :format => :json
          end
          
          it 'updates the existing invoice data' do
            assert @invoice.reload.body['total'] == new_total
          end
          
          it 'creates a SubscriptionEvent record for the payment' do
            record = company.subscriptions.first.subscription_events.last
            assert record.name === SubscriptionEvent::UPDATED
          end
          
          it 'does not change the state of the subscription' do
            assert subscription.state === Subscription::ACTIVE
          end
        end
      
        describe 'invoice.payment_succeeded hook' do
          before do
            subscription.update_attributes({
              :state => Subscription::PENDING
            })
            params = {
              'id' => event_id, 
              'object' => 'event', 
              'type' => 'invoice.payment_succeeded', 
              'data' => {
                'object' => default_invoice.merge({
                  'id' => stripe_invoice_id,
                  'subscription' => stripe_subscription_id,
                  'customer' => stripe_customer_id,
                  'total' => new_total
                })
              }
            }
            post :invoice_events, params, :format => :json
          end
          
          it 'sets the subscription state to active' do
            assert company.subscriptions.first.state === Subscription::ACTIVE
          end
          
          it 'creates a SubscriptionEvent record for the payment' do
            record = company.subscriptions.first.subscription_events.last
            assert record.name === SubscriptionEvent::PAYMENT
          end
        end
      
        describe 'invoice.payment_failed hook' do
          before do
            params = {
              'id' => event_id, 
              'object' => 'event', 
              'type' => 'invoice.payment_failed', 
              'data' => {
                'object' => default_invoice.merge({
                  'id' => stripe_invoice_id,
                  'subscription' => stripe_subscription_id,
                  'customer' => stripe_customer_id,
                  'total' => new_total
                })
              }
            }
            post :invoice_events, params, :format => :json
          end
        
          it 'sets the subscription state to unpaid' do
            assert company.subscriptions.first.state === Subscription::UNPAID
          end
          
          it 'creates a SubscriptionEvent record for the payment' do
            record = company.subscriptions.first.subscription_events.last
            assert record.name === SubscriptionEvent::PAYMENT
          end
        end
      end
    end
    
  end
end