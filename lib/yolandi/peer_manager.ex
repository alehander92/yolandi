defmodule Yolandi.PeerManager do
  use Application

  def start(_, [peers, client]) do
    import Supervisor.Spec

    IO.puts "\n"
    peers |> inspect |> IO.puts
    IO.puts "\n"
    client |> inspect |> IO.puts

    peers = Enum.reject peers, fn (p) -> p.ip == '78.90.139.102' end
    if length(peers) == 0 do
      IO.puts "NO peers"
    else

      IO.puts inspect(Enum.map(peers, fn (p) -> {p.ip, p.port} end))
      children = [worker(Yolandi.Connection, [])]

      options = [strategy: :simple_one_for_one, name: Yolandi.PeerManager.Supervisor]
      Supervisor.start_link(children, options)
      start_peers peers, client
    end
  end

  def start_peers(peers, client) do
    a = [client, Yolandi.listening_port]
    for peer <- peers do
      Supervisor.start_child(Yolandi.PeerManager.Supervisor, [peer | a])
    end
  end
end

