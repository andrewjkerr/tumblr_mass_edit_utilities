# typed: strict

class TumblrApiCredential < T::Struct
  const :consumer_key, String
  const :consumer_secret, String
  const :oauth_token, String
  const :oauth_token_secret, String
end