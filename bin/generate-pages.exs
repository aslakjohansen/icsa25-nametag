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
  
  defp header2color(header) do
    case header do
      "Mjølner Informatics" -> "orange"
      "ICSA Chair" -> "purple"
      "Author"<>_ -> "blue"
      "Student Volunteer" -> "teal"
      "Participant"<>_ -> "olive"
      _ -> "black"
    end
  end
  
  defp datum_cleanaffil(datum) do
    affil =
      datum
      |> Map.get("Company/Institution")
      |> String.replace("&", "\\&", global: true)
      |> String.replace("¨a", "ä", global: true)
    
    Map.put(datum, "Company/Institution", affil)
  end
  
  defp datum2header(datum) do
    domain_invoice =
      datum
      |> Map.get("Invoice field E-mail")
      |> String.split("@")
      |> Enum.at(1)
    domain =
      datum
      |> Map.get("E-mail")
      |> String.split("@")
      |> Enum.at(1)
    case {datum, domain_invoice, domain} do
      {%{"Company/Institution" => "Mjølner Informatics"}, _, _} -> "Mjølner Informatics"
      {_, "mjolner.dk", _} -> "Mjølner Informatics"
      {_, _, "mjolner.dk"} -> "Mjølner Informatics"
      {%{"Participant category" => "ICSA Chair"}, _, _} -> "ICSA Chair"
      {%{"Paper Title and Number" => paper}, _, _} when paper != "" -> "Author"
      {%{"Participant category" => "Student Volunteer"}, _, _} -> "Student Volunteer"
      _ -> "Participant"
    end
  end
  
  def generate(data) do
#    IO.puts(inspect data)
    data
    |> Enum.sort(&(Map.get(&1, "First name") <= Map.get(&2, "First name")))
    |> Enum.map(fn datum -> datum_cleanaffil(datum) end)
    |> Enum.map(fn datum ->
      name  = Map.get(datum, "First name")<>" "<>Map.get(datum, "Last name")
      affil = Map.get(datum, "Company/Institution")
      _ident = Map.get(datum, "Participant ID")
      cat = Map.get(datum, "Participant category")
      ccat = cleancat(cat)
      header = datum2header(datum)
      color = header2color(header)
      
      """
      \\TopBanner{#{color}}{#{header}}
      \\MainText{black}{
        #{name}
        \\\\
        \\textcolor{#{color}}{#{affil}}
      }
      \\BottomBanner{#{color}}{}
      \\OptionBanner{#{color}}
      \\StaticMaterial
      \\OptionWSI
      \\OptionWSII
      \\OptionConfI
      \\OptionConfII
      \\OptionConfIII
      \\OptionTour
      \\OptionReception
      \\OptionGala{+1}
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
    |> (fn data -> [data |> Enum.at(147)] end).()
    |> Generator.generate()
    |> IO.puts()
  end
end

Script.run()

