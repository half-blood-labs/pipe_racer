defmodule PipeRacer.Race do
  @moduledoc "Room codes and racer names."

  @adjectives ~w(swift lazy eager brave quiet sharp tiny cosmic lucky rapid)
  @nouns ~w(atom pipe genserver stream beam macro tuple process agent sigil)

  @code_alphabet ~c"abcdefghjkmnpqrstuvwxyz23456789"

  def new_code do
    for _ <- 1..5, into: "", do: <<Enum.random(@code_alphabet)>>
  end

  def valid_code?(code), do: is_binary(code) and code =~ ~r/\A[a-z0-9]{5}\z/

  def random_name, do: "#{Enum.random(@adjectives)}-#{Enum.random(@nouns)}"
end
