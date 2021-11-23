defmodule Ueberauth.Strategy.Mastodon.SecretTest do
  use ExUnit.Case, async: true
  alias Ueberauth.Strategy.Mastodon.Secret

  test "parse_secret/1 with an MFA tuple" do
    secret = {String, :reverse, ["hello world"]}
    assert {:ok, "dlrow olleh"} == Secret.parse_secret(secret)
  end

  test "parse_secret/1 with a function" do
    secret = fn -> String.reverse("hello world") end
    assert {:ok, "dlrow olleh"} == Secret.parse_secret(secret)
  end

  test "parse_secret/1 with a string" do
    secret = "hello world"
    assert {:ok, "hello world"} == Secret.parse_secret(secret)
  end

  test "parse_secret/1 with nil" do
    secret = nil
    assert {:error, nil} == Secret.parse_secret(secret)
  end
end
