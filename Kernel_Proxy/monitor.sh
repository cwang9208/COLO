#!/bin/bash

CMD='info status'

# command | command [ | command ...]
# Pipe multiple commands together. The standard output of the
# first command becomes the standard input of the second command.
# All commands run simultaneously.

# { command1; command2; command3; }
# The output of all the commands in the list may be redirected to
# a single stream.
# It is important to note that, the braces must be separated from
# the commands by a space and the last command must be terminated
# with either a semicolon or a newline prior to the closing brace.

{ echo "$CMD"; } | telnet localhost 4444