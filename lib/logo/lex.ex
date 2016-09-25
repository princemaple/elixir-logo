defmodule Logo.Lex do
  def parse(code) do
    code
    |> String.replace(~r/([\(\)\[\]])/, ~S{ \1 })
    |> String.split(~r/\s+/, trim: true)
    |> do_lex([])
  end

  @tokens [
    command: ~w(fd bk lt rt repeat pu pd setx sety setxy make print sc)a,
    operator: ~w(+ - * /)a
  ]

  for {type, tokens} <- @tokens do
    for token <- tokens do
      defp do_lex([unquote(Atom.to_string(token)) | rest], state) do
        do_lex(rest, [{unquote(type), unquote(token)} | state])
      end
    end
  end

  defp do_lex(["[" | rest], state) do
    {list, rest} = do_lex(rest, [])
    do_lex(rest, [{:list, list} | state])
  end

  defp do_lex(["]" | rest], state) do
    {Enum.reverse(state), rest}
  end

  defp do_lex(["(" | rest], state) do
    {group, rest} = do_lex(rest, [])
    do_lex(rest, [{:group, group} | state])
  end

  defp do_lex([")" | rest], state) do
    {Enum.reverse(state), rest}
  end

  defp do_lex([other | rest], state) do
    other =
      cond do
        other =~ ~r/^\d+$/ ->
          {number, _} = Integer.parse(other)
          {:number, number}
        String.starts_with?(other, "\"") ->
          "\"" <> string = other
          {:string, string}
        String.starts_with?(other, ":") ->
          ":" <> name = other
          {:variable, name}
      end

    do_lex(rest, [other | state])
  end

  defp do_lex([], state), do: Enum.reverse(state)
end
