# BindableBlock

`instance_exec` can't take block arguments. Get around that with BindableProc

```ruby
<% test 'example', with: :magic_comments do %>
require 'bindable_block'

User = Struct.new :name
greeter = BindableBlock.new(User) { "Welcome, #{name}" }
greeter.bind(User.new "Josh").call # => "Welcome, Josh"
<% end %>
```


## Installation

Add this line to your application's Gemfile:

    gem 'bindable_block'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bindable_block
