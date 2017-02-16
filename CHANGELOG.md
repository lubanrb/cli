# Change log

## Version 0.4.9 (Feb 16, 2017)

Bug fixes:
  * Checked if the resource file (rc_file) exists and is a regular file

## Version 0.4.8 (Oct 19, 2016)

Minor enhancements:
  * Added convenient callback methods, #after_configure and #after_alter, in Luban::CLI::Base

## Version 0.4.7 (Sept 28, 2016)

Minor enhancements:
  * Updated README with description for tasks

Bug fixes:
  * Properly handled any remaining command line arguments to opts[:__remaining__] when action method does not removes command line arguments destructively

## Version 0.4.6 (Sept 27, 2016)

New features:
  * Added a special command, task, that supports common task options

## Version 0.4.5 (Sept 07, 2016)

Bug fixes:
  * Left the default value for a switch to be nil if not set yet

## Version 0.4.4 (Apr 18, 2016)

Bug fixes:
  * Removed comma for the synopsis of multiple arguments

## Version 0.4.3 (Feb 26, 2016)

Bug fixes:
  * Ensured command is defined before it can be undefined

## Version 0.4.2 (Nov 05, 2015)

Minor enhancements:
  * After parsing, added any remaining command line arguments to opts[:__remaining__]
    * This is useful to handle arguments provided after the double hyphen
  * Used Ruby refinements to re-implement camelcase and snakecase handling

Bug fixes:
  * Filter empty default values for help message

## Version 0.4.0 (Oct 14, 2015)

New features:
  * Provide convenient method :start to create and run new instance of CLI application
  * Added method #alter to allow change cli configuration during runtime

Minor enhancements:
  * Merge Commands module into Luban::CLI::Base
  * Handled commands in instance level instead of class level
    * Handled command definition and action method on its eigenclass
    * Enhanced action method invocation to look up thru its parent
  * Update examples accordingly
  * Some other minor refactoring

## Version 0.3.2 (Apr 28, 2015)

Minor enhancements:
  * Add use_commands DSL to inject command definitions to a given Luban app or command
  * Add an example to demonstrate command injection

Bug fixes:
  * Add validation to help command
  * Command dispatching within the correct context

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
