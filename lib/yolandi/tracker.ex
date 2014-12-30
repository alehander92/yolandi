defmodule Yolandi.Tracker do

  alias Yolandi.YolandiError, as: YolandiError

  @flag_compact    "true"
  @listening_port  "6689"
  @yolandi_id      "YI"
  @yolandi_version "0200"

  @spec remaining(Map.t) :: Integer
  defp remaining(torrent) do
    if "length" in Map.keys torrent do
      torrent["info"]["length"]
    else
      Enum.reduce torrent["info"]["files"], 0, fn (f, acc) ->
        acc + f["length"]
      end
    end
  end

  @spec check_sum(binary) :: binary
  def check_sum(binary) do
    :crypto.hash(:sha, binary)
    # |> :binary.bin_to_list |> Enum.map(fn (x) ->
        # Integer.to_string(div(x, 16), 16) <> Integer.to_string(rem(x, 16), 16)
    # end) |> Enum.join
  end

  @spec info_hash(Map.t) :: binary
  defp info_hash(torrent) do
    torrent["info"] |> Bencoder.encode |> check_sum
  end

  @spec generate_query(Map.t, ClientData) :: String
  defp generate_query(torrent, client) do

    q = %{
      "port"       => @listening_port,
      "info_hash"  => client.info_hash,
      "uploaded"   => 0,
      "event"      => "started",
      "left"       => to_string(remaining(torrent)),
      "downloaded" => 0,
      "compact"    => @flag_compact,
      "peer_id"    => client.peer_id
    } |> URI.encode_query

    "#{torrent["announce"]}?#{q}"
  end

  @spec get_tracker_response(Map.t) :: { List.Peer, Yolandi.ClientData } | no_return
  def get_tracker_response(torrent) do
    client = %Yolandi.ClientData{peer_id: generate_peer_id, info_hash: info_hash(torrent)}
    query  = String.to_char_list(generate_query(torrent, client))

    IO.puts "query: #{query}"
    body = get_body(query)

    z = Bencoder.decode(body)
    if Map.has_key?(z, "failure reason") do
      raise YolandiError, message: "failure reason in tracker returns #{z["failure reason"]}"
    end

    client = Map.put client, :interval, z["interval"]
    { parse_peer_response(z["peers"]), client }
  end

  @spec get_body(binary) :: binary | no_return
  defp get_body(query) do
    { ok, {_, _, body} } = :httpc.request(:get, { query, []}, [], [])
    if ok == :ok do
      body |> :binary.list_to_bin
    else
      raise YolandiError, message: "http error"
    end
  end

  @spec generate_peer_id :: binary
  defp generate_peer_id do
    :random.seed(:erlang.now)
    number = :random.uniform(1000000000000)
    number = number |> Integer.to_string |> String.rjust(13, ?0)
    "-#{@yolandi_id}#{@yolandi_version}#{number}"
  end

  defp parse_peer_response(data) when is_binary(data) do
    data_size = String.length(data)
    Enum.chunk(data, 6).map(&analyze/1)
  end

  defp parse_peer_response(data) when is_list(data) do
    Enum.map data, fn (a) ->
      %Peer{ ip: String.to_char_list(a["ip"]), port: a["port"], peer_id: Map.get(a, "peer id", "") }
    end
  end

  defp analyze(data) do
    << ip0  :: 8-integer-big-unsigned, ip1 :: 8-integer-big-unsigned,
       ip2  :: 8-integer-big-unsigned, ip3 :: 8-integer-big-unsigned,
       port :: 16-integer-big-unsigned >> = data
    %Peer{ ip: "#{ip0}.#{ip1}.#{ip2}.#{ip3}", port: port }
  end

  def listening_port do
    @listening_port
  end
end


