require "bindable_block/version"

class BindableBlock

  # match args to arity, since instance_method has lambda properties
  class ArgAligner
    def self.align(args, instance_method)
      new(args, instance_method).call
    end

    private

    attr_reader :args, :parameters, :result

    def initialize(args, instance_method)
      @result, @args, @parameters = [], args, instance_method.parameters.map(&:first)
      track_if_has_rest
      parameters.delete :rest
      remove_block
      take num_required
      parameters.delete :req
      take 1 while parameters.shift && args.any?
      take args.size if has_rest?
    end

    def num_required
      parameters.count { |param| param == :req }
    end

    def take(n)
      n.times { result << args.shift }
    end

    def remove_block
      parameters.pop if parameters.last == :block
    end

    def track_if_has_rest
      @has_splat = parameters.any? { |param| param == :rest }
    end

    def has_rest?
      @has_splat
    end

    def call
      result
    end
  end


  def initialize(klass, &block)
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

  def to_proc
    method(:call).to_proc
  end

  private

  def align(args)
    ArgAligner.align args, instance_method
  end

  def method_name
    @method_name ||= "bindable_block_#{Time.now.to_i}_#{$$}_#{rand 1000000}"
  end
end
