# See LICENSE for licensing information.

defmodule JL.Writer do
  @moduledoc false

  @usecond_format "~2.2.0w:~2.2.0w:~2.2.0w_~3.3.0w.~3.3.0w"

  defp fname(tab, ext), do: ["jop_#{tab}", JLCommon.date_str(), "_", ext]

  defp fmt_duration_us(duration_us) do
    sec = div(duration_us, 1_000_000)
    rem_us = rem(duration_us, 1_000_000)
    ms = div(rem_us, 1000)
    us = rem(rem_us, 1000)
    {_, {h, m, s}} = :calendar.gregorian_seconds_to_datetime(sec)
    :io_lib.format(@usecond_format, [h, m, s, ms, us])
  end

  def flush(tab, t0, logs) do
    names = for f <- ~w(dates keys), do: fname(tab, "#{f}.gz")
    [fa, fb] = for name <- names, do: File.open!(name, [:write, :compressed, encoding: :unicode])

    # factorize
    # flush log to the 'temporal' log file
    awaits = [
      {Task.async(fn ->
         for {k, op, t} <- List.keysort(logs, 2) do
           IO.puts(fa, "#{fmt_duration_us(t - t0)} #{inspect(k)}: #{inspect(op)}")
         end
       end), fa},
      # flush log to 'spatial' log file
      {Task.async(fn ->
         for {k, op, t} <- List.keysort(logs, 0) do
           IO.puts(fb, "#{inspect(k)}: #{fmt_duration_us(t - t0)} #{inspect(op)}")
         end
       end), fb}
    ]

    for {task, fd} <- awaits,
        do:
          (
            Task.await(task, :infinity)
            _ = File.close(fd)
          )

    IO.puts("log stored in :")
    for name <- names, do: IO.puts("- #{name}")
  end
end
