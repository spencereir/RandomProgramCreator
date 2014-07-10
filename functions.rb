class Function
  @@num_functions = 0
  @name = ""
  @return_val = ""
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
      @name = (0...8).map { (65 + rand(26)).chr }.join
    end
    @@num_functions += 1
  end  
  def num
    @@num_functions
  end
end
