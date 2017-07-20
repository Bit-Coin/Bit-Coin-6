
class SendGrid::Client
  def initialize(params={})
    @api_user   = params.fetch(:api_user, ENV['SENDGRID_USERNAME'])
    @api_key    = params.fetch(:api_key, ENV['SENDGRID_PASSWORD'])
    @host       = params.fetch(:host, 'https://api.sendgrid.com')
    @endpoint   = params.fetch(:endpoint, '/api/mail.send.json')
    @conn       = params.fetch(:conn, create_conn)
    @user_agent = params.fetch(:user_agent, 'sendgrid/' + SendGrid::VERSION + ';ruby')
    yield self if block_given?
    raise SendGrid::Exception.new('api_user and api_key are required') unless @api_user && @api_key
  end
end

SendgridToolkit.api_user = ENV['SENDGRID_USERNAME']
SendgridToolkit.api_key = ENV['SENDGRID_PASSWORD']

