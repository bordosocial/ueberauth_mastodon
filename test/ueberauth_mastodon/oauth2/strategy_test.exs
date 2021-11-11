defmodule UeberauthMastodon.OAuth2.StrategyTest do
  use ExUnit.Case, async: true

  test "OAuth2.Client.authorize_url!/2 builds the expected URL" do
    client = UeberauthMastodon.OAuth2.Client.new(site: "https://gleasonator.com")

    params = [
      client_id: "a1b2c3",
      redirect_uri: "https://patron.gleasonator.com/auth/mastodon",
      scope: "read write follow"
    ]

    expected =
      "https://gleasonator.com/oauth/authorize?client_id=a1b2c3&redirect_uri=https%3A%2F%2Fpatron.gleasonator.com%2Fauth%2Fmastodon&response_type=code&scope=read+write+follow"

    assert OAuth2.Client.authorize_url!(client, params) == expected
  end
end
