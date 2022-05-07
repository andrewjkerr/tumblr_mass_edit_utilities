# typed: strict

# require our gems!
require 'date'
require 'optparse'
require 'sorbet-runtime'
require 'tumblr_client'
require 'yaml'

# require our libs!
require_relative('lib/config.rb')
require_relative('lib/page_query_params.rb')
require_relative('lib/options.rb')
require_relative('lib/post.rb')
require_relative('lib/response.rb')
require_relative('lib/stats.rb')
require_relative('lib/tumblr_api_credential.rb')
require_relative('lib/tumblr_client.rb')

# define the namespace for our commands
module Command; end

# load in our commands!
require_relative('command/privatize_posts.rb')