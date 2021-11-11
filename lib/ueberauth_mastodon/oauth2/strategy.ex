defmodule UeberauthMastodon.OAuth2.Strategy do
  @moduledoc """
  `OAuth2.Strategy` implementation for Mastodon & Pleroma.
  """
  use OAuth2.Strategy

  @impl OAuth2.Strategy
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  @impl OAuth2.Strategy
  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
