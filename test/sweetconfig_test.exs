defmodule SweetconfigTest do
  use ExUnit.Case

  test "it works" do
    assert %{pool: ["127.0.0.1", "127.0.0.2"]} = Sweetconfig.get(:cqlex)
  end
  test "defaults working" do
  	assert %{hello: :world} = Sweetconfig.get(:hello, %{hello: :world})
  end
  test "deep get works" do
  	assert ["127.0.0.1", "127.0.0.2"] = Sweetconfig.get([:cqlex, :pool])
  end
end
