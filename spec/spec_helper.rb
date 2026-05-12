# typed: strict
require 'date'
require 'optparse'
require 'sorbet-runtime'
require 'tumblr_client'
require 'yaml'

require_relative('../lib/lib/command.rb')
require_relative('../lib/lib/config.rb')
require_relative('../lib/lib/page_query_params.rb')
require_relative('../lib/lib/post.rb')
require_relative('../lib/lib/response.rb')
require_relative('../lib/lib/stats.rb')
require_relative('../lib/lib/tumblr_api_credential.rb')
require_relative('../lib/lib/tumblr_client.rb')
require_relative('../lib/lib/options.rb')

require_relative('../lib/command/base/iterate_through_likes.rb')
require_relative('../lib/command/base/iterate_through_posts.rb')
require_relative('../lib/command/clear_likes.rb')
require_relative('../lib/command/privatize_posts.rb')
require_relative('../lib/command/update_community_labels.rb')

RSpec.configure do |config|
  config.before(:each) { allow($stdout).to receive(:puts) }
end
