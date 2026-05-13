# typed: false
require 'spec_helper'

RSpec.describe Post do
  let(:post_hash) do
    {
      'id_string' => '123456',
      'post_url' => 'https://example.tumblr.com/post/123456',
      'reblog_key' => 'abcdef',
      'state' => 'published',
      'is_pinned' => false,
      'date' => '2024-01-01 00:00:00 GMT',
    }
  end

  describe '.from_hash' do
    it 'builds a Post from an API response hash' do
      post = Post.from_hash(post_hash)
      expect(post.id).to eq('123456')
      expect(post.post_url).to eq('https://example.tumblr.com/post/123456')
      expect(post.reblog_key).to eq('abcdef')
      expect(post.state).to eq(Post::State::PUBLISHED)
      expect(post.is_pinned).to be false
      expect(post.date).to eq('2024-01-01 00:00:00 GMT')
    end

    it 'defaults is_pinned to false when absent' do
      post = Post.from_hash(post_hash.merge('is_pinned' => nil))
      expect(post.is_pinned).to be false
    end

    it 'handles private state' do
      post = Post.from_hash(post_hash.merge('state' => 'private'))
      expect(post.state).to eq(Post::State::PRIVATE)
    end
  end

  describe '.from_response_posts_array' do
    it 'returns an empty array for an empty input' do
      expect(Post.from_response_posts_array([])).to eq([])
    end

    it 'maps each hash to a Post' do
      posts = Post.from_response_posts_array([post_hash, post_hash.merge('id_string' => '999')])
      expect(posts.length).to eq(2)
      expect(posts.map(&:id)).to eq(['123456', '999'])
    end
  end
end
