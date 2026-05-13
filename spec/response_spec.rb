# typed: false
require 'spec_helper'

RSpec.describe Response do
  describe '.from_response_hash' do
    context 'when the response is an Array' do
      it 'returns an empty hash' do
        expect(Response.from_response_hash([])).to eq({})
        expect(Response.from_response_hash([{'id' => '123'}])).to eq({})
      end
    end

    context 'when the response has a status and message' do
      it 'returns a Response::Error' do
        result = Response.from_response_hash({'status' => 429, 'msg' => 'Limit Exceeded'})
        expect(result).to be_a(Response::Error)
        expect(result.status).to eq(429)
        expect(result.message).to eq('Limit Exceeded')
      end
    end

    context 'when the response is a normal hash' do
      it 'returns the hash unchanged' do
        payload = {'posts' => [], '_links' => {}}
        expect(Response.from_response_hash(payload)).to eq(payload)
      end
    end
  end

  describe Response::Posts do
    let(:post) do
      Post.new(
        id: '123',
        post_url: 'https://example.tumblr.com/post/123',
        reblog_key: 'abc',
        state: Post::State::PUBLISHED,
        is_pinned: false,
        date: '2024-01-01 00:00:00 GMT',
      )
    end

    describe '#has_posts?' do
      it 'returns true when posts are present' do
        response = Response::Posts.new(posts: [post])
        expect(response.has_posts?).to be true
      end

      it 'returns false when posts are empty' do
        response = Response::Posts.new(posts: [])
        expect(response.has_posts?).to be false
      end
    end

    describe '#has_next_page?' do
      it 'returns true when next_page_number is set' do
        response = Response::Posts.new(posts: [], next_page_number: '2')
        expect(response.has_next_page?).to be true
      end

      it 'returns true when next_before is set' do
        response = Response::Posts.new(posts: [], next_before: 1234567890)
        expect(response.has_next_page?).to be true
      end

      it 'returns false when neither is set' do
        response = Response::Posts.new(posts: [])
        expect(response.has_next_page?).to be false
      end
    end
  end
end
