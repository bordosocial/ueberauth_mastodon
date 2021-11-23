# ueberauth_mastodon

Log into [Mastodon](https://joinmastodon.org/) and [Pleroma](https://pleroma.social/) with [Überauth](https://github.com/ueberauth/ueberauth).

This library makes it easy to spin up Elixir microservices to run alongside your social media website.

You can configure one or more Mastodon/Pleroma servers as login options.

## Usage guide

### Configuration

```elixir
# Tesla
config :tesla, adapter: Tesla.Adapter.Hackney

# Ueberauth
config :ueberauth, Ueberauth,
  providers: [
    # You will create routes matching the provider name:
    # - /auth/mastodon
    # - /auth/mastodon/callback
    mastodon: {Ueberauth.Strategy.Mastodon, [
      # instance: "https://example.tld",
      # client_id: "********",
      # client_secret: "********",
      # scope: "read write follow"
    ]},

    # This one will be at /auth/gleasonator
    gleasonator:
      {Ueberauth.Strategy.Mastodon,
       [
         # You MUST provide an instance.
         instance: "https://gleasonator.com",
         # You MUST provide app credentials.
         # Generate your app before getting started.
         client_id: "3WCR-5e3nOg2SJ90W134VLIIwmib2T96qsXWSJAAEUs",
         client_secret: "r-vCWcOk_7IY202yYMMgEHEVEtd5Gv4tlByZqVChRm0",
         scope: "read write follow"
       ]}
  ]
```

#### Tesla

Under the hood, ueberauth_mastodon uses [Tesla](https://github.com/teamon/tesla) to make HTTP requests.

Tesla is not an HTTP client itself, but a flexible layer for switchable HTTP clients.
In this guide we use Hackney, but you can use whatever you want.
Just don't leave it blank.

##### Options

- `instance` (**required**) - A URL to the Mastodon/Pleroma instance.
- `client_id` (**required**) - Generated by an app. Create the app first.
- `client_secret` (**required**) - Generated by an app. Create the app first.
- `scope` - Space-separated list of scopes, eg `read write follow`. It defaults to `read`.

###### Advanced

- `redirect_uri` - Override the redirect URL. By default it goes to `/auth/:provider/callback`
- `uid_field` - Which field from Mastodon API to map to Überauth. It's set to `"url"` (the ActivityPub ID) by default.

##### Runtime configuration

All configuration options are strings.
For runtime configuration, it's possible to pass values that will be evaulated to strings:

- **string**, eg `"123456"`
- **{m, f, a}** tuple, eg `{System, :get_env, ["CLIENT_SECRET"]}`
- **function**, eg `fn -> System.get_env("CLIENT_SECRET") end`

```elixir
# Runtime configuration
config :ueberauth, Ueberauth,
  providers: [
    mastodon: {Ueberauth.Strategy.Mastodon, [

      # Just a plain old hardcoded string
      instance: "https://example.tld",

      # {module, function, args} format
      client_id: {System, :get_env, "MASTODON_CLIENT_ID"},

      # Anonymous function
      client_secret: fn -> System.get_env("MASTODON_CLIENT_SECRET") end
    ]}
  ]
```

### Routes

You'll need to create matching routes in `router.ex`:

```elixir
scope "/auth", PatronWeb do
  pipe_through [:browser, Ueberauth]

  get "/mastodon", AuthController, :request
  get "/mastodon/callback", AuthController, :callback

  # You don't have to have more than one, but you can have any number
  get "/gleasonator", AuthController, :request
  get "/gleasonator/callback", AuthController, :callback
end
```

The `Ueberauth` plug will match names from your config and intercept the conn before it arrives at your controller.

#### request/2

You **do not** need to implement the `request/2` view in your controller. The plug intercepts it and does a redirect before it hits your controller.

Just put a link to `/auth/:provider` somewhere on your website, and it will redirect to the OAuth signup page.

#### callback/2

You **must** provide a `callback/2` view.

```elixir
def callback(%{assigns: %{ueberauth_auth: auth} = conn, _params) do
  # TODO: Store the auth somewhere
  conn
end
```

### Controller

You'll need to create a controller to handle the callback.
Below is an example of a full controller.

```elixir
defmodule PatronWeb.AuthController do
  use PatronWeb, :controller

  alias Ueberauth.Auth
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Failure
  alias Ueberauth.Failure.Error

  # /auth/:provider/callback
  # After the user authorizes the OAuth form, they'll be redirected back here.
  def callback(
        # An `:ueberauth_auth` key is provided upon success.
        # It contains a `%Ueberauth.Auth{}` struct.
        # https://hexdocs.pm/ueberauth/Ueberauth.Auth.html#t:t/0
        %{assigns: %{ueberauth_auth: %Auth{uid: uid, credentials: %Credentials{} = credentials}}} = conn,
        _params
      ) do
    conn
    # Store the credentials in a cookie, or anywhere else
    |> put_session(:token_data, credentials)
    |> put_session(:uid, uid)
    |> redirect(to: "/")
  end

  def callback(
        # Upon failure, you'll get `:ueberauth_failure`.
        # It contains a `%Ueberauth.Failure{}` struct.
        # https://hexdocs.pm/ueberauth/Ueberauth.Failure.html#t:t/0
        %{assigns: %{ueberauth_failure: %Failure{errors: [%Error{message: message} | _]}}} = conn,
        _params
      ) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: "/")
  end

  # If neither exist, just redirect home
  def callback(conn, _params) do
    redirect(conn, to: "/")
  end
end
```

### Authentication Plug

Finally, you'll likely want to create a plug to authenticate the user on pageload.
This is one possible way:

```elixir
defmodule PatronWeb.Plugs.BootstrapUser do
  import Plug.Conn
  alias Patron.User
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Strategy.Mastodon

  @behaviour Plug

  def init(_), do: nil

  def call(conn, _) do
    # Get the token set from the callback
    case get_session(conn, :token_data) do
      nil -> conn
      # Make an HTTP request
      %Credentials{token: token} -> verify_token(conn, token)
      # Delete invalid token
      _ -> delete_session(conn, :token_data)
    end
  end

  # Fetch the account from the token
  defp verify_token(conn, token) do
    # The uid is an ActivityPub ID, which serves as a convenient base URL
    with %Credentials{uid: ap_id} <- get_session(conn, :token_data),
         {:ok, %{status: 200, body: %{"url" => ap_id} = data}} <-
           Mastodon.API.account_verify_credentials(ap_id, token) do
      conn
      |> assign(:user_data, data)
    else
      _ -> delete_session(conn, :token_data)
    end
  end
end
```

And in the router:

```elixir
pipeline :browser do
  # ...
  plug PatronWeb.Plugs.BootstrapUser
end
```

## Installation

Add `ueberauth`, `ueberauth_mastodon`, and a Tesla adapter to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ueberauth, "~> 0.7.0"},
    {:ueberauth_mastodon, "~> 0.1.0"},

    # For `Tesla.Adapter.Hackney` to work
    {:hackney, "~> 1.18"}
  ]
end
```

## Is it worth it?

This might seem like a lot, but it's often not easier to implement auth on your own.

This guide shows one way to implement it, but it's also possible to implement it with a REST API.
Once you learn the building blocks it can be very powerful.

# License

ueberauth_mastodon is licensed under the MIT license.
See LICENSE.md for the full text.
