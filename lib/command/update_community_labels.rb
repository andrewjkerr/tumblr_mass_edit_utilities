# typed: strict

class Command::UpdateCommunityLabels < Command
  extend T::Sig

  sig {params(options: Options, config: Config, client: TumblrClient).void}
  def call(options, config, client)
    unless options_valid?(options)
      raise "Community label categories cannot be empty. Run script with --help for valid community label categories."
    end

    Base::IterateThroughPosts.call(options, config, client) do |post|
      puts "Updating community labels on post #{post.id} (#{post.post_url})" if options.verbose
      client.edit(config.tumblr_blog_url, post.id, community_label_categories: options.community_label_categories)
    end
  end

  sig {params(options: Options).returns(T::Boolean)}
  def options_valid?(options)
    return false if options.community_label_categories.nil?
    true
  end
end
