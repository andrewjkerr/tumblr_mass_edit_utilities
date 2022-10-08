# typed: strict

# todo: Actually fill this Struct out 😅
class Post < T::Struct
  extend T::Sig

  class State < T::Enum
    enums do
      PRIVATE = new
      PUBLISHED = new
    end
  end

  class CommunityLabelCategory < T::Enum
    enums do
      DRUG_USE = new
      VIOLENCE = new
      SEXUAL_THEMES = new
    end
  end

  const :id, String
  const :post_url, String
  const :state, State
  const :is_pinned, T::Boolean
  const :date, String
  const :community_label_categories, T::Array[String]

  sig {params(posts: T::Array[T::Hash[String, T.untyped]]).returns(T::Array[Post])}
  def self.from_response_posts_array(posts)
    posts.map {|post| Post.from_hash(post)}
  end

  sig {params(post: T::Hash[String, T.untyped]).returns(Post)}
  def self.from_hash(post)
    Post.new(
      id: post.dig('id_string'),
      post_url: post.dig('post_url'),
      state: State.deserialize(post.dig('state')),
      is_pinned: post.dig('is_pinned') || false,
      date: post.dig('date'),
      community_label_categories: post.dig('community_label_categories') || [],
    )
  end
end