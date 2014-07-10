class BindableBlock < Proc
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
end
