Nanomonk
========

This is a skeleton without anything but `monk-glue` and a new command, `monk install`.
The goal is to have a skeleton that will let you create the skeleton you want,
free from the restrictions of the default gems that most monk skeletons ship with.

Instructions
------------

First: install rvm and monk.

Add the `nano` skeleton.

    monk add nano git://github.com/rstacruz/nanomonk

Create a new app from this skeleton.

    monk init myapp -s nano
    cd myapp

Install a templating system. It's probably best to do this first!

    monk install haml

Install an ORM if need one.

    monk install ohm

Try a few more packages!

    monk install contest
    monk install rtopia
    monk install less
    monk install sinatra-minify
    monk install jquery  # Even non-gems can work

Start it up!

    monk start

Info
----

When you do a `monk install`, it queries the GitHub repo to see if there is a
recipe for the gem you want to install.

Some gems have recipes for them: for instance, the `ohm` gem will have a recipe
to create the other necessary files such as configuration files and Rake tasks.

If a recipe doesn't exist for the gem, it'll simply be installed and vendored.

Have a look at the current recipes at the [Nanomonk recipes index](http://github.com/rstacruz/nanomonk-recipes/tree/master/recipes/).

Assumptions
-----------

You have to be using RVM.

Tips and tricks
---------------

You can simulate the original Monk skeleton with:

    monk install haml ohm
    monk install quietbacktrace override spawn ffaker stories contest --test

And you can also add in some useful extras (most of there are used in the Sinefunc skeleton):

    monk install sinatra-minify sinatra-helpers sinatra-i18n sinatra-security rtopia
    monk install pagination less sinatra-minify jquery
    monk install webrat --test

To do
-----

 - add_dependency should update an existing dependency instead of add
 - gem_install_from_git?
 - Recipes
   - more ORMs: activerecord, datamapper, candy, mongoid
   - more templating systems: erb, ...
   - more test systems: stories, rspec
