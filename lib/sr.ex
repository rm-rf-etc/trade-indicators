defmodule TradeIndicators.SR do
  alias Enum, as: E
  alias Decimal, as: D

  def support_and_resistance_areas(bar_list) when is_list(bar_list) do
    avg_bar_height = avg_bar_height(bar_list)

    bar_list
    |> create_fractals()
    |> find_levels()
    |> filter_levels(avg_bar_height)
  end

  @fractal_size 5
  defp create_fractals(bar_list),
       do: E.chunk_every(bar_list, @fractal_size, 1, :discard)

  defp find_levels(fractals),
       do: E.reduce(fractals, [], fn fractal, acc -> find_area(fractal, acc) end)

  defp find_area(fractal, acc) do
    cond do
      support?(fractal) -> acc ++ [{:support, get_support_area(fractal)}]
      resistance?(fractal) -> acc ++ [{:resistance, get_resistance_area(fractal)}]
      :else -> acc
    end
  end

  defp support?([b1, b2, b3, b4, b5]) do
     D.lt?(b2.l, b1.l)
     and D.lt?(b3.l, b2.l)
     and D.lt?(b3.l, b4.l)
     and D.lt?(b4.l, b5.l)
  end

  defp resistance?([b1, b2, b3, b4, b5]) do
    D.gt?(b2.h, b1.h)
    and D.gt?(b3.h, b2.h)
    and D.gt?(b3.h, b4.h)
    and D.gt?(b4.h, b5.h)
  end

  defp get_support_area([_, _, bar, _, _]),
       do: %{t: bar.t, h: D.min(bar.o, bar.c), l: bar.l}

  defp get_resistance_area([_, _, bar, _, _]),
       do: %{t: bar.t, h: bar.h, l: D.max(bar.o, bar.c)}

  defp avg_bar_height(bar_list),
       do: bar_height_sum(bar_list) |> D.div(E.count(bar_list))

  defp bar_height_sum(bar_list),
       do: E.reduce(bar_list, D.new("0.00"), fn bar, acc -> D.sub(bar.h, bar.l) |> D.add(acc) end)

  defp filter_levels([], _) do [] end
  defp filter_levels([head|tail], avg_bar_height) do
    acc = filter_levels(tail, avg_bar_height)
    cond do
      far_from_level?(avg_bar_height, acc, head) -> acc ++ [head]
      :else -> acc
    end
  end

  defp far_from_level?(_, [], _),
       do: true
  defp far_from_level?(avg_bar_height, [{:support, val}|_tail], {:support, cur_val}),
       do: D.sub(cur_val.l, val.l) |> D.abs() |> D.gt?(avg_bar_height)
  defp far_from_level?(avg_bar_height, [{:resistance, val}|_tail], {:support, cur_val}),
       do: D.sub(cur_val.h, val.l) |> D.abs() |> D.gt?(avg_bar_height)
  defp far_from_level?(avg_bar_height, [{:support, val}|_tail], {:resistance, cur_val}),
       do: D.sub(cur_val.l, val.h) |> D.abs() |> D.gt?(avg_bar_height)
  defp far_from_level?(avg_bar_height, [{:resistance, val}|_tail], {:resistance, cur_val}),
       do: D.sub(cur_val.h, val.h) |> D.abs() |> D.gt?(avg_bar_height)


end