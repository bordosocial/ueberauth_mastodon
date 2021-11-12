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
    authorize_params =
      [
        response_type: "code",
        client_id: Keyword.get(config_opts, :client_id),
        redirect_uri: Keyword.get(config_opts, :redirect_uri, callback_url(conn)),
        scope: Keyword.get(config_opts, :scope, "read"),
        force_login: Keyword.get(config_opts, :force_login, false)
      ]
      |> with_state_param(conn)

    oauth_url = API.build_authorize_url(base_url, authorize_params)
    redirect!(conn, oauth_url)
  end

  @impl Ueberauth.Strategy
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    config_opts = options(conn)
    base_url = Keyword.get(config_opts, :instance, conn.params["instance"])

    # https://docs.joinmastodon.org/methods/apps/oauth/
    token_params = %{
      grant_type: "authorization_code",
      client_id: Keyword.get(config_opts, :client_id),
      client_secret: Keyword.get(config_opts, :client_secret),
      redirect_uri: Keyword.get(config_opts, :redirect_uri, callback_url(conn)),
      scope: Keyword.get(config_opts, :scope, "read"),
      code: code
    }

    with {_, {:ok, %{status: 200, body: token}}} <-
           {:create_token, API.token_create(base_url, token_params)},
         {_, {:ok, %{status: 200, body: account}}} <-
           {:verify_credentials, API.account_verify_credentials(base_url, token)} do
      conn
      |> put_private(:mastodon_token, token)
      |> put_private(:mastodon_user, account)
    else
      {:create_token, response} ->
        IO.warn(inspect(response))
        set_errors!(conn, [error("create_token", "Could not obtain an OAuth token.")])

      {:verify_credentials, response} ->
        IO.warn(inspect(response))
        set_errors!(conn, [error("account_verify_credentials", "The token did not work.")])
    end
  end

  @impl Ueberauth.Strategy
  def uid(%{private: %{mastodon_user: %{} = user}} = conn) do
    uid_field =
      conn
      |> options()
      |> Keyword.get(:uid_field, "url")
      |> to_string()

    user
    |> Map.get(uid_field)
  end

  @impl Ueberauth.Strategy
  def credentials(%{private: %{mastodon_token: %{} = token}}) do
    other =
      Map.drop(token, [
        "token_type",
        "access_token",
        "scope",
        "expires_in",
        "refresh_token"
      ])

    %Ueberauth.Auth.Credentials{
      token_type: Map.get(token, "token_type", "Bearer"),
      token: Map.get(token, "access_token"),
      scopes: Map.get(token, "scope", "") |> String.split(" ", trim: true),
      expires: Map.get(token, "expires_in") |> is_integer(),
      expires_at: Map.get(token, "expires_in"),
      refresh_token: Map.get(token, "refresh_token"),
      other: other
    }
  end

  @impl Ueberauth.Strategy
  def info(%{private: %{mastodon_user: %{} = user}}) do
    email =
      case user do
        %{"pleroma" => %{"email" => email}} -> email
        _ -> nil
      end

    %Ueberauth.Auth.Info{
      description: Map.get(user, "note"),
      image: Map.get(user, "avatar"),
      name: Map.get(user, "display_name"),
      nickname: Map.get(user, "acct"),
      email: email,
      urls: %{
        url: Map.get(user, "url"),
        avatar: Map.get(user, "avatar"),
        avatar_static: Map.get(user, "avatar_static"),
        header: Map.get(user, "header"),
        header_static: Map.get(user, "header_static")
      }
    }
  end

  @impl Ueberauth.Strategy
  def extra(%{private: %{mastodon_token: %{} = token, mastodon_user: %{} = user}}) do
    %Ueberauth.Auth.Extra{
      raw_info: %{
        token: token,
        user: user
      }
    }
  end

  @impl Ueberauth.Strategy
  def handle_cleanup!(conn) do
    conn
    |> put_private(:mastodon_token, nil)
    |> put_private(:mastodon_user, nil)
  end
end
