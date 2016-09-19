module MethodCachable
  def cache_method(name, i_name, &block)
    define_method name do
      if instance_variable_defined?(i_name)
        instance_variable_get(i_name)
      else
        instance_variable_set(i_name, instance_eval(&block))
      end
    end
  end
end
