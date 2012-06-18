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

## Where the abstraction leaks

Bindable block does something that isn't possible in Ruby.
It does this with black magick. Unfortunately, that abstraction
will leak in the case of return statements. Return statements in
blocks will return you from the containing method.

```ruby
<% test 'proc behaviour', with: :magic_comments do %>
def meth
  Proc.new { return 1 }.call
  2
end

meth # => 1
<% end %>
```


Return statements in lambdas will return you from the lambda.

```ruby
<% test 'lambda behaviour', with: :magic_comments do %>
def meth
  lambda { return 1 }.call
  2
end

meth # => 2
<% end %>
```

You would expect a bindable block to continue to behave like the
former example, but it will actually behave like the latter example.

At present, I can only think of two ways to fix this:

1) It might be possible to rewrite the AST with ripper.
2) It is probably possible to write this in C.

Neither of these are high on my priority list.


## Installation

Add this line to your application's Gemfile:

    gem 'bindable_block'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bindable_block
