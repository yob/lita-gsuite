require 'lita/google_activity'
require 'lita/google_group'
require 'lita/google_organisation_unit'
require 'lita/google_user'
require 'google/apis/admin_directory_v1'
require 'google/apis/admin_reports_v1'

module Lita
  # Wrapper class for interacting with the google apps directory API. Use
  # this to list users, groups, group members.
  #
  # It only has read-only permissions, so cannot make any changes.
  #
  # Usage:
  #
  #     gateway = GoogleAppsGateway.new(
  #       service_account_json: '{"foo":"bar"}',
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

    def initialize(acting_as_email:, service_account_json:, service_account_email: nil, service_account_key: nil, service_account_secret: nil, domains: nil)
      @service_account_json = service_account_json
      @acting_as_email = acting_as_email
      if service_account_email
        $stderr.puts "WARN: GoogleAppsGateway.new no longer requires the service_account_email, option"
      end
      if service_account_key
        $stderr.puts "WARN: GoogleAppsGateway.new no longer requires the service_account_key, option"
      end
      if service_account_secret
        $stderr.puts "WARN: GoogleAppsGateway.new no longer requires the service_account_secret, option"
      end
      if domains
        $stderr.puts "WARN: GoogleAppsGateway.new no longer requires the domains option"
      end
    end

    def admin_activities(start_time, end_time)
      data = reports_service.list_activities("all", "admin", start_time: start_time.iso8601, end_time: end_time.iso8601)
      data.items.map { |item|
        GoogleActivity.from_api(item)
      }.flatten
    end

    # return an Array of all groups
    def groups
      data = directory_service.list_groups(max_results: 500, customer: "my_customer")
      data.groups.map { |group|
        GoogleGroup.from_api(group)
      }
    end

    def organisational_units
      data = directory_service.list_org_units("my_customer", type: "children")
      data.organization_units.map { |ou|
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
      data = directory_service.list_users(max_results: 500, customer: "my_customer", query: query)
      data.users.map { |user|
        GoogleUser.from_api_user(user)
      }
    end

    def google_authorization
			authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        "json_key_io": StringIO.new(@service_account_json),
        "scope": OAUTH_SCOPES.join(" ")
			)
      authorization.sub = @acting_as_email
			authorization.fetch_access_token!
			authorization
    end

    def directory_service
      @directory_service ||= Google::Apis::AdminDirectoryV1::DirectoryService.new.tap { |service|
        service.authorization = google_authorization
      }
    end

    def reports_service
      @reports_service ||= Google::Apis::AdminReportsV1::ReportsService.new.tap { |service|
        service.authorization = google_authorization
      }
    end

  end
end
