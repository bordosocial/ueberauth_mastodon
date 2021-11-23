defmodule Ueberauth.Strategy.Mastodon.OptionsParserTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Ueberauth.Strategy.Mastodon.OptionsParser

  test "from_conn!/1 with valid configuration" do
    valid_opts = [
      instance: "https://example.tld",
      client_id: {String, :reverse, ["4321"]},
      client_secret: fn -> String.reverse("8765") end,
      hello: "world"
    ]

    parsed =
      :get
      |> conn("/", [])
      |> put_private(:ueberauth_request_options, %{options: valid_opts})
      |> OptionsParser.from_conn!()

    expected = [
      instance: "https://example.tld",
      client_id: "1234",
      client_secret: "5678",
      hello: "world"
    ]

    assert parsed == expected
  end

  test "from_conn!/1 with an invalid instance URL" do
    opts = [
      instance: nil,
      client_id: "1234",
      client_secret: "5678"
    ]

    assert_raise RuntimeError, ~r/invalid :instance/, fn ->
      :get
      |> conn("/", [])
      |> put_private(:ueberauth_request_options, %{options: opts})
      |> OptionsParser.from_conn!()
    end
  end

  test "from_conn!/1 with an invalid client_id" do
    opts = [
      instance: "https://example.tld",
      client_id: nil,
      client_secret: "5678"
    ]

    assert_raise RuntimeError, ~r/invalid :client_id/, fn ->
      :get
      |> conn("/", [])
      |> put_private(:ueberauth_request_options, %{options: opts})
      |> OptionsParser.from_conn!()
    end
  end

  test "from_conn!/1 with an invalid client_secret" do
    opts = [
      instance: "https://example.tld",
      client_id: "1234",
      client_secret: nil
    ]

    assert_raise RuntimeError, ~r/invalid :client_secret/, fn ->
      :get
      |> conn("/", [])
      |> put_private(:ueberauth_request_options, %{options: opts})
      |> OptionsParser.from_conn!()
    end
  end

  test "from_conn!/1 with missing required opts" do
    assert_raise RuntimeError, ~r/\[:client_id, :client_secret, :instance\]/, fn ->
      :get
      |> conn("/", [])
      |> put_private(:ueberauth_request_options, %{options: []})
      |> OptionsParser.from_conn!()
    end
  end
end
