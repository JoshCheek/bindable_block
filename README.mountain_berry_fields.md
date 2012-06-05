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

[Here](https://github.com/JoshCheek/surrogate/blob/eb1d7f98a148c032f6d3ef1d8df8b703386f286d/lib/surrogate/options.rb#L32-34) is an example.

## Installation

Add this line to your application's Gemfile:

    gem 'bindable_block'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bindable_block
