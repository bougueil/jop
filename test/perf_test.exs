defmodule PerfTest do
  use ExUnit.Case
  @jop_log "test_jop_log"
  @iterations 2_000_000

  setup do
    ncores = System.schedulers_online()
    number_logs = div(@iterations, ncores) * ncores
    Process.sleep(500)
    {:ok, number_logs: number_logs, ncores: ncores}
  end

  test "measure logging", ctx do
    joplog = Jop.init(@jop_log)

    {tlog, _} =
      fn ->
        for i <- 1..ctx.number_logs,
            do: Jop.log(joplog, <<i::size(40)>>, {<<"data.", <<i::size(40)>>::binary>>})
      end
      |> :timer.tc()

    throughput = div(ctx.number_logs * 1_000_000, tlog)
    IO.puts("throughput #{throughput} logs/s. (1 process)")
    assert Enum.count(joplog) == ctx.number_logs
  end

  test "measure concurrent logging", ctx do
    joplog = Jop.init(@jop_log)
    chunks = Enum.chunk_every(1..ctx.number_logs, div(ctx.number_logs, ctx.ncores))

    {tlog, _} =
      fn ->
        Task.async_stream(
          chunks,
          fn chunk ->
            for i <- chunk,
                do: Jop.log(joplog, <<i::size(40)>>, {<<"data.", <<i::size(40)>>::binary>>})
          end,
          ordered: false,
          timeout: :infinity
        )
        |> Stream.run()
      end
      |> :timer.tc()

    throughput = div(ctx.number_logs * 1_000_000, tlog)
    IO.puts("throughput #{throughput} logs/s. (concurrency: #{ctx.ncores} cores)")
    assert Enum.count(joplog) == ctx.number_logs
  end
end
