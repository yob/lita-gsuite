module Lita
  # Executes a block of code when a window of time includes only
  # times that haven't been executed before.
  #
  # Use this when you have some code that requires a start time and and end time, and
  # you want to execute it roughly every half hour.
  #
  # Redis is used to persist the end of the last window that executed and ensure the
  # block doesn't execute again until that window is passed.
  #
  #     window = SlidingWindow.new("my-sliding-window", redis)
  #     window.advance(duration_minutes: 30) do |window_start, window_end|
  #       puts "#{window_start} -> #{window_end}"
  #     end
  #
  # Call this as often as you like, and the block passed to advance() will
  # only execute if it's been 30 minutes since the last time it executed.
  #
  class SlidingWindow
    def initialize(name, redis)
      @name, @redis = name, redis

      initialise_last_time_if_not_set
    end

    def advance(duration_minutes: 30, buffer_minutes: 0, &block)
      start_time = Time.now - mins_to_seconds(duration_minutes) - mins_to_seconds(buffer_minutes)
      advance_to = start_time + mins_to_seconds(duration_minutes)

      return unless start_time > last_time

      yield last_time, advance_to 

      @redis.set(@name, advance_to.to_i)
    end

    private

    def mins_to_seconds(mins)
      mins * 60
    end

    def last_time
      Time.at(@redis.get(@name).to_i)
    end

    def initialise_last_time_if_not_set
      @redis.setnx(@name, two_weeks_ago.to_i)
    end

    def two_weeks_ago
      ::Time.now - (60 * 60 * 24 * 14)
    end

  end
end
