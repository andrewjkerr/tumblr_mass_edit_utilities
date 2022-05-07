# typed: strict

class Response
  extend T::Sig

  class Posts < T::Struct
    extend T::Sig

    const :posts, T::Array[Post]
    const :next_page_number, T.nilable(String)

    sig {returns(T::Boolean)}
    def has_posts?
      !self.posts.empty?
    end
  
    sig {returns(T::Boolean)}
    def has_next_page?
      !self.next_page_number.nil?
    end
  end

  class Error < T::Struct
    const :status, Integer
    const :message, String
  end

  sig {params(response: T::Hash[String, T.untyped]).returns(T.any(T::Hash[String, T.untyped], Response::Error))}
  def self.from_response_hash(response)
    # this feels ~ bad ~ but basically the caller should build their own response object
    # BUT we do want to standardize some error Struct building so let's do that if we
    # need to!
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