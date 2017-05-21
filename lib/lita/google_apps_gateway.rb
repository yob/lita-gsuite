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
  #       user_authorization: auth
  #     )
  #
  # The user_authorization argument should be an auth object generated
  # the googleauth gem - check its documentation for more details on the
  # ways to build one of these objects.
  #
  class GoogleAppsGateway
    OAUTH_SCOPES = [
      "https://www.googleapis.com/auth/admin.directory.user.readonly",
      "https://www.googleapis.com/auth/admin.directory.orgunit.readonly",
      "https://www.googleapis.com/auth/admin.reports.audit.readonly",
      "https://www.googleapis.com/auth/admin.directory.group.readonly"
    ]

    def initialize(user_authorization: nil)
      @user_authorization = user_authorization
    end

    def admin_activities(start_time, end_time)
      data = reports_service.list_activities("all", "admin", start_time: start_time.iso8601, end_time: end_time.iso8601)
      activities = data.items || []
      activities.map { |item|
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

    def directory_service
      @directory_service ||= Google::Apis::AdminDirectoryV1::DirectoryService.new.tap { |service|
        service.authorization = @user_authorization
      }
    end

    def reports_service
      @reports_service ||= Google::Apis::AdminReportsV1::ReportsService.new.tap { |service|
        service.authorization = @user_authorization
      }
    end

  end
end
