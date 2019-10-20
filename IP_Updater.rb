#!/usr/bin/env ruby
# coding: utf-8
#
require 'open3'
require 'yaml'
require 'nkf'
require 'logger'
require 'date'

require 'pp'

require_relative 'lib/getip'
require_relative 'lib/multiio'
require_relative 'lib/line'
require_relative 'lib/gmail'


conf = YAML.load_file(ARGV.first)

# log
logout = conf[:logout].map{|e|
  next eval(e.to_s) if e.is_a?(Symbol)
  if e.is_a?(String)
    file = File.open(e, ?a)
    file.sync = true
    next file
  end
}
@getlog   = Logger.new(MultiIO.new(logout))
@getlog.formatter = proc do |severity, datetime, progname, msg|
  "#{severity} #{datetime} #{msg}\n"
end

# msgs
@linebot  = LineBot.new(conf[:line][:secret], conf[:line][:token])
@gmail    = GMail.new("#{conf[:gmail][:user]}@gmail.com", conf[:gmail][:pass])
@multimsg = MultiMsg.new(conf[:production]){|title, msg|
  l = @linebot.push(conf[:line][:to], "#{title}\n\n#{msg}")
  g = @gmail.send(conf[:gmail][:to], title, msg)
}

# var init
@daemon = conf[:daemon] || ARGV[1] =~ /-d/
@write_interval = eval(conf[:write_interval].to_s)
@check_interval = eval(conf[:check_interval].to_s)
@ip_before_file = conf[:ip_before_file]
@ip_before      = File.read(@ip_before_file)
@ip_now         = ""

@getIP = GetIP.new(
    mode: conf[:mode],
    sources: conf[:sources],
    servers: conf[:servers],
    limit:   conf[:limit],
    gateway: conf[:gateway],
    token:   conf[:token])

SET_IP=conf[:set_ip]

writer = Thread.new {
begin
  while @ip_now.empty? do
    sleep 0.5
  end

  @multimsg.send("IPU Startup", "#{@ip_now} from #{@source}")
  @getlog.info("IPU Startup #{@ip_now} from #{@source}")

  loop do
    @getlog.info("#{@ip_now} from #{@source}")

    exit 0 unless @daemon
    sleep @write_interval
  end
rescue StandardError => e
  @getlog.error("#{e.message} from #{e.backtrace.join("\n")}")
end
}

update = Thread.new {
loop do
begin

  @ip_now,@source = @getIP.getIP

  if @ip_now == @ip_before then #not changed
    puts "#{DateTime.now} Not changed."
  else  												#changed
    @getlog.info("Changed to #{@ip_now} from #{@ip_before}")

    @multimsg.send(
      "IP Address Notification",
      "IP Address changed #{@ip_before} To #{@ip_now}\n#{DateTime.now}")
    
	  setip_out = `sh #{SET_IP} '#{@ip_now}'`
    @getlog.info(setip_out)

    File.write(@ip_before_file, @ip_now)
    @ip_before = @ip_now
  end

  break unless @daemon
  sleep @check_interval

rescue GetIP::JsonRpcError => e
  @getlog.error("#{e.message}\n#{e.backtrace.join("\n")}")
  @multimsg.send(
    "GetIP::JsonRpcError",
    "#{e.message}\n#{e.backtrace.join("\n")}")
  writer.kill
  exit 1
rescue StandardError => e
  @getlog.error("#{e.message}\n#{e.backtrace.join("\n")}")
  @multimsg.send(
    "GetIP::JsonRpcError",
    "#{e.message}\n#{e.backtrace.join("\n")}")
end
end
}

trap(:INT){
  writer.kill
  update.kill
}

writer.join
update.join
exit 0
