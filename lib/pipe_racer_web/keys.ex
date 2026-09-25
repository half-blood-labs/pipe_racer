defmodule PipeRacerWeb.Keys do
  @moduledoc "Turns a Hologram key_down event into a typing command."

  def classify(event) do
    modified? = event.meta_key or event.ctrl_key or event.alt_key

    cond do
      event.key == "Backspace" and modified? -> :backspace_to_mistake
      modified? -> :ignore
      event.key == "Escape" -> :escape
      event.key == "Enter" -> :enter
      event.key == "Backspace" -> :backspace
      String.length(event.key) == 1 -> {:char, event.key}
      true -> :ignore
    end
  end
end
