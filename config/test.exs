import Config

config :tesla, adapter: Tesla.Adapter.Hackney

config :ueberauth, Ueberauth,
  providers: [
    mastodon: {UeberauthMastodon.Strategy, []},
    gleasonator:
      {UeberauthMastodon.Strategy,
       [
         instance: "https://gleasonator.com",
         client_id: "3WCR-5e3nOg2SJ90W134VLIIwmib2T96qsXWSJAAEUs",
         client_secret: "r-vCWcOk_7IY202yYMMgEHEVEtd5Gv4tlByZqVChRm0"
       ]}
  ]
