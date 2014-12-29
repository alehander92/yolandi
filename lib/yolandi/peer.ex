defmodule Peer do
  defstruct peer_id: <<>>, ip: nil, port: 0, connection: nil, piece_map: <<>>, s: nil
end
