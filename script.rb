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
require_relative('lib/stats.rb')
require_relative('lib/tumblr_api_credential.rb')
require_relative('lib/tumblr_client.rb')

# ~ sorbet magic ~!
extend T::Sig

# parse our command line options and turn them into our `Options` struct to use later
options = T.let(Options.parse_options, Options)

# now, parse our application config file into our `Config` struct to also use later
config = T.let(Config.parse_config!(options.config_file), Config)

# set up our new client
client = TumblrClient.new(config.tumblr_api_credentials)

# Get our initial response.
page_query_params = PageQueryParams.new(
  before: options.beginning_timestamp,
  tumblelog: config.tumblr_blog_url,
)

response = client.posts(config.tumblr_blog_url, page_query_params)

# Check if we need to skip a post due to some fun edge cases.
sig {params(post: T::Hash[String, T.untyped]).returns(T::Boolean)}
def should_skip_post?(post)
  # Pinned posts are somehow always returned in this response. :/
  return true if post['is_pinned']

  # Any posts before the, uh, creation of Tumblr have a timestamp before the beginning timestamp.
  # ... don't ask. :p
  return true if Date.parse(post['date']) <= Date.new(2007, 01, 01)

  false
end

stats = T.let(Stats.new, Stats)

begin
  loop do
    # ++ loop_iterations
    stats.loop_iterations += 1
    puts "New interation: #{stats.loop_iterations}" if options.verbose

    # If there are no more posts, notify and break.
    # The API seems to, uh, have different responses. 😅
    if !response['posts'].is_a?(Array) || response['posts'].nil? || response['posts'].empty?
      puts "No more posts!" if options.verbose
      break
    end

    # Extract the posts from our API response.
    posts = response['posts']

    # Now, get only the published posts.
    posts = response['posts']
    published_posts = posts.select do |post|
      post['state'] === 'published' && !should_skip_post?(post)
    end

    # += total_posts & += published_posts
    stats.total_posts += posts.size
    stats.published_posts += published_posts.size

    # Iterate over each post and turn them to private.
    published_posts.each do |post|
      puts "Privating post #{post['id']} (#{post['post_url']})" if options.verbose
      client.edit(config.tumblr_blog_url, post['id_string'], Post::State::PRIVATE)

      # ++ posts_turned_private
      stats.posts_turned_private += 1
    end

    # Ok, now let's get the next batch of posts.
    next_page_query_params = response.dig('_links', 'next', 'query_params')

    # If we don't have a next page, break.
    if next_page_query_params.nil? || next_page_query_params.empty? || next_page_query_params.dig('page_number').nil?
      puts "No next page!" if options.verbose
      break
    end

    # update our PageQueryParams to use the page_number that is next
    page_query_params.page_number = next_page_query_params.dig('page_number')

    # andddd get the next response!
    response = client.posts(config.tumblr_blog_url, page_query_params)
  end
rescue => e
  puts "Ruh roh, we error'd! Printing stats & bailing..."
  stats.print!
  raise
end

stats.print!
puts "Done!"
