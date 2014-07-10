require 'bindable_block'

describe BindableBlock do
  let(:default_name) { "Carmen" }
  let(:klass)        { Struct.new :name }
  let(:instance)     { klass.new default_name }

  # minitest style, b/c otherwise the levels of things being passed around gets to be a bit much
  def assert_equal(a, b)
    expect(b).to eq a
  end
  def assert_same(a, b)
    expect(b).to equal a
  end
  def assert(val)
    expect(val).to be_truthy
  end
  def refute(val)
    expect(val).to_not be_truthy
  end


  it 'can be bound to instances of the target' do
    block = BindableBlock.new(klass) { self }
    assert_same block.bind(instance).call, instance
  end

  it 'can be rebound' do
    block = BindableBlock.new(klass) { name }
    assert_equal 'Josh', block.bind(klass.new 'Josh').call
    assert_equal 'Mei',  block.bind(klass.new 'Mei').call
  end

  it 'can also just be invoked without being bound' do
    def self.a() 1 end
    b = 2
    block = BindableBlock.new(klass) { |c, &d| a + b + c + d.call }
    assert_equal 10, block.call(3){4}
  end

  it 'can be passed to methods and shit' do
    doubler = lambda { |&block| block.call + block.call }
    assert_equal 24,             doubler.call(&BindableBlock.new(klass) { 12 })
    assert_equal 'CarmenCarmen', doubler.call(&BindableBlock.new(klass) { name }.bind(instance))
  end

  describe 'arguments' do
    it 'can take a block' do
      block = BindableBlock.new(klass) { |a, &b| [a, (b&&b.call)] }.bind(instance)
      assert_equal [1, nil], block.call(1)
      assert_equal [1, 2],   block.call(1){2}
    end

    specify "when given ordinal arguments at the start, it doesn't care about arity" do
      block = BindableBlock.new(klass) { |a| [a] }.bind(instance)
      assert_equal [nil], block.call
      assert_equal [1],   block.call(1)
      assert_equal [1],   block.call(1, 2)
    end

    specify 'when given optional args, it matches them up correctly' do
      block = BindableBlock.new(klass) { |a, b=1, c=2| [a, b, c] }.bind(instance)
      assert_equal [nil, 1, 2]  , block.call
      assert_equal [:a, 1, 2]   , block.call(:a)
      assert_equal [:a, :b, 2]  , block.call(:a, :b)
      assert_equal [:a, :b, :c] , block.call(:a, :b, :c)
      assert_equal [:a, :b, :c] , block.call(:a, :b, :c, :d)
    end

    specify 'splat acts as a catch all' do
      block = BindableBlock.new(klass) { |a, *rest| [a, rest] }.bind(instance)
      assert_equal [nil, []]   , block.call
      assert_equal [1, []]     , block.call(1)
      assert_equal [1, [2]]    , block.call(1, 2)
      assert_equal [1, [2, 3]] , block.call(1, 2, 3)
    end

    specify "when given ordinal arguments at the end, it doesn't care about arity" do
      block = BindableBlock.new(klass) { |*a, b, &c| [a, b] }.bind(instance)
      assert_equal [[], nil]   , block.call
      assert_equal [[], 1]     , block.call(1)
      assert_equal [[1], 2]    , block.call(1,2)
      assert_equal [[1, 2], 3] , block.call(1,2,3)

      block = BindableBlock.new(klass) { |a=:a, b, c| [a, b, c] }.bind(instance)
      assert_equal [:a, nil, nil] , block.call
      assert_equal [:a, 1, nil]   , block.call(1)
      assert_equal [:a, 1, 2]     , block.call(1, 2)
      assert_equal [1, 2, 3]      , block.call(1, 2, 3)
      assert_equal [1, 2, 3]      , block.call(1, 2, 3, 4)
    end


    specify "when given complex arguments, it matches that shit up right" do
      proc  = Proc.new { |a, b, c=1, d=2, *e, f| [a,b,c,d,e,f] }
      block = BindableBlock.new(klass, &proc).bind(instance)
      assert_equal proc.call                       , block.call
      assert_equal proc.call(:a)                   , block.call(:a)
      assert_equal proc.call(:a,:b)                , block.call(:a,:b)
      assert_equal proc.call(:a,:b,:c)             , block.call(:a,:b,:c)
      assert_equal proc.call(:a,:b,:c,:d)          , block.call(:a,:b,:c,:d)
      assert_equal proc.call(:a,:b,:c,:d,:e)       , block.call(:a,:b,:c,:d,:e)
      assert_equal proc.call(:a,:b,:c,:d,:e,:f)    , block.call(:a,:b,:c,:d,:e,:f)
      assert_equal proc.call(:a,:b,:c,:d,:e,:f,:g) , block.call(:a,:b,:c,:d,:e,:f,:g)
    end
  end

  describe 'instance_exec_b', t:true do
    it 'is only available if you require the file explicitly, since it monkey patches BasicObject' do
      expect { method :instance_exec_b }.to raise_error NameError
      require 'bindable_block/instance_exec_b'
      method :instance_exec_b
    end

    it 'is on wherever instance_exec is on (BasicObject)' do
      expect(method(:instance_exec_b).owner).to equal method(:instance_exec).owner
    end

    it 'provides an instance_exec like method, whose last argument is a block' do
      a, b = 1, 2
      result = instance.instance_exec_b(a, lambda { b }) { |ordinal, &block| "#{name}#{ordinal}#{block.call}" }
      assert_equal "Carmen12", result
    end

    it 'passes no block if the last param is nil'  do
      a, b = 1, 2
      result = instance.instance_exec_b(a, nil) { |ordinal, &block| "#{name}#{ordinal}#{!!block}" }
      assert_equal "Carmen1false", result
    end

    it 'the block can be blocky things (can be called and put into the block slot), otherwise raises an ArgumentError' do
      expect { instance.instance_exec_b(1) { |*| } }.to raise_error ArgumentError, /block/
      expect { instance.instance_exec_b(1, :abc) { |*| } }.to raise_error ArgumentError, /block/ # has to_proc, but not call
      o = Object.new
      def o.call(*)
        2
      end
      expect { instance.instance_exec_b(1, o) { |*| } }.to raise_error ArgumentError, /block/ # has call, but not to_proc
      def o.to_proc
        Proc.new { 3 }
      end
      assert_equal 4, instance.instance_exec_b(1, o) { |n, &b| n + b.call }
    end

    it 'doesn\'t need ordinal args' do
      assert instance.instance_exec_b(lambda {}) { |&block| !!block }
      refute instance.instance_exec_b(nil)       { |&block| !!block }
    end
  end
end
