defmodule PipeRacerWeb.KeysTest do
  use ExUnit.Case, async: true

  alias PipeRacerWeb.Keys

  defp event(key, mods \\ []) do
    %{
      key: key,
      meta_key: :meta in mods,
      ctrl_key: :ctrl in mods,
      alt_key: :alt in mods
    }
  end

  test "printable keys become characters, shifted ones included" do
    assert Keys.classify(event("a")) == {:char, "a"}
    assert Keys.classify(event("{")) == {:char, "{"}
    assert Keys.classify(event(" ")) == {:char, " "}
  end

  test "Option, Ctrl or Cmd with Backspace jumps back to the mistake" do
    for mod <- [:alt, :ctrl, :meta] do
      assert Keys.classify(event("Backspace", [mod])) == :backspace_to_mistake
    end
  end

  test "other shortcuts are left to the browser" do
    assert Keys.classify(event("r", [:meta])) == :ignore
    assert Keys.classify(event("Shift")) == :ignore
  end
end
