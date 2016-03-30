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
    config :max_weeks_without_login

    on :loaded, :start_timers

    def start_timers(payload)
      start_max_weeks_without_login_timer
      start_admin_activities_timer
    end

    private

    def start_admin_activities_timer
      every(TIMER_INTERVAL) do |timer|
        logged_errors do
          sliding_window.advance(duration_minutes: 30, buffer_minutes: 30) do |window_start, window_end|
            list_activities(window_start, window_end)
          end
        end
      end
    end

    def start_max_weeks_without_login_timer
      return if config.max_weeks_without_login.to_i < 1

      every(TIMER_INTERVAL) do |timer|
        logged_errors do
          persistent_every("max-weeks-with-login", weeks_in_seconds(1)) do
            list_active_accounts_with_no_recent_login
          end
        end
      end
    end

    def weeks_in_seconds(weeks)
      60 * 60 * 24 * 7 * weeks.to_i
    end

    def max_weeks_without_login_ago
      Time.now - weeks_in_seconds(config.max_weeks_without_login.to_i)
    end

    def logged_errors(&block)
      yield
    rescue Exception => e
      puts "Error in timer loop: #{e.inspect}"
    end

    def persistent_every(name, seconds, &block)
      PersistentEvery.new(name, redis).execute_after(seconds, &block)
    end

    def sliding_window
      @sliding_window ||= SlidingWindow.new("last_activity_list_at", redis)
    end

    def list_active_accounts_with_no_recent_login
      msg = "The following users have active accounts, but have not logged in for #{config.max_weeks_without_login} weeks. "
      msg += "If appropriate, consider suspending or deleting their accounts:\n"
      msg += active_users_with_no_recent_login.map { |user|
        "- #{user.ou_path}/#{user.email}"
      }.join("\n")
      robot.send_message(target, msg)
    end

    def active_users_with_no_recent_login
      gateway.users.reject { |user|
        user.suspended?
      }.select { |user|
        user.last_login_at < max_weeks_without_login_ago && user.created_at < max_weeks_without_login_ago
      }
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
