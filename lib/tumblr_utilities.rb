# typed: strict

# require our gems!
require 'date'
require 'optparse'
require 'sorbet-runtime'
require 'tumblr_client'
require 'yaml'

# require our libs!
require_relative('lib/command.rb')
require_relative('lib/config.rb')
require_relative('lib/page_query_params.rb')
require_relative('lib/post.rb')
require_relative('lib/response.rb')
require_relative('lib/stats.rb')
require_relative('lib/tumblr_api_credential.rb')
require_relative('lib/tumblr_client.rb')

# load options last since it might include structs from above ^
require_relative('lib/options.rb')

# load in our commands!
# load this one first
require_relative('command/base/iterate_through_posts.rb')

# and then these
require_relative('command/privatize_posts.rb')
require_relative('command/snooze_live.rb')
require_relative('command/update_community_labels.rb')
