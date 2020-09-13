defmodule TradeIndicators.SR do
  alias Enum, as: E

  def support_and_resistance_areas(bar_list) when is_list(bar_list) do
    bar_list
    |> create_fractals()
    |> find_levels()
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


end