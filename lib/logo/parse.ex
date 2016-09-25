defmodule Logo.Parse do
  def parse(code) do
    code
    |> Logo.Lex.parse
    |> IO.inspect
    |> Logo.AST.parse
    |> IO.inspect
  end
end
