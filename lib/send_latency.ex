defmodule SendLatency do
  alias SendLatency.{Sender, Receiver, Collector, Quantization}

  @default_clients 2_000
  @default_duration 10

  def main(argv) do
    parse_args(argv)
  end

  def run(argv) do
    parse_args(argv)
  end

  def help do
    IO.puts "usage: ./send_latency --clients <#clients> --duration <duration> --theshhold <0 | 1 | 10 | 50 | 100 | 500 | 1000>"
    IO.puts " clients  = the number of senders and receivers (default = #{inspect @default_clients})"
    IO.puts " duration = the duration of the stress test in seconds (default = #{inspect @default_duration})"
  end

  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: [ help: :boolean, clients: :integer, duration: :integer, threshold: :integer],
                                      aliases: [ h: :help, c: :clients, d: :duration, t: :threshold])
    case parse do
      { [help: true], _, _ } -> help
      { options, _, _ } ->
        clients = case Keyword.fetch(options, :clients) do
          :error -> @default_clients
          {:ok, clients} -> clients
        end
        duration = case Keyword.fetch(options, :duration) do
          :error -> @default_duration
          {:ok, duration} -> duration
        end
        threshold = case Keyword.fetch(options, :threshold) do
          :error -> -1
          {:ok, threshold} -> threshold
        end
        run_stress(clients, duration, threshold)
      _ -> help
    end
  end

  def run_stress(clients, duration, threshold) do
    IO.puts "Clients = #{inspect clients} Duration = #{inspect duration}"
    IO.puts ""
    {:ok, collector} = Collector.start(total: clients, notif_pid: self)
    Process.register(collector, :collector)

    IO.puts " Creating #{clients} senders and #{clients} receivers"

    specs = 0..(clients - 1)
    |> Enum.map(fn index ->
      # Set receiver
      {:ok, receiver} = Receiver.start_link(index: index, collector: :collector)

      # Set sender
      {:ok, sender} = Sender.start_link(index: index)
      Sender.set_receiver(sender, receiver) 

      {index, sender, receiver}
    end)

    :timer.sleep(10_000)

    IO.puts " Starting test"
    specs
    |> Enum.map(fn {index, sender, receiver} ->
      # Start sending packets
      Sender.send_packets(sender, duration)
    end)

    IO.puts " Waiting for test to complete... duration: #{duration}secs"

    receive do
      {:collector_stats, stats} ->
        display_results(clients, stats, threshold)
    end
  end

  def display_results(total, %{count: count, max: max, quantizations: quantizations}, threshold) do
    if count == total do
      if threshold > -1 do
        quantizations
          |> Enum.filter(fn quantization -> Quantization.has_samples(quantization, threshold) end)
          |> Enum.with_index()
          |> Enum.each(fn {quantization, index} ->
            quantization
              |> Quantization.uniquify()
              |> Quantization.display(" \##{index}")
          end)
        IO.puts ""
        IO.puts "Summary"
        IO.puts "======="
      end

      IO.puts "Got #{count} results"
      IO.puts "Max Latency = #{Enum.max(max)}ms"
      quantizations
        |> Enum.reduce(&Quantization.accumulate(&1, &2))
        |> Quantization.uniquify()
        |> Quantization.display()
    else
      IO.puts "Only got #{count} results"
      if (count > 0), do: IO.puts "Max Latency = #{Enum.max(max)}ms"
    end
  end
end
