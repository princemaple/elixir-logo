defmodule Logo.Parse do
  def parse(code) do
    code
    |> lex()
    |> IO.inspect
    |> ast()
    |> IO.inspect
  end

  def lex(code) do
    code
    |> String.replace(~r/([\(\)\[\]])/, ~S{ \1 })
    |> String.split(~r/\s+/, trim: true)
    |> do_lex([])
  end

  @tokens [
    command: ~w(fd bk lt rt repeat pu pd setx sety setxy print sc)a,
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
    {group_state, rest} = do_lex(rest, [])
    do_lex(rest, [{:group, group_state} | state])
  end

  defp do_lex(["]" | rest], state) do
    {Enum.reverse(state), rest}
  end

  defp do_lex(["(" | rest], state) do
    {number_expr_group, rest} = do_lex(rest, [])
    do_lex(rest, [{:number_expr_group, number_expr_group} | state])
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

  def ast(tokens) do
    command_ast(tokens)
  end

  defp command_ast([]), do: []

  defp command_ast([{:command, command} | rest])
    when command in [:fd, :bk, :lt, :rt, :setx, :sety]
  do
    {num_expr_arg, rest} = number_expr_ast(rest)
    [{{:command, command}, [num_expr_arg]} | command_ast(rest)]
  end

  defp number_expr_ast(tokens) do
    do_number_expr_ast(tokens, [], [])
  end

  defp do_number_expr_ast([{:number_expr_group, number_expr_group} | rest], state, cache) do
    do_number_expr_ast([{:number_expr_ast, do_number_expr_ast(number_expr_group, [], [])} | rest], state, cache)
  end

  defp do_number_expr_ast([{operand_type, _operand} = a, {:operator, operator} = op | b], state, [])
    when operand_type in [:number, :number_expr_ast, :variable] and operator in [:+, :-],
    do: do_number_expr_ast(b, [op, a | state], [])

  defp do_number_expr_ast([{operand_type, _operand} = a, {:operator, operator} = op | b], state, cache)
    when operand_type in [:number, :number_expr_ast, :variable] and operator in [:*, :/],
    do: do_number_expr_ast(b, state, [op, a | cache])

  defp do_number_expr_ast([{operand_type, _operand} = a | rest], [], [])
    when operand_type in [:number, :number_expr_ast, :variable], do: {a, rest}

  defp do_number_expr_ast([{:operator, operator} = op, {operand_type, _operand} = b | rest], state, [])
    when operand_type in [:number, :number_expr_ast, :variable] and operator in [:+, :-],
    do: {do_binary_op_ast([b, op | state]), rest}

  defp do_number_expr_ast([{operand_type, _operand} = b | rest], state, [])
    when operand_type in [:number, :number_expr_ast, :variable],
    do: {do_binary_op_ast([b | state]), rest}

  defp do_number_expr_ast([{operand_type, _operand} = b | rest], state, cache)
    when operand_type in [:number, :number_expr_ast, :variable],
    do: do_number_expr_ast(rest, [{:number_expr_ast, do_binary_op_ast([b | cache])} | state], [])

  defp do_number_expr_ast(rest, state, []), do: {do_binary_op_ast(state), rest}

  defp do_binary_op_ast([{:number_expr_ast, number_expr_ast} | rest]) do
    do_binary_op_ast([number_expr_ast | rest])
  end

  defp do_binary_op_ast([b, op | a]) do
    {op, [do_binary_op_ast(a), b]}
  end

  defp do_binary_op_ast([a]), do: a
end
