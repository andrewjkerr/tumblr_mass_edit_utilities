# typed: false
require 'spec_helper'

RSpec.describe TumblrClient do
  let(:credential) do
    TumblrApiCredential.new(
      consumer_key: 'key',
      consumer_secret: 'secret',
      oauth_token: 'token',
      oauth_token_secret: 'token_secret',
    )
  end
  let(:second_credential) do
    TumblrApiCredential.new(
      consumer_key: 'key2',
      consumer_secret: 'secret2',
      oauth_token: 'token2',
      oauth_token_secret: 'token_secret2',
    )
  end
  let(:options) { Options.new(command: Command::Command::PrivatizePosts) }

  # Real Tumblr::Client instances (no network calls on init) so Sorbet's T.let passes.
  # Methods are stubbed per test via allow(tumblr_double).to receive(...)
  let(:tumblr_double) do
    Tumblr::Client.new(consumer_key: 'k', consumer_secret: 's', oauth_token: 't', oauth_token_secret: 'ts')
  end
  let(:second_tumblr_double) do
    Tumblr::Client.new(consumer_key: 'k2', consumer_secret: 's2', oauth_token: 't2', oauth_token_secret: 'ts2')
  end

  let(:client) { TumblrClient.new([credential], options) }

  let(:post_hash) do
    {
      'id_string' => '123',
      'post_url' => 'https://example.tumblr.com/post/123',
      'reblog_key' => 'abc',
      'state' => 'published',
      'is_pinned' => false,
      'date' => '2024-01-01 00:00:00 GMT',
    }
  end
  let(:rate_limit_response) { {'status' => 429, 'msg' => 'Limit Exceeded'} }

  before do
    allow(TumblrClient).to receive(:client_from_tumblr_api_credential).and_return(tumblr_double)
  end

  describe '#posts' do
    let(:page_params) { PageQueryParams.new }

    it 'returns a Response::Posts with posts and next_page_number' do
      allow(tumblr_double).to receive(:posts).and_return({
        'posts' => [post_hash],
        '_links' => {'next' => {'query_params' => {'page_number' => '2'}}},
      })

      result = client.posts('example.tumblr.com', page_params)
      expect(result).to be_a(Response::Posts)
      expect(result.posts.length).to eq(1)
      expect(result.posts.first.id).to eq('123')
      expect(result.next_page_number).to eq('2')
    end

    it 'returns an empty posts response when there are no posts' do
      allow(tumblr_double).to receive(:posts).and_return({'posts' => []})

      result = client.posts('example.tumblr.com', page_params)
      expect(result.has_posts?).to be false
      expect(result.has_next_page?).to be false
    end
  end

  describe '#likes' do
    let(:page_params) { PageQueryParams.new }

    it 'returns a Response::Posts with liked posts and next_before' do
      allow(tumblr_double).to receive(:likes).and_return({
        'liked_posts' => [post_hash],
        '_links' => {'next' => {'query_params' => {'before' => '1704067200'}}},
      })

      result = client.likes(page_params)
      expect(result).to be_a(Response::Posts)
      expect(result.posts.length).to eq(1)
      expect(result.next_before).to eq(1704067200)
    end

    it 'returns an empty posts response when there are no likes' do
      allow(tumblr_double).to receive(:likes).and_return({'liked_posts' => []})

      result = client.likes(page_params)
      expect(result.has_posts?).to be false
    end
  end

  describe '#edit' do
    it 'calls edit with the post id and state' do
      expect(tumblr_double).to receive(:edit).with('example.tumblr.com', {id: '123', state: 'private'}).and_return({})

      client.edit('example.tumblr.com', '123', state: Post::State::PRIVATE)
    end

  end

  describe '#unlike' do
    it 'calls unlike with the post id and reblog key' do
      post = Post.from_hash(post_hash)
      expect(tumblr_double).to receive(:unlike).with('123', 'abc').and_return({})

      client.unlike(post)
    end
  end

  describe '#client_from_next_creds!' do
    let(:client) { TumblrClient.new([credential, second_credential], options) }

    before do
      allow(TumblrClient).to receive(:client_from_tumblr_api_credential).and_return(tumblr_double, second_tumblr_double)
    end

    it 'rotates to the next set of credentials' do
      client.client_from_next_creds!
      expect(client.client).to eq(second_tumblr_double)
    end

    it 'raises when there are no more credentials' do
      client.client_from_next_creds!
      expect { client.client_from_next_creds! }.to raise_error(RuntimeError, 'No more Tumblr API credentials to use')
    end
  end

  describe 'rate limiting' do
    let(:page_params) { PageQueryParams.new }

    it 'sleeps and retries once on a rate limit response' do
      allow(client).to receive(:sleep)
      allow(tumblr_double).to receive(:posts).and_return(rate_limit_response, {'posts' => []})

      expect(client).to receive(:sleep).with(60).once

      result = client.posts('example.tumblr.com', page_params)
      expect(result).to be_a(Response::Posts)
    end

    it 'raises when still rate limited with no remaining credentials' do
      allow(client).to receive(:sleep)
      allow(tumblr_double).to receive(:posts).and_return(rate_limit_response, rate_limit_response)

      expect { client.posts('example.tumblr.com', page_params) }.to raise_error(RuntimeError, 'No more Tumblr API credentials to use')
    end

    it 'rotates credentials when still rate limited after sleep' do
      allow(TumblrClient).to receive(:client_from_tumblr_api_credential).and_return(tumblr_double, second_tumblr_double)
      rotating_client = TumblrClient.new([credential, second_credential], options)
      allow(rotating_client).to receive(:sleep)

      allow(tumblr_double).to receive(:posts).and_return(rate_limit_response, rate_limit_response)
      allow(second_tumblr_double).to receive(:posts).and_return({'posts' => [post_hash]})

      result = rotating_client.posts('example.tumblr.com', page_params)
      expect(result.posts.length).to eq(1)
    end
  end
end
