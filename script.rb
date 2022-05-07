# typed: true

# require our gems!
require 'date'
require 'optparse'
require 'sorbet-runtime'
require 'tumblr_client'
require 'yaml'

# require our libs!
require_relative('lib/config.rb')
require_relative('lib/options.rb')
require_relative('lib/stats.rb')
require_relative('lib/tumblr_api_credential.rb')
require_relative('lib/tumblr_client.rb')

# ~ sorbet magic ~!
extend T::Sig

POST_GET_LIMIT = T.let(50, Integer)

puts 'Starting up...'

# parse our command line options and turn them into our `Options` struct to use later
@options = T.let(Options.parse_options, Options)

# now, parse our application config file into our `Config` struct to also use later
@config = T.let(Config.parse_config!(@options.config_file), Config)

# set up our new client
@client = TumblrClient.new(@config.tumblr_api_credentials)

# Set where we should begin our privatization.
begin
  start_date_date = Date.parse(@options.start_date)
rescue
  puts "Error parsing #{@options.start_date}! Please check the format to ensure it's correct."
  puts "Full error:"
  raise
end

beginning_timestamp = start_date_date.to_time.to_i

# And, set when we should *end* our privatization.
# Note: this doesn't necessarily work as expected, so proceed with caution. :p
ending_timestamp = Date.new(2006, 12, 31).to_time.to_i

# Get our initial response.
next_page_params = T.let({
  before: beginning_timestamp,
  limit: POST_GET_LIMIT,
}, T::Hash[Symbol, Integer])

response = @client.client.posts(@config.tumblr_blog_url, next_page_params)

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
    puts "New interation: #{stats.loop_iterations}" if @options.verbose

    # Check if we're rate limited 😑.
    if response.dig('status') === 429 && response.dig('msg') === 'Limit Exceeded'
      @client.client_from_next_creds!
      response = @client.client.posts(@config.tumblr_blog_url, next_page_params)
      next
    end

    # If there are no more posts, notify and break.
    # The API seems to, uh, have different responses. 😅
    if response.nil? || !response['posts'].is_a?(Array) || response['posts'].nil? || response['posts'].empty?
      puts "No more posts!" if @options.verbose
      break
    end

    # Extract the posts from our API response.
    posts = response['posts']

    # Let's check the timestamp of the first non-pinned post to see if we're hit our end date.
    # If we did, break!
    first_non_pinned_post = posts.find {|post| !post['is_pinned']}
    if first_non_pinned_post['timestamp'] < ending_timestamp
      puts "Hit ending timestamp: #{ending_timestamp}... stopping." if @options.verbose
      break
    end

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
      puts "Privating post #{post['id']} (#{post['post_url']})" if @options.verbose
      @client.client.edit(@config.tumblr_blog_url, id: post['id'], state: 'private')

      # ++ posts_turned_private
      stats.posts_turned_private += 1
    end

    # Ok, now let's get the next batch of posts.
    next_page_params = response.dig('_links', 'next', 'query_params')

    # If we don't have a next page, break.
    if next_page_params.nil? || next_page_params.empty?
      puts "No next page!" if @options.verbose
      break
    end

    response = @client.client.posts(@config.tumblr_blog_url, next_page_params)
  end
rescue => e
  puts "Ruh roh, we error'd! Printing stats & bailing..."
  stats.print!
  raise
end

stats.print!
puts "Done!"
