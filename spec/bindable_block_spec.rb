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

  describe 'arguments' do
    it 'can take a block' do
      block = BindableBlock.new(klass) { |a, &b| [a, (b&&b.call)] }.bind(instance)
      block.call(1).should == [1, nil]
      block.call(1){2}.should == [1, 2]
    end

    specify "when given ordinal arguments at the start, it doesn't care about arity" do
      block = BindableBlock.new(klass) { |a| [a] }.bind(instance)
      block.call.should == [nil]
      block.call(1).should == [1]
      block.call(1, 2).should == [1]
    end

    specify 'when given optional args, it matches them up correctly' do
      block = BindableBlock.new(klass) { |a, b=1, c=2| [a, b, c] }.bind(instance)
      block.call.should == [nil, 1, 2]
      block.call(:a).should == [:a, 1, 2]
      block.call(:a, :b).should == [:a, :b, 2]
      block.call(:a, :b, :c).should == [:a, :b, :c]
      block.call(:a, :b, :c, :d).should == [:a, :b, :c]
    end

    specify 'splat acts as a catch all' do
      block = BindableBlock.new(klass) { |a, *rest| [a, rest] }.bind(instance)
      block.call.should == [nil, []]
      block.call(1).should == [1, []]
      block.call(1, 2).should == [1, [2]]
      block.call(1, 2, 3).should == [1, [2, 3]]
    end

    specify "when given ordinal arguments at the end, it doesn't care about arity" do
      block = BindableBlock.new(klass) { |*a, b, &c| [a, b] }.bind(instance)
      block.call.should == [[], nil]
      block.call(1).should == [[], 1]
      block.call(1,2).should == [[1], 2]
      block.call(1,2,3).should == [[1, 2], 3]

      block = BindableBlock.new(klass) { |a=:a, b, c| [a, b, c] }.bind(instance)
      block.call.should == [:a, nil, nil]
      block.call(1).should == [:a, 1, nil]
      block.call(1, 2).should == [:a, 1, 2]
      block.call(1, 2, 3).should == [1, 2, 3]
      block.call(1, 2, 3, 4).should == [1, 2, 3]
    end


    specify "when given complex arguments, it matches that shit up right" do
      proc  = Proc.new { |a, b, c=1, d=2, *e, f| [a,b,c,d,e,f] }
      block = BindableBlock.new(klass, &proc).bind(instance)
      block.call.should == proc.call
      block.call(:a).should == proc.call(:a)
      block.call(:a,:b).should == proc.call(:a,:b)
      block.call(:a,:b,:c).should == proc.call(:a,:b,:c)
      block.call(:a,:b,:c,:d).should == proc.call(:a,:b,:c,:d)
      block.call(:a,:b,:c,:d,:e).should == proc.call(:a,:b,:c,:d,:e)
      block.call(:a,:b,:c,:d,:e,:f).should == proc.call(:a,:b,:c,:d,:e,:f)
      block.call(:a,:b,:c,:d,:e,:f,:g).should == proc.call(:a,:b,:c,:d,:e,:f,:g)
    end
  end
end
