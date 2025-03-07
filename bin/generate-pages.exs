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
  defp cleancat(cat) do
    case String.split(cat, " - ") do
      ["Full conference" = name|_] -> name
      ["Main conference only" = name|_] -> name
      ["ICSA Chair" = name|_] -> name
      ["Workshops/tutorials" = name|[days|_]] -> name <>": "<>days
      name -> name
    end
  end
  
  defp cat2color(ccat) do
    case ccat do
      "Full conference" -> "purple"
      "Main conference only" -> "orange"
      "ICSA Chair" -> "teal"
      "Workshops/tutorials"<>_ -> "blue"
      _ -> "black"
    end
  end
  
  def generate(data) do
    IO.puts(inspect data)
    data
    |> Enum.map(fn datum ->
      name  = Map.get(datum, "First name")<>" "<>Map.get(datum, "Last name")
      _ident = Map.get(datum, "Participant ID")
      cat = Map.get(datum, "Participant category")
      ccat = cleancat(cat)
      color = cat2color(ccat)
      
      """
      \\StaticMaterial
      \\TopBanner{#{color}}{#{name}}
      \\BottomBanner{#{color}}{#{ccat}}
      \\OptionBanner{#{color}}
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

