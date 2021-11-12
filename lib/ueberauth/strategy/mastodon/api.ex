defmodule Ueberauth.Strategy.Mastodon.API do
  use Tesla
  plug(Tesla.Middleware.JSON)

  def app_create(base_url, params) do
    base_url
    |> build_url("/api/v1/apps")
    |> post(params)
  end

  def token_create(base_url, params) do
    base_url
    |> build_url("/oauth/token")
    |> post(params)
  end

  def account_verify_credentials(base_url, token) when is_binary(token) do
    headers = [{"Authorization", "Bearer #{token}"}]

    base_url
    |> build_url("/api/v1/accounts/verify_credentials")
    |> get(headers: headers)
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

  defp build_url(base_url, endpoint) do
    URI.parse(base_url)
    |> URI.merge(endpoint)
    |> to_string()
  end
end
