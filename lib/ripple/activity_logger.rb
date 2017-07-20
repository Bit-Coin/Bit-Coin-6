module Ripple

  # A wrapper for HTTParty to post things using the Slack incoming webhook  
  #   => TODO: Refactor this so that the token is loaded by an env var
  # @text is the message to post
  # @channel is the Slack channel to post into (e.g. #general)
  # @username is the username to post as (doesn't have to be a real user)
  # @icon_emoji is the emoji to use as the "avatar" (e.g. :ghost:)
  #   => Note that the icon isn't always shown if the bot posts several things
  #      in succession, so don't count on the icon being there

  class ActivityLogger

    attr_accessor :text, :channel, :username, :icon_emoji

    @queue = :slack

    # If you want a record of this event to persist, call
    # Ripple::EventLogger instead.  It will, in turn, call
    # ActivityLogger.

    def initialize(params={})
      @text = params.fetch(:text, 'Default ActivityLogger message')
      @channel = params.fetch(:channel, '#activity')
      @username = params.fetch(:username, "#{Rails.env}")
      @icon_emoji = params.fetch(:icon_emoji, ':ghost:')

      if Rails.env.staging? # intercept
        @channel = '#staging'
      elsif Rails.env.demo? 
        @channel = '#demo'
      end
    end

    def to_s
      "#{channel} (#{username}) (#{icon_emoji}) \"#{text}\""
    end

    def log!
      if Rails.env.development? || Rails.env.test?
        Rails.logger.info "\n#{self.to_s}\n"

      else # staging or production
        status = Resque.enqueue(
          Job::NotifySlack,
          text: @text, 
          channel: @channel, 
          username: @username, 
          icon_emoji: @icon_emoji
        )

        if !status 
          Rails.logger.error "\nActivityLogger - Failed to enqueue to Slack:\n#{self.to_s}\n"
        end
      end
    end
  end
end
