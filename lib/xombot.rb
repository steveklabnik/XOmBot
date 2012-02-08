require 'bundler'
Bundler.require

require 'fileutils'
require 'yaml'

# allow sending of actions
module Cinch
  class Message
    def emote(m)
      reply "\001ACTION #{m}\001"
    end
  end
end

require 'xombot/plugin'

# Place all plugins into a module
Dir[File.dirname(__FILE__) + '/xombot/plugins/*.rb'].each do |file|
  eval "module XOmBot; module Plugins; #{File.read(file)}; end; end"
end

module XOmBot
  # Default Parameters
  NAME = "XOmBot-test"
  CHANNELS = ["#XOmBot"]
  SERVER = "irc.freenode.org"
  PORT = 6697
  SSL = true

  class << self
    attr_reader :plugins
    attr_reader :name
    attr_reader :server
    attr_reader :channels
    attr_reader :port
    attr_reader :ssl

    def add_plugin plugin
      @plugins = {} if @plugins.nil?
      @plugins[plugin.class.name] = plugin
    end

    def start
      config_path = "#{File.dirname(__FILE__)}/../config"
      if not File.exists?("#{config_path}/config.yml")
        FileUtils.cp("#{config_path}/config.yml.example", "#{config_path}/config.yml")
      end
      config = YAML.load(File.open("#{config_path}/config.yml"))

      @name = config["name"] || NAME
      @server = config["server"] || SERVER
      @port = config["port"] || PORT
      @ssl = (config["ssl"] == "true") || SSL
      @channels = config["channels"] || CHANNELS

      bot = Cinch::Bot.new do
        configure do |c|
          c.server = XOmBot.server
          c.port = XOmBot.port
          c.ssl.use = XOmBot.ssl
          c.nick = XOmBot.name 
          c.channels = XOmBot.channels
          c.plugins.plugins = XOmBot::Plugins.constants.map do |plugin|
            XOmBot::Plugins.const_get(plugin)
          end
        end
      end

      bot.start
    end
  end
end
