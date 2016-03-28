require "lita"

module Lita
  class Googleapps < Handler
    TIMER_INTERVAL = 60

    config :service_account_email
    config :service_account_key
    config :service_account_secret
    config :domains
    config :user_email
    config :channel_name

    on :loaded, :start_timers

    def start_timers(payload)
      every(TIMER_INTERVAL) do |timer|
        sliding_window.advance(duration_minutes: 30, buffer_minutes: 30) do |window_start, window_end|
          list_activities(window_start, window_end)
        end
      end
    end

    private

    def sliding_window
      @sliding_window ||= SlidingWindow.new("last_activity_list_at", redis)
    end

    def list_activities(window_start, window_end)
      gateway.admin_activities(window_start, window_end).sort_by(&:time).each do |activity|
        robot.send_message(target, activity.to_msg)
      end
    end

    def target
      Source.new(room: Lita::Room.find_by_name(config.channel_name) || "general")
    end

    def gateway
      @gateway ||= Lita::GoogleAppsGateway.new(
        service_account_email: config.service_account_email,
        service_account_key: config.service_account_key,
        service_account_secret: config.service_account_secret,
        domains: config.domains,
        acting_as_email: config.user_email
      ) 
    end

    Lita.register_handler(self)
  end
end
