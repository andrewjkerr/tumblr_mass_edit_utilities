# typed: strict

class Config < T::Struct
  extend T::Sig

  DEFAULT_CONFIG_FILE_PATH = T.let('config/application_config.rb', String)

  const :tumblr_blog_url, String
  prop :tumblr_api_credentials, T::Array[TumblrApiCredential]

  sig {params(config_file: String).returns(Config)}
  def self.parse_config!(config_file)
    # first, attempt to load in our Ruby config file
    begin
      require_relative("../#{config_file}")
    rescue
      if config_file == DEFAULT_CONFIG_FILE_PATH
        puts "Error loading configuration file; does #{config_file} exist?"
      else
        puts "Error loading configuration file; perhaps you need to rename application_config.rb.sample?"
      end

      puts "Full error:"
      raise
    end

    # then, check to make sure it has the right `get_config` method
    begin
      klass = Module.const_get('ApplicationConfig')
      unless ApplicationConfig.respond_to?(:get_config)
        puts "Error loading configuration file; 'get_config' method does not seem to be defined."
        exit
      end
    rescue NameError
      puts "Error loading configuration file; 'ApplicationConfig' class does not seem to be defined."

      puts "Full error:"
      raise
    end

    # finally, get the application config
    application_config = ApplicationConfig.get_config

    # just kidding, do some checks to make sure things are ok!
    # first up, check that the blog url is properly formatted
    tumblr_blog_url = application_config.tumblr_blog_url
    raise "Tumblr blog URL needs to be in the format of blogname.tumblr.com" unless tumblr_blog_url =~ /[a-zA-Z0-9-]{1,32}\.tumblr\.com/

    tumblr_api_credentials = application_config.tumblr_api_credentials
    raise "No Tumblr API credentials found" if tumblr_api_credentials.size == 0

    # ok, *finally* instantiate our new `Config` struct!
    Config.new(
      tumblr_blog_url: application_config.tumblr_blog_url,
      tumblr_api_credentials: application_config.tumblr_api_credentials
    )
  end
end