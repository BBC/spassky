require 'sinatra/base'
require 'spassky/server/random_string_generator'
require 'spassky/server/test_run'
require 'spassky/server/device_list'
require 'spassky/server/html_test'
require 'spassky/server/device_database'

module Spassky::Server
  class App < Sinatra::Base
    def initialize(device_list=DeviceList.new)
      @device_list = device_list
      super()
    end

    get "/devices/clear" do
      @device_list.clear
    end

    get "/devices/list" do
      @device_list.recently_connected_devices.to_json
    end

    get '/device/connect' do
      redirect idle_url
    end

    def get_device_identifier
      SingletonDeviceDatabase.instance.device_identifier(request.user_agent)
    end

    get '/device/idle/:random' do
      test_run = TestRun.find_next_test_to_run_by_device_id(get_device_identifier)
      @device_list.update_last_connected(get_device_identifier)
      if test_run
        redirect_to_run_tests(test_run)
      else
        idle_page
      end
    end

    def create_test_run
      TestRun.create({
        :name => params[:name],
        :contents => JSON.parse(params[:contents]),
        :devices => @device_list.recently_connected_devices
      })
    end

    post '/test_runs' do
      recently_connected_devices = @device_list.recently_connected_devices
      if recently_connected_devices.size > 0
        redirect "/test_runs/#{create_test_run.id}"
      else
        halt 500, "There are no connected devices"
      end
    end

    get '/test_runs/:id' do
      run = TestRun.find(params[:id])
      run.update_connected_devices(@device_list.recently_connected_devices)
      run.result.to_json
    end

    get '/test_runs/:id/run/:random/assert' do
      TestRun.find(params[:id]).save_result_for_device(
        :device_identifier => get_device_identifier,
        :status => params[:status],
        :message => params[:message]
      )
    end

    get "/test_runs/:id/run/:random/*" do
      file_name = params[:splat].join("/")
      get_test_file_contents params[:id], file_name
    end

    private

    def get_test_file_contents test_run_id, file_name
      test_run = TestRun.find(params[:id])
      HtmlTest.new(test_run.contents, idle_url, 1).get_file(file_name)
    end

    def redirect_to_run_tests(test_run)
      redirect "/test_runs/#{test_run.id}/run/#{RandomStringGenerator.random_string}/#{test_run.name}"
    end

    def idle_url
      "/device/idle/#{RandomStringGenerator.random_string}"
    end

    def idle_page
      "<html><head><meta http-equiv=\"refresh\" content=\"1; url='#{idle_url}'\"></head>" +
        "<body>Idle #{RandomStringGenerator.random_string}</body>" +
        "</html>"
    end
  end
end
