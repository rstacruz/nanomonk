Nanomonk
========

This is a skeleton without anything but `monk-glue` and a new command, `monk install`.

Instructions
------------

Add the `nano` skeleton.

   monk add nano git://github.com/rstacruz/nanomonk

Create a new app from this skeleton.

    monk init myapp -s nano
    cd myapp

Install a templating system.

    monk install haml

Install an ORM (if needed).

    monk install ohm

Start it up!

    monk start
