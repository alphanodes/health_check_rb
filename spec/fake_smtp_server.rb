# frozen_string_literal: true

# !/usr/bin/env ruby

require 'socket'
require 'openssl'

class FakeSmtpServer
  def initialize(port)
    @port = port
    @socket = TCPServer.new @port
    @client = @orig_client = nil
  end

  def start
    return unless @client.nil?

    puts "fake_smtp_server: Waiting for one connection to port #{@port} ..."
    @client = @socket.accept

    send '220 dummy-smtp.example.com SMTP'
    cmd = receive

    while cmd !~ /^QUIT\r/
      if /^HELO(.*)\r/.match?(cmd)
        if ENV['FAIL_SMTP'] == 'HELO'
          send '550 Access Denied – Invalid HELO name'
        else
          send '250-Welcome to a dummy smtp server'
          send :'250-STARTTLS' unless ENV['SMTP_STARTTLS'] == 'DISABLED'
          send '250-AUTH PLAIN LOGIN'
          send '250 Ok'
        end
      elsif /^AUTH(.*)\r/.match?(cmd)
        if ENV['FAIL_SMTP'] == 'AUTH'
          send '535 5.7.8 Authentication credentials invalid'
        else
          send '235 2.7.0 Authentication successful'
        end
      elsif /^STARTTLS\r/.match?(cmd)
        send '502 STARTTLS is disabled!' if ENV['SMTP_STARTTLS'] == 'DISABLED'
        send '220 Ready to start TLS'
        if ENV['FAIL_SMTP'] == 'STARTTLS'
          cmd = receive
          return close
        end
        @orig_client = @client
        @client = tlsconnect @client
      else
        send '502 I am so dumb I only understand HELO, AUTH, STARTTLS and QUIT which always return a success status'
      end

      cmd = receive
    end
    send '221 Bye Bye'

    close
  end

  def finish
    sleep 1
    @socket.close
  end

  private

  def close
    @client.close unless @client.nil?
    @orig_client.close unless @orig_client.nil?
  end

  def send(line)
    @client.puts line
    puts "-> #{line}"
  end

  def receive
    line = @client.gets
    puts "<- #{line}"
    line
  end

  def ssl_socket(client, context)
    OpenSSL::SSL::SSLSocket.new client, context
  end

  def ssl_context
    @_ssl_context ||= begin
      key, cert = generate_certificate

      context = OpenSSL::SSL::SSLContext.new
      context.key = key
      context.cert = cert
      context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      context
    end
  end

  # Pass socket from TCPServer.new accept
  def tlsconnect(client)
    ssl_client = ssl_socket client, ssl_context
    puts '=> TLS connection started'
    ssl_client.accept
    puts '=> TLS connection established'

    ssl_client
  end

  def generate_certificate
    key = OpenSSL::PKey::RSA.new 2048
    name = OpenSSL::X509::Name.parse 'CN=localhost'

    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 0
    cert.not_before = Time.now
    cert.not_after = Time.now + 3600

    cert.public_key = key.public_key
    cert.subject = name

    extension_factory = OpenSSL::X509::ExtensionFactory.new nil, cert

    cert.add_extension extension_factory.create_extension('basicConstraints', 'CA:FALSE', true)
    cert.add_extension extension_factory.create_extension('keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature')
    cert.add_extension extension_factory.create_extension('subjectKeyIdentifier', 'hash')

    cert.issuer = name
    cert.sign key, OpenSSL::Digest.new('SHA256')

    [key, cert]
  end
end
