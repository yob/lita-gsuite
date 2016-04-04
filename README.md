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

Second, the domains that are in use in your google apps accounts:

    config.handlers.googleapps.domains = ["example.com"]

Next, an administrators email address. The API requires this, even though
we're only make read-only requests.

    config.handlers.googleapps.user_email = ENV["GOOGLE_USER_EMAIL"]

There's 3 values required for authentication. See "Authentication" below for more
details on these values.

    config.handlers.googleapps.service_account_email = ENV["GOOGLE_SERVICE_ACCOUNT_EMAIL"]
    config.handlers.googleapps.service_account_key = ENV["GOOGLE_SERVICE_ACCOUNT_KEY"]
    config.handlers.googleapps.service_account_secret = ENV["GOOGLE_SERVICE_ACCOUNT_SECRET"]

Finally, there's two optional settings that configure how long user accounts
can be inactive before being flagged.

    config.handlers.googleapps.max_weeks_without_login = 8
    config.handlers.googleapps.max_weeks_suspended = 26

## Authentication

The lita handler will be connecting to Google APIs on your behalf, which
requires a "Service Account". These can be created on the [Google Developers
Console](https://console.developers.google.com/), and Google has [some
documentation](https://developers.google.com/identity/protocols/OAuth2ServiceAccount#creatinganaccount).

Note the "Service account ID", and use it as the "service\_account\_email" config value.

You should also be given the opportunity to create a new private key. Be sure to select
the "P12" format. Save it to a file called "google.key", and then run the following
command:

    ruby -rbase64 -e "puts Base64.encode64(File.read('google.key'))" > google-base64.key

The content of google-base64.key should be used for the "service\_account\_key"
config value.

Finally, you should be provided with an automatically generated password that
can be used for the "service\_account\_secret" config value.

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
     https://www.googleapis.com/auth/admin.reports.usage.readonly,
     https://www.googleapis.com/auth/admin.reports.audit.readonly,

6. Click authorize

## Chat commands

This handler provides no additional chat commands.

## Periodic Updates

### Admin Activity

Every 30 minutes, any admin activities that have occurred to the Google Apps
account (new user, delete user, new group, password reset, etc) will be listed.

### Administrators

Each week, users with super or delegated administrative privileges will be
listed.

### Empty Groups

Each week, groups with no members will be listed.

### Inactive Users

If the optional max\_weeks\_without\_login config is set to 1 or higher, each
week active users that haven't logged in for that many weeks will be listed.
This may be helpful for identifying accounts that should be suspended or
deleted.

### Suspended Users

If the optional max\_weeks\_suspended config is set to 1 or higher, each
week suspended users that haven't logged in for that many weeks will be listed. This may
be helpful for identifying accounts that have been suspended for a long time and
may be candidates for deletion.

### User with No Organisational Unit

Each week, users not assigned to an Organisational Unit will be listed.

### Second Factor Authentication

Each week, key stats on Second Factor Authentication uptake will be listed.

## TODO

Possible ideas for new features, either via chat commands or periodic updates:

* expand 2fa uptake report to include a per-OU breakdown
* improve format of admn activity messages
* split admin list in to super admins and delegated admins
* more specs
