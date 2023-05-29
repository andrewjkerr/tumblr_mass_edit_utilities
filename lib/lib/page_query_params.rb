# typed: strict

class PageQueryParams < T::Struct
  POST_GET_LIMIT = T.let(50, Integer)

  const :limit, Integer, default: POST_GET_LIMIT

  prop :before, T.nilable(Integer)
  prop :offset, T.nilable(Integer)
  prop :page_number, T.nilable(String)
  prop :tag, T.nilable(String)
  prop :tumblelog, T.nilable(String)
end
