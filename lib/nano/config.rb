require 'yaml'

# Returns a value for a configuration key.
#
# Params:
#   domain: The file.
#   key:    The key. Leave blank to return the whole thing.
#
# Example:
#   # Reads datamapper.yml for [:development]['adapter']
#   app_config(:datamapper, 'adapter')  #=> 'mysql'
#
# TODO: Merge this onto a custom monk glue?
#
def app_config(domain, key=nil)
  domain = domain.to_sym

  unless $monk_config
    $monk_config = Hash.new { Hash.new }
  end

  unless $monk_config.include?(domain)
    fname = root_path('config', "#{domain}.yml")
    $monk_config[domain] = YAML.load_file(fname)  if File.exists?(fname)
  end

  return $monk_config[domain][RACK_ENV.to_sym] if key.nil?
  $monk_config[domain][RACK_ENV.to_sym][key]
end
