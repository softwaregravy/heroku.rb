require "base64"
require "cgi"
require "excon"
require "securerandom"

require "heroku/errors"
require "heroku/mock"
require "heroku/vendor/heroku/okjson"

require "heroku/api/addons"
require "heroku/api/apps"
require "heroku/api/collaborators"
require "heroku/api/config_vars"
require "heroku/api/domains"
require "heroku/api/keys"
require "heroku/api/logs"
require "heroku/api/processes"
require "heroku/api/releases"
require "heroku/api/stacks"
require "heroku/api/version"

srand

module Heroku
  class API < Excon::Connection

    def initialize(options={})
      @api_key = options.delete(:api_key) || ENV['HEROKU_API_KEY']
      user_pass = ":#{@api_key}"
      options = {
        :headers  => {},
        :host     => 'api.heroku.com',
        :scheme   => 'https'
      }.merge(options)
      options[:headers] = {
        'Accept'                => 'application/json',
        'Authorization'         => "Basic #{Base64.encode64(user_pass).gsub("\n", '')}",
        'User-Agent'            => "heroku-rb/#{Heroku::API::VERSION}",
        'X-Heroku-API-Version'  => '3',
        'X-Ruby-Version'        => RUBY_VERSION,
        'X-Ruby-Platform'       => RUBY_PLATFORM
      }.merge(options[:headers])
      super("#{options[:scheme]}://#{options[:host]}", options)
    end

    def request(params, &block)
      begin
        response = super
      rescue Excon::Errors::NotFound => error
        reerror = Heroku::Errors::NotFound.new(error.message)
        reerror.set_backtrace(error.backtrace)
        raise reerror
      rescue Excon::Errors::Error => error
        reerror = Heroku::Errors::Error.new(error.message)
        reerror.set_backtrace(error.backtrace)
        raise reerror
      end

      reset
      if response.body && !response.body.empty?
        begin
          response.body = Heroku::OkJson.decode(response.body)
        rescue
          # leave non-JSON body as is
        end
      end
      response
    end

    private

    def app_params(params)
      app_params = {}
      params.each do |key, value|
        app_params["app[#{key}]"] = value
      end
      app_params
    end

  end
end
