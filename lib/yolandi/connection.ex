defmodule Yolandi.Connection do
  @doc """
  Connects to other pc and downloads file from it.
  """

  @bett 19
  @pstr "BitTorrent protocol"

  def start_link(peer, client, on_port) do
    handshake = generate_handshake(client)
    {:ok, j} = :inet.ip(peer.ip)
    IO.puts "#{peer.ip}:#{peer.port}"
    { status, socket } = :gen_tcp.connect(j, peer.port, [:binary, {:active, false}])
    if status == :ok do
      :gen_tcp.send(socket, handshake)
      { status, response } = :gen_tcp.recv(socket, 0)
      if status == :ok do
        { _, peer_id, right } = parse_handshake response
        unless peer_id == peer.peer_id do
          IO.puts "closing connection"
          IO.puts "exp #{inspect(peer.peer_id)}"
          IO.puts "not #{inspect(peer_id)}"
          :gen_tcp.close(socket)
        else
          IO.puts "seeding from #{peer.ip}:#{peer.port}"
          data = [am_choking: true, am_interested: false, peer_chocking: true, peer_interested: false]
          :gen_tcp.send(socket, Wire.encode(type: :interested))
          data = Keyword.merge data, [am_choking: 0, am_interested: 1]
          process_messages(peer, socket, data, right)
        end
      else
        IO.puts { status, response }
      end
    else
      IO.puts { status, socket }
    end
  end

  def generate_handshake(client) do
    << @bett, @pstr :: binary >> <>
    << 0, 0, 0, 0, 0, 0, 0, 0, client.info_hash :: binary, client.peer_id :: binary >>
  end

  defp parse_handshake(handshake) do
    IO.puts byte_size(handshake) #:binary.bin_to_list(handshake)
    << a :: binary-size(28), info_hash :: binary-size(20), peer_id :: binary-size(20), rest :: binary >> = handshake
    { info_hash, peer_id, rest }
  end

  defp process_messages(z, socket, info, buf) do

    {info, waiting} = process_buf(buf, info)
    {:ok, msg} = read(socket)
    # IO.puts :binary.bin_to_list(msg)
    process_messages(z, socket, info, waiting <> msg)
  end

  defp read(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp process_buf(buf, info) do
    {messages, q} = Message.decode_messages(buf)
    IO.puts "k #{length(messages)}"
    {Enum.reduce(messages, info, &act_message/2), q}
  end

  defp act_message(message, info) do
    # act for each message and return info
    # if needed

    case message[:type] do
      :keep_alive ->
        IO.puts "partner keep alive"
      :choke ->
        IO.puts "partner choke me"
        info = Keyword.put info, :peer_chocking, true
      :bitfield ->
        IO.puts "bitfield yee"
      :unchoke ->
        IO.puts "partner unchoke me"
        info = Keyword.put info, :peer_chocking, false
        # for part <- parts do
        # :gen_tcp.send(socket, Message.to_bytes([type: :request, begin: 0, end: 16, s: part]))
      :have ->
        IO.puts "partner has something #{message[:piece_index]}"
        # parts = parts ++ [message[:piece_index]]
      :piece ->
        2
        # List.update_at pieces, message[:index], message[:field]
    end
    info
  end
end

