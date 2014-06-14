defmodule SweetconfigTest do
  use ExUnit.Case

  test "the truth" do
    assert %{pool: ["127.0.0.1", "127.0.0.2"]} = Sweetconfig.get(:cqlex)
  end
end
