# lita-googleapps

A lita plugin for interacting a Google Apps account. 

By design, only read-only access is requested. This is intended to provide some visibility
into the account, not provide administrative functions.

This was written for a Google Apps account with ~100 active users. It may not scale
well to larger accounts, but feedback and optimisations are welcome.

## Installation

Add this gem to your lita installation by including the following line in your Gemfile:

    gem "lita-googleapps", git: "http://github.com/yob/lita-googleapps.git"

## Configuration

Edit your lita\_config.rb to include the following lines lines:

    config.handlers.googleapps.channel_name = "general"
    config.handlers.googleapps.domains = ["example.com"]
    config.handlers.googleapps.user_email = ENV["GOOGLE_USER_EMAIL"]
    config.handlers.googleapps.service_account_email = ENV["GOOGLE_SERVICE_ACCOUNT_EMAIL"]
    config.handlers.googleapps.service_account_key = ENV["GOOGLE_SERVICE_ACCOUNT_KEY"] ||
    config.handlers.googleapps.service_account_secret = ENV["GOOGLE_SERVICE_ACCOUNT_SECRET"]

TODO: describe convoluted hoops required to determine the values for these options.

## Chat commands

This handler currently provides no additional chat commands.

## Periodic Updates

### Admin Activity

Every 30 minutes, any admin activities that have occurred to the Google Apps
account (new user, delete user, new group, password reset, etc) will be listed
in the configured channel.

## TODO

Possible ideas for new features, either via chat commands or periodic updates:

* ratio of 2fa uptake
* list users that haven't signed in for some time - possible candidates for closing
* list groups with no members
* list users who have some admin privileges but don't use 2fa
* list users who have never signed in
* list users who aren't in an OU
