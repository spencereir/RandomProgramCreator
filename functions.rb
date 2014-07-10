class Function
  @@num_functions = 0
  @name = ""
  @return_val = ""
  @prototype = ""
  @num_params = 0
  @vars = Array.new()
  @var_types = Array.new()
  def initialize (name, return_val, num_params, vars, var_types) 
    @name = name
    @return_val = return_val
    @num_params = num_params
    @vars = vars
    @var_types = var_types
    if (@name.eql? "main")    # Main is a dumb name for a function. Lets cool it up a bit
      @name = (0...6).map { (65 + rand(26)).chr }.join
    end
    @@num_functions += 1
    @prototype = @return_val + " " + @name + "("
    @num_params.times do |i|
      @prototype += @var_types[i].to_s + " " + @vars[i].to_s
      if(i < @num_params - 1)
        @prototype += ", "
      end
    end
    @prototype += ");"
  end  
  def num
    @@num_functions
  end
  def rType
    @return_val
  end
  def name
    @name
  end
  def numParams
    @num_params
  end
  def vars(i)
    @vars[i]
  end
  def varTypes(i)
    @varTypes[i]
  end
  def prototype
    @prototype
  end
end
