defmodule SendLatency.Quantization do
  def new do
    [0, 0, 0, 0, 0, 0, 0]
  end

  def quantize(latencies) do
    [-1, 0, 10, 50, 100, 500, 1000] |> Enum.map(fn threshold ->
      Enum.filter(latencies, &(&1 > threshold)) |> length
    end)
  end

  def uniquify(rest), do: uniquify(rest, [])
  def uniquify([a], acc), do: acc ++ [a]
  def uniquify([a, b | rest], acc), do: uniquify([b | rest], acc ++ [a-b])    

  def accumulate(a, b) do
    Enum.zip(a, b)
      |> Enum.map(fn {a1, b1} -> a1+b1 end)
  end

  def has_samples(quantize, threshold) do
    has_entry = [0, 1, 10, 50, 100, 500, 1000]
      |> Enum.map(&(&1 == threshold))
    if Enum.any?(has_entry) do
      quantize
        |> Enum.zip(has_entry)
        |> Enum.reduce(false, fn {entry, check_entry}, res ->
          res || (entry != 0 && check_entry)
        end)
    else
      false
    end
  end

  def display(quantize, title \\ "") do
    IO.puts "Quantize#{title}:"
    ["  0ms", "  1ms", " 10ms", " 50ms", "100ms", "500ms", "   1s" ]
      |> Enum.zip(quantize)
      |> Enum.each(fn {title, value} ->
        IO.puts "#{title} = #{value}"
      end)
  end

end