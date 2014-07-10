require "bindable_block/version"
require 'bindable_block/bound_block'

class BindableBlock < Proc

  # match args to arity, since instance_method has lambda properties

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
    bound = BoundBlock.new @original_block, &@instance_method.bind(target)
    if @curried_args then bound.curry(@uncurried_size)[*@curried_args]
    else                  bound
    end
  end

  def call(*args, &block)
    @original_block.call(*args, &block)
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
      p = Proc.new do |*args, &block|
        actual_args = curried_args + args
        if uncurried_size <= actual_args.size
          original_block.call(*actual_args, &block)
        else
          curried = proc_maker.call actual_args, uncurried_size
          bindable_blk_class.new klass, &curried
        end
      end
      p.instance_variable_set :@curried_values, {
        original_block: original_block,
        curried_args:   curried_args,
        uncurried_size: arity,
      }
      p
    end
    curried = proc_maker.call [], arity
    BindableBlock.new klass, &curried
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
