# typed: false
require 'spec_helper'

RSpec.describe Command::UpdateCommunityLabels do
  let(:credential) do
    TumblrApiCredential.new(
      consumer_key: 'k', consumer_secret: 's',
      oauth_token: 't', oauth_token_secret: 'ts',
    )
  end
  let(:options) { Options.new(command: Command::Command::UpdateCommunityLabels) }
  let(:config) { Config.new(tumblr_blog_url: 'example.tumblr.com', tumblr_api_credentials: [credential]) }
  let(:tumblr_api_double) do
    Tumblr::Client.new(consumer_key: 'k', consumer_secret: 's', oauth_token: 't', oauth_token_secret: 'ts')
  end
  let(:client) { TumblrClient.new([credential], options) }

  before do
    allow(TumblrClient).to receive(:client_from_tumblr_api_credential).and_return(tumblr_api_double)
  end

  describe '#options_valid?' do
    subject { Command::UpdateCommunityLabels.new }

    it 'returns false when community_label_categories is nil' do
      options = Options.new(command: Command::Command::UpdateCommunityLabels)
      expect(subject.options_valid?(options)).to be false
    end

    it 'returns true when community_label_categories is set' do
      options = Options.new(
        command: Command::Command::UpdateCommunityLabels,
        community_label_categories: [Post::CommunityLabelCategory::DRUG_USE],
      )
      expect(subject.options_valid?(options)).to be true
    end

    it 'returns true when community_label_categories is an empty array' do
      options = Options.new(
        command: Command::Command::UpdateCommunityLabels,
        community_label_categories: [],
      )
      expect(subject.options_valid?(options)).to be true
    end
  end

  describe '#call' do
    it 'raises when community_label_categories is not set' do
      options = Options.new(command: Command::Command::UpdateCommunityLabels)
      expect {
        Command::UpdateCommunityLabels.new.call(options, config, client)
      }.to raise_error(RuntimeError, /Community label categories cannot be empty/)
    end

    it 'calls client.edit with the community labels for each published post' do
      options = Options.new(
        command: Command::Command::UpdateCommunityLabels,
        community_label_categories: [Post::CommunityLabelCategory::DRUG_USE],
      )

      post_hash = {
        'id_string' => '123',
        'post_url' => 'https://example.tumblr.com/post/123',
        'reblog_key' => 'abc',
        'state' => 'published',
        'is_pinned' => false,
        'date' => '2024-01-01 00:00:00 GMT',
        'community_label_categories' => [],
      }

      allow(tumblr_api_double).to receive(:posts).and_return({'posts' => [post_hash]})
      expect(tumblr_api_double).to receive(:edit).with(
        'example.tumblr.com',
        hash_including(id: '123', community_label_categories: ['drug_use']),
      ).and_return({})

      Command::UpdateCommunityLabels.new.call(options, config, client)
    end
  end
end
