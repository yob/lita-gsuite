require "lita"
require "lita-timing"

module Lita
  class Googleapps < Handler
    TIMER_INTERVAL = 60

    config :service_account_email
    config :service_account_key
    config :service_account_secret
    config :user_email
    config :channel_name
    config :max_weeks_without_login
    config :max_weeks_suspended

    on :loaded, :start_timers

    def start_timers(payload)
      start_max_weeks_without_login_timer
      start_max_weeks_suspended_timer
      start_no_org_unit_timer
      start_admin_activities_timer
      start_admin_list_timer
      start_empty_groups_timer
      start_two_factor_timer
    end

    private

    def start_admin_activities_timer
      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        sliding_window.advance(duration_minutes: 30, buffer_minutes: 30) do |window_start, window_end|
          list_activities(window_start, window_end)
        end
      end
    end

    def start_admin_list_timer
      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        weekly_at("01:00", :thursday, "admin-list") do
          msg = AdminListMessage.new(gateway).to_msg
          robot.send_message(target, msg) if msg
        end
      end
    end

    def start_empty_groups_timer
      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        weekly_at("01:00", :wednesday, "empty-groups") do
          msg = EmptyGroupsMessage.new(gateway).to_msg
          robot.send_message(target, msg) if msg
        end
      end
    end

    def start_max_weeks_without_login_timer
      return if config.max_weeks_without_login.to_i < 1

      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        weekly_at("01:00", :tuesday, "max-weeks-with-login") do
          msg = MaxWeeksWithoutLoginMessage.new(gateway, config.max_weeks_without_login).to_msg
          robot.send_message(target, msg) if msg
        end
      end
    end

    def start_max_weeks_suspended_timer
      return if config.max_weeks_suspended.to_i < 1

      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        weekly_at("01:00", :tuesday, "max-weeks-suspended") do
          msg = MaxWeeksSuspendedMessage.new(gateway, config.max_weeks_suspended).to_msg
          robot.send_message(target, msg) if msg
        end
      end
    end

    def start_no_org_unit_timer
      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        weekly_at("01:00", :wednesday, "no-org-unit") do
          msg = NoOrgUnitMessage.new(gateway).to_msg
          robot.send_message(target, msg) if msg
        end
      end
    end

    def start_two_factor_timer
      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        weekly_at("01:00", :friday, "two-factor") do
          msg = TwoFactorMessage.new(gateway).to_msg
          robot.send_message(target, msg) if msg
        end
      end
    end

    def every_with_logged_errors(interval, &block)
      logged_errors do
        every(interval, &block)
      end
    end

    def logged_errors(&block)
      yield
    rescue Exception => e
      puts "Error in timer loop: #{e.inspect}"
    end

    def sliding_window
      @sliding_window ||= Lita::Timing::SlidingWindow.new("last_activity_list_at", redis)
    end

    def weekly_at(time, day, name, &block)
      Lita::Timing::Scheduled.new(name, redis).weekly_at(time, day, &block)
    end

    def list_activities(window_start, window_end)
      activities = gateway.admin_activities(window_start, window_end)
      activities.sort_by(&:time).map(&:to_msg).each_with_index do |message, index|
        after(index) do
          robot.send_message(target, message)
        end
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
        acting_as_email: config.user_email
      )
    end

    Lita.register_handler(self)
  end
end
