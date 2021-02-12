defmodule Janus.Utilities do
    @spec generate_random_string(non_neg_integer) :: binary
    def generate_random_string(length \\ 12) do
        :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
    end
end
