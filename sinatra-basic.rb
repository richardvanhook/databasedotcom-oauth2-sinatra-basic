require "sinatra/base"
require "rack/ssl" unless ENV['RACK_ENV'] == "development"
require "base64"
require "databasedotcom-oauth2"

class SinatraBasic < Sinatra::Base

  use Rack::SSL unless ENV['RACK_ENV'] == "development"
  use Rack::Session::Cookie
  use Databasedotcom::OAuth2::WebServerFlow, 
    :token_encryption_key => Base64.strict_decode64(ENV['TOKEN_ENCRYPTION_KEY']),
    :endpoints            => {"login.salesforce.com" => {:key => ENV['CLIENT_ID'], :secret => ENV['CLIENT_SECRET']}}

  configure do
    set :app_file            , __FILE__
    set :root                , File.expand_path("../..",__FILE__)
    set :port                , ENV['PORT']
    set :raise_errors        , Proc.new { false }
    set :show_exceptions     , true
  end

  get '/logout' do
    request.env['rack.session'] = {}
    redirect to("/")
  end
  
  get '/*' do
    if env['databasedotcom.client'].nil?
      "<html><body>You're not logged in.  Click <a href=\"/auth/salesforce\">here </a> to login.</body></html>"
    else
      token = env['databasedotcom.token']
      userinfo = nil
      userinfo = token.post(token['id']).parsed unless token.nil?
      "<html><body>You're logged in as #{userinfo['username']}.  Click <a href=\"/logout\">here </a> to logout.</body></html>"
    end
  end

end
