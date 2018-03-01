use Mix.Config

config :server, :general,
  domain: 'example.com',
  db_filename: 'client_db',
  auto_save: 60 * 1000,
  crawl_interval: 3000,
  cert_path: nil,
  key_path: nil

config :server, :network,
  client_port: 10101,
  api_port: 10102,
  timeout: 1000
