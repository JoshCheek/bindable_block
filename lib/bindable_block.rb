require "bindable_block/version"

class BindableBlock < Proc

  # match args to arity, since instance_method has lambda properties
  class ArgAligner
    def initialize(args, instance_method)
      @result, @args, @parameters = [], args, instance_method.parameters.map(&:first)
      take num :req
      take [num(:opt), args.size].min
      take args.size if has? :rest
    end

    def call
      result
    end

    private

    attr_reader :args, :parameters, :result

    def has?(type)
      parameters.any? { |param| param == type }
    end

    def num(type)
      parameters.count { |param| param == type }
    end

    def take(n)
      n.times { result << args.shift }
    end
  end


  def initialize(klass=BasicObject, &block)
    @original_block  = block

    klass.__send__ :define_method, method_name, &block
    @instance_method = klass.instance_method method_name
    klass.__send__ :remove_method, method_name
  end

  attr_reader :instance_method, :original_block

  def bind(target)
    Proc.new do |*args, &block|
      instance_method.bind(target).call(*align(args), &block)
    end
  end

  def call(*args, &block)
    original_block.call(*args, &block)
  end

  def arity
    original_block.arity
  end

  def lambda?
    false # not strictly necessary, I just want to be explicit
  end

  private

  def align(args)
    ArgAligner.new(args, instance_method).call
  end

  def method_name
    @method_name ||= "bindable_block_#{Time.now.to_i}_#{$$}_#{rand 1000000}"
  end
end
