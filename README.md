# Luban::CLI

Luban::CLI is a command-line interface for Ruby with a simple lightweight option parser and command handler based on Ruby standard library, OptionParser.

Luban::CLI requires Ruby 2.1 or later. 

## Installation

Add this line to your application Gemfile:

```ruby
gem "luban-cli"
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install luban-cli
```

## Usage

### Simple Example

```ruby
require 'luban/cli'

class MyApp < Luban::CLI::Application
  configure do
    # program "my_app"
    version "1.0.0"
    long_desc "Demo app for Luban::CLI" 
    option :prefix, "Prefix to a name, e.g., Mr, Ms, etc.", short: :p
    option :suffix, "Suffix to a name, e.g., Jr, Sr, etc.", short: :s
    switch :verbose, "Run in verbose mode", short: :V
    argument :name, "Name to say hi"
    action :say_hi
  end

  def say_hi(args:, opts:)
    name = compose_name(opts[:prefix], opts[:suffix], args[:name])
    if opts[:verbose]
      say_hi_verbosely(name, opts, args)
    else
      say_hi_concisely(name)
    end
  end

  protected

  def say_hi_verbosely(name, opts, args)
    puts "Options: #{opts.inspect}"
    puts "Arguments: #{args.inspect}"
    say_hi_concisely(name)
  end

  def say_hi_concisely(name)
    puts "Hi, #{name}!"
  end

  def compose_name(prefix, suffix, name)
    name = name.capitalize
    name = "#{prefix.capitalize}. #{name}" unless prefix.nil?
    name = "#{name} #{suffix.capitalize}." unless suffix.nil?
    name
  end
end

MyApp.start
```

```
$ ruby my_app.rb -h
Usage: my_app [options] NAME

  Options:
    -v, --version                    Show hi version.
    -p, --prefix PREFIX              Prefix to a name, e.g., Mr, Ms, etc.
    -s, --suffix SUFFIX              Suffix to a name, e.g., Jr, Sr, etc.
    -V, --verbose                    Run in verbose mode
    -h, --help                       Show this help message.

  Arguments:
    NAME                             Name to say hi

  Description:
    Demo app for Luban::CLI

$ ruby my_app.rb -v
my_app 1.0.0

$ ruby my_app.rb john -p mr -s jr
Hi, Mr. John Jr.!

$ ruby my_app.rb john -p mr -s jr -V
Options: {:version=>false, :prefix=>"mr", :suffix=>"jr", :verbose=>true, :help=>false, :__remaining__=>[]}
Arguments: {:name=>"john"}
Hi, Mr. John Jr.!
```

Please refer to [examples](examples) for more sample usage.

## DSL

The following is an overview of the Luban::CLI DSL. 

### program

The name of the application. Default: $0.

### desc

A short description of what the application does.

### long_desc

A long description of what the application does.

### argument

An arguement is a positioned parameter passed from command-line. To declare an argument:

```ruby
argument :name, 'description', **modifiers, &blk
```

The modifiers below can be used:

* :default - Default value for the argument.
* :required - Flag to indicate if the argument is mandatory or not. Default: true.
* :multiple - Flag to indicate argument is a list of values or a single value. Default: false.
* :type - Value type for the argument. Default: :string.
* :match - A regex for argument value matching.
* :within - A range or a list of values the argument value to be within.
* :assure - A code block for argument value validation.

If required argument is not provided, Luban::CLI::Base::MissingRequiredArguments will be raised.

If validation failed, Luban::CLI::Argument::InvalidArgumentValue will be raised.

Note: An argument with multiple values needs to be positioned at the last argument. Furthermore, you cannot specify more than one arguements with multiple values.

Here is an example how to use argument:

```ruby
require 'luban/cli'

class MyApp < Luban::CLI::Application
  configure do
    argument :name, 'Name for an employee'
    argument :gender, 'Gender for an employee',
             type: :symbol, within: [:male, :femal]
    argument :age, 'Age for an employee',
              type: :integer, assure: ->(age) { age < 60 }
    argument :level, 'Level for an employee', 
             type: :integer, within: 1..4
    argument :email, 'Email for an employee', 
              match: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i,
              multiple: true, required: false
    action do |**params|
      puts params.inspect
    end
  end
end

MyApp.start
```

```
$ ruby my_app.rb
Missing required argument(s): NAME, GENDER, LEVEL (Luban::CLI::Base::MissingRequiredArguments)
... ...
    
$ ruby my_app.rb john male 90
Invalid value of argument AGE: 90 (Luban::CLI::Argument::InvalidArgumentValue)
... ...

$ ruby my_app.rb john male 30 2
{:args=>{:name=>"john", :gender=>:male, :age=>30, :level=>2, :email=>nil}, :opts=>{:help=>false}}

$ ruby my_app.rb john male 30 2 john@company.com
{:args=>{:name=>"john", :gender=>:male, :age=>30, :level=>2, :email=>["john@company.com"]}, :opts=>{:help=>false}}

$ ruby my_app.rb john male 30 2 john@company.com john@personal.com
{:args=>{:name=>"john", :gender=>:male, :age=>30, :level=>2, :email=>["john@company.com", "john@personal.com"]}, :opts=>{:help=>false}}
```

### option

An option usually takes an argument, e.g. --require LIBRARIES. To declare an option:

```ruby
option :name, 'description', **modifiers, &blk
```

The extra modifiers below can be used along with all modifiers applicable to arguments:

* :long - Long style argument name.
* :short - Short style argument alias.

Note: modifier :required is turned off by default. Therefore, all options are not mandatory unless they are declared explicitly.

Here is an example how to use option:

```ruby
require 'luban/cli'

class MyApp < Luban::CLI::Application
  configure do
    option :libraries, 'Require the LIBRARIES before executing your script', 
           long: :require, short: :r, multiple: true
    action do |**params|
      puts params.inspect
    end
  end
end

MyApp.start
```

```
$ ruby my_app.rb --require bundler
{:args=>{}, :opts=>{:libraries=>["bundler"], :help=>false}}

$ ruby my_app.rb -r bundler,rails
{:args=>{}, :opts=>{:libraries=>["bundler", "rails"], :help=>false}}
```

Occassionally an option might take an optional argument, e.g. --inplace [EXTENSION]. This kind of option is called nullable option. The nullable option is set to true if the optional argument is not provided; otherwise, the value of the option is set to the value of the argument. To declare a nullable option, you can explicitly turn off nullable modifier which is off by default.

Here is an example how to use nullable option:

```ruby
require 'luban/cli'

class MyApp < Luban::CLI::Application
  configure do
    option :inplace, 'Edit in place (make backup if EXTENSION supplied)', 
            nullable: true # Turn the option into nullable
    action do |**params|
      puts params.inspect
    end
  end
end

MyApp.start
```

```
$ ruby my_app.rb
{:args=>{}, :opts=>{:inplace=>nil, :help=>false}}

$ ruby my_app.rb --inplace
{:args=>{}, :opts=>{:inplace=>true, :help=>false}}

$ ruby my_app.rb --inplace .bak 
{:args=>{}, :opts=>{:inplace=>".bak", :help=>false}}
```

### switch

A switch is a special option that doesn't take any arguments, e.g., --verbose, --help, etc. To declare a switch:

```ruby
switch :name, 'description', **modifiers, &blk
```

All modifiers applied to an option can be used for a switch except the following:

* :type - Type for switch is set to :bool (true/false) and it cannot be changed.
* :multiple - Set to false to ensure to handle a single value and it cannot be changed.

Negatable switch is also supported, e.g., --local, --no-local. To declare a negatable switch, you can explicitly turn on negatable modifier which is off by default. 

Here is an example how to use negatable option:

```ruby
require 'luban/cli'

class MyApp < Luban::CLI::Application
  configure do
    switch :local, 'Check repository locally', 
           negatable: true # Turn the switch into negatable: --local or --no-local
    action do |**params|
      puts params.inspect
    end
  end
end

MyApp.start
```

### help

Add a switch for help message display. The modifiers below can be used:

* :short - Short style switch for help display. Default: :h
* :desc - Set a switch description for help display. Default: "Show this help message."

DSL alias #auto_help is provided which applies default values for the above options.

The switch of help display is turned on by default unless explicitly turning off when creating an application or a command.

```ruby
require 'luban/cli'

class MyApp < Luban::CLI::Application
  ... ...
end

MyApp.start(auto_help: false)
``` 

### version

Specify or retrieve the version of the application. 

If calling without any parameters, version previously set is returned.

If calling with a version, a switch for version display is added to the application. The modifiers below can be used:

* :short - Set a short style switch for version display. Default: :v
* :desc - Set a switch description for version disiplay. Default: "Show #{program_name} version."

### action

Specify handler for the CLI application or command.

It accepts a code block or an instance method name from the application as the action handler. If a code block is given, the code block is executed in the binding of the application. If both a code block and an instance method name are provided, the instance method name is used and the code block is ignored.

The handler accepts the following keyword arguments:

* :args - arguments parsed from the command-line
* :opts - options parsed from the command-line


### action!

Same as action, but removes command-line arguments destructively. 

### configure

This is used to configure CLI application during definition.

Here is an example for how to configure CLI application:

```ruby
require 'luban/cli'

class MyApp < Luban::CLI::Application
  configure do
    program "my_app"
    version "1.0.0"
    long_desc "Demo app for Luban::CLI" 
    option :opt1, "Description for opt1", short: :o
    switch :swt1, "Description for swt1", short: :s
    argument :arg1, "Description to arg1"
    action :do_something
  end

  def do_something(args:, opts:)
    ... ...
  end
end

MyApp.start

```

However, it can be overriden if a configuration block is provided during application instance creation:

```ruby
MyApp.start do
  program "my_app"
  version "1.0.0"
  long_desc "Demo app for Luban::CLI" 
  option :opt2, "Description for opt2", short: :p
  switch :swt2, "Description for swt2", short: :w
  action :do_something_else
end

```

## Option Parsing Termination

It is a convention that a double hyphen is a signal to stop option interpretation and to read the remaining statements on the command line literally. Luban::CLI supports this convention and stores the remaining statements on the command line, if any, into the keyword argument :opts with a hash key :\__remaining\__, which is passed to the given action handler.

The following refers to the simple example shown in the section Usage, which demonstrates the parsing result with remaining statements in option parsing termination.

```ruby
$ ruby my_app.rb john -p mr -s jr -V
Options: {:version=>false, :prefix=>"mr", :suffix=>"jr", :verbose=>true, :help=>false, :__remaining__=>[]}
Arguments: {:name=>"john"}
Hi, Mr. John Jr.!

$ ruby my_app.rb john -p mr -s jr -V -- --test here
Options: {:version=>false, :prefix=>"mr", :suffix=>"jr", :verbose=>true, :help=>false, :__remaining__=>["--test", "here"]}
Arguments: {:name=>"john"}
Hi, Mr. John Jr.!
```

## Commands

Luban::CLI supports commands/subcommands. Commands can also be nested. However, all action handlers are preferred to be defined under the the application class; otherwise RuntimeError will be raised.

```ruby
require 'luban/cli'

class MyApp < Luban::CLI::Application
  configure do
    version '1.0.0'
    desc 'Short description for the application'
    long_desc 'Long description for the application'

    command :cmd1 do
      desc 'Description for command 1'

      command :task1 do
        desc 'Description for task 1'
        argument :arg1, 'Description for arg1', type: :string
        action :exec_command1_task1
      end

      command :task2 do
        desc 'Description for task 2'
        option :opt1, 'Description for opt1', type: :integer
        action :exec_command1_task2
      end
    end

    command :cmd2 do
      desc 'Description for command 1'
      switch :swt1, 'Description for swt1'
      action :exec_command2
    end

    # Define a help command to list all commands or help for one command.
    auto_help_command
  end

  def exec_command1_task1(args:, opts:); puts 'In command 1/task 1'; end
  def exec_command1_task2(args:, opts:); puts 'In command 1/task 2'; end
  def exec_command2(args:, opts:); puts 'In command 2'; end
end

MyApp.start
```

### Command method/handler

By default, a new method will be defined for each command under the application/command instance's eigenclass. Usually you don't need to call this method directly. Luban::CLI dispatches the specified command to the corresponding command method/handler properly.

The command method name is composed of the following, concatenating with an underscore:

* prefix - Default prefix is "__command_".
* command chain
  * For regular command, it is the command name itself
  * For nested commands, it is the commands from the top to the bottom one

In the example above, there are following command methods defined in MyApp:

* __command_cmd1_task1
* __command_cmd1_task2
* __command_cmd2

You can also change the prefix to your preferred one by setting the modifier :prefix when defining a command:

```ruby
command :cmd1, prefix: '__my_prefix_' do
  ... ...
end
```

### auto_help_command / help_command

DSL method #auto_help_command is used to define a command to list all commands or help for one command. Under rare circumstances that you need to customize the help command (i.e., use a different command name like :manual), you can use DSL method #help_command which accepts the same parameters that for #command. 

### Tasks

A task is a special command that supports common options shared among other tasks, and usually it is the last command in a command chain. 

In a typical use case, all commands have a set of common options in addition to their own. Tasks can be defined to solve this issue in a DRY way with an instance method, #add_common_task_options, in where the common options are defined. Here is a simple example demonstrating the usage of tasks: 

```ruby
require 'luban/cli'

class MyApp < Luban::CLI::Application
  configure do
    version '1.0.0'
    desc 'Short description for the application'
    long_desc 'Long description for the application'

    command :tasks do
      desc 'Description for tasks'

      task :task1 do
        desc 'Description for task 1'
        argument :arg1, 'Description for arg1', type: :string
        action :exec_tasks_task1
      end

      task :task2 do
        desc 'Description for task 2'
        option :opt1, 'Description for opt1', type: :integer
        action :exec_tasks_task2
      end
    end
  end

  def exec_tasks_task1(**params)
    puts params.inspect
  end

  def exec_tasks_task2(**params)
    puts params.inspect
  end

  protected

  def add_common_task_options(task)
    task.switch :dry_run, "Run as a simulation", short: :d
    task.switch :verbose, "Turn on verbose mode", short: :V
  end
end

MyApp.start

$ ruby my_app.rb tasks task1 arg1 -d -V
{:args=>{:arg1=>"arg1"}, :opts=>{:help=>nil, :dry_run=>true, :verbose=>true, :__remaining__=>[]}}

$ ruby my_app.rb tasks task2 -d
{:args=>{}, :opts=>{:opt1=>nil, :help=>nil, :dry_run=>true, :verbose=>nil, :__remaining__=>[]}}

```

### Command injection

Commands can be defined directly within the Luban app class like examples shown in the previous sections. In addition, commands can be defined separately and injected into a given Luban app later. Command definition can be also namespaced by using module. With this feature, commands can be designed in a more re-usable and scalable way. This feature also implies that Luban CLI application supports namespaced commands.

Below is an example demonstrating how command injection is supposed to work.

```ruby
require 'luban/cli'

module App
  module ControlTasks
    class Task1 < Luban::CLI::Command
      configure do
        ... ...
      end
    end

    class Task2 < Luban::CLI::Command
      configure do
        ... ...
      end
    end
  end
end

class MyApp < Luban::CLI::Application
  configure do
    ... ...
  end

  # Inject Luban commands directly defined under the given module
  use_commands 'app:control_tasks'

  # Alternatively, commands can be injected individually
  # The following has the same effect
  # command 'app:control_tasks:task1'
  # command 'app:control_tasks:task2'
end

MyApp.start
```

```
$ ruby my_app.rb app:control_tasks:task1

$ ruby my_app.rb app:control_tasks:task2
```

As shown above, there are a few naming conventions about the command class naming and injection:

* Module name to be injected should be fully qualified
  * namespaces/modules should be in snake case and
  * Separated by colon as the delimiter
  * For instance, 'app:control_tasks'
* Alternatively, commands can be injected individually
  * Command name should be fully qualified
  * For instance, 'app:control_tasks:task2'
  
## Applications

Luban::CLI provides a base class for cli application, Luban::CLI::Application. You can define your own cli application by inheriting it as examples shown in the previous sections. 

In addition to command-line argument parsing capabilities, Luban::CLI::Application also supports a rc file. For example, if an application called "my_app.rb", it looks up rc file ".my_apprc" under user home when the application starts up. The rc file uses YML format. If rc file is found, the content will be loaded into the instance variable :rc; if rc file is not found, the instance variable :rc will be initialized as an empty hash.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
