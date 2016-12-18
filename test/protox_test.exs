defmodule RandomInit do

  import Protox.Util

  def gen(mod) do

    Enum.reduce(
      mod.defs().fields,
      struct(mod.__struct__),
      fn ({_, field}, msg) ->
        case field.kind do
          {:oneof, _} -> msg # TODO.
          _           -> struct!(msg, [{field.name, value(field.kind, field.type)}])
        end
      end
    )
  end


  defp value(:normal, e = %Protox.Enumeration{}) do
    e.members |> Map.values() |> Enum.random()
  end
  defp value(:normal, :bool) do
    :rand.uniform(2) == 1
  end
  defp value(:normal, ty)
  when ty == :int32 or ty == :int64 or ty == :sint32 or ty == :sint64 or ty == :sfixed32\
       or ty == :sfixed64
  do
    :rand.uniform(100) * sign()
  end
  defp value(:normal, ty) when ty == :double or ty == :float do
    :rand.uniform(1000000) * :rand.uniform() * sign()
  end
  defp value(:normal, ty) when is_primitive(ty) do
    :rand.uniform(1000000)
  end
  defp value(:normal, :bytes) do
    Enum.reduce(1..:rand.uniform(10), <<>>, fn (b, acc) -> <<b, acc::binary>> end)
  end
  defp value(:normal, :string) do
    if :rand.uniform(2) == 1, do: "#{inspect make_ref()}", else: ""
  end
  defp value(:normal, m = %Protox.Message{}) do
    if :rand.uniform(2) == 1 do
      RandomInit.gen(m.name)
    else
      nil
    end
  end
  defp value({:repeated, _}, :bool) do
    for _ <- 1..:rand.uniform(10), do: value(:normal, :bool)
  end
  defp value({:repeated, _}, ty) when is_primitive(ty) do
    for _ <- 1..:rand.uniform(10), do: :rand.uniform(100)
  end
  defp value({:repeated, _}, e = %Protox.Enumeration{}) do
    for _ <- 1..:rand.uniform(10), do: value(:normal, e)
  end
  defp value({:repeated, _}, m = %Protox.Message{}) do
    Enum.reduce(
      1..:rand.uniform(10),
      [],
      fn (_ , acc) ->
        sub = value(:normal, m)
        if sub do
          [sub | acc]
        else
          acc
        end
      end
    )
  end
  defp value(:map, {key_type, value_type}) do
    Enum.reduce(
      1..:rand.uniform(10),
      %{},
      fn (_ , acc) ->
        key = value(:normal, key_type)
        value = value(:normal, value_type)
        if key && value do
          Map.put(acc, key, value)
        else
          acc
        end
      end
    )
  end

  defp sign() do
    if :rand.uniform(2) == 1, do: -1, else: 1
  end

end

defmodule ProtoxTest do
  use ExUnit.Case

  test "symmetric (Sub)" do
    msg = RandomInit.gen(Sub)
    assert (msg |> Sub.encode_binary() |> Sub.decode()) == msg
  end


  test "symmetric (Msg)" do
    msg = RandomInit.gen(Msg)
    assert (msg |> Msg.encode_binary() |> Msg.decode()) == msg
  end


  test "symmetric (Upper)" do
    msg = RandomInit.gen(Upper)
    assert (msg |> Upper.encode_binary() |> Upper.decode()) == msg
  end

end
