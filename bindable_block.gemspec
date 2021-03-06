# -*- encoding: utf-8 -*-
require File.expand_path('../lib/bindable_block/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Josh Cheek"]
  gem.email         = ["josh.cheek@gmail.com"]
  gem.description   = %q{instance_exec can't pass block arguments through. Use a bindable block instead (there is also an optional core extension instance_exec_b, which will mimic the instance_exec interface, but also allow you to pass the block).}
  gem.summary       = %q{Allows you to bind procs to instances of classes}

  gem.homepage      = "https://github.com/JoshCheek/bindable_block"
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "bindable_block"
  gem.require_paths = ["lib"]
  gem.version       = BindableBlock::VERSION

  gem.required_ruby_version = '~> 2.1'

  gem.add_development_dependency 'rspec', '>= 3.0.0', '~> 3.0'
end
