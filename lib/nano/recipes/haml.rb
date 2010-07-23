gem_install 'haml'
add_require 'haml'

create_file 'app/views/layout.haml', I(%{
  !!! 5
  %html(lang='en')
    %head
      %meta(charset='UTF-8')
      %title Document

    %body
      != yield
})

create_file 'app/views/home.haml', I(%{
  %h1 Hello world!
})

create_file 'app/views/site.rb', I(%{
  class Main
    get '/' do
      haml :home
    end
  end
})

create_file 'app/helpers/haml.rb', I(%{
  class Main
    helpers do
      # Generate HAML and escape HTML by default.
      def haml(template, options = {}, locals = {})
        options[:escape_html] = true unless options.include?(:escape_html)
        super(template, options, locals)
      end

      # Render a partial and pass local variables.
      #
      # Example:
      #   != partial :games, :players => @players
      def partial(template, locals = {})
        haml(template, {:layout => false}, locals)
      end
    end
  end
})
