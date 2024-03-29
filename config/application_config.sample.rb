# typed: strict

class ApplicationConfig < T::Struct
  extend T::Sig

  prop :tumblr_blog_url, String
  prop :tumblr_api_credentials, T::Array[TumblrApiCredential]

  sig {returns(ApplicationConfig)}
  def self.get_config
    ApplicationConfig.new(
      ################
      # CHANGE ME ⬇ #
      ################
      tumblr_blog_url: 'blog.tumblr.com',
      tumblr_api_credentials: T.let([
        TumblrApiCredential.new(
          consumer_key: 'tumblr_consumer_key',
          consumer_secret: 'tumblr_consumer_secret',
          oauth_token: 'tumblr_oauth_token',
          oauth_token_secret: 'tumblr_oauth_token_secret',
        ),
        TumblrApiCredential.new(
          consumer_key: 'backup_tumblr_consumer_key',
          consumer_secret: 'backup_tumblr_consumer_secret',
          oauth_token: 'backup_tumblr_oauth_token',
          oauth_token_secret: 'backup_tumblr_oauth_token_secret',
        ),
        # ...
      ], T::Array[TumblrApiCredential]),
    )
  end
end