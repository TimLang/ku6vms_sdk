# -*- encoding : utf-8 -*-
require 'date'
require 'net/http'
require 'cgi'
require 'eventmachine'
require 'em-http'
require 'json'
require 'base64'
require 'openssl'
require 'multipart_body'
require 'logger'
require 'grand_cloud/exceptions'
require 'grand_cloud/authentication'
require 'grand_cloud/base'
require 'grand_cloud/video'
require 'grand_cloud/version'
require 'debugger'

module GrandCloud

  DEFAULT_HOST_URL = "api.ku6vms.com"

  attr_reader :logger

  def self.logger
    @logger || (@logger = Logger.new(STDOUT))
  end


end
