# Change log

## Version 0.1.0 (Mar 31, 2015)

Bootstrapped Luban::CLI

Features:
  * Support general command-line parsing
    * Support options
    * Support switches (boolean options)
    * Support arguments
    * Support subcommand
  * Provide base class (Luban::CLI::Base) for command-line application

## Version 0.2.0 (Apr 02, 2015)

Minor enhancements:
  * Refractor error class
  * Refractor argument validation
  * Validate required options/arguments in Luban::CLI::Base
  * Create singleton action handler method on application instance
  * Move parse error handling to action handler
  * Exclude examples and spec from the gem itself
