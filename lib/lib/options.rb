# typed: strict

class Options < T::Struct
  extend T::Sig

  sig {params(date: Date).returns(Integer)}
  def self.get_timestamp(date)
    date.to_time.to_i
  end

  prop :beginning_timestamp, T.nilable(Integer)
  prop :config_file, String, default: Config::DEFAULT_CONFIG_FILE_PATH
  prop :verbose, T::Boolean, default: false
  prop :tag, T.nilable(String)
  prop :command, Command::Command # this is required for execution
  prop :community_label_categories, T.nilable(T::Array[Post::CommunityLabelCategory])

  sig {returns(Options)}
  def self.parse_options
    command = ARGV[0]

    begin
      command = Command::Command.deserialize(command.downcase)
    rescue
      raise "Command #{command} is not valid. Valid commands: #{self.enumerate_enum_values(Command::Command)}."
    end

    # make a "default" options struct that we will change in the options below
    options = Options.new(
      command: command,
    )

    # having the start_date option default to today can be somewhat jarring for users of previous verison
    # so, we'll ask the user if they want to continue with the default option if they don't set their own
    continue_prompt = T.let(true, T::Boolean)

    OptionParser.new do |opts|
      opts.banner = 'Usage: ruby script.rb [options]'

      opts.on('-dSTART_DATE', '--start_date=START_DATE', 'The date to start privatizing posts, in YYYY-DD-MM format (default: today)') do |d|
        options.beginning_timestamp = Options.calculate_beginning_timestamp!(d)
        continue_prompt = false
      end

      opts.on('-tTAG', '--tag=TAG', 'The tag of the posts to turn private') do |t|
        options.tag = t
      end

      opts.on('-v', '--verbose', 'Print debug-y information') { options.verbose = true }

      # individual command options
      case options.command
      when Command::Command::UpdateCommunityLabels
        opts.on('-lLABELS', '--labels=LABELS', "(required) A comma separated array of community labels to update posts with. Valid community labels: #{self.enumerate_enum_values(Post::CommunityLabelCategory)}.") do |l|
          community_label_categories = []
          labels = l.split(',').map {|label| label.strip}
          unless labels.empty?
            labels.each do |label|
              begin
                community_label_categories << Post::CommunityLabelCategory.deserialize(label.downcase)
              rescue
                raise "Community label category #{label} is not valid. Valid labels: #{self.enumerate_enum_values(Post::CommunityLabelCategory)}."
              end
            end
          end

          options.community_label_categories = community_label_categories
        end
      end

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
    raise "Required option 'command' is not set. Please use --help to view which flags are required." unless options.key?(:command)
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

  sig {params(klass: T::Class[T.anything]).returns(String)}
  def self.enumerate_enum_values(klass)
    raise "Class #{klass.class.name} does not inherit from T::Enum" unless klass < T::Enum
    klass.values.map {|value| value.serialize}.join(', ')
  end
end
