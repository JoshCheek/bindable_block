require 'bindable_block'

class BasicObject
  def instance_exec_b(*args, argument_block, &instance_block)
    if argument_block.nil?
      instance_exec(*args, &instance_block)
    elsif argument_block.respond_to?(:call) && argument_block.respond_to?(:to_proc)
      ::BindableBlock
        .new(self.singleton_class, &instance_block)
        .bind(self)
        .call(*args, &argument_block)
    else
      ::Kernel.raise ::ArgumentError, "Last argument to instance_exec_b must be blocky (respond to #call and #to_proc), or nil"
    end
  end
end
