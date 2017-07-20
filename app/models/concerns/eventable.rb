module Eventable

  # `include Eventable` in any models that you want to have their
  # own event class, e.g. UserEvent, SurveyEvent, etc.

  # Quick way to log a common event
  #   1.  Register that event in the EVENTS hash of the object event
  #   2.  Call `object.log_event!(name)` from anywhere in the code.

  # For ad-hoc events
  #   1. Pass more params to #log_event!(name, params) where
  #      params = { severity: Event::CRITICAL, channel: '#alert', 
  #                 body: { 'message' => "Your fly is down" }}
  
  extend ActiveSupport::Concern

  included do
    has_many "#{self.to_s.underscore}_events".to_sym, as: :eventable
  end

  def log_event!(event_name=nil, options={})
    raise "Must supply event name" unless event_name || options[:name]
    params = {eventable: self, name: event_name}.merge(options)
    event_class.create!(params)
  end

  private

  def event_class
    self.class == SystemEvent ? SystemEvent : "#{self.class}Event".constantize
  end

  module ClassMethods
  end
end
