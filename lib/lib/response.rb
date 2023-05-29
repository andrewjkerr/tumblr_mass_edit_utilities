# typed: strict

class Response
  extend T::Sig

  class Posts < T::Struct
    extend T::Sig

    const :next_before, T.nilable(Integer)
    const :next_page_number, T.nilable(String)
    const :posts, T::Array[Post]

    sig {returns(T::Boolean)}
    def has_posts?
      !self.posts.empty?
    end

    sig {returns(T::Boolean)}
    def has_next_page?
      !self.next_page_number.nil? || !self.next_before.nil?
    end
  end

  class Error < T::Struct
    const :status, Integer
    const :message, String
  end

  sig {params(response: T.any(T::Array[T.untyped], T::Hash[String, T.untyped])).returns(T.any(T::Hash[String, T.untyped], Response::Error))}
  def self.from_response_hash(response)
    # this feels ~ bad ~ but basically the caller should build their own response object
    # BUT we do want to standardize some error Struct building so let's do that if we
    # need to!

    # this feels ~ even worse ~ but some responses just return an empty array??
    # so just return an empty hash so we can move along
    return {} if response.is_a?(Array)

    status = response.dig('status')
    message = response.dig('msg')

    if status && message
      return Response::Error.new(
        status: status,
        message: message
      )
    end

    response
  end
end
