**⚠️ Warning: Use at your own risk! Not thoroughly tested!** I do not recommend running on a blog you might actually care about.

# Tumblr Mass Edit: Privatize Posts

This is a small utility script to privatize Tumblr posts for a blog, starting at a given start date.

## Instructions

1. Copy `config/application.yaml.sample` to `config/application.yaml`.
1. Add your Tumblr API keys & Tumblr OAuth tokens to that configuration file.
    * If you have more than 1k posts that you want to make private, you'll need to have "backup" API keys & OAuth tokens. They take the form of `backup_x` and you can have as many as you want. I recommend having at least one set of key per every ~950 posts or so.
        * ⚠️ Please take caution when doing this!
1. Change the `tumblr_blog_url` in the configuration file to your blog URL.
1. Change `beginning_timestamp` in `script.rb` to be whatever timestamp you want.
1. `ruby script.rb` and cross your fingers! 🤞

There's a 1k request per hour and 5k request per day rate limit for each OAuth application so don't be running this on thousands & thousands of posts!
