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

When an API call to google is required, we want to make it with tokens that
are tied to the specific user that requested data. To do so, we use Google's
OAuth2 support.

That requires an OAuth2 client ID and secret - see "Authentication" below for more
details on how to generate these:

    config.handlers.googleapps.oauth_client_id = ENV["GOOGLE_CLIENT_ID"]
    config.handlers.googleapps.oauth_client_secret = ENV["GOOGLE_CLIENT_SECRET"]

## Authentication

The lita bot requires an OAuth client ID and secret before it can initiate
the process to generate an OAuth2 token for each user.

These can be created on the [Google Developers
Console](https://console.developers.google.com/), and Google has [some
documentation](https://developers.google.com/identity/protocols/OAuth2).

You should be given the opportunity to view the new ID and secret. Be sure to copy them
down, as they can't be retrieved again later.

Once the handler is configured and running, each user that wants to interact with it
will be prompted to complete an OAuth authorisation process before they can start. This
generates an API token that's specific to them and will be used to make API calls on
their behalf.

## Enable Google API

The Google Apps API must be explicitly enabled for your account, and the new service account
must be whitelisted before it can access any data.

1. Sign in to https://admin.google.com
2. Visit the Security tab, click "API reference" and "Enable API Access"

## Chat commands

### Administrators

List users with super or delegated administrative privileges, and their two-factor
auth status.

    lita googleapps list-admins

### Empty Groups

List groups with no members.

    lita googleapps empty-groups

### Inactive Users

List active users that haven't logged in for 8 weeks.  This may be helpful for
identifying accounts that should be suspended or deleted.

    lita googleapps suspension-candidates

### Suspended Users

List suspended users that haven't logged in for 26 weeks. This may be helpful
for identifying accounts that have been suspended for a long time and may be
candidates for deletion.

    lita googleapps deletion-candidates

### User with No Organisational Unit

List users not assigned to an Organisational Unit.

    lita googleapps no-ou

### Two Factor Authentication

Print key stats on Second Factor Authentication uptake.

    lita googleapps two-factor-stats

### Two Factor Authentication Disabled

Print users within an Organisational Unit that don't have Second Factor Authentication enabled.

    lita googleapps two-factor-off /OUPATH

## Periodic Updates

To help monitor the above reports automatically, it's possible to schedule them to be printed in
a channel periodically.

List the reports that will periodically print in the current channel:

    lita googleapps schedule list

List the reports that are available to print periodically:

    lita googleapps schedule commands

Schedule a weekly report in the current channel, specified in UTC time:

    lita googleapps schedule add-weekly <day-of-the-week> HH:MM <report-name>
    lita googleapps schedule add-weekly wednesday 01:00 list-admins
    lita googleapps schedule add-weekly monday 13:45 no-ou

Schedule a time-window report that will run regularly and print output when
new data is available:
    
    lita googleapps schedule add-window <report-name>
    lita googleapps schedule add-window list-activities

Delete a scheduled report from the current room. The ID can be find in th
output of "schedule list":

    lita googleapps schedule del <id>

## TODO

Possible ideas for new features, either via chat commands or periodic updates:

* improve format of admin activity messages
* split admin list in to super admins and delegated admins
* more specs
