defmodule SendLatency.Sender do
  use GenServer
  alias __MODULE__

  defstruct index:    0,
            receiver: nil

  def start_link(params, opts \\ []) do
    GenServer.start_link(__MODULE__, params, opts)
  end

  def set_receiver(server, handler) do
    GenServer.call(server, {:set_receiver, handler})
  end

  def send_packets(server, duration) do
    GenServer.cast(server, {:send_packets, duration})
  end

  def init(params) do
    { :ok, %Sender{index: params[:index]} }
  end

  def handle_call({:set_receiver, receiver}, _from, state) do
    {:reply, :ok, %Sender{state | receiver: receiver}}
  end
  def handle_call(:disconnect, _from, state) do    
    {:reply, :ok, state}
  end

  def handle_cast({:send_packets, duration}, state) do
    0..(duration*5)
    |> Enum.map(fn(_index) ->   
      send(state.receiver, {:packet, { timestamp, "0123456789"}} )
      :timer.sleep(200)
    end)
    send(state.receiver, :done)
    GenServer.cast(self, {:stop, :normal})

    {:noreply, state}
  end
  def handle_cast({:stop, reason}, state) do
    {:stop, reason, state}
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