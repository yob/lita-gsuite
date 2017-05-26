require "lita"
require "lita-timing"
require 'googleauth'
require 'googleauth/stores/redis_token_store'
require 'securerandom'

module Lita
  class Googleapps < Handler
    TIMER_INTERVAL = 60
    OOB_OAUTH_URI = 'urn:ietf:wg:oauth:2.0:oob'
    MAX_SCHEDULES = 50

    config :oauth_client_id
    config :oauth_client_secret

    route(/^googleapps list-admins$/, :list_admins, command: true,  help: {"googleapps list-admins" => "List active admins"})
    route(/^googleapps suspension-candidates$/, :suspension_candidates, command: true, help: {"googleapps suspension-candidates" => "List active users that habven't signed in for a while"})
    route(/^googleapps deletion-candidates$/, :deletion_candidates, command: true,  help: {"googleapps deletion-candidates" => "List suspended users that habven't signed in for a while"})
    route(/^googleapps no-ou$/, :no_org_unit, command: true,  help: {"googleapps no-ou" => "List users that aren't assigned to an Organisation Unit"})
    route(/^googleapps empty-groups$/, :empty_groups, command: true,  help: {"googleapps empty-groups" => "List groups with no users"})
    route(/^googleapps two-factor-stats$/, :two_factor_stats, command: true,  help: {"googleapps two-factor-stats" => "Display stats on option of two factor authentication"})
    route(/^googleapps two-factor-off (.+)$/, :two_factor_off, command: true,  help: {"googleapps two-factor-off <OU path>" => "List users from the OU path with two factor authentication off"})

    route(/^googleapps auth$/, :start_auth, command: true)
    route(/^googleapps set-token (.+)$/, :set_token, command: true)
    route(/^googleapps schedule list$/, :schedule_list, command: true)
    route(/^googleapps schedule commands$/, :schedule_commands, command: true)
    route(/^googleapps schedule add-weekly (.+) (\d\d:\d\d) (.+)$/, :schedule_add_weekly, command: true, help: {"googleapps schedule add-weekly <day> <HH:MM> <cmd>" => "Add a new googleapps schedule"})
    route(/^googleapps schedule add-window (.+)$/, :schedule_add_window, command: true, help: {"googleapps schedule add-window <cmd>" => "Add a new googleapps schedule"})

    on :loaded, :start_timers

    def start_timers(payload)
      weekly_commands_timer
      window_commands_timer
    end

    def deletion_candidates(response)
      return unless confirm_user_authenticated(response)

      DeletionCandidatesCommand.new.run_manual(
        robot,
        response.room,
        gateway(response.user)
      )
    end

    def empty_groups(response)
      return unless confirm_user_authenticated(response)

      EmptyGroupsCommand.new.run_manual(
        robot,
        response.room,
        gateway(response.user)
      )
    end

    def list_admins(response)
      return unless confirm_user_authenticated(response)

      ListAdminsCommand.new.run_manual(
        robot,
        response.room,
        gateway(response.user)
      )
    end

    def no_org_unit(response)
      return unless confirm_user_authenticated(response)

      NoOrgUnitCommand.new.run_manual(
        robot,
        response.room,
        gateway(response.user)
      )
    end

    def suspension_candidates(response)
      return unless confirm_user_authenticated(response)

      SuspensionCandidatesCommand.new.run_manual(
        robot,
        response.room,
        gateway(response.user)
      )
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

      TwoFactorStatsCommand.new.run_manual(
        robot,
        response.room,
        gateway(response.user)
      )
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

    def schedule_list(response)
      room_commands = (weekly_commands_for_room(response.room.name) + window_commands_for_room(response.room.name)).select { |cmd|
        cmd.room_name == response.room.name
      }
      if room_commands.any?
        room_commands.each do |cmd|
          response.reply("#{cmd.human}")
        end
      else
        response.reply("no scheduled commands for this room")
      end
    end

    def schedule_commands(response)
      msg = "The following commands are available for scheduling:\n\n"
      COMMANDS.each do |cmd_name, cmd_klass|
        msg += "- #{cmd_name}\n"
      end
      response.reply(msg)
    end

    def schedule_add_weekly(response)
      return unless confirm_user_authenticated(response)

      _, day, time, cmd_name = *response.match_data

      schedule = WeeklySchedule.new(
        id: SecureRandom.hex(3),
        day: day,
        time: time,
        cmd: COMMANDS.fetch(cmd_name.downcase, nil),
        user_id: response.user.id,
        room_name: response.room.name,
      )
      if schedule.valid?
        redis.rpush("weekly-schedule", schedule.to_json)
        response.reply("scheduled command")
      else
        response.reply("invalid command")
      end
    end

    def schedule_add_window(response)
      return unless confirm_user_authenticated(response)

      data = {
        id: SecureRandom.hex(3),
        cmd: response.match_data[1].to_s,
        user_id: response.user.id,
        room_name: response.room.name,
      }
      redis.rpush("window-schedule", JSON.dump(data))
      response.reply("scheduled command")
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
          weekly_at(cmd.time, cmd.day, "#{cmd.id}-#{cmd.name}") do
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
          sliding_window ||= Lita::Timing::SlidingWindow.new("#{cmd.id}-#{cmd.name}", redis)
          sliding_window.advance(duration_minutes: cmd.duration_minutes, buffer_minutes: cmd.buffer_minutes) do |window_start, window_end|
            cmd.run(robot, target, gateway(user), window_start, window_end)
          end
        end
      end
    end

    class ListAdminsCommand

      def name
        'list-admins'
      end

      def run(robot, target, gateway)
        msg = AdminListMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
      end

      def run_manual(robot, target, gateway)
        msg = AdminListMessage.new(gateway).to_msg
        if msg
          robot.send_message(target, msg) if msg
        else
          robot.send_message(target, "No admins found")
        end
      end
    end

    class EmptyGroupsCommand

      def name
        'empty-groups'
      end

      def run(robot, target, gateway)
        msg = EmptyGroupsMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
      end

      def run_manual(robot, target, gateway)
        msg = EmptyGroupsMessage.new(gateway).to_msg
        if msg
          robot.send_message(target, msg) if msg
        else
          robot.send_message(target, "No groups found")
        end
      end
    end

    class NoOrgUnitCommand

      def name
        'no-org-unit'
      end

      def run(robot, target, gateway)
        msg = NoOrgUnitMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
      end

      def run_manual(robot, target, gateway)
        msg = NoOrgUnitMessage.new(gateway).to_msg
        if msg
          robot.send_message(target, msg) if msg
        else
          robot.send_message(target, "No users are missing an org unit")
        end
      end
    end

    class TwoFactorStatsCommand

      def name
        'two-factor-stats'
      end

      def run(robot, target, gateway)
        msg = TwoFactorMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
      end

      def run_manual(robot, target, gateway)
        msg = TwoFactorMessage.new(gateway).to_msg
        if msg
          robot.send_message(target, msg) if msg
        else
          robot.send_message(target, "No stats found")
        end
      end
    end

    class SuspensionCandidatesCommand
      MAX_WEEKS_WITHOUT_LOGIN = 8

      def name
        'suspension-candidates'
      end

      def run(robot, target, gateway)
        return if @max_weeks_without_login < 1

        msg = MaxWeeksWithoutLoginMessage.new(gateway, MAX_WEEKS_WITHOUT_LOGIN).to_msg
        robot.send_message(target, msg) if msg
      end

      def run_manual(robot, target, gateway)
        msg = MaxWeeksWithoutLoginMessage.new(gateway, MAX_WEEKS_WITHOUT_LOGIN).to_msg
        if msg
          robot.send_message(target, msg) if msg
        else
          robot.send_message(target, "No users found")
        end
      end
    end

    class DeletionCandidatesCommand
      MAX_WEEKS_SUSPENDED = 26

      def name
        'deletion-candidates'
      end

      def run(robot, target, gateway)
        return if @max_weeks_suspended < 1

        msg = MaxWeeksSuspendedMessage.new(gateway, MAX_WEEKS_SUSPENDED).to_msg
        robot.send_message(target, msg) if msg
      end

      def run_manual(robot, target, gateway)
        msg = MaxWeeksSuspendedMessage.new(gateway, MAX_WEEKS_SUSPENDED).to_msg
        if msg
          robot.send_message(target, msg) if msg
        else
          robot.send_message(target, "No users found")
        end
      end
    end

    class ListActivitiesCommand

      def name
        'list-activities'
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

    class WeeklySchedule
      attr_reader :id, :room_name, :user_id, :day, :time, :cmd

      def initialize(id:, room_name:, user_id:, day:, time:, cmd:)
        @id = id
        @room_name, @user_id = room_name, user_id
        @day, @time = day.to_s.to_sym, time.to_s
        @cmd = cmd.new if cmd
      end

      def name
        @cmd.name
      end

      def run(*args)
        @cmd.run(*args)
      end

      def valid?
        room_name && user_id && valid_day? && valid_time?
      end

      def to_json
        {
          id: @id,
          day: @day,
          time: @time,
          cmd: @cmd.name,
          user_id: @user_id,
          room_name: @room_name,
        }.to_json
      end

      def human
        "Weekly: #{@day} #{@time} - #{@cmd.name}"
      end

      private

      def valid_day?
        [:monday, :tuesday, :wednesday, :thursday, :saturday, :sunday].include?(day)
      end

      def valid_time?
        time.match(/\A\d\d:\d\d\Z/)
      end

      def valid_cmd?
        cmd.respond_to?(:run)
      end
    end

    class WindowSchedule
      attr_reader :id, :room_name, :user_id, :cmd

      def initialize(id:, room_name:, user_id:, cmd:)
        @id = id
        @room_name, @user_id = room_name, user_id
        @cmd = cmd
      end

      def duration_minutes
        @cmd.duration_minutes
      end

      def buffer_minutes
        @cmd.buffer_minutes
      end

      def name
        @cmd.name
      end

      def run(*args)
        @cmd.run(*args)
      end

      def human
        "Sliding Window: #{@cmd.name}"
      end
    end

    def weekly_commands_for_room(room_name)
      weekly_commands.select { |cmd|
        cmd.room_name == room_name
      }
    end

    def window_commands_for_room(room_name)
      window_commands.select { |cmd|
        cmd.room_name == room_name
      }
    end

    #  WeeklySchedule.new(day: :wednesday, time: "01:00", room_name: "shell", user_id: "1", cmd: EmptyGroupsCommand.new),
    #  WeeklySchedule.new(day: :thursday, time: "01:00", room_name: "shell", user_id: "1", cmd: ListAdminsCommand.new),
    #  WeeklySchedule.new(day: :wednesday, time: "01:00", room_name: "shell", user_id: "1", cmd: NoOrgUnitCommand.new),
    #  WeeklySchedule.new(day: :friday, time: "01:00", room_name: "shell", user_id: "1", cmd: TwoFactorStatsCommand.new),
    #  WeeklySchedule.new(day: :tuesday, time: "01:00", room_name: "shell", user_id: "1", cmd: SuspensionCandidatesCommand.new),
    #  WeeklySchedule.new(day: :tuesday, time: "01:00", room_name: "shell", user_id: "1", cmd: DeletionCandidatesCommand.new),
    def weekly_commands
      redis.lrange("weekly-schedule", 0, MAX_SCHEDULES - 1).map { |data|
        JSON.parse(data)
      }.map { |data|
        WeeklySchedule.new(
          id: data.fetch("id", "foo"),
          day: data.fetch("day", nil),
          time: data.fetch("time", "12:00"),
          room_name: data.fetch("room_name", nil),
          user_id: data.fetch("user_id", nil),
          cmd: COMMANDS.fetch(data.fetch("cmd", nil), nil),
        )
      }.select { |schedule|
        schedule.valid?
      }
    end

    # WindowSchedule.new(id: SecureRandom.hex(3), room_name: "shell", user_id: "1", cmd: ListActivitiesCommand.new)
    def window_commands
      redis.lrange("window-schedule", 0, MAX_SCHEDULES - 1).map { |data|
        JSON.parse(data)
      }.map { |data|
        WindowSchedule.new(
          id: data.fetch("id", "foo"),
          room_name: data.fetch("room_name", nil),
          user_id: data.fetch("user_id", nil),
          cmd: ListActivitiesCommand.new
        )
      }
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

    def gateway(user)
      Lita::GoogleAppsGateway.new(
        user_authorization: google_authorizer.get_credentials(user.id)
      )
    end

    Lita.register_handler(self)

    # TODO move to the top of this class
    COMMANDS = [
			ListAdminsCommand,
			EmptyGroupsCommand,
			NoOrgUnitCommand,
			TwoFactorStatsCommand,
			SuspensionCandidatesCommand,
			DeletionCandidatesCommand,
    ].map { |cmd|
      [cmd.new.name, cmd]
    }.to_h

  end
end
