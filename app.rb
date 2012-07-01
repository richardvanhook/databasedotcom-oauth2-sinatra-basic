require "sinatra/base"
require "rack/ssl" unless ENV['RACK_ENV'] == "development" # only utilized when deployed to heroku
require "base64"
require "databasedotcom-oauth2"

class SinatraBasic < Sinatra::Base

  # validate environment variables set
  fail "TOKEN_ENCRYPTION_KEY, CLIENT_ID, and CLIENT_SECRET environment variables must not be nil" \
    if ENV['TOKEN_ENCRYPTION_KEY'].nil? || ENV['CLIENT_ID'].nil? || ENV['CLIENT_SECRET'].nil?

  # Rack Middleware
  use Rack::SSL unless ENV['RACK_ENV'] == "development"  # only utilized when deployed to heroku
  use Rack::Session::Pool#, :expire_after => 60*60*7    # holds oauth2 token in encrypted, serialized form
  use Databasedotcom::OAuth2::WebServerFlow,             # will intercept requests sent to /auth/salesforce
    :prompt               => "login consent",
    :debugging            => true,
    :token_encryption_key => Base64.strict_decode64(ENV['TOKEN_ENCRYPTION_KEY']),
    :endpoints            => {"login.salesforce.com" => {
                              :key => ENV['CLIENT_ID'], :secret => ENV['CLIENT_SECRET']}},
    :display              => "touch"

  # mixes in client, me, authenticated?, etc.
  include Databasedotcom::OAuth2::Helpers

  # Sinatra routes
  
  # Clears rack session.
  get '/logout' do
    request.env['rack.session'] = {}  #clear session
    redirect to("/")
  end

  # By default, errors encountered by Databasedotcom::OAuth2::WebServerFlow
  # are redirected to /auth/salesforce/failure.  An alternative is to provide
  # :on_failure configuration option.
  get '/auth/salesforce/failure' do  
    "<html><body>Ruh-roh: #{params['message']}</body></html>"
  end
  
  # Will show login status.
  get '/*' do
    if unauthenticated?
      "<html><body>You're not logged in.  Click <a href=\"/auth/salesforce\">here</a> to login.</body></html>"
    else
      "<html><body>You're logged in as #{me.username}.  Click <a href=\"/logout\">here</a> to logout.</body></html>"
    end
  end

end
