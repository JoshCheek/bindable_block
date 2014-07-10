# BindableBlock

`instance_exec` can't take block arguments. Get around that with BindableProc (also provides optional `BasicObject#instance_exec_b`)

If you understand that previous statement, then I probably can't dissuade you from using this.
If you don't, then a word of warning: This is probably the wrong solution.
`instance_exec` is probably the wrong solution too.
Metaprogramming is almost never merited.
It's lighting your way by setting yourself on fire.
Your problem will be simpler if you don't use it.
It will be more comprehensible.
You'll waste less time later trying to figure out how to get it to do what you want.
95% of the times I've used metaprogramming, I've later regretted it.
The whole use-case that led to the creation of this gem was wrong,
it was unnecessary, it added tremendous complexity to the implementation.
Think Rails moving from `find_by_name(name)` to `find_by(name: name)`,
and how much better that was.

BUT! If I still can't convince you, then read on:


```ruby
require 'bindable_block'

User = Struct.new :name
greeter = BindableBlock.new { "Welcome, #{name}" }
greeter.bind(User.new "Josh").call # => "Welcome, Josh"
```

```ruby
require 'bindable_block/instance_exec_b'

# http://rdoc.info/stdlib/core/BasicObject:instance_exec
class KlassWithSecret
  def initialize
    @secret = 99
  end
end
k           = KlassWithSecret.new
sum         = 10
sum_updater = lambda { |to_add| sum += to_add }
result      = k.instance_exec_b(5, sum_updater) { |x, &b| b.call(@secret+x) } # => 114
sum # => 114
```

[Here](https://github.com/JoshCheek/surrogate/blob/eb1d7f98a148c032f6d3ef1d8df8b703386f286d/lib/surrogate/options.rb#L32-34) is an example.
Note that it is the old-style where users had to submit the class that could be bound to.

## Possible advances in usefulness

It just occurred to me that if we bound it to BasicObject
then it could be used on any class without the user needing to
specify which class they want to bind it to.

## Where the abstraction leaks

Bindable block does something that isn't possible in Ruby.
It does this with black magick. Unfortunately, that abstraction
will leak in the case of return statements. Return statements in
blocks will return you from the containing method.

```ruby
def meth
  Proc.new { return 1 }.call
  2
end

meth # => 1
```


Return statements in lambdas will return you from the lambda.

```ruby
def meth
  lambda { return 1 }.call
  2
end

meth # => 2
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
