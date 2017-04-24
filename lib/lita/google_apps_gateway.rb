require 'lita/google_activity'
require 'lita/google_group'
require 'lita/google_organisation_unit'
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
  #       acting_as_email: "admin.user@example.com"
  #     )
  #
  class GoogleAppsGateway
    OAUTH_SCOPES = [
      "https://www.googleapis.com/auth/admin.directory.user.readonly",
      "https://www.googleapis.com/auth/admin.directory.orgunit.readonly",
      "https://www.googleapis.com/auth/admin.reports.audit.readonly",
      "https://www.googleapis.com/auth/admin.directory.group.readonly"
    ]

    def initialize(service_account_email:, service_account_key:, service_account_secret:, acting_as_email:, domains: nil)
      @service_account_email = service_account_email
      @service_account_key = service_account_key
      @service_account_secret = service_account_secret
      @acting_as_email = acting_as_email
      if domains
        $stderr.puts "WARN: GoogleAppsGateway.new no longer requires the domains option"
      end
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

    # return an Array of all groups
    def groups
      result = client.execute!(api_list_groups, maxResults: 500, customer: "my_customer")
      result.data.groups.map { |group|
        GoogleGroup.from_api(group)
      }
    end

    def organisational_units
      result = client.execute!(api_list_orgunits, customerId: "my_customer", type: "children")
      result.data.organization_units.map { |ou|
        GoogleOrganisationUnit.from_api(ou)
      }
    end

    # return a list of users that have Two Factor Auth enabled
    def two_factor_users
      list_users("isEnrolledIn2Sv=true")
    end

    # return all users
    def users
      list_users
    end

    # return super administrators
    def super_admins
      list_users("isAdmin=true")
    end

    # return administrators with delegated administration of some users or groups
    def delegated_admins
      list_users("isDelegatedAdmin=true")
    end

    private

    def list_users(query = nil)
      result = client.execute!(api_list_users, maxResults: 500, customer: "my_customer", query: query)
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

    def api_list_groups
      @api_list_groups ||= directory_api.groups.list
    end

    def api_list_users
      @api_list_users ||= directory_api.users.list
    end

    def api_list_orgunits
      @api_list_orgunits ||= directory_api.orgunits.list
    end

    def api_admin_activity
      @api_user_activity ||= client.discovered_api('admin', 'reports_v1').activities.list
    end

  end
end
