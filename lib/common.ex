# See LICENSE for licensing information.

defmodule JLValid do
  @moduledoc false

  defmacro ets?(tab, clauses) do
    valid_if(tab, clauses)
  end

  defp valid_if(tab, do: do_clause) do
    valid_if(tab, do: do_clause, else: nil)
  end

  defp valid_if(tab, do: do_clause, else: else_clause) do
    quote do
      case :undefined != :ets.info(unquote(tab), :size) do
        x when :"Elixir.Kernel".in(x, [false, nil]) -> unquote(else_clause)
        _ -> unquote(do_clause)
      end
    end
  end
end

defmodule JLCommon do
  @moduledoc false

  @date_format ".~p_~2.2.0w_~2.2.0w_~2.2.0w.~2.2.0w.~2.2.0w"

  def date_str do
    hms =
      List.flatten(
        for e <- Tuple.to_list(:calendar.universal_time_to_local_time(:calendar.universal_time())) do
          Tuple.to_list(e)
        end
      )

    :io_lib.format(@date_format, hms)
  end
end
