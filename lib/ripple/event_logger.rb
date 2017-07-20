module Ripple
  class EventLogger

    attr_accessor :name, :severity, :body, :channel, :username, :icon_emoji

    def initialize(name, params={})
      @name = name || 'unspecified'
      @severity = params.fetch(:severity, Event::INFO)
      @body = params.fetch(:body, {})
      @channel = params.fetch(:channel, '#activity')
      @username = params.fetch(:username, "#{Rails.env}")
      @icon_emoji = params.fetch(:icon_emoji, ':ghost:')
    end

    def log!
      SystemEvent.create!({
        name: name, severity: severity, body: body
      })
    end

  end
end
