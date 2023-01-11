# typed: strict

class Command::SnoozeLive < Command
  extend T::Sig

  sig {params(options: Options, config: Config, client: TumblrClient).void}
  def call(options, config, client)
    client.update_settings({snooze_tmg_live: true})
  end
end
