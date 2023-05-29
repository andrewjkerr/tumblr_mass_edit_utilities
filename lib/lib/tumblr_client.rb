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

  sig {params(tumblelog_url: String, next_page_params: PageQueryParams).returns(Response::Posts)}
  def posts(tumblelog_url, next_page_params)
    response = make_request do
      @client.posts(tumblelog_url, next_page_params.serialize.transform_keys(&:to_sym))
    end

    posts = Post.from_response_posts_array(response.dig('posts') || T.let([], T::Array[Post]))
    next_page_number = response.dig('_links', 'next', 'query_params', 'page_number')

    return Response::Posts.new(
      posts: posts,
      next_page_number: next_page_number,
    )
  end

  sig {params(next_page_params: PageQueryParams).returns(Response::Posts)}
  def likes(next_page_params)
    response = make_request do
      @client.likes(next_page_params.serialize.transform_keys(&:to_sym))
    end

    posts = Post.from_response_posts_array(response.dig('liked_posts') || T.let([], T::Array[Post]))
    next_before = response.dig('_links', 'next', 'query_params', 'before').to_i

    return Response::Posts.new(
      posts: posts,
      next_before: next_before,
    )
  end

  sig do
    params(
      tumblelog_url: String,
      post_id: String,
      state: T.nilable(Post::State),
      community_label_categories: T.nilable(T::Array[Post::CommunityLabelCategory])
    ).void
  end
  def edit(tumblelog_url, post_id, state: nil, community_label_categories: nil)
    payload = {id: post_id}
    payload[:state] = state.serialize unless state.nil?

    unless community_label_categories.nil?
      payload[:community_label_categories] = community_label_categories.map {|label| label.serialize}
      payload[:has_community_label] = !payload[:community_label_categories].empty?
    end

    make_request {@client.edit(tumblelog_url, payload)}
  end

  sig do
    params(post: Post).void
  end
  def unlike(post)
    make_request {@client.unlike(post.id, post.reblog_key)}
  end

  sig {void}
  def client_from_next_creds!
    # get the next set of credentials; throw an error if there are none!
    new_tumblr_api_creds = @tumblr_api_credentials.shift
    raise 'No more Tumblr API credentials to use' if new_tumblr_api_creds.nil?

    # instantiate a new client to use
    @client = TumblrClient.client_from_tumblr_api_credential(new_tumblr_api_creds)
  end

  private
    sig {params(block: Proc).returns(T::Hash[String, T.untyped])}
    def make_request(&block)
      response = Response.from_response_hash(block.call)

      # if the response isn't an error, return it!
      return response unless response.is_a?(Response::Error)

      # check if we're rate limited or if we have an unknown error
      if is_rate_limited?(response)
        # if we are rate limited, instantiate a new client and re-try the request!
        client_from_next_creds!
        response = Response.from_response_hash(block.call)
      else
        puts "Funky error: #{response.serialize}"
      end

      return response unless response.is_a?(Response::Error)
      response.serialize
    end

    sig {params(response: Response::Error).returns(T::Boolean)}
    def is_rate_limited?(response)
      # check to see if we're rate limited!
      response.status === 429 && response.message === 'Limit Exceeded'
    end
end
