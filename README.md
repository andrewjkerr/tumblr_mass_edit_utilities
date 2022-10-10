**⚠️ Warning: Use at your own risk! Not thoroughly tested!** I do not recommend running on a blog you might actually care about.

# Tumblr Mass Edit Utilities

This is a collection of utilities ("commands") to mass edit posts on a Tumblr blog.

There are currently two commands that are supported:

1. `PrivatizePosts`: Turns all published posts private.
1. `UpdateCommunityLabels`: Updates the community labels on all published posts.

Each command allows for an optional tag & start date to filter on which published posts are being updated.

## Instructions

1. Run `bundle install` to install the gems!
1. Copy `config/application_config.sample.rb` to `config/application_config.rb`.
1. Add your Tumblr API keys & Tumblr OAuth tokens to that configuration file.
    * If you have more than 1k posts that you want to make private, you'll need to have "backup" API keys & OAuth tokens by adding more than one set of credentials to the config. I recommend having at least one set of key per every ~950 posts or so.
        * ⚠️ Please take caution when doing this! This may be against Tumblr's terms of service.
1. Change the `tumblr_blog_url` in the configuration file to your blog URL.

### PrivatizePosts

To run the PrivatizePosts command, use the `PrivatizePosts` argument:

1. Run `ruby script.rb PrivatizePosts --state_date=YYYY-MM-DD`
    * `ruby script.rb PrivatizePosts --help` will list all of the available options.

### UpdateCommunityLabels

To run the UpdateCommunityLabels command, use the `UpdateCommunityLabels` argument:

1. Run `ruby script.rb UpdateCommunityLabels --community_labels=sexual_themes,violence,drug_use`
    * `ruby script.rb UpdateCommunityLabels --help` will list all of the available options.

## Development

If you'd like to contribute, you'll probably want to get Sorbet up and running by either...:

1. Use VSCode and install `watchman` (`brew install watchman` on macOS) & the Sorbet extension
1. Add a pre-commit hook that runs `srb tc`

### Adding a new utility

If you'd like to add a new utility, please...:

1. Add a new command in `lib/command` with the following structure:

```ruby
# typed: strict

class Command::NewCommand < Command
  extend T::Sig

  sig {params(options: Options, config: Config, client: TumblrClient).void}
  def call(options, config, client)
    Base::IterateThroughPosts.call(options, config, client) do |post|
      puts "Updating post #{post.id} (#{post.post_url})" if options.verbose
      # do something
    end
  end
end
```

1. Add the command to the `Command::Command` enum in `lib/lib/command.rb`:

```diff
 class Command < T::Enum
   enums do
     PrivatizePosts = new
     UpdateCommunityLabels = new
+    NewCommand = new
   end
 end
```

1. Add the new file to `lib/tumblr_utilties.rb` to ensure it's loaded:

```ruby
# note, order matters!
require_relative('command/new_command.rb')
```

1. Add the new command call to the entry `script.rb` file:

```ruby
when Command::Command::NewCommand
  Command::NewCommand.call(options, config, client)
```

And then you can call it via:

```bash
ruby script.rb NewCommand
```

## Need help?

File an issue! I'm more than happy to assist where I can. :)
