defmodule Ueberauth.Strategy.Mastodon.API do
  def app_create(base_url, params) do
    conn = %MastodonClient.Conn{instance: base_url}
    MastodonClient.post(conn, "/api/v1/apps", params)
  end

  def token_create(base_url, params) do
    conn = %MastodonClient.Conn{instance: base_url}
    MastodonClient.post(conn, "/oauth/token", params)
  end

  def account_verify_credentials(base_url, token) when is_binary(token) do
    conn = %MastodonClient.Conn{instance: base_url, access_token: token}
    MastodonClient.get(conn, "/api/v1/accounts/verify_credentials")
  end

  def account_verify_credentials(base_url, %{"access_token" => token}) when is_binary(token) do
    account_verify_credentials(base_url, token)
  end

  def build_authorize_url(base_url, params) do
    base_url
    |> URI.parse()
    |> Map.merge(%{
      path: "/oauth/authorize",
      query: URI.encode_query(params)
    })
    |> URI.to_string()
  end
end
