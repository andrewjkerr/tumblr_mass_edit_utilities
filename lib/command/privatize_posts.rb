# typed: strict

class Command::PrivatizePosts < Command
  extend T::Sig

  sig {params(options: Options, config: Config, client: TumblrClient).void}
  def call(options, config, client)
    Base::IterateThroughPosts.call(options, config, client) do |post|
      puts "Privating post #{post.id} (#{post.post_url})" if options.verbose
      client.edit(config.tumblr_blog_url, post.id, state: Post::State::PRIVATE)
    end
  end
end
