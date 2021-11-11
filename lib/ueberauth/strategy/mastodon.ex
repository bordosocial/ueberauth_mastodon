defmodule Ueberauth.Strategy.Mastodon do
  @moduledoc """
  Überauth strategy for Mastodon and Pleroma.
  """
  use Ueberauth.Strategy

  @impl Ueberauth.Strategy
  def handle_request!(conn) do
    client = build_client(conn)
    config_opts = options(conn)

    # https://docs.joinmastodon.org/methods/apps/oauth/
    authorize_params = [
      scope: Keyword.get(config_opts, :scope, "read"),
      force_login: Keyword.get(config_opts, :force_login, false)
    ]

    oauth_url = OAuth2.Client.authorize_url!(client, authorize_params)
    redirect!(conn, oauth_url)
  end

  @impl Ueberauth.Strategy
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    client = build_client(conn)
    config_opts = options(conn)

    # https://docs.joinmastodon.org/methods/apps/oauth/
    token_params = [
      code: code,
      scope: Keyword.get(config_opts, :scope, "read")
    ]

    with {:ok, %OAuth2.Client{token: %OAuth2.AccessToken{access_token: access_token} = token}}
         when is_binary(access_token) <- OAuth2.Client.get_token(client, token_params) do
      # TODO: Fetch the user
      conn
    end
  end

  defp build_client(%Plug.Conn{params: params} = conn) do
    config_opts = options(conn)

    # https://hexdocs.pm/oauth2/OAuth2.Client.html#new/2
    [
      site: Keyword.get(config_opts, :instance, params["instance"]),
      redirect_uri: Keyword.get(config_opts, :redirect_uri, callback_url(conn)),
      client_id: Keyword.get(config_opts, :client_id),
      client_secret: Keyword.get(config_opts, :client_secret)
    ]
    |> UeberauthMastodon.OAuth2.Client.new()
  end
end
