class Function
  @@num_functions = 0
  @function = ""
  @name = ""
  @return_val = ""
  @prototype = ""
  @num_params = 0
  @vars = Array.new()
  @var_types = Array.new()
  def initialize (function, name, return_val, num_params, vars, var_types) 
    @function = function
    @old_name = name
    @return_val = return_val
    @num_params = num_params
    @vars = vars
    @var_types = var_types
    @name = @old_name.to_s + (0..2).map { (65 + rand(26)).chr }.join
    @@num_functions += 1
    @prototype = @return_val + " " + @name + "("
    @num_params.times do |i|
      @prototype += @var_types[i].to_s + " " + @vars[i].to_s
      if(i < @num_params - 1)
        @prototype += ", "
      end
    end
    @prototype += ");"
    @function.gsub!(@old_name, @name)
  end  
  def num
    @@num_functions
  end
  def function
    @function
  end
  def rType
    @return_val
  end
  def name
    @name
  end
  def oldName
    @old_name
  end
  def numParams
    @num_params
  end
  def vars
    @vars
  end
  def sVars(i)
    @vars[i]
  end
  def varTypes
    @var_types
  end
  def sVarTypes(i)
    @var_types[i]
  end
  def prototype
    @prototype
  end
  def call(params, mode)
    if (mode == 1)
      @call = @name + "("
    elsif (mode == 0)
      @call = @old_name + "("
    end
    if(params.length > 0)
      params.length.times do |i|
        @call += params[i]
        if (i < params.length - 1) 
          @call += ", "
        end
      end
    end
    @call += ");\n"
    @call
  end
  def replaceName(f)
    empty = []
    @function.gsub!(f.call(empty, 0), f.call(empty, 1))
  end
end
