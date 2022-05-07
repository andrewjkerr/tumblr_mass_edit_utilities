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

  const :id, String
  const :post_url, String
  const :state, State
  const :is_pinned, T::Boolean
  const :date, String

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
    )
  end

  # Check if we need to skip a post due to some fun edge cases.
  sig {params(post: Post).returns(T::Boolean)}
  def self.should_skip_post?(post)
    # Pinned posts are somehow always returned in this response. :/
    return true if post.is_pinned

    # Any posts before the, uh, creation of Tumblr have a timestamp before the beginning timestamp.
    # ... don't ask. :p
    return true if Date.parse(post.date) <= Date.new(2007, 01, 01)

    false
  end
end