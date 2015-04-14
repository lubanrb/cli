# Luban::CLI

Luban::CLI is a command-line interface for Ruby with a simple lightweight option parser and command handler based on Ruby standard library, OptionParser.

Luban::CLI requires Ruby 2.1 or later. 

## Installation

Add this line to your application Gemfile:

```ruby
    gem "luban-cli"
```

And then execute:

```sh
    $ bundle
```

Or install it yourself as:

```sh
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

  def say_hi(cmd:, argv:, args:, opts:)
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

MyApp.new.run
```

### Sample Usage

```sh
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

ruby examples/hi.rb john -p mr -s jr -V
Options: {:version=>false, :prefix=>"mr", :suffix=>"jr", :verbose=>true, :help=>false}
Arguments: {:name=>"chi"}
Hi, Mr. John Jr.!
```

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

MyApp.new.run
```

```sh
$ ruby my_app.rb
Missing required argument(s): NAME, GENDER, LEVEL (Luban::CLI::Base::MissingRequiredArguments)
... ...
    
$ ruby my_app.rb john male 90
Invalid value of argument AGE: 90 (Luban::CLI::Argument::InvalidArgumentValue)
... ...

$ ruby my_app.rb john male 30 2
{:cmd=>nil, :argv=>[], :args=>{:name=>"john", :gender=>:male, :age=>30, :level=>2, :email=>nil}, :opts=>{:help=>false}}

$ ruby my_app.rb john male 30 2 john@company.com
{:cmd=>nil, :argv=>[], :args=>{:name=>"john", :gender=>:male, :age=>30, :level=>2, :email=>["john@company.com"]}, :opts=>{:help=>false}}

$ ruby my_app.rb john male 30 2 john@company.com john@personal.com
{:cmd=>nil, :argv=>[], :args=>{:name=>"john", :gender=>:male, :age=>30, :level=>2, :email=>["john@company.com", "john@personal.com"]}, :opts=>{:help=>false}}
```

### option

An option usually takes an argument, e.g. --require LIBRARY. To declare an option:

```ruby
    option :name, 'description', **modifiers, &blk
```

The extra modifiers below can be used along with all modifiers applicable to arguments:

* :long - Long style argument name.
* :short - Short style argument alias.

Note: modifier :required is turned off by default. Therefore, all options are not mandatory unless they are declared explicitly.

Here is an example how to use option:

```ruby
class MyApp < Luban::CLI::Application
  configure do
    option :libraries, 'Require the LIBRARIES before executing your script', 
           long: :require, short: :r, multiple: true
    action do |**params|
      puts params.inspect
    end
  end
end

MyApp.new.run
```

```sh
$ ruby my_app.rb --require bundler
{:cmd=>nil, :argv=>[], :args=>{}, :opts=>{:libraries=>["bundler"], :help=>false}}

$ ruby my_app.rb -r bundler,rails
{:cmd=>nil, :argv=>[], :args=>{}, :opts=>{:libraries=>["bundler", "rails"], :help=>false}}
```

Occassionally an option might take an optional argument, e.g. --inplace [EXTENSION]. This kind of option is called nullable option. The nullable option is set to true if the optional argument is not provided; otherwise, the value of the option is set to the value of the argument. To declare a nullable option, you can explicitly turn off nullable modifier which is off by default.

Here is an example how to use nullable option:

```ruby
class MyApp < Luban::CLI::Application
  configure do
    option :inplace, 'Edit in place (make backup if EXTENSION supplied)', 
            nullable: true
    action do |**params|
      puts params.inspect
    end
  end
end

MyApp.new.run
```

```sh
$ ruby my_app.rb
{:cmd=>nil, :argv=>[], :args=>{}, :opts=>{:inplace=>nil, :help=>false}}

$ ruby my_app.rb --inplace
{:cmd=>nil, :argv=>[], :args=>{}, :opts=>{:inplace=>true, :help=>false}}

$ ruby my_app.rb --inplace .bak 
{:cmd=>nil, :argv=>[], :args=>{}, :opts=>{:inplace=>".bak", :help=>false}}
```

### switch

### help

Add a switch for help message display. The modifiers below can be used:

* :short - Short style switch for help display. Default: :h
* :desc - Set a switch description for help display. Default: "Show this help message."

DSL alias #auto_help is provided which applies default values for the above options.

The switch of help display is turned on by default unless explicitly turning off when creating an application or a command.

```ruby
class MyApp < Luban::CLI::Application
  ... ...
end

MyApp.new(auto_help: false)
``` 

### version

Specify or retrieve the version of the application. 

If calling without any parameters, version previously set is returned.

If calling with a version, a switch for version display is added to the application. The modifiers below can be used:

* :short - Set a short style switch for version display. Default: :v
* :desc - Set a switch description for version disiplay. Default: "Show #{program_name} version."

### action

### action!

### configure

## Commands

### help_command

## Applications

### Error Handling

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
