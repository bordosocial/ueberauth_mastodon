defmodule Ueberauth.Strategy.Mastodon.OptionsParser do
  @moduledoc """
  Parses configuration secrets at runtime.
  """
  alias Ueberauth.Strategy.Helpers
  alias Ueberauth.Strategy.Mastodon.Secret

  @required_keys [:instance, :client_id, :client_secret]

  @doc """
  Similar to `Ueberauth.Strategy.Helpers.options/1` except it also
  parses secrets with `Ueberauth.Strategy.Mastodon.Secret.parse_secret/1`

  If any required options are missing or invalid, it will raise.
  """
  @spec from_conn!(conn :: Plug.Conn.t()) :: options :: Keyword.t()
  def from_conn!(%Plug.Conn{} = conn) do
    conn
    |> validate_required!()
    |> parse_options!()
  end

  defp parse_options!(conn) do
    conn
    |> Helpers.options()
    |> Enum.map(fn opt ->
      parse_option!(conn, opt)
    end)
  end

  defp validate_required!(conn) do
    found_keys =
      conn
      |> Helpers.options()
      |> Keyword.take(@required_keys)
      |> Keyword.keys()
      |> MapSet.new()

    missing_keys =
      @required_keys
      |> MapSet.new()
      |> MapSet.difference(found_keys)
      |> MapSet.to_list()

    if Enum.count(missing_keys) == 0 do
      conn
    else
      raise """
      Ueberauth Mastodon:

      Provider "#{Helpers.strategy_name(conn)}" is missing configuration:
      #{inspect(missing_keys)}
      """
    end
  end

  defp parse_option!(conn, {key, value}) do
    case Secret.parse_secret(value) do
      {:ok, secret} ->
        {key, secret}

      {:error, value} ->
        raise """
        Ueberauth Mastodon:

        Provider "#{Helpers.strategy_name(conn)}" has an invalid #{inspect(key)}. Expected a string, function, or {m, f, a} tuple.
        Got: #{inspect(value)}

        Check your configuration.
        """
    end
  end
end
