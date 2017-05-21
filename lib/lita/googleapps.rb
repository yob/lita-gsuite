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
      weekly_commands_timer
      window_commands_timer
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

    def weekly_commands_timer
      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        weekly_commands.each do |cmd|
          weekly_at(cmd.time, cmd.day, cmd.name) do
            target = Source.new(room: Lita::Room.find_by_name(cmd.room_name) || "general")
            user = Lita::User.find_by_id(cmd.user_id)
            cmd.run(robot, target, gateway(user))
          end
        end
      end
    end

    def window_commands_timer
      every_with_logged_errors(TIMER_INTERVAL) do |timer|
        window_commands.each do |cmd|
          target = Source.new(room: Lita::Room.find_by_name(cmd.room_name) || "general")
          user = Lita::User.find_by_id(cmd.user_id)
          sliding_window ||= Lita::Timing::SlidingWindow.new(cmd.name, redis)
          sliding_window.advance(duration_minutes: cmd.duration_minutes, buffer_minutes: cmd.buffer_minutes) do |window_start, window_end|
            cmd.run(robot, target, gateway(user), window_start, window_end)
          end
        end
      end
    end

    class ListAdminsCommand
      attr_reader :room_name, :user_id, :day, :time

      def initialize(room_name:, user_id:, day:, time:)
        @room_name, @user_id = room_name, user_id
        @day, @time = day, time
      end

      def name
        'admin-list'
      end

      def run(robot, target, gateway)
        msg = AdminListMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
      end
    end


    class EmptyGroupsCommand
      attr_reader :room_name, :user_id, :day, :time

      def initialize(room_name:, user_id:, day:, time:)
        @room_name, @user_id = room_name, user_id
        @day, @time = day, time
      end

      def name
        'empty-groups'
      end

      def run(robot, target, gateway)
        msg = EmptyGroupsMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
      end
    end

    class NoOrgUnitCommand
      attr_reader :room_name, :user_id, :day, :time

      def initialize(room_name:, user_id:, day:, time:)
        @room_name, @user_id = room_name, user_id
        @day, @time = day, time
      end

      def name
        'no-org-unit'
      end

      def run(robot, target, gateway)
        msg = NoOrgUnitMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
      end
    end

    class TwoFactorStatsCommand
      attr_reader :room_name, :user_id, :day, :time

      def initialize(room_name:, user_id:, day:, time:)
        @room_name, @user_id = room_name, user_id
        @day, @time = day, time
      end

      def name
        'two-factor'
      end

      def run(robot, target, gateway)
        msg = TwoFactorMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
      end
    end

    class SuspensionCandidatesCommand
      attr_reader :room_name, :user_id, :day, :time

      def initialize(room_name:, user_id:, day:, time:, max_weeks_without_login:)
        @room_name, @user_id = room_name, user_id
        @day, @time = day, time
        @max_weeks_without_login = max_weeks_without_login.to_i
      end

      def name
        'max-weeks-with-login'
      end

      def run(robot, target, gateway)
        return if @max_weeks_without_login < 1

        msg = MaxWeeksWithoutLoginMessage.new(gateway, @max_weeks_without_login).to_msg
        robot.send_message(target, msg) if msg
      end
    end

    class DeletionCandidatesCommand
      attr_reader :room_name, :user_id, :day, :time

      def initialize(room_name:, user_id:, day:, time:, max_weeks_suspended:)
        @room_name, @user_id = room_name, user_id
        @day, @time = day, time
        @max_weeks_suspended = max_weeks_suspended.to_i
      end

      def name
        'max-weeks-suspended'
      end

      def run(robot, target, gateway)
        return if @max_weeks_suspended < 1

        msg = MaxWeeksSuspendedMessage.new(gateway, @max_weeks_suspended).to_msg
        robot.send_message(target, msg) if msg
      end
    end

    class ListActivitiesCommand
      attr_reader :room_name, :user_id, :day, :time

      def initialize(room_name:, user_id:)
        @room_name, @user_id = room_name, user_id
      end

      def name
        'last_activity_list_at'
      end

      def duration_minutes
        30
      end

      def buffer_minutes
        30
      end

      def run(robot, target, gateway, window_start, window_end)
        puts "run: #{window_start} #{window_end}"
        activities = gateway.admin_activities(window_start, window_end)
        activities.sort_by(&:time).map(&:to_msg).each_with_index do |message, index|
          robot.send_message(target, message)
          sleep(1) # TODO ergh. required to stop slack disconnecting us for high sending rates
        end
      end
    end

    def weekly_commands
      [
        EmptyGroupsCommand.new(room_name: "google-admin", user_id: "1", day: :wednesday, time: "01:00"),
        ListAdminsCommand.new(room_name: "google-admin", user_id: "1", day: :thursday, time: "01:00"),
        NoOrgUnitCommand.new(room_name: "google-admin", user_id: "1", day: :wednesday, time: "01:00"),
        TwoFactorStatsCommand.new(room_name: "google-admin", user_id: "1", day: :friday, time: "01:00"),
        SuspensionCandidatesCommand.new(room_name: "google-admin", user_id: "1", day: :tuesday, time: "01:00", max_weeks_without_login: config.max_weeks_without_login),
        DeletionCandidatesCommand.new(room_name: "google-admin", user_id: "1", day: :tuesday, time: "01:00", max_weeks_suspended: config.max_weeks_suspended),
      ]
    end

    def window_commands
      [
        ListActivitiesCommand.new(room_name: "google-admin", user_id: "1"),
      ]
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

    def weekly_at(time, day, name, &block)
      Lita::Timing::Scheduled.new(name, redis).weekly_at(time, day, &block)
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
