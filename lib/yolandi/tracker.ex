defmodule Yolandi.Tracker do

  @flag_compact    "true"
  @listening_port  "6689"
  @yolandi_id      "YI"
  @yolandi_version "0200"

  @spec remaining(Map.t) :: Integer
  def remaining(torrent) do
    torrent["info"]["length"]
  end

  @spec check_sum(binary) :: binary
  def check_sum(binary) do
    :crypto.hash(:sha, binary).bin_to_list |>
      Enum.map(fn (x) ->
        Integer.to_string(div(x, 16), 16) <> Integer.to_string(rem(x, 16), 16)
    end) |> Enum.join
  end

  @spec info_hash(Map.t) :: binary
  def info_hash(torrent) do
    torrent["info"] |> Bencoder.encode |> check_sum
  end

  @spec generate_query(Map.t, Client) :: String
  def generate_query(torrent, client) do

    q = %{
      "port"       => @listening_port,
      "info_hash"  => Client.info_hash,
      "uploaded"   => 0,
      "event"      => "started",
      "left"       => to_string(remaining(torrent)),
      "downloaded" => 0,
      "compact"    => @flag_compact,
      "peer_id"    => client.peer_id
    } |> URI.encode_query

    "#{torrent["announce"]}?#{q}"
  end
end

