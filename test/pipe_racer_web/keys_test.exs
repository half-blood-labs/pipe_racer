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

  describe "classify_input/1" do
    test "characters typed after the blank field are typed in order" do
      assert Keys.classify_input(Keys.blank_field() <> "ab") == [{:char, "a"}, {:char, "b"}]
      assert Keys.classify_input(Keys.blank_field() <> "\n") == [:enter]
    end

    test "characters typed in the middle of the blank field count the same" do
      {left, right} = String.split_at(Keys.blank_field(), 3)
      assert Keys.classify_input(left <> "a" <> right) == [{:char, "a"}]
    end

    test "each filler character deleted is a backspace" do
      assert Keys.classify_input(String.slice(Keys.blank_field(), 1..-1//1)) == [:backspace]
      assert Keys.classify_input("") == List.duplicate(:backspace, 8)
    end

    test "a word replaced by the keyboard deletes before it types" do
      value = String.slice(Keys.blank_field(), 2..-1//1) <> "the"

      assert Keys.classify_input(value) ==
               [:backspace, :backspace, {:char, "t"}, {:char, "h"}, {:char, "e"}]
    end

    test "typographic quotes and spaces become the plain ones" do
      assert Keys.classify_input(Keys.blank_field() <> "\u201Cok\u201D") ==
               [{:char, "\""}, {:char, "o"}, {:char, "k"}, {:char, "\""}]

      assert Keys.classify_input(Keys.blank_field() <> "\u2019\u00A0") ==
               [{:char, "'"}, {:char, " "}]
    end

    test "an untouched field is no command" do
      assert Keys.classify_input(Keys.blank_field()) == []
    end
  end
end
