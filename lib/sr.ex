defmodule TradeIndicators.SR do
  alias Enum, as: E

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

  defp support?([b1, b2, b3, b4, b5]),
       do: b2.l < b1.l and b3.l < b2.l and b3.l < b4.l and b4.l < b5.l

  defp resistance?([b1, b2, b3, b4, b5]),
       do: b2.h > b1.h and b3.h > b2.h and b3.h > b4.h and b4.h > b5.h

  defp get_support_area([_, _, bar, _, _]),
       do: %{h: min(bar.o, bar.c), l: bar.l}

  defp get_resistance_area([_, _, bar, _, _]),
       do: %{h: bar.h, l: max(bar.o, bar.c)}

  defp avg_bar_height(bar_list),
       do: bar_height_sum(bar_list) / E.count(bar_list)

  defp bar_height_sum(bar_list),
       do: E.reduce(bar_list, 0, fn bar, acc -> (bar.h - bar.l) + acc end)

  defp filter_levels([], _) do [] end
  defp filter_levels([head|tail], avg_bar_height) do
    acc = filter_levels(tail, avg_bar_height)
    cond do
      far_from_level?(avg_bar_height, acc, head) -> acc ++ [head]
      :else -> acc
    end
  end

  defp far_from_level?(avg_bar_height, [], _),
       do: true
  defp far_from_level?(avg_bar_height, [{:support, val}|_tail], {:support, cur_val}),
       do: abs(cur_val.l - val.l) > avg_bar_height
  defp far_from_level?(avg_bar_height, [{:resistance, val}|_tail], {:support, cur_val}),
       do: abs(cur_val.h - val.l) > avg_bar_height
  defp far_from_level?(avg_bar_height, [{:support, val}|_tail], {:resistance, cur_val}),
       do: abs(cur_val.l - val.h) > avg_bar_height
  defp far_from_level?(avg_bar_height, [{:resistance, val}|_tail], {:resistance, cur_val}),
       do: abs(cur_val.h - val.h) > avg_bar_height

  """

  TradeIndicators.SR.support_and_resistance_areas([
     %{l: 1, o: 2, c: 2, h: 3},
     %{l: 4, o: 5, c: 5, h: 6},
     %{l: 5, o: 6, c: 6, h: 7},
     %{l: 4, o: 5, c: 5, h: 6},
     %{l: 1, o: 2, c: 2, h: 3},
     %{l: 5, o: 6, c: 6, h: 7},
     %{l: 8, o: 9, c: 9, h: 10},
     %{l: 11, o: 13, c: 13, h: 16}
  ])

  # => [support: %{h: 2, l: 1}, resistance: %{h: 7, l: 6}]

  """


end