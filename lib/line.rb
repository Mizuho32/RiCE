require 'net/http'
require 'uri'
require 'json'

class LineBot

  def initialize(secret, token)
    @secret = secret
    @token  = token
  end


  def push(userid, msgs)
    msgs = [msgs] unless msgs.is_a?(Array)

    uri = URI.parse("https://api.line.me/v2/bot/message/push")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{@token}"
    request.body = JSON.dump({
      "to" => userid,
      "messages" => msgs.map{|msg| 
        {
          "type" => "text",
          "text" => msg
        }
      } 
    })

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    return response.code.to_i, response.body
  end

end
