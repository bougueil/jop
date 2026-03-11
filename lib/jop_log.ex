# See LICENSE for licensing information.

defmodule Jop do
  import JLValid, only: [safe_ets: 2]

  @tag_start_date "jop_start_date"

  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.at(1)

  defstruct [:ets]
  @type t :: %__MODULE__{ets: atom()}

  @doc """
  Initialize a Jop instance with a `name`
  The initialization clears out all entries found and inserts a start time log
  returns a handle `%Jop{}`.
  """
  @spec init(log_name :: binary()) :: Jop.t()
  def init(name) when is_binary(name) do
    tab = String.to_atom(name)

    safe_ets tab do
      Jop.ref(name)
      |> reset()
    end

    _ = :ets.new(tab, [:bag, :named_table, :public, write_concurrency: true])

    jop = Jop.ref(name)

    IO.puts("Jop now logging on memory jop #{jop.ets}.")
    log(jop, @tag_start_date, "#{JLCommon.date_str()}")
  end

  @doc """
  returns the handle from the Jop instance name.
  """
  @spec ref(name :: String.t()) :: Jop.t()
  def ref(name) when is_binary(name) do
    tab = String.to_atom(name)

    %Jop{ets: tab}
  end

  @doc """
  Log a `key` and its `value` with a `jop` instance handle.
  returns the handle.
  """
  @spec log(jop :: Jop.t(), key :: any, value :: any) :: Jop.t()
  def log(%Jop{ets: tab} = jop, key, value) do
    safe_ets(tab, do: :ets.insert(tab, {key, value, now_μs()}))
    jop
  end

  @doc """
  Write on disk a `jop` instance logs.
  2 log files are generated : dates.gz and keys.gz
  unless option `:notstop` is given, the logging is stopped.
  """
  @spec flush(jop :: Jop.t(), opt :: atom) :: Jop.t()
  def flush(%Jop{ets: tab} = jop, opt \\ nil) do
    _ =
      safe_ets tab do
        {logs, t0} =
          case start_time(jop) do
            nil ->
              {[], 0}

            t0 ->
              {:ets.tab2list(tab), t0}
          end

        _ =
          if opt == :nostop do
            IO.puts(
              "Jop continue logging.\nflushing memory jop #{tab} (#{Enum.count(jop)} records) on files ..."
            )

            clear(jop)
          else
            IO.puts(
              "Jop logging stopped.\nflushing memory jop #{tab} (#{Enum.count(jop)} records) on files ..."
            )

            reset(jop)
          end

        JL.Writer.flush(tab, t0, logs)
      end

    jop
  end

  @doc """
  Returns the start time of a `jop` instance or `nil` if not started.
  """
  @spec start_time(jop :: Jop.t()) :: nil | integer()
  def start_time(%Jop{ets: tab}) do
    case :ets.lookup(tab, @tag_start_date) do
      [{_, _, t0}] ->
        t0

      [] ->
        nil
    end
  end

  defp reset(%Jop{ets: tab}),
    do: safe_ets(tab, do: :ets.delete(tab))

  @doc """
  Erase all log entries of a `jop` instance.
  """
  @spec clear(jop :: Jop.t()) :: Jop.t()
  def clear(%Jop{ets: tab} = jop) do
    safe_ets tab do
      t0 = start_time(jop)
      :ets.delete_all_objects(tab)

      if t0 do
        :ets.insert(tab, {@tag_start_date, t0, now_μs()})
      end
    end

    jop
  end

  defp now_μs, do: System.monotonic_time(:microsecond)

  @doc """
  Returns true if the `jop` instance is initialized

  See init/1.
  """
  def initialized?(%Jop{ets: tab}),
    do: safe_ets(tab, do: true, else: false)

  defimpl Enumerable do
    @doc """
    Returns the `jop` logs size.
    """
    @spec count(jop :: Jop.t()) :: {:ok, integer()}
    def count(%Jop{ets: tab}) do
      {:ok, max(0, :ets.info(tab, :size) - 1)}
    end

    @doc """
    Returns if one or more elements in the `jop` logs has key `key`.
    """
    @spec member?(jop :: Jop.t(), key :: any) :: {:ok, boolean}
    def member?(%Jop{ets: tab}, key) do
      {:ok, :ets.member(tab, key)}
    end

    def reduce(%Jop{ets: tab}, acc, fun) do
      :ets.tab2list(tab)
      |> List.keysort(2)
      |> Enum.drop(1)
      |> Enum.map(fn {k, v, _t} -> {k, v} end)
      |> Enumerable.List.reduce(acc, fun)
    end

    def slice(_id) do
      {:error, __MODULE__}
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%Jop{ets: tab} = jop, opts) do
      safe_ets tab do
        concat(["#Jop<#{tab}:size(", to_doc(Enum.count(jop), opts), ")>"])
      else
        concat(["#Jop<#{tab}:uninitialized>"])
      end
    end
  end
end
