# typed: strict

require_relative('lib/tumblr_utilities.rb')

# parse our command line options and turn them into our `Options` struct to use later
options = T.let(Options.parse_options, Options)

# now, parse our application config file into our `Config` struct to also use later
config = T.let(Config.parse_config!(options.config_file), Config)

# set up our new client
client = TumblrClient.new(config.tumblr_api_credentials)

case options.command
when Command::Command::PrivatizePosts
  Command::PrivatizePosts.call(options, config, client)
when Command::Command::UpdateCommunityLabels
  Command::UpdateCommunityLabels.call(options, config, client)
else
  raise "Un-implemented command #{options.command}. Please implement the command."
end
