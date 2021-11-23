defmodule Ueberauth.Strategy.MastodonTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Ueberauth.Strategy.Mastodon, as: Strategy

  @json_library Ueberauth.json_library()

  test "handle_request!/1 redirects to the expected URL" do
    options = %{
      callback_path: "/auth/gleasonator/callback",
      options: [
        instance: "https://gleasonator.com",
        client_id: "3WCR-5e3nOg2SJ90W134VLIIwmib2T96qsXWSJAAEUs",
        client_secret: "r-vCWcOk_7IY202yYMMgEHEVEtd5Gv4tlByZqVChRm0"
      ]
    }

    response =
      :get
      |> conn("/auth/gleasonator", [])
      |> put_private(:ueberauth_request_options, options)
      |> Strategy.handle_request!()

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
  end

  describe "handle_callback!/1" do
    setup do
      Tesla.Mock.mock(fn
        %{method: :post, url: "https://gleasonator.com/oauth/token"} ->
          %Tesla.Env{
            status: 200,
            body: File.read!("test/fixtures/token.json") |> @json_library.decode!()
          }

        %{method: :get, url: "https://gleasonator.com/api/v1/accounts/verify_credentials"} ->
          %Tesla.Env{
            status: 200,
            body: File.read!("test/fixtures/account.json") |> @json_library.decode!()
          }
      end)

      :ok
    end

    test "sets :mastodon_token and :mastodon_user private fields" do
      options = %{
        callback_path: "/auth/fediverse/callback",
        options: [
          instance: "https://gleasonator.com",
          client_id: "3qMJ_nS7tNO0BrbExHFnYGVrjKidn1X4AxDPZvJ09uU",
          client_secret: "pWIQ9TrQXjMtJuq1Ywznf-5YwFWey0_vjq2Tzk8Q6pI"
        ]
      }

      response =
        :get
        |> conn("/", %{"code" => "2rAXcKT5DFrg4uyUn2xfAJCcKZ6WaajKdOb0mUwh41s"})
        |> put_private(:ueberauth_request_options, options)
        |> Strategy.handle_callback!()

      assert response.private.mastodon_token ==
               File.read!("test/fixtures/token.json") |> @json_library.decode!()

      assert response.private.mastodon_user ==
               File.read!("test/fixtures/account.json") |> @json_library.decode!()
    end
  end

  test "uid/1 returns the account URL by default" do
    options = %{
      options: [instance: "https://example.com", client_id: "123", client_secret: "456"]
    }

    response =
      :get
      |> conn("/")
      |> put_private(:ueberauth_request_options, options)
      |> put_private(:mastodon_user, %{"url" => "https://gleasonator.com/users/alex"})
      |> Strategy.uid()

    assert response == "https://gleasonator.com/users/alex"
  end

  test "uid/1 can be configured to return the ID" do
    options = %{
      options: [
        instance: "https://example.com",
        client_id: "123",
        client_secret: "456",
        uid_field: "id"
      ]
    }

    response =
      :get
      |> conn("/")
      |> put_private(:ueberauth_request_options, options)
      |> put_private(:mastodon_user, %{"id" => "1"})
      |> Strategy.uid()

    assert response == "1"
  end

  test "credentials/1 builds the expected %Credentials{} struct" do
    token = %{
      "token_type" => "Bearer",
      "access_token" => "QgSGz2QZ8oVT5NMFR42QE4hQL2NBSzx3Y817rmTPyTQ",
      "refresh_token" => "WOSd6v_JirDGt0H1QPFpacK15xuCMXtySG7I7Sq3MK0",
      "scope" => "read write follow push admin",
      "created_at" => 1_637_341_837,
      "expires_in" => 3_153_600_000,
      "me" => "https://gleasonator.com/users/alex"
    }

    response =
      :get
      |> conn("/")
      |> put_private(:mastodon_token, token)
      |> Strategy.credentials()

    expected = %Ueberauth.Auth.Credentials{
      token_type: "Bearer",
      token: "QgSGz2QZ8oVT5NMFR42QE4hQL2NBSzx3Y817rmTPyTQ",
      refresh_token: "WOSd6v_JirDGt0H1QPFpacK15xuCMXtySG7I7Sq3MK0",
      scopes: ["read", "write", "follow", "push", "admin"],
      expires: true,
      expires_at: 3_153_600_000,
      secret: nil,
      other: %{"created_at" => 1_637_341_837, "me" => "https://gleasonator.com/users/alex"}
    }

    assert response == expected
  end

  test "info/1 builds the expected %Info{} struct" do
    account = %{
      "id" => "1",
      "acct" => "alex",
      "display_name" => "Alex Gleason",
      "note" => "Hello world!",
      "avatar" => "https://media.gleasonator.com/123.jpg",
      "avatar_static" => "https://media.gleasonator.com/123-static.jpg",
      "header" => "https://media.gleasonator.com/456.jpg",
      "header_static" => "https://media.gleasonator.com/456-static.jpg",
      "url" => "https://gleasonator.com/users/alex",
      "pleroma" => %{
        "email" => "alex@alexgleason.me"
      }
    }

    response =
      :get
      |> conn("/")
      |> put_private(:mastodon_user, account)
      |> Strategy.info()

    expected = %Ueberauth.Auth.Info{
      description: "Hello world!",
      image: "https://media.gleasonator.com/123.jpg",
      name: "Alex Gleason",
      nickname: "alex",
      email: "alex@alexgleason.me",
      urls: %{
        url: "https://gleasonator.com/users/alex",
        avatar: "https://media.gleasonator.com/123.jpg",
        avatar_static: "https://media.gleasonator.com/123-static.jpg",
        header: "https://media.gleasonator.com/456.jpg",
        header_static: "https://media.gleasonator.com/456-static.jpg"
      }
    }

    assert response == expected
  end

  test "extra/1 builds the expected %Extra{} struct" do
    response =
      :get
      |> conn("/")
      |> put_private(:mastodon_token, %{"access_token" => "12345678"})
      |> put_private(:mastodon_user, %{"id" => "1", "url" => "https://gleasonator.com/users/alex"})
      |> Strategy.extra()

    expected = %Ueberauth.Auth.Extra{
      raw_info: %{
        token: %{"access_token" => "12345678"},
        user: %{"id" => "1", "url" => "https://gleasonator.com/users/alex"}
      }
    }

    assert response == expected
  end

  test "handle_cleanup!/1 removes private data" do
    dirty =
      :post
      |> conn("/")
      |> put_private(:mastodon_token, %{"access_token" => "12345678"})
      |> put_private(:mastodon_user, %{"id" => "1", "url" => "https://gleasonator.com/users/alex"})

    cleaned = Strategy.handle_cleanup!(dirty)

    refute cleaned.private.mastodon_token
    refute cleaned.private.mastodon_user
  end
end
