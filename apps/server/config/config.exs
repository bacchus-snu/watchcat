use Mix.Config

config :general,
  db_filename: "client_db",
  crawl_interval: 3000

config :network,
  client_port: 10101,
  timeout: 1000
