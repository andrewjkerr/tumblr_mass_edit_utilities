# typed: strict

class Command::PrivatizePosts < Command
  extend T::Sig

  sig {params(options: Options, config: Config, client: TumblrClient).void}
  def call(options, config, client)
  end
end