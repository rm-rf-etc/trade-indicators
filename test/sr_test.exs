defmodule TradeIndicators.Tests.SR do
  use ExUnit.Case
  alias TradeIndicators.Util, as: U
  alias TradeIndicators.SR

  @msft_data TradeIndicators.Tests.Fixtures.fixture(:msft_m1_2020_08_17)
  @expected_sr_values [
    {:resistance, %{h: 209.71, l: 209.58, t: 1597657384}},
    {:support, %{h: 208.94, l: 208.94, t: 1597657204}},
    {:resistance, %{h: 210.16, l: 209.84, t: 1597656664}}
  ]

  describe "SR" do
    test "support and resistance" do
      U.context(fn ->
        sr_list = SR.support_and_resistance_areas(@msft_data)

        sr_result = for {type, val} <- sr_list, do: {type, %{h: U.rnd(val.h), l: U.rnd(val.l), t: val.t}}

        assert sr_result == @expected_sr_values
      end)
    end
  end

end

