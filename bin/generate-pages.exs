#!/usr/bin/env elixir

Mix.install([:xlsx_reader])

defmodule Parser do
  def parse(filename) do
    {:ok, package} = XlsxReader.open(filename)
    {:ok, rows} = XlsxReader.sheet(package, "Sheet 1")
    [header_data|data] = rows
    header = parse_header(header_data)
    Enum.map(data, fn datum -> parse_datum(datum, header) end)
  end
  
  defp parse_header(header_data) do
    header_data
    |> Enum.with_index(fn element, index -> {index, element} end)
    |> Map.new()
  end
  
  defp parse_datum(datum, header) do
    datum
    |> Enum.with_index(fn element, index -> {Map.get(header, index), element} end)
    |> Map.new()
  end
end

defmodule Generator do
  def generate(data) do
    IO.puts(inspect data)
    data
    |> Enum.map(fn datum ->
      name  = Map.get(datum, "First name")<>" "<>Map.get(datum, "Last name")
      _ident = Map.get(datum, "Participant ID")
      
      """
      \\StaticMaterial
      \\TopBanner{purple}{#{name}}
      \\BottomBanner{purple}
      \\newpage
      
      """
      end)
    |> Enum.join()
  end
end

defmodule Script do
  def run() do
    "../data/ICSA.xlsx"
    |> Parser.parse()
    |> Generator.generate()
    |> IO.puts()
  end
end

Script.run()

