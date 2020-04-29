This files are what is usually needed to add a new project for an AT release.

You should copy then to the desired at release path. Something like
$ cp ./* configs/<at_release>/packages/<project_name>/.

Inside each file are instructions on how to use them and what they are supposed
to do. All of them have "TODO" tags explaining chages mandatory to them. A new
project should solve all the TODOs before trying to compile. Althoug the "TODO"
tags shows the most common changes it might not cover every requirements for
your project.
