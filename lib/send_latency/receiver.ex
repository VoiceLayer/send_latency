defmodule SendLatency.Receiver do
  use GenServer
  alias __MODULE__
  alias SendLatency.Quantization

  defstruct index:      0,
            pkt_count:  0,
            rcv_bytes:  0,
            latencies:  [],
            collector:  nil

  def start_link(params, opts \\ []) do
    GenServer.start_link(__MODULE__, params, opts)
  end

  def get_stats(server) do
    GenServer.call(server, :get_stats)
  end

  def init(params) do
    {:ok, %Receiver{ index: params[:index], collector: params[:collector] }}
  end

  def handle_call(:get_stats, _from, state) do
    {:reply, :stats, state}
  end

  def handle_cast({:stop, reason}, state) do
    {:stop, reason, state}
  end

  def handle_info({:packet, packet}, state) do
     latency = case packet do
       { send_time, _ } ->
          timestamp - send_time
        _ ->
          IO.puts "unknown packet format"
          -1
     end

    state = state
     |> Map.put(:pkt_count, state.pkt_count+1)
     |> Map.put(:rcv_bytes, state.rcv_bytes+byte_size(elem(packet, 1)))
     |> Map.put(:latencies, [latency | state.latencies])

    {:noreply, state}
  end

  def handle_info(:done, state) do
    # :timer.sleep(2_000)
    case state.latencies do
      [] -> IO.puts "No results received for #{inspect self}"
      latencies -> 
        SendLatency.Collector.send_stats(state.collector,
         {state.index, Enum.max(latencies), Quantization.quantize(latencies)})
    end
    GenServer.cast(self, {:stop, :normal})
    {:noreply, state}
  end

  def handle_info({:error, error }, state) do
    IO.puts "Error #{inspect error}"
    {:noreply, state}
  end

  def handle_info(_event, state) do
    {:noreply, state}
  end

  def timestamp do
    {m, s, u} = :os.timestamp
    1000*(m * 1000000 + s) + trunc(u/1000)
  end

end