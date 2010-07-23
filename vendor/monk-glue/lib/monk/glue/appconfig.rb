require 'yaml'

# TODO Add documentation.
def appconfig(key)
  $appconfig ||= YAML.load_file(root_path("config", "appconfig.yml"))[RACK_ENV.to_sym]

  unless $appconfig.include?(key)
    message = "No appconfig defined for #{key.inspect}."
    defined?(logger) ? logger.warn(message) : $stderr.puts(message)
  end

  $appconfig[key]
end

