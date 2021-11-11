defmodule UeberauthMastodon.OAuth2.Client do
  @defaults [
    strategy: UeberauthMastodon.OAuth2.Strategy
  ]

  @spec new(opts :: Keyword.t()) :: OAuth2.Client.t()
  def new(opts \\ []) do
    opts = Keyword.merge(@defaults, opts)
    json_library = Ueberauth.json_library()

    opts
    |> OAuth2.Client.new()
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end
end
