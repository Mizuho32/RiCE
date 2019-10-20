#!/usr/bin/env ruby

require 'gmail'

class GMail
  def initialize(email, pass)
    @gmail = Gmail.new(email, pass)
  end

  def send(to, sub, content)

  message = @gmail.generate_message do
    to "#{to.split("@").first} <#{to}>"
    subject "#{sub}"
    html_part do
      content_type 'text/plain; charset="UTF-8"'
      body "#{content}"
    end
  end

  @gmail.deliver(message)
  @gmail.logout

  end
end
