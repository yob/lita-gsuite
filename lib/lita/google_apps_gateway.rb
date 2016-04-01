require 'lita/google_activity'
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
        GoogleActivity.from_api(item)
      }.flatten
    end

    def users
      @domains.map { |domain|
        users_for_domain(domain)
      }.flatten
    end

    private

    def users_for_domain(domain)
      result = client.execute!(api_list_users, domain: domain)
      result.data.users.map { |user|
        GoogleUser.from_api_user(user)
      }
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

    def directory_api
      @api ||= client.discovered_api('admin','directory_v1')
    end

    def api_list_users
      @api_list_users ||= directory_api.users.list
    end

    def api_admin_activity
      @api_user_activity ||= client.discovered_api('admin', 'reports_v1').activities.list
    end

  end
end
