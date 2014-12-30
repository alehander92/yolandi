defmodule Yolandi do
  use GenServer

  @listening_port  6689
  @yolandi_id      "YI"
  @yolandi_version "0020"

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(_) do
  end

  @doc """
    downloads a torrent from torrent_path
    shows info about the download on stdout

    raises an YolandiError on an error

    # Examples

        iex > Yolandi.download("e.torrent")


  """
  def download(torrent_path \\ "movies/misfits") do
    :inets.start

    peer_id = generate_peer_id

    { status, response } = torrent_path
        |> read_torrent
        |> TrackerRequest.request listening_port: @listening_port, peer_id: peer_id
    if status == :ok do
      client_data = %Yolandi.ClientData{info_hash: response["info_hash"], peer_id: peer_id, interval: response["interval"]}
      Yolandi.PeerManager.start(nil, [response["peers"], client_data])
    else
      IO.puts "Error #{response}"
    end
  end

  @spec read_torrent(binary) :: Map.t | no_return
  defp read_torrent(torrent_path) do
    { ok, content }  = File.read(torrent_path)
    if ok == :ok do
      e = Bencoder.decode(content)
      IO.puts inspect(e)
      e
    else
      raise Yolandi.YolandiError, message: "torrent file not found"
    end
  end

  @spec generate_peer_id :: binary
  defp generate_peer_id do
    :random.seed(:erlang.now)
    number = :random.uniform(1000000000000)
    number = number |> Integer.to_string |> String.rjust(13, ?0)
    "-#{@yolandi_id}#{@yolandi_version}#{number}"
  end

  def listening_port do
    @listening_port
  end
end


