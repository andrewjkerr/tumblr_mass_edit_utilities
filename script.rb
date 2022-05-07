# typed: true

require 'date'
require 'optparse'
require 'sorbet-runtime'
require 'tumblr_client'
require 'yaml'

extend T::Sig

POST_GET_LIMIT = T.let(50, Integer)
DEFAULT_CONFIG_FILE_PATH = T.let('config/application.yaml', String)

class Options < T::Struct
    const :start_date, String
    const :config_file, String, default: DEFAULT_CONFIG_FILE_PATH
    const :verbose, T::Boolean, default: false
end

sig {returns(Options)}
def parse_options
    # Create a new options array
    options = T.let({}, T::Hash[Symbol, String])

    OptionParser.new do |opts|
        opts.banner = 'Usage: ruby script.rb [options]'
        opts.on('-cFILE_PATH', '--config=FILE_PATH', "Override the config file that's used (default: config/application.yaml)") do |c|
            options[:config_file] = c
        end
        opts.on('-dSTART_DATE', '--start_date=START_DATE', "The date to start privatizing posts, in YYYY-DD-MM format.") do |d|
            options[:start_date] = d
        end
        opts.on('-v', '--verbose', "Print debug-y information") { |v| options[:verbose] = v }
        opts.on('-h', '--help', 'Prints this help') do
            puts opts
            exit
        end
    end.parse!

    # Validate that we have the correct options
    [:start_date].each do |required_flags|
        unless options.key?(required_flags)
            puts "Required option #{required_flags} is not set. Please use --help to view which flags are required."
            exit(1)
        end
    end

    Options.new(**T.unsafe(options))
end

puts 'Starting up...'

# Parse our options into an Options struct. Keep it for the entire script!
@options = T.let(parse_options, Options)

# Load in our config
begin
    @config = YAML.load_file(@options.config_file)
rescue
    if @options.config_file == DEFAULT_CONFIG_FILE_PATH
        puts "Error loading configuration file; does #{@options.config_file} exist?"
    else
        puts "Error loading configuration file; perhaps you need to rename application.yaml.sample?"
    end

    puts "Full error:"
    raise
end

@backup_api_key_config_keys = @config.keys.select {|config_key| config_key.start_with?('backup_')}

# Authenticate via OAuth
@client = Tumblr::Client.new({
    consumer_key: @config['tumblr_consumer_key'],
    consumer_secret: @config['tumblr_consumer_secret'],
    oauth_token: @config['tumblr_oauth_token'],
    oauth_token_secret: @config['tumblr_oauth_token_secret'],
})

sig {void}
def rotate_api_keys!
    next_backup_key_set = @backup_api_key_config_keys.shift
    raise "Out of API key sets to try." if next_backup_key_set.nil?

    puts "Rotating to #{next_backup_key_set}..." if @options.verbose

    @client = Tumblr::Client.new({
        consumer_key: @config[next_backup_key_set]['tumblr_consumer_key'],
        consumer_secret: @config[next_backup_key_set]['tumblr_consumer_secret'],
        oauth_token: @config[next_backup_key_set]['tumblr_oauth_token'],
        oauth_token_secret: @config[next_backup_key_set]['tumblr_oauth_token_secret'],
    })
end

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

response = @client.posts(@config['tumblr_blog_url'], next_page_params)

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
sig {params(stats: T::Hash[Symbol, Integer]).void}
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
        puts "New interation: #{stats[:loop_iterations]}" if @options.verbose

        # Check if we're rate limited 😑.
        if response.dig('status') === 429 && response.dig('msg') === 'Limit Exceeded'
            rotate_api_keys!
            response = @client.posts(@config['tumblr_blog_url'], next_page_params)
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
        stats[:total_posts] += posts.size
        stats[:published_posts] += published_posts.size

        # Iterate over each post and turn them to private.
        published_posts.each do |post|
            puts "Privating post #{post['id']} (#{post['post_url']})" if @options.verbose
            @client.edit(@config['tumblr_blog_url'], id: post['id'], state: 'private')

            # ++ posts_turned_private
            stats[:posts_turned_private] += 1
        end

        # Ok, now let's get the next batch of posts.
        next_page_params = response.dig('_links', 'next', 'query_params')

        # If we don't have a next page, break.
        if next_page_params.nil? || next_page_params.empty?
            puts "No next page!" if @options.verbose
            break
        end

        response = @client.posts(@config['tumblr_blog_url'], next_page_params)
    end
rescue => e
    puts "Ruh roh, we error'd! Printing stats & bailing..."
    print_stats!(stats)
    raise
end

print_stats!(stats)
puts "Done!"
