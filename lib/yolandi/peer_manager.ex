defmodule Yolandi.PeerManager do
  use Application

  @bett 19
  @pstr "BitTorrent protocol"

  alias Yolandi.Message, as: Message
  def start(_, [peers, client]) do
    import Supervisor.Spec

    IO.puts "\n"
    peers |> inspect |> IO.puts
    IO.puts "\n"
    client |> inspect |> IO.puts

    connect_to_peers(peers, client, Yolandi.Tracker.listening_port)
    # children = [
    #   supervisor(Task.Supervisor, [[name: Yolandi.PeerManager.TaskSupervisor]]),
    #   worker(Task, [Yolandi.PeerManager, :connect_to_peers,
    #                [peers, client, Yolandi.Tracker.listening_port]])
    # ]

    # options = [strategy: :one_for_one, name: Yolandi.PeerManager.Supervisor]
    # Supervisor.start_link(children, options)
  end

  def generate_handshake(client) do
    << @bett, @pstr :: binary >> <>
    << 0, 0, 0, 0, 0, 0, 0, 0, client.info_hash :: binary, client.peer_id :: binary >>
  end

  def connect_to_peers(peers, client, on_port) do
    peers = Enum.reject peers, fn (p) -> p.ip == '78.90.139.102' end
    if length(peers) == 0 do
      IO.puts "NO peers"
    else
      IO.puts inspect(Enum.map(peers, fn (p) -> {p.ip, p.port} end))
      q = Enum.at peers, -4
      IO.puts "task started"
      seed_from q, on_port, generate_handshake(client)
    end
  end


  defp seed_from(peer, on_port, handshake) do
    {:ok, j} = :inet.ip(peer.ip)
    #IO.puts :binary.bin_to_list(handshake)
    IO.puts "#{peer.ip}:#{peer.port}"
    { :ok, socket } = :gen_tcp.connect(j, peer.port, [:binary, {:active, false}])
    :gen_tcp.send(socket, handshake)
    { :ok, response } = :gen_tcp.recv(socket, 0)
    { _, peer_id, right } = parse_handshake response

    unless peer_id == peer.peer_id do
      :gen_tcp.close(socket)
    else

      IO.puts "seeding from #{peer.ip}:#{peer.port}"
      data = [am_choking: 1, am_interested: 0, peer_chocking: 1, peer_interested: 0]
      :gen_tcp.send(socket, Message.to_bytes(type: :interested))
      data = Keyword.merge data, [am_choking: 0, am_interested: 1]
      process_messages(peer, socket, data, right)
    end
    # Task.Supervisor.start_child(Yolandi.PeerManager.TaskSupervisor,
    #   fn -> process_messages(peer, socket) end)
    # seed_from(peer, on_port)
  end

  defp parse_handshake(handshake) do
    IO.puts byte_size(handshake) #:binary.bin_to_list(handshake)
    << a :: binary-size(28), info_hash :: binary-size(20), peer_id :: binary-size(20), rest :: binary >> = handshake
    { info_hash, peer_id, rest }
  end

  defp process_messages(z, socket, info, buf) do

    {info, waiting} = process_buf(buf)
    {:ok, msg} = read(socket)
    IO.puts :binary.bin_to_list(msg)
    process_messages(z, socket, info, waiting <> msg)
  end

  defp read(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp process_buf(buf) do
    {messages, q} = Message.parse_messages(buf)
    {Enum.reduce(messages, info, &act_message/2), q}
  end

  defp act_message(message, info) do
    # act for each message and return info
    # if needed
    [w: 2]
  end
end
