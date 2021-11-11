defmodule Ueberauth.Strategy.Mastodon.OAuthTest do
  use ExUnit.Case, async: true
  alias Ueberauth.Strategy.Mastodon.OAuth

  test "authorize_url!/2 returns a URL" do
    params = [
      client_id: "a1b2c3",
      redirect_uri: "https://patron.gleasonator.com/auth/mastodon",
      scope: "read write follow"
    ]

    opts = [site: "https://gleasonator.com"]

    expected =
      "https://gleasonator.com/oauth/authorize?client_id=a1b2c3&redirect_uri=https%3A%2F%2Fpatron.gleasonator.com%2Fauth%2Fmastodon&response_type=code&scope=read+write+follow"

    assert OAuth.authorize_url!(params, opts) == expected
  end
end
