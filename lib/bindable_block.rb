require "bindable_block/version"

class BindableBlock
  def initialize(klass, &block)
    @original_block  = block

    klass.__send__ :define_method, method_name, &block
    @instance_method = klass.instance_method method_name
    klass.__send__ :remove_method, method_name
  end

  def method_name
    @method_name ||= "bindable_block_#{Time.now.to_i}_#{$$}_#{rand 1000000}"
  end

  def arg_size
    instance_method.arity
  end

  attr_reader :instance_method, :original_block

  def bind(target)
    Proc.new do |*args, &block|
      # match args to arity, since instance_method has lambda properties
      if args.size >= arg_size
        args = args.take arg_size
      else
        args[arg_size-1] = nil
      end
      instance_method.bind(target).call(*args, &block)
    end
  end

  def call(*args, &block)
    original_block.call(*args, &block)
  end

  def to_proc
    method(:call).to_proc
  end
end
