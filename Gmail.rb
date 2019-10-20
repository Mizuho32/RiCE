#!/usr/bin/env ruby

require 'yaml'
require_relative 'lib/gmail'

if ARGV.size != 3 then
	puts(<<-EOF)
ARGV[0] is target address
ARGV[1] is Subject
ARGV[2] is main
EOF
exit
end


cred    = YAML.load_file('account.yaml')
gmail   = GMail.new("#{cred[:user]}@gmail.com", cred[:pass])
gmail.send(ARGV.first, ARGV[1], ARGV.last.gsub('\n', "\n"))
