# See LICENSE for licensing information.

defmodule Jop do
  require JLValid
  @tag_start "jop_start"

  @moduledoc """
  Documentation for Jop an in memory log

  ## Example

  iex> "mylog"
  ...> |> Jop.init()
  ...> |> Jop.log("device_1", data: 112)
  ...> |> Jop.log("device_2", data: 113)
  ...> |> Jop.flush()

  """

  defstruct [:ets]
  @type t :: %__MODULE__{ets: atom()}

  @doc """
    Initialize Jop with a log name.
  returns a handle %Joplog{}
  """
  @spec init(log_name :: binary()) :: Jop.t()
  def init(log_name) when is_binary(log_name) do
    tab = String.to_atom(log_name)

    JLValid.ets? tab do
      Jop.ref(log_name)
      |> reset()
    end

    _ = :ets.new(tab, [:bag, :named_table, :public])

    joplog = Jop.ref(log_name)

    IO.puts("Jop now logging on memory joplog #{joplog.ets}.")
    log(joplog, @tag_start, "#{JLCommon.date_str()}")
  end

  @doc """
  returns a handle from a log name
  does not require JOP doesn't require init/1
  """
  @spec ref(log_name :: String.t()) :: Jop.t()
  def ref(log_name) when is_binary(log_name) do
    tab = String.to_atom(log_name)

    %Jop{ets: tab}
  end

  @doc """
  log with the handle jop a key and its value
  returns the handle.
  """
  @spec log(Jop.t(), any, any) :: Jop.t()
  def log(%Jop{ets: tab} = jop, key, value) do
    JLValid.ets?(tab, do: :ets.insert(tab, {key, value, now_μs()}))
    jop
  end

  @doc """
  write a joplog on disk from a handle.
  2 logs are generated : dates.gz and keys.gz
  unless option :notstop is used, logging is stopped.
  """
  @spec flush(Jop.t(), opt :: atom) :: Jop.t()
  def flush(%Jop{ets: tab} = joplog, opt \\ nil) do
    JLValid.ets? tab do
      {logs, t0} =
        case lookup_tag_start(tab) do
          nil ->
            {[], 0}

          t0 ->
            {:ets.tab2list(tab), t0}
        end

      if opt == :nostop do
        IO.puts(
          "Jop continue logging.\nflushing memory joplog #{tab} (#{Enum.count(joplog)} records) on files ..."
        )

        clear(joplog)
      else
        IO.puts(
          "Jop logging stopped.\nflushing memory joplog #{tab} (#{Enum.count(joplog)} records) on files ..."
        )

        reset(joplog)
      end

      JL.Writer.flush(tab, t0, logs)
    end

    joplog
  end

  defp reset(%Jop{ets: tab}),
    do: JLValid.ets?(tab, do: :ets.delete(tab))

  defp lookup_tag_start(tab) do
    case :ets.lookup(tab, @tag_start) do
      [{_, _, t0}] ->
        t0

      [] ->
        nil
    end
  end

  @doc """
  erase all entries from the jop handle
  """
  @spec clear(Jop.t()) :: Jop.t()
  def clear(%Jop{ets: tab} = jop) do
    JLValid.ets? tab do
      t0 = lookup_tag_start(tab)
      :ets.delete_all_objects(tab)

      if t0 do
        :ets.insert(tab, {@tag_start, t0, now_μs()})
      end
    end

    jop
  end

  defp now_μs, do: System.monotonic_time(:microsecond)

  @doc """
  returns if the handle  is initialized with an ets table
  """
  def is_initialized(%Jop{ets: tab}),
    do: JLValid.ets?(tab, do: true, else: false)

  defimpl Enumerable do
    @doc """
    returns the size of the Jop log
    """
    def count(%Jop{ets: tab}) do
      {:ok, max(0, :ets.info(tab, :size) - 1)}
    end

    @doc """
    returns if `key`is member of Jop
    """
    @spec member?(Jop.t(), any) :: {:ok, boolean}
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
      JLValid.ets? tab do
        concat(["#Jop<#{tab}:size(", to_doc(Enum.count(jop), opts), ")>"])
      else
        concat(["#Jop<#{tab}:uninitialized>"])
      end
    end
  end
end
