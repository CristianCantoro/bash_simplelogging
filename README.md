Bash simplelogging
-------------------

A bash "library" for logging in just one file that you can source in your scripts.

This library was inspired by Python's [logging][PythonLogging] module and in part based on work by Piyush Chordia detailed in the post: ["Log tracing mechanism for Shell scripts"][PiyushChordiaPost].

It aims to be a simple library that can be used in scripts, with no dependencies. This library has been written for Bash 4.

It is also a "simple" library in the sense that it does not implement a fully-fledged object-oriented frameworks as in other projects such as [Bash Infinity][BashInfinity].

## Usage

`cat example.sh`
```bash
#!/usr/bin/env bash
source "lib/simplelogging.sh"

get_logger 'demologger' 'DEBUG'

demologger.attach_handler 'CONSOLE' 'ERROR'
demologger.attach_handler '/tmp/logger.txt' 'DEBUG'

demologger.debug 'debug message'
demologger.info 'info message'
demologger.warning 'warning message'
demologger.error 'error message'
demologger.critical 'critical message'
```

Output:
```
$ ./example.sh
[2017-04-14 14:35:55][ERROR   ](demologger.main)	error message
[2017-04-14 14:35:55][CRITICAL](demologger.main)	critical message
```

```
$ cat /tmp/logger.txt
[2017-04-14 14:35:55][DEBUG   ](demologger.main)	attach handler: /tmp/logger.txt (DEBUG)
[2017-04-14 14:35:55][DEBUG   ](demologger.main)	debug message
[2017-04-14 14:35:55][INFO    ](demologger.main)	info message
[2017-04-14 14:35:55][WARNING ](demologger.main)	warning message
[2017-04-14 14:35:55][ERROR   ](demologger.main)	error message
[2017-04-14 14:35:55][CRITICAL](demologger.main)	critical message
```

### Reference manual

### General approach

With this library you can define loggers, each logger has its own logging level. You can attach handlers which are channels were the logger outputs its log messages. Each logger can have several handlers.

Sourcing `bash_simplelogging.sh` will define a function called `get_logger` the other variable and function defined in the script global scope are prefixed by `_BASH_LOGGING_` and are internals of the library that should not modified directly. This idea is borrowed directly from Python.

The API of the `get_logger` function is the following:
```bash
get_logger <name> <logging_level>
```

For example, you can define the logger `demologger` and set its logging level to 'WARNING' with the following call:
```bash
get_logger 'demologger' 'WARNING'
```

### Loggers

A logger is a set of functions for each logging level. So defining a logger consists actually in defining the function that output log messages.

After the definition of `demologger` as in the example above, you will obtain in the global scope the following functions:
```bash
demologger.debug
demologger.info
demologger.warning
demologger.error
demologger.critical
```
Each logger will output only messages that are of a level equal or higher of its own.

You can effectivel change a logger's logging level by redefining it:
```
get_logger 'demologger' 'DEBUG'
```

This means that `bash_simplelogging` does not check if a logger with the same name has already been defined.

### Logging levels

`bash_simplelogging` offers the same logging levels as Python's logging module (in parethensys the numerical values for each level):
* CRITICAL (50)
* ERROR	   (40)
* WARNING  (30)
* INFO	   (20)
* DEBUG	   (10)
* NOTSET   (0)

If a logger level is set to `NOTSET` it will not print anything.

## Handlers

Each logger can output to several handlers. When created, a logger has no handlers and will not output anything. You can attach handlers calling the method `attach_handler` of the logger, whose signature is as follows:
```bash
{loggername}.attach_handler <handler> <logging_level>
```
as in the following examples:
```bash
demologger.attach_handler 'CONSOLE' 'DEBUG'
demologger.attach_handler 'logger.txt' 'DEBUG'
```
The handler should be a file path where the logger will write the output, if the special name `CONSOLE` is used then the handler will output to stderr on the active console.

Each handler has its own logging level and will output only messages of a level equal or greater of its own, this filter is in addition to the logging level defined by the logger.

You can change the logging level of an handler by attach one with the same name:
```bash
demologger.attach_handler 'CONSOLE' 'DEBUG'
```

### Functions

The logger will print its name and the name of the scope within it has been called, assuming `main` if not otherwise specified.

When you use the logger inside a function you can use the logger's `entry` and `return` function to signal that you are within a function:
```bash
{loggername}.entry
{loggername}.entry
```

In the following example a logger is declared with two handlers and it is used in the main scope and inside a function.
```bash
cat example_with_function.sh
```
```bash
#!/usr/bin/env bash

source "lib/simplelogging.sh"

get_logger 'demologger' 'DEBUG'

example_function(){
    demologger.entry
    demologger.info "inside example_function"
    demologger.debug "first: $1, second: $2"
    demologger.warning "warning!"
    demologger.return
}

demologger.attach_handler 'CONSOLE' 'INFO'
demologger.attach_handler '/tmp/loggerfunc.txt' 'DEBUG'

demologger.info "calling example_function"

example_function 'aaa' 'bbb'

demologger.info "back to main"
```
```bash
$ ./example_with_function.sh
[2017-04-14 15:01:06][INFO    ](demologger.main)	calling example_function
[2017-04-14 15:01:06][INFO    ](demologger.example_function)	inside example_function
[2017-04-14 15:01:06][WARNING ](demologger.example_function)	warning!
[2017-04-14 15:01:06][INFO    ](demologger.main)	back to main
```

```bash
$ cat /tmp/loggerfunc.txt
[2017-04-14 15:01:06][DEBUG   ](demologger.main)	attach handler: /tmp/loggerfunc.txt (DEBUG)
[2017-04-14 15:01:06][INFO    ](demologger.main)	calling example_function
[2017-04-14 15:01:06][DEBUG   ](demologger.example_function)	> example_function demologger.entry
[2017-04-14 15:01:06][INFO    ](demologger.example_function)	inside example_function
[2017-04-14 15:01:06][DEBUG   ](demologger.example_function)	first: aaa, second: bbb
[2017-04-14 15:01:06][WARNING ](demologger.example_function)	warning!
[2017-04-14 15:01:06][DEBUG   ](demologger.example_function)	< example_function demologger.return
[2017-04-14 15:01:06][INFO    ](demologger.main)	back to main
```

[PiyushChordiaPost]: http://www.cubicrace.com/2016/03/efficient-logging-mechnism-in-shell.html  
[PythonLogging]: https://docs.python.org/3/library/logging.html
[BashInfinity]: https://github.com/niieani/bash-oo-framework
