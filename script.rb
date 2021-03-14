require 'tumblr_client'
require 'yaml'

POST_GET_LIMIT = 50

begin
    config = YAML.load_file('config/application.yaml')
rescue => e
    puts "Error loading configuration file; perhaps you need to rename application.yaml.sample?"
    puts "Full error:"
    raise
end

# Authenticate via OAuth
client = Tumblr::Client.new({
  consumer_key: config['tumblr_consumer_key'],
  consumer_secret: config['tumblr_consumer_secret'],
  oauth_token: config['tumblr_oauth_token'],
  oauth_token_secret: config['tumblr_oauth_token_secret'],
})

# Set where we should begin our privatization.
beginning_timestamp = Date.new(2014, 01, 01).to_time.to_i

# Get our initial response.
response = client.posts(config['tumblr_blog_url'], before: beginning_timestamp, limit: POST_GET_LIMIT)

# Store some stats!
stats = Hash.new(0)

# Check if we need to skip a post due to some fun edge cases.
def should_skip_post?(post)
    # Pinned posts are somehow always returned in this response. :/
    return true if post['is_pinned']

    # Any posts before the, uh, creation of Tumblr have a timestamp before the beginning timestamp.
    # ... don't ask. :p
    return true if Date.parse(post['date']) <= Date.new(2007, 01, 01)

    false
end

# Print our stats.
def print_stats!(stats)
    # At the end, print out our stats.
    puts "Stats:"
    stats.each do |key, value|
        puts "\t#{key}: #{value}"
    end
end

begin
    loop do
        # ++ loop_iterations
        stats[:loop_iterations] += 1

        # Check if we're rate limited 😑.
        if response.dig('status') === 429 && response.dig('msg') === 'Limit Exceeded'
            raise "Rate limited by Tumblr API, try again later."
        end

        # If there are no more posts, notify and break.
        if response['posts'].empty?
            puts "No more posts!"
            break
        end

        # Get the published posts from our API response.
        posts = response['posts']
        published_posts = posts.select do |post|
            post['state'] === 'published' && !should_skip_post?(post)
        end

        # += total_posts & += published_posts
        stats[:total_posts] += posts.size
        stats[:published_posts] += published_posts.size

        # Iterate over each post and turn them to private.
        published_posts.each do |post|
            puts "Privating post #{post['id']} (#{post['post_url']})"
            client.edit(config['tumblr_blog_url'], id: post['id'], state: 'private')

            # ++ posts_turned_private
            stats[:posts_turned_private] += 1
        end

        # Ok, now let's get the next batch of posts.
        next_page_params = response.dig('_links', 'next', 'query_params')

        # If we don't have a next page, break.
        if next_page_params.nil? || next_page_params.empty?
            puts "No next page!"
            break
        end

        response = client.posts(config['tumblr_blog_url'], next_page_params)
    end
rescue => e
    puts "Ruh roh, we error'd! Printing stats & bailing..."
    print_stats!(stats)
    raise
end

print_stats!(stats)
puts "Done!"
