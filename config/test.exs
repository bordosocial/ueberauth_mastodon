import Config

# Configure Tesla mock adapter
# https://hexdocs.pm/tesla/Tesla.Mock.html
config :tesla, adapter: Tesla.Mock

config :ueberauth, Ueberauth,
  providers: [
    mastodon: {Ueberauth.Strategy.Mastodon, []},
    gleasonator:
      {Ueberauth.Strategy.Mastodon,
       [
         instance: "https://gleasonator.com",
         client_id: "3WCR-5e3nOg2SJ90W134VLIIwmib2T96qsXWSJAAEUs",
         client_secret: "r-vCWcOk_7IY202yYMMgEHEVEtd5Gv4tlByZqVChRm0"
       ]}
  ]
