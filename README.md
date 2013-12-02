INTRODUCTION
============
Erroneous is a plugin for handling errors from external programs. Vim provides
you with the `:make` command to run compilers and parse the errors using the
'errorformat' option, but you must set the 'errorformat' option in advance. If
you use more than one language regularly, you'll have to change 'errorformat'
often. This is usually done with file-type plugins - but that means you have to
always compile from one of the source files(you can't, for example, compile
from one of the configuration XML files).  You can also set a long, compound
'errorformat' that can catch errors in many formats - but from my experience
those catch-all 'errorformat's tend to identify error-description lines as
error headlines and create entries in the quickfix list that are mapped to
nowhere and send you to empty buffers. Not as fun as it sounds...

Erroneous takes a different approach - instead of parsing stderr based on the
filetype, parsing is done based on the shell command that invoked the program
that created the error. So, if you run `javac MyClass.java` Erroneous will
automatically set the 'errorformat' to parse `javac` errors, while running
`gcc main.c` will cause Erroneous to set 'errorformat' to parse `gcc` errors.

Erroneous can also read shebangs to know how to parse errors of interepted
scripts in linux, and it provides API for other plugins that want to determine
the error format by other means.


USAGE

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

OPTIONAL REQUIREMENT: RUBY
============
Erroneous can run without Ruby support in Vim, but with Ruby and unless you run
Windows, when Erroneous runs a command, you can see it's output as it runs.
Without Ruby, Erroneous redirects the command's stdout and stderr to files that
it reads, so you can only get the results once the command finishes.  That also
means that without Ruby, you will see stdout and then stderr, even if the
command was writing to them both alternately.

So: use Ruby. It's awesome.


BUILD SYSTEM SUPPORT
====================
Erroneous can read and parse error output from
[Make](http://www.gnu.org/software/make), [Rake](http://rake.rubyforge.org) and
[Apache Ant](http://ant.apache.org), [Apache Maven](http://maven.apache.org),
and [XBuild](http://www.mono-project.com/Microsoft.Build)(which is the same as
[MSBuild](http://msdn2.microsoft.com/en-us/library/0k6kkbsd.aspx)).
