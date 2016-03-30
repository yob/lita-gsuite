module Lita
  # lita comes with an "every" helper that executes a block of code at fixed
  # intervals. However the interval is only stored in memory, which means
  # long intervals will often be reset if the lita process restarts (like
  # during a deploy).
  #
  # This provides a similar function, but it records the time of the last
  # exceution in redis. If the process restarts, it will be able to continue
  # monitoring the interval and excute at the approproriate time.
  #
  # For best result, use in conjunction with the built in every() helper:
  #
  #   one_minute = 60
  #   one_week = 60 + 60 + 24 + 7
  #   every(one_minute) do
  #     PersistentEvery.new("interval-name", redis).execute_after(one_week) do
  #       ... weekly code in here ...
  #     end
  #   end
  #
  class PersistentEvery
    def initialize(name, redis)
      @name, @redis = name, redis
    end

    def execute_after(seconds, &block)
      if last_time.nil? || last_time + seconds < Time.now
        yield
        @redis.set(@name, Time.now.to_i)
      end
    end

    def last_time
      value = @redis.get(@name)
      value ? Time.at(value.to_i).utc : nil
    end

  end
end
