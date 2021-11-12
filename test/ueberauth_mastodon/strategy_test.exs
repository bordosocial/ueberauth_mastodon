defmodule UeberauthMastodon.StrategyTest do
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
    assert location ==
             "https://gleasonator.com/oauth/authorize?response_type=code&client_id=3WCR-5e3nOg2SJ90W134VLIIwmib2T96qsXWSJAAEUs&redirect_uri=http%3A%2F%2Fwww.example.com%2Fauth%2Fgleasonator%2Fcallback&scope=read&force_login=false"
  end
end
