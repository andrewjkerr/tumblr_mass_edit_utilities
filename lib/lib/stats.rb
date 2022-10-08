# typed: strict

class Stats < T::Struct
  extend T::Sig

  prop :loop_iterations, Integer, default: 0
  prop :total_posts, Integer, default: 0
  prop :published_posts, Integer, default: 0
  prop :posts_updated, Integer, default: 0

  sig {void}
  def print!
      # At the end, print out our stats.
      puts "Stats:"
      self.serialize.each do |key, value|
          puts "\t#{key}: #{value}"
      end
  end
end