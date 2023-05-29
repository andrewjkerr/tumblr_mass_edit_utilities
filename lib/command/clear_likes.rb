# typed: strict

class Command::ClearLikes < Command
  extend T::Sig

  sig {params(options: Options, config: Config, client: TumblrClient).void}
  def call(options, config, client)
    Base::IterateThroughLikes.call(options, config, client) do |post|
      puts "Unliking #{post.id} (#{post.post_url})" if options.verbose
      # do something
    end
  end
end
