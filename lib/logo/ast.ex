defmodule Logo.AST do
  def parse(tokens) do
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
