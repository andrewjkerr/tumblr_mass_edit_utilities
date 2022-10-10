# typed: strict

class PageQueryParams < T::Struct
  POST_GET_LIMIT = T.let(50, Integer)

  const :limit, Integer, default: POST_GET_LIMIT

  prop :before, T.nilable(Integer)
  prop :tumblelog, String
  prop :page_number, T.nilable(String)
  prop :tag, T.nilable(String)
end
