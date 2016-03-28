require 'lita/google_activity'
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

    private

    def days_in_seconds(days)
      days.to_i * 24 * 60 * 60
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

    def api_admin_activity
      @api_user_activity ||= client.discovered_api('admin', 'reports_v1').activities.list
    end

  end
end
