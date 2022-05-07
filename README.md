**⚠️ Warning: Use at your own risk! Not thoroughly tested!** I do not recommend running on a blog you might actually care about.

# Tumblr Mass Edit: Privatize Posts

This is a small utility script to privatize Tumblr posts for a blog, starting at a given start date.

## Instructions

1. Run `bundle install` to install the gems!
1. Copy `config/application_config.sample.rb` to `config/application_config.rb`.
1. Add your Tumblr API keys & Tumblr OAuth tokens to that configuration file.
    * If you have more than 1k posts that you want to make private, you'll need to have "backup" API keys & OAuth tokens by adding more than one set of credentials to the config. I recommend having at least one set of key per every ~950 posts or so.
        * ⚠️ Please take caution when doing this!
1. Change the `tumblr_blog_url` in the configuration file to your blog URL.
1. `ruby script.rb --state_date=YYYY-MM-DD` and cross your fingers! 🤞
    * `ruby script.rb --help` will list all of the available options.

There's a 1k request per hour and 5k request per day rate limit for each OAuth application so don't be running this on thousands & thousands of posts!

## Development

If you'd like to contribute, you'll probably want to get Sorbet up and running by either...:

1. Use VSCode and install `watchman` (`brew install watchman` on macOS) & the Sorbet extension
1. Add a pre-commit hook that runs `srb tc`

## Need help?

File an issue! I'm more than happy to assist where I can. :)