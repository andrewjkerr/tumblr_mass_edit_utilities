# typed: strict

class Options < T::Struct
  extend T::Sig

  sig {params(date: Date).returns(Integer)}
  def self.get_timestamp(date)
    date.to_time.to_i
  end

  prop :beginning_timestamp, Integer, default: Options.get_timestamp(Date.today)
  prop :config_file, String, default: Config::DEFAULT_CONFIG_FILE_PATH
  prop :verbose, T::Boolean, default: false

  sig {returns(Options)}
  def self.parse_options
    # make a "default" options struct that we will change in the options below
    options = Options.new

    # having the start_date option default to today can be somewhat jarring for users of previous verison
    # so, we'll ask the user if they want to continue with the default option if they don't set their own
    continue_prompt = T.let(true, T::Boolean)

    OptionParser.new do |opts|
      opts.banner = 'Usage: ruby script.rb [options]'

      opts.on('-dSTART_DATE', '--start_date=START_DATE', "The date to start privatizing posts, in YYYY-DD-MM format (default: today)") do |d|
        options.beginning_timestamp = Options.calculate_beginning_timestamp!(d)
        continue_prompt = false
      end

      opts.on('-v', '--verbose', "Print debug-y information") { options.verbose = true }

      opts.on('-h', '--help', 'Prints this help') do
        puts opts
        exit
      end
    end.parse!

    Options.prompt_for_continue! if continue_prompt

    options
  end

  sig {params(start_date: String).returns(Integer)}
  def self.calculate_beginning_timestamp!(start_date)
    begin
      return Options.get_timestamp(Date.parse(start_date))
    rescue
      puts "Error parsing #{start_date}! Please check the format to ensure it's correct."
      puts "Full error:"
      raise
    end
  end

  sig {params(options: T::Hash[Symbol, T.any(String, T::Boolean)]).void}
  def self.validate_required_options!(options)
    [:start_date].each do |required_flags|
      unless options.key?(required_flags)
        puts "Required option #{required_flags} is not set. Please use --help to view which flags are required."
        exit(1)
      end
    end
  end

  sig {void}
  def self.prompt_for_continue!
    puts "⚠ WARNING ⚠: The default option for this script is to start with posts from right now."
    puts "If this is expected, enter 'y' to proceed:"

    input = T.must(STDIN.gets).chomp.downcase

    unless ['y', 'yes', 'true'].include?(input)
      puts "Phew, glad I double checked! Please use `--start_date=YYYY-MM-DD`` to specify a start date (`--help` for help!)."
      exit
    end

    puts "Thanks for letting me double check! Continuing..."
  end
end