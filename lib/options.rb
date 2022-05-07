# typed: strict

class Options < T::Struct
  extend T::Sig

  const :start_date, String
  const :config_file, String, default: Config::DEFAULT_CONFIG_FILE_PATH
  const :verbose, T::Boolean, default: false

  sig {returns(Options)}
  def self.parse_options
    # Create a new options array
    options = T.let({}, T::Hash[Symbol, T.any(String, T::Boolean)])

    OptionParser.new do |opts|
      opts.banner = 'Usage: ruby script.rb [options]'
      opts.on('-cFILE_PATH', '--config=FILE_PATH', "Override the config file that's used (default: config/application.yaml)") do |c|
        options[:config_file] = c
      end
      opts.on('-dSTART_DATE', '--start_date=START_DATE', "The date to start privatizing posts, in YYYY-DD-MM format.") do |d|
        options[:start_date] = d
      end
      opts.on('-v', '--verbose', "Print debug-y information") { |v| options[:verbose] = true }
      opts.on('-h', '--help', 'Prints this help') do
        puts opts
        exit
      end
    end.parse!

    # Validate that we have the correct options
    Options.validate_required_options!(options)

    # A note on this: we're fine with the unsafe here because all of our keys match 1:1 with Options `const`s.
    # However, we need to splat the options array in so we can have the default `const` values instead of `nil`.
    Options.new(**T.unsafe(options))
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
end