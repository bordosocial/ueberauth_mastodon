defmodule Ueberauth.Strategy.Mastodon do
  @moduledoc """
  Überauth strategy for Mastodon and Pleroma.
  """
  use Ueberauth.Strategy
  alias Ueberauth.Strategy.Mastodon.API

  @impl Ueberauth.Strategy
  def handle_request!(conn) do
    config_opts = options(conn)
    base_url = Keyword.get(config_opts, :instance, conn.params["instance"])

    # https://docs.joinmastodon.org/methods/apps/oauth/
    authorize_params = [
      response_type: "code",
      client_id: Keyword.get(config_opts, :client_id),
      redirect_uri: Keyword.get(config_opts, :redirect_uri, callback_url(conn)),
      scope: Keyword.get(config_opts, :scope, "read"),
      force_login: Keyword.get(config_opts, :force_login, false)
    ]

    oauth_url = API.build_authorize_url(base_url, authorize_params)
    redirect!(conn, oauth_url)
  end

  @impl Ueberauth.Strategy
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    config_opts = options(conn)
    base_url = Keyword.get(config_opts, :instance, conn.params["instance"])

    # https://docs.joinmastodon.org/methods/apps/oauth/
    token_params = [
      grant_type: "authorization_code",
      client_id: Keyword.get(config_opts, :client_id),
      client_secret: Keyword.get(config_opts, :client_secret),
      redirect_uri: Keyword.get(config_opts, :redirect_uri, callback_url(conn)),
      scope: Keyword.get(config_opts, :scope, "read"),
      code: code
    ]

    with {_, {:ok, %{status: 200, body: token}}} <-
           {:create_token, API.token_create(base_url, token_params)},
         {_, {:ok, %{status: 200, body: account}}} <-
           {:verify_credentials, API.account_verify_credentials(base_url, token)} do
      conn
      |> put_private(:mastodon_token, token)
      |> put_private(:mastodon_account, account)
    else
      {:create_token, _} ->
        set_errors!(conn, [error("create_token", "Could not obtain an OAuth token.")])

      {:verify_credentials, _} ->
        set_errors!(conn, [error("account_verify_credentials", "The token did not work.")])
    end
  end

  @impl Ueberauth.Strategy
  def extra(%{private: %{mastodon_user: %{} = user, mastodon_token: %{} = token}}) do
    %Ueberauth.Auth.Extra{
      raw_info: %{
        token: token,
        user: user
      }
    }
  end

  def extra(_conn), do: %Ueberauth.Auth.Extra{}
end
