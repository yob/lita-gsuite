require "lita"
require "lita-timing"
require 'googleauth'
require 'googleauth/stores/redis_token_store'

module Lita
  class Googleapps < Handler
    TIMER_INTERVAL = 60
    OOB_OAUTH_URI = 'urn:ietf:wg:oauth:2.0:oob'

    config :oauth_client_id
    config :oauth_client_secret
    config :channel_name
    config :max_weeks_without_login
    config :max_weeks_suspended

    route(/^googleapps list-admins$/, :list_admins, command: true,  help: {"googleapps list-admins" => "List active admins"})
    route(/^googleapps suspension-candidates$/, :suspension_candidates, command: true, help: {"googleapps suspension-candidates" => "List active users that habven't signed in for a while"})
    route(/^googleapps deletion-candidates$/, :deletion_candidates, command: true,  help: {"googleapps deletion-candidates" => "List suspended users that habven't signed in for a while"})
    route(/^googleapps no-ou$/, :no_org_unit, command: true,  help: {"googleapps no-ou" => "List users that aren't assigned to an Organisation Unit"})
    route(/^googleapps empty-groups$/, :empty_groups, command: true,  help: {"googleapps empty-groups" => "List groups with no users"})
    route(/^googleapps two-factor-stats$/, :two_factor_stats, command: true,  help: {"googleapps two-factor-stats" => "Display stats on option of two factor authentication"})
    route(/^googleapps two-factor-off (.+)$/, :two_factor_off, command: true,  help: {"googleapps two-factor-off <OU path>" => "List users from the OU path with two factor authentication off"})

    route(/^googleapps auth$/, :start_auth, command: true)
    route(/^googleapps set-token (.+)$/, :set_token, command: true)

    on :loaded, :start_timers

    def start_timers(payload)
      start_timer_list_admins
      start_timer_suspension_candidates
      start_timer_deletion_candidates
      start_timer_no_org_unit
      start_timer_admin_activities
      start_timer_empty_groups
      start_timer_two_factor_stats
    end

    def deletion_candidates(response)
      return unless confirm_user_authenticated(response)
      return if config.max_weeks_suspended.to_i < 1

      msg = MaxWeeksSuspendedMessage.new(gateway(response.user), config.max_weeks_suspended).to_msg
      if msg
        response.reply(msg)
      else
        response.reply("No users found")
      end
    end

    def empty_groups(response)
      return unless confirm_user_authenticated(response)

      msg = EmptyGroupsMessage.new(gateway(response.user)).to_msg
      if msg
        response.reply(msg)
      else
        response.reply("No groups found")
      end
    end

    def list_admins(response)
      return unless confirm_user_authenticated(response)

      msg = AdminListMessage.new(gateway(response.user)).to_msg
      if msg
        response.reply(msg)
      else
        response.reply("No admins found")
      end
    end

    def no_org_unit(response)
      return unless confirm_user_authenticated(response)

      msg = NoOrgUnitMessage.new(gateway(response.user)).to_msg
      if msg
        response.reply(msg)
      else
        response.reply("No users found")
      end
    end

    def suspension_candidates(response)
      return unless confirm_user_authenticated(response)
      return if config.max_weeks_without_login.to_i < 1

      msg = MaxWeeksWithoutLoginMessage.new(gateway(response.user), config.max_weeks_without_login).to_msg
      if msg
        response.reply(msg)
      else
        response.reply("No users found")
      end
    end

    def two_factor_off(response)
      return unless confirm_user_authenticated(response)

      ou_path = response.match_data[1].to_s
      msg = TwoFactorOffMessage.new(gateway(response.user), ou_path).to_msg
      if msg
        response.reply(msg)
      else
        response.reply("No users found")
      end
    end

    def two_factor_stats(response)
      return unless confirm_user_authenticated(response)

      msg = TwoFactorMessage.new(gateway(response.user)).to_msg
      if msg
        response.reply(msg)
      else
        response.reply("No stats found")
      end
    end

    def start_auth(response)
      credentials = google_credentials_for_user(response.user)
      url = google_authorizer.get_authorization_url(base_url: OOB_OAUTH_URI)
      if credentials.nil?
        response.reply "Open the following URL in your browser and enter the resulting code via the 'googleapps set-token <foo>' command:\n\n#{url}"
      else
        response.reply "#{response.user.name} is already authorized with Google. To re-authorize, open the following URL in your browser and enter the resulting code via the 'googleapps set-token <foo>' command:\n\n#{url}"
      end
    end

    def set_token(response)
      auth_code = response.match_data[1].to_s

      google_authorizer.get_and_store_credentials_from_code(user_id: response.user.id, code: auth_code, base_url: OOB_OAUTH_URI)
      response.reply("#{response.user.name} now authorized")
    end

    private

    def confirm_user_authenticated(response)
      credentials = google_credentials_for_user(response.user)
      if credentials.nil?
        response.reply("#{response.user.name} not authorized with Google yet. Use the 'googleapps auth' command to initiate authorization") 
        false
      else
        true
      end
    end

    def google_credentials_for_user(user)
      google_authorizer.get_credentials(user.id)
    end

    def google_authorizer
      @google_authorizer ||= begin
        client_id = Google::Auth::ClientId.new(
          config.oauth_client_id,
          config.oauth_client_secret
        )
        token_store = Google::Auth::Stores::RedisTokenStore.new(redis: redis)
        Google::Auth::UserAuthorizer.new(client_id, GoogleAppsGateway::OAUTH_SCOPES, token_store)
      end
    end

    def start_timer_admin_activities
      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        sliding_window.advance(duration_minutes: 30, buffer_minutes: 30) do |window_start, window_end|
          list_activities(window_start, window_end)
        end
      end
    end

    def start_timer_list_admins
      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        weekly_at("01:00", :thursday, "admin-list") do
          msg = AdminListMessage.new(gateway).to_msg
          robot.send_message(target, msg) if msg
        end
      end
    end

    def start_timer_empty_groups
      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        weekly_at("01:00", :wednesday, "empty-groups") do
          msg = EmptyGroupsMessage.new(gateway).to_msg
          robot.send_message(target, msg) if msg
        end
      end
    end

    private

    def start_timer_suspension_candidates
      return if config.max_weeks_without_login.to_i < 1

      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        weekly_at("01:00", :tuesday, "max-weeks-with-login") do
          msg = MaxWeeksWithoutLoginMessage.new(gateway, config.max_weeks_without_login).to_msg
          robot.send_message(target, msg) if msg
        end
      end
    end

    def start_timer_deletion_candidates
      return if config.max_weeks_suspended.to_i < 1

      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        weekly_at("01:00", :tuesday, "max-weeks-suspended") do
          msg = MaxWeeksSuspendedMessage.new(gateway, config.max_weeks_suspended).to_msg
          robot.send_message(target, msg) if msg
        end
      end
    end

    def start_timer_no_org_unit
      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        weekly_at("01:00", :wednesday, "no-org-unit") do
          msg = NoOrgUnitMessage.new(gateway).to_msg
          robot.send_message(target, msg) if msg
        end
      end
    end

    def start_timer_two_factor_stats
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

    def gateway(user)
      Lita::GoogleAppsGateway.new(
        user_authorization: google_authorizer.get_credentials(user.id)
      )
    end

    Lita.register_handler(self)
  end
end
