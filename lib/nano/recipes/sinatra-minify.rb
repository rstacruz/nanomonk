gem_install "sinatra-minify"
add_require "sinatra/minify"

create_file 'lib/tasks/minify.rake', I(%{
  desc "Builds the minified CSS and JS assets."
  task :minify do
    require './init'
    files = Sinatra::Minify::Package.build
    files.each { |f| puts " * \#{File.basename f}" }
  end
})

create_file 'config/assets.yml', I(%{
  css:
    base:
      - main.css

  js:
    base:
      #- jquery-1.4.2.min.js
      #- app.js
})


if File.exists?('app/views/layout.haml')
  inject_into_file 'app/views/layout.haml', '    != css_assets :base', :after => /^  %title.*$/
  append_file      'app/views/layout.haml', '    != js_assets :base'
end
