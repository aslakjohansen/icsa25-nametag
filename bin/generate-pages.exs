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
    sponsor_color = "orange!80!black"
    case header do
      "Mjølner Informatics" -> sponsor_color
      "DDSA" -> sponsor_color
      "ICSA Chair" -> "black"
      "ICSA Organizer" -> "purple"
      "ICSA Staff" -> "purple"
      "Author"<>_ -> "blue!80"
      "Gala Participant" -> "teal"
      "Participant"<>_ -> "olive"
      _ -> "pink"
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
      {%{"Participant category" => "Mjolner Informatics - no fee"}, _, _} -> "Mjølner Informatics"
      {%{"Company/Institution" => "Mjølner Informatics"}, _, _} -> "Mjølner Informatics"
      {_, "mjolner.dk", _} -> "Mjølner Informatics"
      {_, _, "mjolner.dk"} -> "Mjølner Informatics"
      {%{"Participant category" => "Danish Data Science Academy"}, _, _} -> "DDSA"
      {%{"Participant category" => "ICSA Chair"}, _, _} -> "ICSA Chair"
      {%{"Participant category" => "SDU Organizers - no fee"}, _, _} -> "ICSA Organizer"
      {%{"Paper Title and Number" => paper}, _, _} when paper != "" -> "Author"
      {%{"Participant category" => "Student Volunteer"}, _, _} -> "ICSA Staff"
      {%{"Participant category" => "ICSA Staff"}, _, _} -> "ICSA Staff"
      {%{"Participant category" => "Gala Dinner"}, _, _} -> "Gala Participant"
      _ -> "Participant"
    end
  end
  
  defp datum2days(datum) do
    cat = Map.get(datum, "Participant category")
    subcat = Map.get(datum, "Participation category")
    cond do
      subcat =~ ~r/Full conference/i -> {true, true, true, true, true}
      subcat =~ ~r/Workshop, 1 day/i -> {false, false, false, true, false}
      cat =~ ~r/Data Science Day/i -> {false, true, false, false, false}
      cat =~ ~r/Full conference/i -> {true, true, true, true, true}
      cat =~ ~r/ICSA Chair/i -> {true, true, true, true, true}
      cat =~ ~r/Main conference only/i -> {false, false, true, true, true}
      cat =~ ~r/Mjolner Informatics/i -> {true, true, true, true, true}
      cat =~ ~r/SDU Organizers/i -> {true, true, true, true, true}
      cat =~ ~r/Speaker/i -> {true, true, true, true, true}
      cat =~ ~r/March 31st/i -> {true, false, false, false, false}
      cat =~ ~r/April 1st/i -> {false, true, false, false, false}
      cat =~ ~r/Danish Data Science Academy/i -> {false, true, false, false, false}
      cat =~ ~r/2 days/i -> {true, true, false, false, false}
      cat =~ ~r/Gala Dinner/i -> {false, false, false, false, false}
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
      header = datum2header(datum)
      color = header2color(header)
      {ws1, ws2, conf1, conf2, conf3} = datum2days(datum)
      reception = Map.get(datum, "Options Reception Yes - I will participate in the ICSA reception")
      tour = Map.get(datum, "Options City tour Yes - I would like to participate in the city tour")
      gala =
        cond do
          Map.get(datum, "Options Gala dinner - free ticket. I would like to attend the gala dinner.")=="1" -> true
          header=="Gala Participant" -> true
          true -> false
        end
      plus =
        case Map.get(datum, "Options Additional tickets for Gala Dinner Select amount of additional Gala Dinner tickets") do
          "" -> ""
          num -> "+"<>num
        end
      
      """
      \\TopBanner{#{color}}{#{header}}
      \\MainText{black}{
        #{name}
        \\\\
        \\textcolor{#{color}}{#{affil}}
      }
      %\\BottomBanner{#{color}}{}
      \\OptionBanner{#{color}}
      \\StaticMaterial
      #{if ws1 do "" else "%" end}\\OptionWSI
      #{if ws2 do "" else "%" end}\\OptionWSII
      #{if conf1 do "" else "%" end}\\OptionConfI
      #{if conf2 do "" else "%" end}\\OptionConfII
      #{if conf3 do "" else "%" end}\\OptionConfIII
      #{if tour=="1" do "" else "%" end}\\OptionTour
      #{if reception=="1" do "" else "%" end}\\OptionReception
      #{if gala do "" else "%" end}\\OptionGala{#{plus}}
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
#    |> (fn data -> [data |> Enum.at(147)] end).()
    |> Generator.generate()
    |> IO.puts()
  end
end

Script.run()

