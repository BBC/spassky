require "restclient"
require "wurfl-lite"
require "singleton"

module Spassky::Server
  LATEST = 'http://downloads.sourceforge.net/project/wurfl/WURFL/latest/wurfl-latest.xml.gz'
  WURFL_FILE = "wurfl/wurfl-latest.xml.gz"

  class DeviceNotFoundError < StandardError
  end

  class DeviceDatabase
    def initialize
      download_wurfl_file unless File.exist?(WURFL_FILE)
      @wurfl = WURFL.new(WURFL_FILE)
    end

    def download_wurfl_file
      Kernel.puts("Downloading WURFL database")
      content = RestClient.get(LATEST)
      File.open(WURFL_FILE, "w") do |file|
        file.write(content)
      end
    end

    def device_identifier user_agent
      device = @wurfl[user_agent]
      return user_agent if device.nil?
      "#{device.model_name} (id = #{device.id}, mobile_browser = #{device.mobile_browser}, device_os_version = #{device.device_os_version})"
    end

    def device user_agent
      @wurfl[user_agent]
    end
  end

  class SingletonDeviceDatabase < DeviceDatabase
    include Singleton
  end
end
