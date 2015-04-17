# Change log

## Version 0.3.1 (Apr 15, 2015)

Minor enhancements:
  * Simplify keyword arguments for dispatch_command and action handler
  * Include command chain as part of action method name for commands
  * Enrich README with more documentation

Bug fixes:
  * Handle validation for multiple values correctly

## Version 0.3.0 (Apr 11, 2015)

New features:
  * Support prefix for action name
    * By default, subcommand method is prefixed with "__command_"
    * By default, application action method has no prefix
  * Support nested subcommands
  * Add help option by default in Luban::CLI::Base in order to turn on auto help by default

Minor enhancements:
  * Refactor action creation to be more readable
  * Add an example for subcommands and nested subcommands

Bug fixes:
  * Apply the correct method creator when defining action method
  * Dispatch command under the right class context
  * Show correct command chain between program name and synopsis when composing parser banner

## Version 0.2.0 (Apr 02, 2015)

Minor enhancements:
  * Refactor error class
  * Refactor argument validation
  * Validate required options/arguments in Luban::CLI::Base
  * Create singleton action handler method on application instance
  * Move parse error handling to action handler
  * Exclude examples and spec from the gem itself

## Version 0.1.0 (Mar 31, 2015)

Bootstrapped Luban::CLI

New features:
  * Support general command-line parsing
    * Support options
    * Support switches (boolean options)
    * Support arguments
    * Support subcommand
  * Provide base class (Luban::CLI::Base) for command-line application
