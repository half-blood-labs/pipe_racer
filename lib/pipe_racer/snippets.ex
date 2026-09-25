defmodule PipeRacer.Snippets do
  @moduledoc """
  The Elixir snippets players type. Kept to plain ASCII so every character
  can be typed on a standard keyboard, and indented with two spaces because
  the game auto-skips indentation after Enter.
  """

  @snippets [
    %{
      title: "Pipe chain",
      code: """
      users
      |> Enum.filter(& &1.active)
      |> Enum.map(& &1.email)
      |> Enum.uniq()\
      """
    },
    %{
      title: "Pattern match on a tuple",
      code: """
      case File.read(path) do
        {:ok, body} -> Jason.decode(body)
        {:error, reason} -> {:error, reason}
      end\
      """
    },
    %{
      title: "with for happy paths",
      code: """
      with {:ok, user} <- fetch_user(id),
           {:ok, order} <- create_order(user, items) do
        {:ok, order}
      end\
      """
    },
    %{
      title: "GenServer call",
      code: """
      def handle_call(:pop, _from, [head | tail]) do
        {:reply, head, tail}
      end\
      """
    },
    %{
      title: "Recursion with an accumulator",
      code: """
      def sum([], acc), do: acc
      def sum([head | tail], acc), do: sum(tail, acc + head)\
      """
    },
    %{
      title: "Comprehension with a filter",
      code: """
      for x <- 1..10, rem(x, 2) == 0, into: %{} do
        {x, x * x}
      end\
      """
    },
    %{
      title: "Enum.reduce into a map",
      code: """
      Enum.reduce(words, %{}, fn word, acc ->
        Map.update(acc, word, 1, &(&1 + 1))
      end)\
      """
    },
    %{
      title: "Guards",
      code: """
      def grade(score) when score >= 90, do: "A"
      def grade(score) when score >= 75, do: "B"
      def grade(_score), do: "C"\
      """
    },
    %{
      title: "Supervisor children",
      code: """
      children = [
        {Registry, keys: :unique, name: MyApp.Registry},
        {Task.Supervisor, name: MyApp.TaskSupervisor}
      ]

      Supervisor.start_link(children, strategy: :one_for_one)\
      """
    },
    %{
      title: "Task.async_stream",
      code: """
      urls
      |> Task.async_stream(&fetch/1, max_concurrency: 8)
      |> Enum.map(fn {:ok, result} -> result end)\
      """
    },
    %{
      title: "Struct with defaults",
      code: """
      defmodule Point do
        defstruct x: 0, y: 0

        def add(%Point{} = a, %Point{} = b) do
          %Point{x: a.x + b.x, y: a.y + b.y}
        end
      end\
      """
    },
    %{
      title: "Binary pattern matching",
      code: """
      <<version::8, length::16, payload::binary-size(length), rest::binary>> =
        packet\
      """
    },
    %{
      title: "Keyword options",
      code: """
      def connect(host, opts \\\\ []) do
        port = Keyword.get(opts, :port, 5432)
        timeout = Keyword.get(opts, :timeout, 5_000)
        {host, port, timeout}
      end\
      """
    },
    %{
      title: "Stream, lazily",
      code: """
      File.stream!("access.log")
      |> Stream.filter(&String.contains?(&1, "ERROR"))
      |> Stream.take(10)
      |> Enum.to_list()\
      """
    },
    %{
      title: "Spawn and receive",
      code: """
      parent = self()
      spawn(fn -> send(parent, {:done, heavy_work()}) end)

      receive do
        {:done, result} -> result
      after
        5_000 -> :timeout
      end\
      """
    }
  ]

  def count, do: length(@snippets)

  def get(index), do: Enum.at(@snippets, index)

  @doc "A random snippet index, never equal to `except` so Next always changes the text."
  def random_index(except \\ nil) do
    index = :rand.uniform(count()) - 1

    if index == except, do: rem(index + 1, count()), else: index
  end
end
