defmodule GithubSyncTest do
  use ExUnit.Case
  doctest GithubSync

  test "greets the world" do
    assert GithubSync.hello() == :world
  end
end
