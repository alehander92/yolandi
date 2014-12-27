defmodule Yolandi.Message do
  def to_bytes(type: :port, listen_port: listen_port) do
    << 0, 0, 0, 3, listen_port :: 16-integer-big-unsigned, 0 >>
  end

  def to_bytes(type: request_or_cancel, index: index, begin: begin, length: length) when request_or_cancel in [:cancel, :request] do
    << 0, 0, 0, 0xd, 8,
       index :: 32-integer-big-unsigned,
       begin :: 32-integer-big-unsigned,
       length  :: 32-integer-big-unsigned >>
  end

  def to_bytes(type: :bitfield, field: field) do
    << (1 + byte_size(field)) :: 32-integer-big-unsigned, 5, field :: binary>>
  end

  def to_bytes(type: :have, piece_index: piece_index) do
    << 0, 0, 0, 5, 4, piece_index :: 32-integer-big-unsigned >>
  end

  def to_bytes(type: :not_interested) do
    << 0, 0, 0, 1, 3 >>
  end

  def to_bytes(type: :interested) do
    << 0, 0, 0, 1, 2 >>
  end

  def to_bytes(type: :unchoke) do
    << 0, 0, 0, 1, 1 >>
  end

  def to_bytes(type: :choke) do
    << 0, 0, 0, 1, 0 >>
  end

  def to_bytes(type: :keep_alive) do
    << 0 >>
  end

  @doc ~S"""
  Parses a `message` and
  returns a message keyword list and the unparsed part of the message

  """
  @spec parse(binary) :: {Keyword.t, binary}
  def parse(message) do
    << l :: 32-integer-big-unsigned, rest :: binary >> = message
    if l == 0 do
      {[type: :keep_alive], rest}
    else
      << id, rest :: binary >> = rest
      case id do
        9 ->
          << port :: 16-integer-big-unsigned, rest :: binary >> = rest
          {[type: :port, listen_port: port], rest}
        id when id in [8, 6] ->
          << index   :: 32-integer-big-unsigned,
             begin   :: 32-integer-big-unsigned,
             length  :: 32-integer-big-unsigned,
             rest    :: binary >> = rest
          type = if id == 8 do :cancel else :request end
          {[type: type, index: index, begin: begin, length: length], rest}
        5 ->
          l2 = 4 + l
          << field :: size(l2), rest :: binary >> = rest
          {[type: :bitfield, field: field], rest}
        4 ->
          << piece_index :: 32-integer-big-unsigned, rest :: binary >> = rest
          {[type: :have, piece_index: piece_index], rest}
        3 ->
          {[type: :not_interested], rest}
        2 ->
          {[type: :interested], rest}
        1 ->
          {[type: :unchoke], rest}
        0 ->
          {[type: :choke], rest}
      end
    end
  end
end
