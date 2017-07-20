module Ripple
  class Time

    WEEK_START_DAY = :tuesday
    WEEK_START_DAY_INDEX = 2 # Tuesday
    WEEK_START_HOUR_EASTERN = 8
    WEEK_START_MINUTE_EASTERN = 34

    SURVEYS_DUE = 'Friday' # used in SMS prompt
    WHEN_ROBOTS_RULE = DateTime.new(4000, 01, 01, 00, 00, 00)

    def initialize(time=::Time.now)
      @time = time
    end

    def beginning_of_week
      if @time.wday == WEEK_START_DAY_INDEX &&
          @time.hour <= WEEK_START_HOUR_EASTERN &&
          @time.min < WEEK_START_MINUTE_EASTERN
        base = (@time.beginning_of_day - 1.second).beginning_of_week(WEEK_START_DAY)
      else
        base = @time.beginning_of_week(WEEK_START_DAY)
      end
      base + WEEK_START_HOUR_EASTERN.hours + WEEK_START_MINUTE_EASTERN.minutes
    end

    def end_of_week
      beginning_of_week + 7.days - 1.second
    end

    def beginning_of_next_week
      beginning_of_week + 1.week
    end

    def beginning_of_fourth_week
      beginning_of_week + 4.weeks
    end

    def week_midpoint
      beginning_of_week + 3.days + 12.hours
    end

    def round # round to nearest beginning of week
      if @time <= week_midpoint
        beginning_of_week
      else
        beginning_of_next_week
      end
    end

    # Used by default config settings in Company
    # and User
    def self.default_reminder_hour
      8
    end

    # Calculates the number of business days in range (start_date, end_date]
    # from http://stackoverflow.com/questions/4027768/calculate-number-of-business-days-between-two-days
    #
    # @param start_date [Date]
    # @param end_date [Date]
    #
    # @return [Fixnum]
    def self.business_days_between(start_date, end_date)
      days_between = (end_date - start_date).to_i
      return 0 unless days_between > 0

      # Assuming we need to calculate days from 9th to 25th, 10-23 are covered
      # by whole weeks, and 24-25 are extra days.
      #
      # Su Mo Tu We Th Fr Sa    # Su Mo Tu We Th Fr Sa
      #        1  2  3  4  5    #        1  2  3  4  5
      #  6  7  8  9 10 11 12    #  6  7  8  9 ww ww ww
      # 13 14 15 16 17 18 19    # ww ww ww ww ww ww ww
      # 20 21 22 23 24 25 26    # ww ww ww ww ed ed 26
      # 27 28 29 30 31          # 27 28 29 30 31
      whole_weeks, extra_days = days_between.divmod(7)

      unless extra_days.zero?
        # Extra days start from the week day next to start_day,
        # and end on end_date's week date. The position of the
        # start date in a week can be either before (the left calendar)
        # or after (the right one) the end date.
        #
        # Su Mo Tu We Th Fr Sa    # Su Mo Tu We Th Fr Sa
        #        1  2  3  4  5    #        1  2  3  4  5
        #  6  7  8  9 10 11 12    #  6  7  8  9 10 11 12
        # ## ## ## ## 17 18 19    # 13 14 15 16 ## ## ##
        # 20 21 22 23 24 25 26    # ## 21 22 23 24 25 26
        # 27 28 29 30 31          # 27 28 29 30 31
        #
        # If some of the extra_days fall on a weekend, they need to be subtracted.
        # In the first case only corner days can be days off,
        # and in the second case there are indeed two such days.
        extra_days -= if start_date.tomorrow.wday <= end_date.wday
                        [start_date.tomorrow.sunday?, end_date.saturday?].count(true)
                      else
                        2
                      end
      end

      (whole_weeks * 5) + extra_days
    end

  end
end
