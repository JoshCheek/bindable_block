require 'bindable_block/arg_aligner'

class BindableBlock < Proc
  class BoundBlock < Proc
    def initialize(original_block, &method)
      f, ln, *               = caller[2].split(':')
      self.bound_file        = f
      self.bound_line_number = ln.to_i
      self.original_block    = original_block
      self.method            = method
    end

    def call(*args, &block)
      method.call(*align(args), &block)
    end

    def lambda?
      original_block.lambda?
    end

    def bound_location
      [bound_file.dup, bound_line_number]
    end

    def parameters
      original_block.parameters
    end

    def inspect
      original_block.to_s.gsub(/^#<\w*/, "#<#{self.class.name}")
    end
    alias to_s inspect


    def binding
      raise NotImplementedError, <<-SADFACE.gsub(/^\s*/, '')
        I legit tried to figure this out, and can't :(

        * Can't just ask, it's private on most objects
        * Can't use `__send__` b/c it's like "the binding at the top of the callstack", which would not be the binding of the obj you're invoking it on
        * Can't `instance_eval { binding }`, because BasicObject doesn't have a binding method
        * Can't `Kernel.instance_method(:binding).bind(obj).instance_eval { binding }` because if obj is a BasicObject, then Kernel isn't an ancestor and thus won't bind to it
        * Tried all manner of adding temp methods, subclassing the singleton class, etc. In the end, I think it's just not doable.

        This is your friendly reminder that whatever you're using this method for is probably bullshit.
      SADFACE
    end

    private

    attr_accessor :bound_file, :bound_line_number, :original_block, :method

    def align(args)
      if original_block.lambda?
        args
      else
        ArgAligner.new(args, method).call
      end
    end
  end
end
