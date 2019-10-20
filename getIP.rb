#!/usr/bin/ruby
# -*- coding:utf-8 -*-

require 'open3'
require 'yaml'
require 'nkf'
require 'logger'

require 'net/http'
require 'uri'
require 'pp'

require_relative "lib/getip"
require_relative "lib/multiio"


conf = YAML.load_file(ARGV.first)

#errorlog = Logger.new(MultiIO.new(STDOUT, File.open("error.log", ?a)))
logout = conf[:logout].map{|e|
  next eval(e.to_s) if e.is_a?(Symbol)
  next File.open(e, ?a) if e.is_a?(String)
}
getlog   = Logger.new(MultiIO.new(logout))


getlog.formatter = proc do |severity, datetime, progname, msg|
  "#{severity} #{datetime} #{msg}\n"
end

begin
  getIP = GetIP.new(
    mode: conf[:mode],
    sources: conf[:sources],
    servers: conf[:servers],
    limit:   conf[:limit],
    gateway: conf[:gateway],
    token:   conf[:token])
  unless ARGV[1] == "rpc"
    ip,source = getIP.getIP
    getlog.info("#{ip} from #{source}")
  else
    pp getIP.json_rpc(ARGV[2], ARGV[3], eval(ARGV[4]))
  end
  exit 0
rescue => e
  getlog.error("#{e.message} from #{e.backtrace.join("\n")}")
  exit 1
end
