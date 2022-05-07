# typed: strict

# todo: Actually fill this Struct out 😅
class Post < T::Struct
  class State < T::Enum
    enums do
      PRIVATE = new
    end
  end
end