defmodule Ueberauth.Strategy.Mastodon.APITest do
  use ExUnit.Case, async: true
  alias Ueberauth.Strategy.Mastodon.API

  @json_library Ueberauth.json_library()
  @base_url "https://gleasonator.com"

  setup do
    Tesla.Mock.mock(fn
      %{method: :post, url: "https://gleasonator.com/api/v1/apps"} ->
        %Tesla.Env{
          status: 200,
          body: File.read!("test/fixtures/app.json") |> @json_library.decode!()
        }

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

  test "app_create/2" do
    expected = File.read!("test/fixtures/app.json") |> @json_library.decode!()
    assert {:ok, %Tesla.Env{body: ^expected}} = API.app_create(@base_url, %{})
  end

  test "token_create/2" do
    expected = File.read!("test/fixtures/token.json") |> @json_library.decode!()
    assert {:ok, %Tesla.Env{body: ^expected}} = API.token_create(@base_url, %{})
  end

  test "account_verify_credentials/2" do
    expected = File.read!("test/fixtures/account.json") |> @json_library.decode!()
    assert {:ok, %Tesla.Env{body: ^expected}} = API.account_verify_credentials(@base_url, "")
  end

  test "build_authorize_url/2" do
    params = %{
      response_type: "code",
      client_id: "12345678",
      redirect_uri: "https://patron.gleasonator.com/callback/fediverse",
      scope: "read"
    }

    expected =
      "https://gleasonator.com/oauth/authorize?client_id=12345678&redirect_uri=https%3A%2F%2Fpatron.gleasonator.com%2Fcallback%2Ffediverse&response_type=code&scope=read"

    assert API.build_authorize_url(@base_url, params) == expected
  end
end
