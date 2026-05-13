# typed: false
require 'spec_helper'

RSpec.describe Command::Base::IterateThroughPosts do
  let(:credential) do
    TumblrApiCredential.new(
      consumer_key: 'k', consumer_secret: 's',
      oauth_token: 't', oauth_token_secret: 'ts',
    )
  end
  let(:options) { Options.new(command: Command::Command::PrivatizePosts) }
  let(:config) { Config.new(tumblr_blog_url: 'example.tumblr.com', tumblr_api_credentials: [credential]) }

  let(:tumblr_api_double) do
    Tumblr::Client.new(consumer_key: 'k', consumer_secret: 's', oauth_token: 't', oauth_token_secret: 'ts')
  end
  let(:client) { TumblrClient.new([credential], options) }

  before do
    allow(TumblrClient).to receive(:client_from_tumblr_api_credential).and_return(tumblr_api_double)
  end

  def make_post(overrides = {})
    {
      'id_string' => '1',
      'post_url' => 'https://example.tumblr.com/post/1',
      'reblog_key' => 'abc',
      'state' => 'published',
      'is_pinned' => false,
      'date' => '2024-01-01 00:00:00 GMT',
    }.merge(overrides)
  end

  def empty_response
    Response::Posts.new(posts: [])
  end

  def single_page_response(posts)
    Response::Posts.new(posts: posts.map { |p| Post.from_hash(p) })
  end

  def paginated_response(posts, next_page_number)
    Response::Posts.new(
      posts: posts.map { |p| Post.from_hash(p) },
      next_page_number: next_page_number,
    )
  end

  describe '#call' do
    it 'yields each published post to the block' do
      post1 = make_post('id_string' => '1')
      post2 = make_post('id_string' => '2')
      allow(tumblr_api_double).to receive(:posts).and_return(
        {'posts' => [post1, post2]},
      )

      yielded_ids = []
      Command::Base::IterateThroughPosts.new.call(options, config, client) { |p| yielded_ids << p.id }
      expect(yielded_ids).to eq(['1', '2'])
    end

    it 'skips private posts' do
      allow(tumblr_api_double).to receive(:posts).and_return(
        {'posts' => [make_post('state' => 'private')]},
      )

      yielded = []
      Command::Base::IterateThroughPosts.new.call(options, config, client) { |p| yielded << p }
      expect(yielded).to be_empty
    end

    it 'skips pinned posts' do
      allow(tumblr_api_double).to receive(:posts).and_return(
        {'posts' => [make_post('is_pinned' => true)]},
      )

      yielded = []
      Command::Base::IterateThroughPosts.new.call(options, config, client) { |p| yielded << p }
      expect(yielded).to be_empty
    end

    it 'skips posts dated before 2007-01-01' do
      allow(tumblr_api_double).to receive(:posts).and_return(
        {'posts' => [make_post('date' => '2006-12-31 00:00:00 GMT')]},
      )

      yielded = []
      Command::Base::IterateThroughPosts.new.call(options, config, client) { |p| yielded << p }
      expect(yielded).to be_empty
    end

    it 'follows pagination via next_page_number' do
      page1 = make_post('id_string' => '1')
      page2 = make_post('id_string' => '2')

      allow(tumblr_api_double).to receive(:posts).and_return(
        {'posts' => [page1], '_links' => {'next' => {'query_params' => {'page_number' => '2'}}}},
        {'posts' => [page2]},
      )

      yielded_ids = []
      Command::Base::IterateThroughPosts.new.call(options, config, client) { |p| yielded_ids << p.id }
      expect(yielded_ids).to eq(['1', '2'])
    end

    it 'stops iterating when the response has no posts' do
      allow(tumblr_api_double).to receive(:posts).and_return({'posts' => []})

      expect(tumblr_api_double).to receive(:posts).once
      Command::Base::IterateThroughPosts.new.call(options, config, client) { }
    end
  end

  describe '#should_skip_post?' do
    subject { Command::Base::IterateThroughPosts.new }

    it 'returns false for a normal published post' do
      post = Post.from_hash(make_post)
      expect(subject.should_skip_post?(post)).to be false
    end

    it 'returns true for a pinned post' do
      post = Post.from_hash(make_post('is_pinned' => true))
      expect(subject.should_skip_post?(post)).to be true
    end

    it 'returns true for a post dated on or before 2007-01-01' do
      post = Post.from_hash(make_post('date' => '2007-01-01 00:00:00 GMT'))
      expect(subject.should_skip_post?(post)).to be true
    end

    it 'returns false for a post dated after 2007-01-01' do
      post = Post.from_hash(make_post('date' => '2007-01-02 00:00:00 GMT'))
      expect(subject.should_skip_post?(post)).to be false
    end
  end
end
