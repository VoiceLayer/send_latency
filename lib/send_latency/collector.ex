defmodule SendLatency.Collector do
  use GenServer
  alias __MODULE__

  defstruct count:          0,
            total:          0,
            notif_pid:      nil,
            max:            [],
            quantizations:  []

  def start(params, opts \\ []) do
    GenServer.start(__MODULE__, params, opts)
  end

  def send_stats(server, stats) do
    GenServer.cast(server, {:send_stats, stats})
  end

  def get_stats(server) do
    GenServer.call(server, :get_stats)    
  end

  def init(params) do
    :erlang.process_flag(:priority, :low)
    state = %Collector{ 
      total: params[:total], 
      notif_pid: params[:notif_pid]
    }
    { :ok, state }
  end

  def handle_call(:get_stats, _from, state) do
    {:reply, state.stats, state}
  end

  def handle_cast({:send_stats, {_count, max, quantization}}, state) do
    state = state
      |> Map.put(:max, [max | state.max])
      |> Map.put(:count, state.count+1)
      |> Map.put(:quantizations, [quantization | state.quantizations])
    if state.count == state.total do
      send state.notif_pid, {:collector_stats, 
        %{count: state.count, max: state.max, quantizations: state.quantizations}}
    end
    {:noreply, state}
  end

  def handle_cast({:stop, reason}, state) do
    IO.puts "Stopping collector"
    {:stop, reason, state}
  end

  def terminate(reason, _state) do
    IO.puts "Terminating collector reason #{inspect reason}"
    :ok
  end

  def timestamp do
    {m, s, u} = :os.timestamp
    1000*(m * 1000000 + s) + trunc(u/1000)
  end

end