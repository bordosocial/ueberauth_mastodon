defmodule Ueberauth.Strategy.MastodonTest do
  use ExUnit.Case, async: true
  use Plug.Test

  # Note: These tests work because of the configuration in config/test.exs

  test "handle_request!/1 redirects to the expected URL" do
    opts = Ueberauth.init()

    response =
      conn(:get, "/auth/gleasonator", [])
      |> Ueberauth.call(opts)

    location = Map.new(response.resp_headers)["location"]

    # It redirects
    assert response.status == 302

    # ...to the expected URL
    %{host: "gleasonator.com", path: "/oauth/authorize", scheme: "https", query: query} =
      URI.parse(location)

    q = query |> URI.query_decoder() |> Map.new()
    assert q["client_id"] == "3WCR-5e3nOg2SJ90W134VLIIwmib2T96qsXWSJAAEUs"
    # assert q["force_login"] == "false"
    assert q["redirect_uri"] == "http://www.example.com/auth/gleasonator/callback"
    assert q["response_type"] == "code"
    assert q["scope"] == "read"
    assert q["state"]
  end
end
