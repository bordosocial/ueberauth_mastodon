defmodule Ueberauth.Strategy.Mastodon.OAuth do
  @moduledoc """
  `OAuth2.Strategy` implementation for Mastodon & Pleroma.

  Add `:client_id` and `:client_secret` to your configuration:

  ```elixir
  config :ueberauth, Ueberauth.Strategy.Mastodon.OAuth,
    client_id: System.get_env("MASTODON_APP_ID"),
    client_secret: System.get_env("MASTODON_APP_SECRET")
  ```
  """
  use OAuth2.Strategy

  @defaults [
    # Maybe we'll add defaults later
    strategy: __MODULE__
  ]

  @doc """
  `OAuth2.Client` is an HTTP client.

  This function builds an `%OAuth2.Client{}` struct, which is used by
  `OAuth2.Client.get/4` and other OAuth HTTP methods:

  - `OAuth2.Client.get/4`
  - `OAuth2.Client.post/4`
  - `OAuth2.Client.put/4`
  - `OAuth2.Client.patch/4`
  """
  @spec client(opts :: Keyword.t()) :: OAuth2.Client.t()
  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.Mastodon.OAuth, [])

    opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    json_library = Ueberauth.json_library()

    opts
    |> OAuth2.Client.new()
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end

  @doc """
  Convenience function for `OAuth2.Client.authorize_url!/2`.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client()
    |> OAuth2.Client.authorize_url!(params)
  end

  @doc """
  Convenience function for `OAuth2.Client.get_token!/2`.
  """
  def get_token!(params \\ [], opts \\ []) do
    opts
    |> client()
    |> OAuth2.Client.get_token!(params)
  end

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
