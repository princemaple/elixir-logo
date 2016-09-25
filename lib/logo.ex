defmodule Logo do
  def main(args) do
    args
    |> parse_args()
    |> parse_code()
  end

  defp parse_args(args) do
    OptionParser.parse(
      args,
      switches: [stdin: :boolean, file: :string],
      aliases: [i: :stdin, f: :file]
    )
  end

  def parse_code({[stdin: true], [code], _errors}) do
    code
    |> Logo.Parse.parse
  end

  def parse_code({[file: file_path], _argv, _errors}) do
    file_path
    |> File.read!
    |> Logo.Parse.parse
  end
end
