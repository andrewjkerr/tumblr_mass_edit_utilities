# typed: false
require 'spec_helper'

RSpec.describe Command::Base::IterateThroughLikes do
  let(:credential) do
    TumblrApiCredential.new(
      consumer_key: 'k', consumer_secret: 's',
      oauth_token: 't', oauth_token_secret: 'ts',
    )
  end
  let(:options) { Options.new(command: Command::Command::ClearLikes) }
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
      'community_label_categories' => [],
    }.merge(overrides)
  end

  # TumblrClient#likes calls nil.to_i on a missing 'before' value, producing 0.
  # Since has_next_page? checks !next_before.nil?, 0 is treated as "has next page".
  # Production handles this by making one extra fetch that returns empty liked_posts.
  # Tests must do the same: always end with an empty-liked_posts response.
  def empty_likes_response
    {'liked_posts' => []}
  end

  describe '#call' do
    it 'yields each liked post to the block' do
      post1 = make_post('id_string' => '1')
      post2 = make_post('id_string' => '2')
      allow(tumblr_api_double).to receive(:likes).and_return(
        {'liked_posts' => [post1, post2]},
        empty_likes_response,
      )

      yielded_ids = []
      Command::Base::IterateThroughLikes.new.call(options, config, client) { |p| yielded_ids << p.id }
      expect(yielded_ids).to eq(['1', '2'])
    end

    it 'stops when the response has no posts' do
      allow(tumblr_api_double).to receive(:likes).and_return({'liked_posts' => []})

      expect(tumblr_api_double).to receive(:likes).once
      Command::Base::IterateThroughLikes.new.call(options, config, client) { }
    end

    it 'paginates using offset' do
      post1 = make_post('id_string' => '1')
      post2 = make_post('id_string' => '2')

      allow(tumblr_api_double).to receive(:likes).and_return(
        {'liked_posts' => [post1], '_links' => {'next' => {'query_params' => {'before' => '999'}}}},
        {'liked_posts' => [post2]},
        empty_likes_response,
      )

      yielded_ids = []
      Command::Base::IterateThroughLikes.new.call(options, config, client) { |p| yielded_ids << p.id }
      expect(yielded_ids).to eq(['1', '2'])
    end

    it 'skips posts after beginning_timestamp when set' do
      options_with_ts = Options.new(
        command: Command::Command::ClearLikes,
        beginning_timestamp: Date.parse('2024-01-01').to_time.to_i,
      )

      future_post = make_post('date' => '2024-06-01 00:00:00 GMT')
      past_post = make_post('id_string' => '2', 'date' => '2023-01-01 00:00:00 GMT')

      allow(tumblr_api_double).to receive(:likes).and_return(
        {'liked_posts' => [future_post, past_post]},
        empty_likes_response,
      )

      yielded_ids = []
      Command::Base::IterateThroughLikes.new.call(options_with_ts, config, client) { |p| yielded_ids << p.id }
      expect(yielded_ids).to eq(['2'])
    end
  end

  describe '#should_skip_post?' do
    subject { Command::Base::IterateThroughLikes.new }

    let(:post) { Post.from_hash(make_post('date' => '2024-06-01 00:00:00 GMT')) }

    it 'returns false when beginning_timestamp is not set' do
      expect(subject.should_skip_post?(options, post)).to be false
    end

    it 'returns true for a post dated after beginning_timestamp' do
      options_with_ts = Options.new(
        command: Command::Command::ClearLikes,
        beginning_timestamp: Date.parse('2024-01-01').to_time.to_i,
      )
      expect(subject.should_skip_post?(options_with_ts, post)).to be true
    end

    it 'returns false for a post dated before beginning_timestamp' do
      options_with_ts = Options.new(
        command: Command::Command::ClearLikes,
        beginning_timestamp: Date.parse('2025-01-01').to_time.to_i,
      )
      expect(subject.should_skip_post?(options_with_ts, post)).to be false
    end
  end
end
