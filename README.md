# lita-googleapps

A lita plugin for interacting with a Google Apps account.

By design, only read-only access is requested. This is intended to provide some visibility
into the account, not provide administrative functions.

This was written for a Google Apps account with ~125 active users. It may not scale
well to larger accounts, but feedback and optimisations are welcome.

## Installation

Add this gem to your lita installation by including the following line in your Gemfile:

    gem "lita-googleapps", git: "http://github.com/yob/lita-googleapps.git"

## Configuration

Edit your lita\_config.rb to include the following lines lines. Some of the
values are sensitive, so using ENV vars is recommended to keep the values out
of version control.

First, the channel to send periodic updates to:

    config.handlers.googleapps.channel_name = "general"

Next, an administrators email address. The API requires this, even though
we're only make read-only requests.

    config.handlers.googleapps.user_email = ENV["GOOGLE_USER_EMAIL"]

There's a number of values required for authentication, and the easiest way to
provide them is via a JSON blob that google provides. See "Authentication" below for more
details on these values.

    config.handlers.googleapps.service_account_json = ENV["GOOGLE_SERVICE_ACCOUNT_JSON"]

Finally, there's two optional settings that configure how long user accounts
can be inactive before being flagged.

    config.handlers.googleapps.max_weeks_without_login = 8
    config.handlers.googleapps.max_weeks_suspended = 26

## Authentication

The lita handler will be connecting to Google APIs on your behalf, which
requires a "Service Account". These can be created on the [Google Developers
Console](https://console.developers.google.com/), and Google has [some
documentation](https://developers.google.com/identity/protocols/OAuth2ServiceAccount#creatinganaccount).

You should also be given the opportunity to create a new private key. Be sure to select
the "JSON" format. Save it to a file called "google.json".

The content of google.json should then be used for the "service\_account\_json"
config value.

## Enable Google API

The Google Apps API must be explicitly enabled for your account, and the new service account
must be whitelisted before it can access any data.

1. Sign in to https://admin.google.com
2. Visit the Security tab, click "API reference" and "Enable API Access"
3. Click "Advanced settings", and "Manage API client access"
4. In Client Name, enter the "Service account ID" you generated earlier
5. In Scopes, enter the following separated by commas:

     https://www.googleapis.com/auth/admin.directory.user.readonly,
     https://www.googleapis.com/auth/admin.directory.orgunit.readonly,
     https://www.googleapis.com/auth/admin.directory.group.readonly
     https://www.googleapis.com/auth/admin.reports.audit.readonly,

6. Click authorize

## Chat commands

### Administrators

List users with super or delegated administrative privileges, and their two-factor
auth status.

    lita googleapps list-admins

### Empty Groups

List groups with no members.

    lita googleapps empty-groups

### Inactive Users

If the optional max\_weeks\_without\_login config is set to 1 or higher, list
active users that haven't logged in for that many weeks.  This may be helpful
for identifying accounts that should be suspended or deleted.

    lita googleapps suspension-candidates

### Suspended Users

If the optional max\_weeks\_suspended config is set to 1 or higher, list
suspended users that haven't logged in for that many weeks. This may be helpful
for identifying accounts that have been suspended for a long time and may be
candidates for deletion.

    lita googleapps deletion-candidates

### User with No Organisational Unit

List users not assigned to an Organisational Unit.

    lita googleapps no-ou

### Two Factor Authentication

Print key stats on Second Factor Authentication uptake.

    lita googleapps two-factor-stats

## Periodic Updates

Once per week, each of the reports listed above will automatically be sent to
the channel specified in `config.handlers.googleapps.channel_name`.

### Admin Activity

Every 30 minutes, any admin activities that have occurred to the Google Apps
account (new user, delete user, new group, password reset, etc) will be listed.

## TODO

Possible ideas for new features, either via chat commands or periodic updates:

* improve format of admn activity messages
* split admin list in to super admins and delegated admins
* more specs
