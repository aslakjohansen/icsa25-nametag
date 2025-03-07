#!/usr/bin/env elixir

defmodule Script do
  def run() do
    """
    \\StaticMaterial
    \\TopBanner{purple}{Aslak Johansen}
    """
    |> IO.puts()
  end
end

Script.run()

