class Play
  def self.method1
    puts "Method 1"
  end

  def self.method2
    puts "In Method 2"
    method1
    puts "Out method 2"
  end
end


Play2 = Play.clone
class Play2 
  def self.method1 
    puts "Overridden Method 1"
  end
end

Play.method2
puts "-------"
Play2.method2