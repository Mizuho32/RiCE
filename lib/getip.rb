#!/usr/bin/ruby
# -*- coding:utf-8 -*-

require 'open3'
require 'yaml'
require 'nkf'
require 'date'
require 'json'

require 'net/https'
require 'uri'

class GetIP

def initialize(mode: :parse_html, sources:[], servers:[], limit:3, gateway: "192.168.1.1", token: "", dev: "pppoe-WAN")
  @mode    = mode     # parse_html, openwrt
  @sources = sources
  @servers = servers
  @limit   = limit
  @gateway = gateway
  @token   = token
  @dev     = dev
end

def get_html(url)
	uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  if url =~ /https/
    http.use_ssl     = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  req = Net::HTTP::Get.new(uri.request_uri)
  res = http.request(req)

  return res.body
end

def online?()
	router = gateway?(@gateway, 2)
	return router if router 							 == false
	return false 	if servers?(@servers, 2) == false
	true
end

def gateway?(count)
	ping?(@gateway, count)
end

def servers?(count)
	return false if @servers.all?{|el| ping?(el, count) == false}
	true
end


def ping?(url, count)
	ping = Open3.capture3("ping -c #{count} '#{url}'")
	ping[2].success?
end

def to(type, str)
return str.encode(type, NKF.guess(str).to_s, :invalid => :replace, :undef => :replace, :replace => '?')
end

def getIP()
  raise	StandardError, "Unreachable to GateWay #{@gateway}" if !gateway?(3)
  if @mode == :openwrt
    return get_ip_address_from_openwrt()
  elsif @mode == :parse_html
    #raise StandardError, "Unreachable to Internet" if  !servers?(2)
    return get_ip_address_by_parsing()
  else
    return @mode
  end
end

class JsonRpcError < StandardError
end

def json_rpc(lib, method, params)
  uri = URI.parse("http://#{@gateway}/cgi-bin/luci/rpc/#{lib}?auth=#{@token}")
  request = Net::HTTP::Post.new(uri)
  request.body = {id: 1, method: method, params: params}.to_json

  req_options = {
      use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
  end

  code = response.code.to_i
  raise JsonRpcError, "Code: #{code}. Expired?" if code != 200
  JSON.parse(response.body, symbolize_names: true)
end

def get_ip_address_from_openwrt()
  ip = json_rpc("sys", "exec", ["ip a show dev #{@dev}"])[:result]
    .each_line
    .select{|line| line =~ /inet/}
    .first[/inet\s+((\d+\.){3}\d+)/, 1]
  return ip, @gateway
end

def get_ip_address_by_parsing()
	sources = @sources
	servers = @servers
	limit 	= @limit
	source  = nil
	
	while true do
		limit.downto(0) do |lim|
      raise StandardError, "Sources Empty, All Sources are Unreachable" if sources.empty?
      source = sources.delete_at((rand*sources.size).to_i)

			page = to("UTF-8", get_html(source))

			if page != nil then
					system %Q|echo "#{source} : #{page[/((\d+\.){3}\d+)/, 1]} : #{DateTime.now().to_s}" >> ./getlog|
				if(page =~ /((\d+\.){3}\d+)/)	
					return page[/((\d+\.){3}\d+)/, 1].gsub(/\s/, ""), source
				else
          raise StandardError, "Parse error #{source}"
				end
			end
		end

	end
end

end
