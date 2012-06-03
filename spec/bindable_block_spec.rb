require 'bindable_block'

describe BindableBlock do
  let(:default_name) { "Carmen" }
  let(:klass)        { Struct.new :name }
  let(:instance)     { klass.new default_name }

  it 'can be bound to instances of the target' do
    block = BindableBlock.new(klass) { self }
    block.bind(instance).call.should equal instance
  end

  it 'can be rebound' do
    block = BindableBlock.new(klass) { name }
    block.bind(klass.new 'Josh').call.should == 'Josh'
    block.bind(klass.new 'Mei').call.should == 'Mei'
  end

  it 'can also just be invoked without being bound' do
    def self.a() 1 end
    b = 2
    block = BindableBlock.new(klass) { |c, &d| a + b + c + d.call }
    block.call(3){4}.should == 10
  end

  it "doesn't care about arity" do
    block = BindableBlock.new(klass) { |a| [a] }.bind(instance)
    block.call.should == [nil]
    block.call(1).should == [1]
    block.call(1, 2).should == [1]
  end

  it 'can take a block' do
    block = BindableBlock.new(klass) { |a, &b| [a, (b&&b.call)] }.bind(instance)
    block.call(1).should == [1, nil]
    block.call(1){2}.should == [1, 2]
  end

  it 'can be passed to methods and shit' do
    doubler = lambda { |&block| block.call + block.call }
    doubler.call(&BindableBlock.new(klass) { 12 }).should == 24

    # sadly this part doesn't work, I think it unwraps the block from the proc, then re-wraps it in a new one, losing the singleton method
    # binder = lambda { |&block| block.bind(instance).call }
    # binder.call(&BindableBlock.new(klass) { name }).should == default_name
    #
    # This was my attempted to_proc implementation
    # bindable_block = self
    # proc = method(:call).to_proc
    # proc.define_singleton_method(:bind) { |target| bindable_block.bind target }
    # proc
  end
end
