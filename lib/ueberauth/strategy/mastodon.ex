defmodule Ueberauth.Strategy.Mastodon do
  @moduledoc """
  Überauth strategy for Mastodon and Pleroma.
  """
  use Ueberauth.Strategy
  alias Ueberauth.Strategy.Mastodon

  @impl Ueberauth.Strategy
  def handle_request!(conn) do
    params = conn.params
    config_opts = options(conn)

    # https://hexdocs.pm/oauth2/OAuth2.Client.html#new/2
    oauth_opts = [
      site: Keyword.get(config_opts, :instance, params["instance"]),
      redirect_uri: Keyword.get(config_opts, :redirect_uri, callback_url(conn)),
      client_id: Keyword.get(config_opts, :client_id),
      client_secret: Keyword.get(config_opts, :client_secret)
    ]

    # https://docs.joinmastodon.org/methods/apps/oauth/
    oauth_params = [
      scope: Keyword.get(config_opts, :scope, "read"),
      force_login: Keyword.get(config_opts, :force_login, false)
    ]

    oauth_url = Mastodon.OAuth.authorize_url!(oauth_params, oauth_opts)
    redirect!(conn, oauth_url)
  end
end
