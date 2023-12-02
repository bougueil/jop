defmodule PerfTest do
  use ExUnit.Case
  @jop_log "test_jop_log"

  test "measure logging" do
    joplog = Jop.init(@jop_log)

    n = 1_000_000

    {tlog, _} =
      fn ->
        for i <- 1..n,
            do: Jop.log(joplog, <<i::size(40)>>, {<<"data.", <<i::size(40)>>::binary>>})
      end
      |> :timer.tc()

    througput = div(n * 1_000_000, tlog)
    IO.puts("througput #{througput} logs/s.")
    assert Enum.count(joplog) == n
  end
end
