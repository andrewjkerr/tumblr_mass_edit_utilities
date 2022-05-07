# typed: strict

# todo: Actually fill this Struct out 😅
class Post < T::Struct
  extend T::Sig

  class State < T::Enum
    enums do
      PRIVATE = new
    end
  end

  # Check if we need to skip a post due to some fun edge cases.
  sig {params(post: T::Hash[String, T.untyped]).returns(T::Boolean)}
  def self.should_skip_post?(post)
    # Pinned posts are somehow always returned in this response. :/
    return true if post['is_pinned']

    # Any posts before the, uh, creation of Tumblr have a timestamp before the beginning timestamp.
    # ... don't ask. :p
    return true if Date.parse(post['date']) <= Date.new(2007, 01, 01)

    false
  end
end