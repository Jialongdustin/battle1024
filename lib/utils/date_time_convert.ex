defmodule Battle.DateTimeConvert do

    def convert(nil) do
      0
    end

    def convert(time) do
      {g, s, _} = Bson.UTC.to_now(time)
      g * 1_000_000 + s
    end

end
