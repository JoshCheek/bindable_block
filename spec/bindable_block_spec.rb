require 'bindable_block'

describe BindableBlock do
  let(:name)         { 'Unbound Name' }
  let(:default_name) { "Carmen" }
  let(:klass)        { Struct.new :name }
  let(:instance)     { klass.new default_name }

  # minitest style, b/c otherwise the levels of things being passed around gets to be a bit much
  def assert_equal(a, b)
    expect(b).to eq a
  end
  def refute_equal(a, b)
    expect(b).to_not eq a
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


  describe 'binding' do
    it 'can be bound to any object' do
      block = BindableBlock.new { self }
      assert_same block.bind(instance).call, instance
    end

    it 'can be bound to a BasicObject' do
      o = BasicObject.new
      o.instance_eval { @a = 1 }
      assert_equal 1, BindableBlock.new { @a }.bind(o).call
    end

    it 'can be bound to multiple different objects' do
      block = BindableBlock.new { name }
      assert_equal 'Josh', block.bind(klass.new 'Josh').call
      assert_equal 'Mei',  block.bind(klass.new 'Mei').call
    end

    it 'can be rebound to instances of different classes' do
      klass1 = Class.new { def m; 1; end }
      klass2 = Class.new { def m; 2; end }
      block  = BindableBlock.new { m }
      assert_equal 1, block.bind(klass1.new).call
      assert_equal 2, block.bind(klass2.new).call
    end

    it 'can scope the class of objects it can be bound to' do
      klass1 = Class.new
      klass2 = Class.new
      block = BindableBlock.new(klass1) {}
      block.bind(klass1.new).call
      expect { block.bind(klass2.new).call }.to raise_error TypeError, /instance of/
    end
  end

  describe 'as a block' do
    it 'can be passed in the block slot to methods and shit' do
      doubler = lambda { |&block| block.call + '!' }
      assert_equal 'Unbound Name!', doubler.call(&BindableBlock.new { name })
      assert_equal 'Carmen!',       doubler.call(&BindableBlock.new { name }.bind(instance))
    end

    it 'can be invoked without being bound, in which case self is that of the scope it was defined in' do
      def self.a() 1 end
      @b = 2
      c = 3
      block = BindableBlock.new { |d, &e| a + @b + c + d + e.call }
      assert_equal 15, block.call(4){5}
    end

    it 'retains it\'s bindability after being passed through a method' do
      block = BindableBlock.new { name }
      def m(&bindable_block)
        bindable_block.bind(instance).call
      end
      assert_equal default_name, m(&block)
    end

    it 'has a #bound_location to complement #source_location' do
      unbound = BindableBlock.new { }
      bound   = unbound.bind(instance)
      assert_equal bound.bound_location, [__FILE__, __LINE__-1]
    end

    specify '#bound_location isn\'t susceptible to mutation of returned value' do
      bound = BindableBlock.new { }.bind(instance)
      bound.bound_location.first.replace ""  # mutate the string
      bound.bound_location.replace []        # mutate the array
      assert_equal bound.bound_location, [__FILE__, __LINE__-3]
    end

    context 'Proc instance methods' do
      let(:args_and_name) { BindableBlock.new { |arg| [arg, name] } }

      example '#[]' do
        assert_equal [1, 'Unbound Name'], args_and_name[1]
        assert_equal [1, 'Carmen'],       args_and_name.bind(instance)[1]
      end

      example '#===' do
        assert_equal [1, 'Unbound Name'], args_and_name === 1
        assert_equal [1, 'Carmen'],       args_and_name.bind(instance) === 1
      end

      example '#yield' do
        assert_equal [1, 'Unbound Name'], args_and_name.yield(1)
        assert_equal [1, 'Carmen'],       args_and_name.bind(instance).yield(1)
      end

      example '#arity' do
        p = Proc.new { |a, b, c=1, d=2, *e, f| [a,b,c,d,e,f] }
        b = BindableBlock.new(&p)
        assert_equal p.arity, b.arity
        assert_equal p.arity, b.bind(instance).arity

        l = Proc.new { |a, b, c=1, d=2, *e, f| [a,b,c,d,e,f] }
        b = BindableBlock.new(&l)
        assert_equal l.arity, b.arity
        assert_equal l.arity, b.bind(instance).arity
      end

      example '#binding' do
        a = 1
        b = BindableBlock.new { }

        assert_equal 1,        b.binding.eval('a')
        assert_equal self,     b.binding.eval('self')

        pending "If anyone can solve this, I'll be so impressed"
        assert_equal 1,        b.bind(instance).binding.eval('a')
        assert_equal instance, b.bind(instance).binding.eval('self')
      end

      example '#clone' do
        assert_equal [1, 'Unbound Name'], args_and_name.clone.call(1)
        assert_equal [1, 'Carmen'],       args_and_name.bind(instance).clone.call(1)
      end

      example '#dup' do
        assert_equal [1, 'Unbound Name'], args_and_name.dup.call(1)
        assert_equal [1, 'Carmen'],       args_and_name.bind(instance).dup.call(1)
      end

      example '#curry without being bound' do
        b    = BindableBlock.new { |a, b, c, &d| [a, b, c, d.call, name] }
        four = lambda { 4 }

        assert_equal [1, 2, 3, 4, 'Unbound Name'], b.curry[1, 2, 3, &four]
        assert_equal [1, 2, 3, 4, 'Unbound Name'], b.curry[1][2][3, &four]
        assert_equal [1, 2, 3, 4, 'Unbound Name'], b.curry[1, 2][3, &four]
      end

      example '#curry after being bound' do
        b    = BindableBlock.new { |a, b, c, &d| [a, b, c, d.call, name] }.bind(instance)
        four = lambda { 4 }
        assert_equal [1, 2, 3, 4, 'Carmen'], b.curry[1][2][3, &four]
        assert_equal [1, 2, 3, 4, 'Carmen'], b.curry[1, 2][3, &four]
      end

      example '#curry before being bound' do
        b = BindableBlock.new { |a, b, c, &d| [a, b, c, d.call, name] }
        four = lambda { 4 }
        assert_equal [1, 2, 3, 4, 'Carmen'], b.curry[1].bind(instance).curry[2][3, &four]
        assert_equal [1, 2, 3, 4, 'Carmen'], b.curry[1, 2].bind(instance).curry[3, &four]
        assert_equal [1, 2, 3, 4, 'Carmen'], b.curry[1][2].bind(instance).curry[3, &four]
        assert_equal [1, 2, 3, 4, 'Carmen'], b.curry[1][2].bind(instance).curry[3, &four]

        assert_equal [1, 2, 3, 4, 'Carmen'], b.curry[1].bind(instance)[2][3, &four]
        assert_equal [1, 2, 3, 4, 'Carmen'], b.curry[1, 2].bind(instance)[3, &four]
        assert_equal [1, 2, 3, 4, 'Carmen'], b.curry[1][2].bind(instance)[3, &four]
        assert_equal [1, 2, 3, 4, 'Carmen'], b.curry[1][2].bind(instance)[3, &four]
      end

      example 'other #curry bullshit' do
        b = BindableBlock.new { |a, b, c, &d| [a,b,c,d.call, name] }
        four = lambda { 4 }
        assert_equal [1, 2, 3, 4, 'Unbound Name'], b.curry[1].call(2).yield(3, &four)
        assert_equal [1, 2, 3, 4, 'Unbound Name'], b.curry[1].===(2).(3, &four)
        assert_equal [1, 2, 3, 4, 'Carmen'], b.curry.bind(instance).call(1)[2].yield(3, &four)
        assert_equal [1, 2, 3, 4, 'Carmen'], b.curry.bind(instance).===(1).(2, 3, &four)
      end

      describe '#hash' do
        context 'when unbound' do
          it 'delegates the hash to its proc' do
            p = Proc.new {}
            assert_equal p.hash, BindableBlock.new(&p).hash
          end
          # something about curry?
        end

        context 'when bound' do
          let(:p)       { lambda {} }
          let(:unbound) { BindableBlock.new(&p) }

          it 'is an integer' do
            expect(unbound.bind(instance).hash).to be_a_kind_of Integer
          end

          it 'gives a different hash than the unbound version' do
            refute_equal p.hash, unbound.bind(instance).hash
          end

          it 'gives the same hash when bound to an object with the same hash' do
            o = Object.new
            assert_equal unbound.bind(o).hash,
                         unbound.bind(o).hash
          end

          it 'gives a different hash when bound to an object with a different hash' do
            o1 = Object.new
            o2 = Object.new
            refute_equal unbound.bind(o1).hash, unbound.bind(o2).hash
          end

          it 'gives the same hash when bound to an object without a hash' do
            assert_equal unbound.bind(BasicObject.new).hash,
                         unbound.bind(BasicObject.new).hash
          end
        end
      end

      example '#lambda?' do
        refute BindableBlock.new {}.lambda?
        refute BindableBlock.new {}.bind(instance).lambda?

        assert BindableBlock.new(&lambda {}).lambda?
        assert BindableBlock.new(&lambda {}).bind(instance).lambda?
      end

      example '#parameters' do
        b = BindableBlock.new { |a, b=1, *c, d, e:, **f, &g| }
        assert_equal [[:opt, :a], [:opt, :b], [:rest, :c], [:opt, :d], [:keyreq, :e], [:keyrest, :f], [:block, :g]], b.parameters
        assert_equal [[:opt, :a], [:opt, :b], [:rest, :c], [:opt, :d], [:keyreq, :e], [:keyrest, :f], [:block, :g]], b.bind(instance).parameters

        b = BindableBlock.new(&lambda { |a, b=1, *c, d, e:, **f, &g| })
        assert_equal [[:req, :a], [:opt, :b], [:rest, :c], [:req, :d], [:keyreq, :e], [:keyrest, :f], [:block, :g]], b.parameters
        assert_equal [[:req, :a], [:opt, :b], [:rest, :c], [:req, :d], [:keyreq, :e], [:keyrest, :f], [:block, :g]], b.bind(instance).parameters
      end

      example '#source_location' do
        b, f, l = BindableBlock.new { }, __FILE__, __LINE__
        assert_equal [f, l], b.source_location
        assert_equal [f, l], b.bind(instance).source_location
      end

      example '#to_proc' do
        unbound = BindableBlock.new {}
        assert_same unbound, unbound.to_proc

        bound = unbound.bind(instance)
        assert_same bound, bound.to_proc
      end

      example '#to_s and #inspect have the source file and line' do
        # proc
        unbound, f, l = BindableBlock.new {}, __FILE__, __LINE__
        expect(unbound.to_s).to include "#{f}:#{l}"
        expect(unbound.to_s).to include "BindableBlock"

        bound = unbound.bind(instance)
        expect(bound.to_s).to include "#{f}:#{l}"
        expect(bound.to_s).to include "BindableBlock::BoundBlock"

        # lambda
        unbound, f, l = BindableBlock.new(&lambda {}), __FILE__, __LINE__
        expect(unbound.to_s).to include "#{f}:#{l}"
        expect(unbound.to_s).to include "BindableBlock"

        bound = unbound.bind(instance)
        expect(bound.to_s).to include "#{f}:#{l}"
        expect(bound.to_s).to include "BindableBlock::BoundBlock"
      end

      specify '#to_s and #inspect should not have lambda in them' do
        # proc
        unbound = BindableBlock.new {}
        expect(unbound.to_s).to_not include 'lambda'
        expect(unbound.inspect).to_not include 'lambda'

        bound = unbound.bind instance
        expect(bound.to_s).to_not include 'lambda'
        expect(bound.inspect).to_not include 'lambda'

        # lambda
        unbound = BindableBlock.new(&lambda {})
        expect(unbound.to_s).to include 'lambda'
        expect(unbound.inspect).to include 'lambda'

        bound = unbound.bind instance
        expect(bound.to_s).to include 'lambda'
        expect(bound.inspect).to include 'lambda'
      end
    end
  end


  describe 'arguments' do
    def assert_same_error(b1, b2)
      e1 = b1.call rescue $!
      e2 = b2.call rescue $!
      expect(e1).to be_an Exception
      expect(e2).to be_an Exception
      assert_equal e1.class,   e2.class
      assert_equal e1.message, e2.message
    end

    it 'matches them lambda-style if initialized with a lambda' do
      l     = lambda { |a| a }
      block = BindableBlock.new(&l)
      assert_equal 1, block.call(1)
      assert_equal 1, block.bind(instance).call(1)
      assert_same_error lambda { block.call                     }, lambda { l.call      }
      assert_same_error lambda { block.call 1, 2                }, lambda { l.call 1, 2 }
      assert_same_error lambda { block.bind(instance).call      }, lambda { l.call      }
      assert_same_error lambda { block.bind(instance).call 1, 2 }, lambda { l.call 1, 2 }
    end

    it 'matches them proc-style if initialized with a proc' do
      p     = Proc.new { |a| a }
      block = BindableBlock.new(&p)
      assert_equal 1,            block.call(1)
      assert_equal p.call,       block.call
      assert_equal p.call(1),    block.call(1)
      assert_equal p.call(1, 2), block.call(1, 2)

      assert_equal 1,            block.bind(instance).call(1)
      assert_equal p.call,       block.bind(instance).call
      assert_equal p.call(1),    block.bind(instance).call(1)
      assert_equal p.call(1, 2), block.bind(instance).call(1, 2)
    end

    it 'can take a block' do
      block = BindableBlock.new { |a, &b| [a, (b&&b.call)] }.bind(instance)
      assert_equal [1, nil], block.call(1)
      assert_equal [1, 2],   block.call(1){2}
    end

    specify "when given ordinal arguments at the start, it doesn't care about arity" do
      block = BindableBlock.new { |a| [a] }.bind(instance)
      assert_equal [nil], block.call
      assert_equal [1],   block.call(1)
      assert_equal [1],   block.call(1, 2)
    end

    specify 'when given optional args, it matches them up correctly' do
      block = BindableBlock.new { |a, b=1, c=2| [a, b, c] }.bind(instance)
      assert_equal [nil, 1, 2]  , block.call
      assert_equal [:a, 1, 2]   , block.call(:a)
      assert_equal [:a, :b, 2]  , block.call(:a, :b)
      assert_equal [:a, :b, :c] , block.call(:a, :b, :c)
      assert_equal [:a, :b, :c] , block.call(:a, :b, :c, :d)
    end

    specify 'splat acts as a catch all' do
      block = BindableBlock.new { |a, *rest| [a, rest] }.bind(instance)
      assert_equal [nil, []]   , block.call
      assert_equal [1, []]     , block.call(1)
      assert_equal [1, [2]]    , block.call(1, 2)
      assert_equal [1, [2, 3]] , block.call(1, 2, 3)
    end

    specify "when given ordinal arguments at the end, it doesn't care about arity" do
      block = BindableBlock.new { |*a, b, &c| [a, b] }.bind(instance)
      assert_equal [[], nil]   , block.call
      assert_equal [[], 1]     , block.call(1)
      assert_equal [[1], 2]    , block.call(1,2)
      assert_equal [[1, 2], 3] , block.call(1,2,3)

      block = BindableBlock.new { |a=:a, b, c| [a, b, c] }.bind(instance)
      assert_equal [:a, nil, nil] , block.call
      assert_equal [:a, 1, nil]   , block.call(1)
      assert_equal [:a, 1, 2]     , block.call(1, 2)
      assert_equal [1, 2, 3]      , block.call(1, 2, 3)
      assert_equal [1, 2, 3]      , block.call(1, 2, 3, 4)
    end


    specify "when given complex arguments, it matches that shit up right" do
      proc  = Proc.new { |a, b, c=1, d=2, *e, f| [a,b,c,d,e,f] }
      block = BindableBlock.new(&proc).bind(instance)
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

  describe 'instance_exec_b' do
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

    it 'Doesn\'t define methods on the class' do
      class BasicObject
        old_method_added = singleton_class.method(:method_added)
        def self.method_added(method_name)
          raise "METHOD ADDED: #{method_name}"
        end
        instance_exec_b(lambda {}) { }
        define_singleton_method(:method_added, &old_method_added)
      end
    end
  end
end
