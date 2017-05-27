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

    # Authentication commands - each user is required to run these before they can interact with
    # the Google API
    route(/^googleapps auth$/, :start_auth, command: true, help: {"googleapps auth" => "Initiate the first of two steps required to authorise the current user wth Google"})
    route(/^googleapps set-token (.+)$/, :set_token, command: true, help: {"googleapps set-token <token>" => "The second and final step required to authorise the current user with Google. Run 'googleapps auth' first"})

    # Instant queries. Authenticated users can run these commands and the result will be returned
    # immediately
    route(/^googleapps list-admins$/, :list_admins, command: true,  help: {"googleapps list-admins" => "List active admins"})
    route(/^googleapps suspension-candidates$/, :suspension_candidates, command: true, help: {"googleapps suspension-candidates" => "List active users that habven't signed in for a while"})
    route(/^googleapps deletion-candidates$/, :deletion_candidates, command: true,  help: {"googleapps deletion-candidates" => "List suspended users that habven't signed in for a while"})
    route(/^googleapps no-ou$/, :no_org_unit, command: true,  help: {"googleapps no-ou" => "List users that aren't assigned to an Organisation Unit"})
    route(/^googleapps empty-groups$/, :empty_groups, command: true,  help: {"googleapps empty-groups" => "List groups with no users"})
    route(/^googleapps two-factor-stats$/, :two_factor_stats, command: true,  help: {"googleapps two-factor-stats" => "Display stats on option of two factor authentication"})
    route(/^googleapps two-factor-off (.+)$/, :two_factor_off, command: true,  help: {"googleapps two-factor-off <OU path>" => "List users from the OU path with two factor authentication off"})

    # Control a schedule of automated commands to run in specific channels
    route(/^googleapps schedule list$/, :schedule_list, command: true, help: {"googleapps schedule list" => "Print the list of scheduled googleapps commands for the current channel"})
    route(/^googleapps schedule commands$/, :schedule_commands, command: true, help: {"googleapps schedule commands" => "Print the list of commands available for scheduling"})
    route(/^googleapps schedule add-weekly (.+) (\d\d:\d\d) (.+)$/, :schedule_add_weekly, command: true, help: {"googleapps schedule add-weekly <day> <HH:MM> <cmd>" => "Add a new weekly scheduled command. Run 'googleapps schedule commands' to see the available commands"})
    route(/^googleapps schedule add-window (.+)$/, :schedule_add_window, command: true, help: {"googleapps schedule add-window <cmd>" => "Add a new scheduled window command"})
    route(/^googleapps schedule del (.+)$/, :schedule_delete, command: true, help: {"googleapps schedule del <cmd-id>" => "Delete a scheduled command. Requires a command ID, which is printed in 'googleapps schedule list' output"})

    on :loaded, :start_timers

    def start_timers(payload)
      weekly_commands_timer
      window_commands_timer
    end

    def deletion_candidates(response)
      return unless confirm_user_authenticated(response)

      Commands::DeletionCandidates.new.run_manual(
        robot,
        response.room,
        gateway(response.user)
      )
    end

    def empty_groups(response)
      return unless confirm_user_authenticated(response)

      Commands::EmptyGroups.new.run_manual(
        robot,
        response.room,
        gateway(response.user)
      )
    end

    def list_admins(response)
      return unless confirm_user_authenticated(response)

      Commands::ListAdmins.new.run_manual(
        robot,
        response.room,
        gateway(response.user)
      )
    end

    def no_org_unit(response)
      return unless confirm_user_authenticated(response)

      Commands::NoOrgUnit.new.run_manual(
        robot,
        response.room,
        gateway(response.user)
      )
    end

    def suspension_candidates(response)
      return unless confirm_user_authenticated(response)

      Commands::SuspensionCandidates.new.run_manual(
        robot,
        response.room,
        gateway(response.user)
      )
    end

    def two_factor_off(response)
      return unless confirm_user_authenticated(response)

      ou_path = response.match_data[1].to_s
      Commands::TwoFactorOff.new(ou_path).run_manual(
        robot,
        response.room,
        gateway(response.user)
      )
    end

    def two_factor_stats(response)
      return unless confirm_user_authenticated(response)

      Commands::TwoFactorStats.new.run_manual(
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
    rescue StandardError => e
      response.reply("Error: #{e.class} #{e.message}")
    end

    def set_token(response)
      auth_code = response.match_data[1].to_s

      google_authorizer.get_and_store_credentials_from_code(user_id: response.user.id, code: auth_code, base_url: OOB_OAUTH_URI)
      response.reply("#{response.user.name} now authorized")
    rescue StandardError => e
      response.reply("Error: #{e.class} #{e.message}")
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
    rescue StandardError => e
      response.reply("Error: #{e.class} #{e.message}")
    end

    def schedule_commands(response)
      msg = "The following commands are available for scheduling weekly:\n\n"
      COMMANDS.each do |cmd_name, cmd_klass|
        msg += "- #{cmd_name}\n"
      end
      msg += "The following commands are available for scheduling for sliding windows:\n\n"
      WINDOW_COMMANDS.each do |cmd_name, cmd_klass|
        msg += "- #{cmd_name}\n"
      end
      response.reply(msg)
    rescue StandardError => e
      response.reply("Error: #{e.class} #{e.message}")
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
        redis.hmset("weekly-schedule", schedule.id, schedule.to_json)
        response.reply("scheduled command")
      else
        response.reply("invalid command")
      end
    rescue StandardError => e
      response.reply("Error: #{e.class} #{e.message}")
    end

    def schedule_add_window(response)
      return unless confirm_user_authenticated(response)

      cmd_name = response.match_data[1].to_s
      schedule = WindowSchedule.new(
        id: SecureRandom.hex(3),
        cmd: WINDOW_COMMANDS.fetch(cmd_name.downcase, nil),
        user_id: response.user.id,
        room_name: response.room.name,
      )
      if schedule.valid?
        redis.hmset("window-schedule", schedule.id, schedule.to_json)
        response.reply("scheduled command")
      else
        response.reply("invalid command")
      end
    rescue StandardError => e
      response.reply("Error: #{e.class} #{e.message}")
    end

    def schedule_delete(response)
      return unless confirm_user_authenticated(response)

      cmd_id = response.match_data[1].to_s

      count = redis.hdel("weekly-schedule", cmd_id)
      count += redis.hdel("window-schedule", cmd_id)
      if count > 0
        response.reply("scheduled command #{cmd_id} deleted")
      else
        response.reply("no scheduled command with ID #{cmd_id} found")
      end
    rescue StandardError => e
      response.reply("Error: #{e.class} #{e.message}")
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

    def weekly_commands
      redis.hgetall("weekly-schedule").map { |_id, data|
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

    def window_commands
      redis.hgetall("window-schedule").map { |_id, data|
        JSON.parse(data)
      }.map { |data|
        WindowSchedule.new(
          id: data.fetch("id", nil),
          room_name: data.fetch("room_name", nil),
          user_id: data.fetch("user_id", nil),
          cmd: WINDOW_COMMANDS.fetch(data.fetch("cmd", nil), nil),
        )
      }.select { |schedule|
        schedule.valid?
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
      Commands::ListAdmins,
      Commands::EmptyGroups,
      Commands::NoOrgUnit,
      Commands::TwoFactorOff,
      Commands::TwoFactorStats,
      Commands::SuspensionCandidates,
      Commands::DeletionCandidates,
    ].map { |cmd|
      [cmd.new.name, cmd]
    }.to_h

    WINDOW_COMMANDS = [
      Commands::ListActivities
    ].map { |cmd|
      [cmd.new.name, cmd]
    }.to_h

  end
end
