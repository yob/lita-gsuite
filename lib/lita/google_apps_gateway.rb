require 'lita/google_activity'
require 'lita/google_group'
require 'lita/google_organisation_unit'
require 'lita/google_two_factor_user'
require 'lita/google_user'
require 'google/api_client'

module Lita
  # Wrapper class for interacting with the google apps directory API. Use
  # this to list users, groups, group members.
  #
  # It only has read-only permissions, so cannot make any changes.
  #
  # Usage:
  #
  #     gateway = GoogleAppsGateway.new(
  #       service_account_email: "xxx@developer.gserviceaccount.com",
  #       service_account_key: "base64 key",
  #       service_account_secret: "secret",
  #       domains: ["example.com"],
  #       acting_as_email: "admin.user@example.com"
  #     )
  #
  class GoogleAppsGateway
    OAUTH_SCOPES = [
      "https://www.googleapis.com/auth/admin.directory.user.readonly",
      "https://www.googleapis.com/auth/admin.directory.orgunit.readonly",
      "https://www.googleapis.com/auth/admin.reports.usage.readonly",
      "https://www.googleapis.com/auth/admin.reports.audit.readonly",
      "https://www.googleapis.com/auth/admin.directory.group.readonly"
    ]

    def initialize(service_account_email:, service_account_key:, service_account_secret:, domains:, acting_as_email:)
      @service_account_email = service_account_email
      @service_account_key = service_account_key
      @service_account_secret = service_account_secret
      @domains = domains
      @acting_as_email = acting_as_email
    end

    def admin_activities(start_time, end_time)
      result = client.execute!(api_admin_activity, userKey: "all",
                                                   startTime: start_time.iso8601,
                                                   endTime: end_time.iso8601,
                                                   applicationName: "admin")
      result.data.items.map { |item|
        item.events.map { |event|
          GoogleActivity.new(
            time: item.id.time,
            actor: item.actor.email,
            ip: item.ip_address,
            name: event.name,
            params: event.parameters.inject({}) { |accum, param|
              accum[param.name] = param.value
              accum
            }
          )
        }
      }.flatten
    end

    # return an Array of all groups
    def groups
      @domains.map { |domain|
        groups_for_domain(domain)
      }.flatten
    end

    # return an Array of email addresses that are in a group
    def group_members(email)
      result = client.execute!(api_group_members, groupKey: email)
      result.data.members.map(&:email)
    end

    def organisational_units
      result = client.execute!(api_ou_list, customerId: "my_customer", type: "children")
      result.data.organization_units.map { |ou|
        GoogleOrganisationUnit.new( name: ou.name, path: ou.orgUnitPath )
      }
    end

    def users
      @domains.map { |domain|
        users_for_domain(domain)
      }.flatten
    end

    # return a list of users that have Two Factor Auth enabled. Unfortunately this uses the reports
    # API, so the most recent data is 4 days old.
    def two_factor_users
      result = client.execute!(api_user_usage, userKey: "all",
                                              date: four_days_ago,
                                              filters: "accounts:is_2sv_enrolled==true")
      result.data.usage_reports.map { |item|
        GoogleTwoFactorUser.new( email: item.entity.userEmail )
      }
    end

    private

    def days_in_seconds(days)
      days.to_i * 24 * 60 * 60
    end

    def groups_for_domain(domain)
      result = client.execute!(api_list_groups, domain: domain)
      result.data.groups.map { |group|
        GoogleGroup.new(
          id: group.id,
          email: group.email,
          name: group.name,
          description: group.description,
          member_count: group.directMembersCount,
        )
      }
    end

    def users_for_domain(domain)
      result = client.execute!(api_list_users, domain: domain)
      result.data.users.map { |user|
        GoogleUser.new(
          id: user.id,
          email: user.primaryEmail,
          suspended: user.suspended,
          last_login_at: user.lastLoginTime,
          ou_path: user.orgUnitPath,
          admin: user.isAdmin,
          delegated_admin: user.isDelegatedAdmin
        )
      }
    end

    def four_days_ago
      (Time.now.utc - days_in_seconds(4)).strftime("%Y-%m-%d")
    end

    def client
      @client ||= Google::APIClient.new(
        authorization: google_authorization,
        application_name: "lita-googleapps",
        application_version: "0.1"
      )
    end

    def google_authorization
      authorization = Signet::OAuth2::Client.new(
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
        audience: 'https://accounts.google.com/o/oauth2/token',
        scope: OAUTH_SCOPES.join(" "),
        issuer: @service_account_email,
        person: @acting_as_email,
        signing_key: api_key
      )
      authorization.fetch_access_token!
      authorization
    end

    def api_key
      return if @service_account_key.nil?

      @api_key ||= Google::APIClient::KeyUtils.load_from_pkcs12(
        Base64.decode64(@service_account_key),
        @service_account_secret
      )
    end

    def api
      @api ||= client.discovered_api('admin','directory_v1')
    end

    def api_list_groups
      @api_list_groups ||= api.groups.list
    end

    def api_group_members
      @api_group_members ||= api.members.list
    end

    def api_list_users
      @api_list_users ||= api.users.list
    end

    def api_ou_list
      @api_ou_list ||= api.orgunits.list
    end

    def api_user_usage
      @api_users_usage ||= client.discovered_api('admin', 'reports_v1').user_usage_report.get
    end

    def api_admin_activity
      @api_user_activity ||= client.discovered_api('admin', 'reports_v1').activities.list
    end

  end
end
