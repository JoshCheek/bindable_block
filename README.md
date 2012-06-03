# BindableBlock

`instance_exec` can't take block arguments. Get around that with BindableProc

```ruby

require 'bindable_block'
User = Struct.new :name
greeter = BindableBlock.new(User) { "Welcome, #{name}" }
greeter.bind(User.new "Josh").call # => "Welcome, Josh"

```


## Installation

Add this line to your application's Gemfile:

    gem 'bindable_block'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bindable_block
