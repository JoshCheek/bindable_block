require "bindable_block/version"
require 'bindable_block/bound_block'

class BindableBlock < Proc
  def initialize(klass=BasicObject, &block)
    @klass           = klass
    @original_block  = block
    if curried_values = block.instance_variable_get(:@curried_values)
      @original_block = curried_values[:original_block]
      @curried_args   = curried_values[:curried_args]
      @uncurried_size = curried_values[:uncurried_size]
    end
    @instance_method = block_to_method klass, @original_block
  end

  def bind(target)
    bound = BoundBlock.new @original_block, target, &@instance_method.bind(target)
    if @curried_args then bound.curry(@uncurried_size)[*@curried_args]
    else                  bound
    end
  end

  def arity
    @original_block.arity
  end

  def curry(arity=nil)
    arity ||= @instance_method.parameters.count { |type, _| type == :req }
    original_block     = @original_block # can't use the imeth, because it's unbound, so no curry
    bindable_blk_class = self.class
    klass              = @klass

    proc_maker = lambda do |curried_args, uncurried_size|
      curried = Proc.new do |*args, &block|
        actual_args = curried_args + args
        if uncurried_size <= actual_args.size
          original_block.call(*actual_args, &block)
        else
          proc_maker.call actual_args, uncurried_size
        end
      end
      curried.instance_variable_set :@curried_values, {
        original_block: original_block,
        curried_args:   curried_args,
        uncurried_size: arity,
      }
      bindable_blk_class.new klass, &curried
    end
    proc_maker.call [], arity
  end

  private

  def block_to_method(klass, block)
    temp_method_name = "bindable_block_#{Time.now.to_i}_#{$$}_#{rand 1_000_0000}"
    @klass.__send__(:define_method, temp_method_name, &block)
    @klass.instance_method(temp_method_name)
  ensure
    @klass.__send__(:remove_method, temp_method_name)
  end
end
