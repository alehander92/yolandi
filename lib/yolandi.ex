defmodule Yolandi do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
  end

  @doc """
    downloads a torrent from torrent_path
    shows info about the download on stdout

    raises an YolandiError on an error

    # Examples

        iex > Yolandi.download("e.torrent")


  """
  def download(torrent_path) do
    :inets.start

    { peers, client } = torrent_path |> read_torrent |> Yolandi.Tracker.get_tracker_response
    Yolandi.PeerManager.start(nil, [peers, client])
  end

  @spec read_torrent(binary) :: Map.t | no_return
  defp read_torrent(torrent_path) do
    { ok, content }  = File.read(torrent_path)
    if ok == :ok do
      Bencoder.decode(content)
    else
      raise Yolandi.YolandiError, message: "torrent file not found"
    end
  end
end


