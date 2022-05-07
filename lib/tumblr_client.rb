# typed: strict

class TumblrClient
  extend T::Sig

  sig {returns(Tumblr::Client)}
  attr_reader :client

  sig {params(tumblr_api_credentials: T::Array[TumblrApiCredential]).void}
  def initialize(tumblr_api_credentials)
    @tumblr_api_credentials = tumblr_api_credentials

    # we validate whether or not we actually have credentials when we load the config
    # so we can use `T.must`
    first_tumblr_api_credential = T.must(@tumblr_api_credentials.shift)

    # _technically_ we could just call client_from_next_creds! here but Sorbet complains
    # and I don't want to define @client as nilable :sob:
    @client = T.let(
      TumblrClient.client_from_tumblr_api_credential(first_tumblr_api_credential),
      Tumblr::Client
    )
  end

  sig {params(tumblr_api_credential: TumblrApiCredential).returns(Tumblr::Client)}
  def self.client_from_tumblr_api_credential(tumblr_api_credential)
    # note to self - serialize gives you T::Hash[String, T.untyped]
    Tumblr::Client.new(tumblr_api_credential.serialize.transform_keys(&:to_sym))
  end

  sig {params(tumblelog_url: String, next_page_params: PageQueryParams).returns(T::Hash[String, T.untyped])}
  def posts(tumblelog_url, next_page_params)
    @client.posts(tumblelog_url, next_page_params.serialize.transform_keys(&:to_sym))
  end

  sig {params(tumblelog_url: String, post_id: String, state: Post::State).void}
  def edit(tumblelog_url, post_id, state)
    @client.edit(tumblelog_url, id: post_id, state: state.serialize)
  end

  sig {void}
  def client_from_next_creds!
    # get the next set of credentials; throw an error if there are none!
    new_tumblr_api_creds = @tumblr_api_credentials.shift
    raise 'No more Tumblr API credentials to use' if new_tumblr_api_creds.nil?

    # instantiate a new client to use
    @client = TumblrClient.client_from_tumblr_api_credential(new_tumblr_api_creds)
  end
end