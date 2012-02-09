module Gitlog

  class Config

    def initialize
      if File.exists?("config.yaml")
        @config ||= YAML.load_file("config.yaml")
      else
        puts "Not config.yaml present.."
        exit 0
      end
    end

    def [](symbol)
      @config[symbol]
    end

    def repositories
      @config[:repositories]
    end

    def tracker_ticket_url(name)
      repo = repository(name)
      return repo[:tracker_ticket_url]
    end

    def repository(name)
      @config[:repositories][name.to_sym]
    end

  end

end
