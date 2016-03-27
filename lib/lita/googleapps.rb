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
        list_activities
      end
    end

    private

    def list_activities
      gateway.admin_activities.sort_by(&:time).each do |activity|
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
