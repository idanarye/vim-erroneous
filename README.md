INTRODUCTION
============

Erroneous is a plugin for handling errors from other programs. Vim provides
you with the `:make` command to run compilers and parse the errors using the
'errorformat' option, but you must the 'errorformat' option in advance. If you
more than one many language, you'll have to change 'errorformat' often. This
is usually done with file-type plugins - but that means you have to always
compile from one of the source files(you can't, for example, compile from one
of the configuration XML files).
You can also set a long 'errorformat' that can catch many formats - but in my
experience those catch-all 'errorformat's tend to identify error-description
lines as error headlines and create entries in the quickfix list that are
mapped to nowhere and send you to empty buffers. Not as fun as it sounds...

Erroneous takes a different approach - instead of parsing stderr based on the
filetype, parsing is done based on the shell command that invoked the program
that created the error. So, if you run `javac MyClass.java` Erroneous will
automatically set the 'errorformat' to parse `javac` errors, while running
`gcc main.c` will cause Erroneous to set 'errorformat' to parse `gcc` errors.

Erroneous can also read shebangs to know how to parse errors of interepted
scripts in linux, and it provides API for other plugins that want to determine
the error format by other means.


USAGE
=====

First you need to set the g:erroneous\_errorFormatChooserPatterns and/or the
g:erroneous\_errorFormatChooserWords dictionaries. Then use the supplied
commands(see erroneous-commands for list of commands) to run shell commands
and parse their error formats according to what you configured in those
dictionaries.

Refer to the vim-doc for examples and more information.

###IMPORTANT NOTE

Erroneous can not be used for running commands that require user interaction,
since it redirects stderr and stdout to files and only displays them once the
program finishes.

BUILD SYSTEM SUPPORT
====================

Erroneous can read and parse error output from
[Make](http://www.gnu.org/software/make), [Rake](http://rake.rubyforge.org) and
[Apache Ant](http://ant.apache.org). I've tried to support Maven, but Maven
writes the stderr of the commands it runs to it's stdout - __all of it__.
Without stderr, Erroneous can not tell if there were any errors. Ant also write
errors to stdout, but it at least writes __something__ to stderr, so Erroneous
can detect that there were errors.
