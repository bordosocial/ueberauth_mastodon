defmodule Ueberauth.Strategy.Mastodon.Secret do
  @moduledoc """
  Functions for dealing with configuration secrets.
  """

  @typedoc """
  Tuple in the form `{module, function_name, args}`.
  Parsed into a string at runtime.

  Example:

  ```elixir
  {System, :get_env, ["SECRET_KEY"]}
  ```
  """
  @type mfa_secret :: {module, function_name :: atom, args :: [any()]}

  @typedoc """
  A configuration secret.
  Either a `t:mfa_secret/0`, a function, or a string.
  """
  @type secret :: mfa_secret | function | String.t()

  @doc """
  Accepts a `t:secret/0` and returns a tuple with the parsed string.
  Useful for runtime configuration.

  Example:

  ```elixir
  iex(1)> parse_secret({System, :get_env, ["SECRET_KEY"]})
  {:ok, "12345678"}
  iex(2)> parse_secret(nil)
  {:error, nil}
  ```
  """
  @spec parse_secret(secret()) :: {:ok, String.t()} | {:error, any()}
  def parse_secret({m, f, a}), do: {:ok, apply(m, f, a)}
  def parse_secret(fun) when is_function(fun), do: {:ok, fun.()}
  def parse_secret(secret) when is_binary(secret), do: {:ok, secret}
  def parse_secret(value), do: {:error, value}
end
