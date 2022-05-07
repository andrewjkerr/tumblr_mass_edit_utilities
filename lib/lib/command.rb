# typed: true

class Command
  extend T::Sig

  def self.call(*args, &block)
    klass = T.unsafe(new)
    
    puts "Running command: #{klass.class.name}"

    start_time = Time.now
    T.unsafe(new).call(*args, &block)
    end_time = Time.now

    puts "Done in #{end_time - start_time} seconds!"
  end
end