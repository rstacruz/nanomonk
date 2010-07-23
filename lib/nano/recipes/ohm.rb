gem_install "ohm"

add_require "ohm"

add_initializer %{
  # Connect to redis database.
  Ohm.connect(appconfig(:redis))
}

create_file 'config/redis/development.example.conf', I(%{
  ..
})

create_file 'config/redis/test.example.conf', I(%{
  ..
})

empty_directory 'db/redis/development'
empty_directory 'db/redis/test'

add_config I(%{
  defaults: &defaults
    :log_level: warn
    :redis:
      :port: 6379

  :development:
    <<: *defaults
    :log_level: debug

  :test:
    <<: *defaults
    :redis:
      :port: 6380

  :production:
    <<: *defaults
})
