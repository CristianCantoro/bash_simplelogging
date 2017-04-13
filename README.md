Bash simplelogging
-------------------

A bash "library" for logging in just one file that you can source in your scripts.

This library was inspired by Python's [logging][PythonLogging] module and in part based on work by Piyush Chordia detailed in the post: ["Log tracing mechanism for Shell scripts"][PiyushChordiaPost].

It aims to be a simple library that can be used in scripts, with no dependencies. This library has been written for Bash 4.

It is also a "simple" library in the sense that it does not implement a fully-fledged object-oriented frameworks as in other projects such as [Bash Infinity][BashInfinity].

## Usage

```bash
source "lib/simplelogging.sh"

get_logger 'demologger' 'DEBUG'

demologger.attach_handler 'STDOUT' 'ERROR'

demologger.debug 'debug message'
demologger.info 'info message'
demologger.warning 'warning message'
demologger.error 'error message'
demologger.critical 'critical message'
```

[PiyushChordiaPost]: http://www.cubicrace.com/2016/03/efficient-logging-mechnism-in-shell.html  
[PythonLogging]: https://docs.python.org/3/library/logging.html
[BashInfinity]: https://github.com/niieani/bash-oo-framework
