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

  defp support?([p1, p2, p3, p4, p5]),
       do: p2.l < p1.l and p3.l < p2.l and p3.l < p4.l and p4.l < p5.l

  defp resistance?([p1, p2, p3, p4, p5]),
       do: p2.h > p1.h and p3.h > p2.h and p3.h > p4.h and p4.h > p5.h

  defp get_support_area([p1, p2, p3, p4, p5]),
       do: %{l: p3.l, h: ((p1.h + p2.h + p3.h + p4.h + p5.h) / @fractal_size)}

  defp get_resistance_area([p1, p2, p3, p4, p5]),
       do: %{h: p3.h, l: ((p1.l + p2.l + p3.l + p4.l + p5.l) / @fractal_size)}

  defp avg_bar_height(bar_list),
       do: bar_height_sum(bar_list) / E.count(bar_list)

  defp bar_height_sum(bar_list),
       do: E.reduce(bar_list, 0, fn p, acc -> (p.h - p.l) + acc end)

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


  # SR.support_and_resistance_areas([%{l: 1, h: 2}, %{l: 4, h: 6}, %{l: 5, h: 7}, %{l: 4, h: 6}, %{l: 2, h: 3}, %{l: 5, h: 7}, %{l: 8, h: 9}, %{l: 15, h: 16}])
  #
  # => [support: %{h: 8.0, l: 2}, resistance: %{h: 7, l: 1.5}]


end