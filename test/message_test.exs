Code.require_file "test_helper.exs", __DIR__

defmodule MessageTest do
  use ExUnit.Case, async: True

  import Yolandi.Message, only: [to_bytes: 1, parse: 1]

  test "converts port correctly" do
    assert to_bytes(type: :port, listen_port: 80) ==
           << 0, 0, 0, 3, 0, 80, 0 >>
  end

  test "converts cancel correctly" do
    assert to_bytes(type: :cancel, index: 2, begin: 0, length: 4) ==
           << 0, 0, 0, 0xd, 8, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 4 >>
  end

  test "converts request correctly" do
    assert to_bytes(type: :request, index: 2, begin: 0, length: 4) ==
           << 0, 0, 0, 0xd, 8, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 4 >>
  end

  test "converts bitfield correctly" do
    assert to_bytes(type: :bitfield, field: << 0 >>) ==
           << 0, 0, 0, 2, 5, 0 >>
  end

  test "converts have correctly" do
    assert to_bytes(type: :have, piece_index: 22) ==
      << 0, 0, 0, 5, 4, 0, 0, 0, 22 >>
  end

  test "converts interested correctly" do
    assert to_bytes(type: :interested) == << 0, 0, 0, 1, 2 >>
  end

  test "parses keep_alive correctly" do
    assert parse(<< 0, 0, 0, 0 >>)  == {[type: :keep_alive], <<>>}
  end

  test "parses have correctly" do
    assert parse(<< 0, 0, 0, 5, 4, 0, 0, 0, 96, 0, 96, 3, 5>>) == {[type: :have, piece_index: 96], <<0, 96, 3, 5>>}
  end
end



