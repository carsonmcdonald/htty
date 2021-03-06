require File.expand_path("#{File.dirname __FILE__}/display")
# TODO: See if we can avoid circular references without omitting these 'require' statements
# require File.expand_path("#{File.dirname __FILE__}/../request")
# require File.expand_path("#{File.dirname __FILE__}/commands/cookies_use")
# require File.expand_path("#{File.dirname __FILE__}/commands/follow")
# require File.expand_path("#{File.dirname __FILE__}/commands/ssl_verification_off")

module HTTY; end

class HTTY::CLI; end

# Encapsulates behavior common to all HTTP-method-oriented HTTY::CLI::Command
# subclasses.
module HTTY::CLI::HTTPMethodCommand

  # Class methods for modules that include HTTY::CLI::HTTPMethodCommand.
  module ClassMethods

    # Returns the name of a category under which help for the command should
    # appear.
    def category
      'Issuing Requests'
    end

  end

  # Extends _other_module_ with ClassMethods.
  def self.included(other_module)
    other_module.extend ClassMethods
  end

  include HTTY::CLI::Display

  # Performs the command.
  def perform
    add_request_if_has_response do |request|
      unless body? || request.body.to_s.empty?
        puts notice("The body of your #{method.to_s.upcase} request is not " +
                    'being sent')
      end

      begin
        request = request.send("#{method}!", *arguments)
      rescue OpenSSL::SSL::SSLError => e
        puts notice('Type '                                                      +
                    strong(HTTY::CLI::Commands::SslVerificationOff.command_line) +
                    ' to ignore SSL warnings and complete the request')
        raise e
      end

      notify_if_cookies
      notify_if_follow

      request
    end
    show_response session.last_response
    self
  end

private

  # Returns true if the command sends the request body.
  def body?
    HTTY::Request::METHODS_SENDING_BODY.include? method
  end

  def method
    self.class.name.split('::').last.gsub(/^http/i, '').downcase.to_sym
  end

  def notify_if_cookies
    request  = session.requests.last
    response = session.last_response
    unless response.cookies.empty? || (request.cookies == response.cookies)
      puts notice('Type ' +
                  "#{strong HTTY::CLI::Commands::CookiesUse.command_line} to " +
                  'use cookies offered in the response')
    end
    self
  end

  def notify_if_follow
    location_header = session.last_response.headers.detect do |header|
      header.first == 'Location'
    end
    if location_header
      puts notice('Type ' +
                  "#{strong HTTY::CLI::Commands::Follow.command_line} to " +
                  "follow the 'Location' header received in the response")
    end
    self
  end

end
