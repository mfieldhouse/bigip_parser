require 'parslet'
require 'parslet/convenience'
require 'pp'

class BIGIP_v9_Parser < Parslet::Parser
  root(:config)

  rule(:config)           { (virtual | ignore).repeat }

  rule(:virtual)          { (str('virtual ') >> word.as(:name).repeat.maybe >> 
                            space? >> str("{") >> space >> lines >> str("}")).as(:virtual_server) >> newline.maybe }

  rule(:lines)            { line.repeat }
  rule(:line)             { (mask | destination | ip_protocol | string.as(:generic_option)) >> newline >> space? }
  rule(:mask)             { (str('mask ') >> string.as(:mask)) }
  rule(:ip_protocol)      { (str('ip protocol ') >> string.as(:ip_protocol)) }
  rule(:destination)      { (str('destination ') >> string.as(:destination)) }

  rule(:ignore)           { (str('virtual').absent? >> any.as(:generic_line) >> newline.maybe).repeat(1) }

  rule(:newline)          { str("\n") }
  rule(:space)            { match('\s').repeat(1) }
  rule(:space?)           { space.maybe }

  rule(:string)           { (word >> str(" ").maybe).repeat(1)}
  rule(:word)             { match('[\w!-:=]').repeat(1) >> str(" ").maybe } 
end

test_string = File.read('sample-config.txt')
parsed_config = BIGIP_v9_Parser.new.parse_with_debug(test_string)

virtual_server_count = parsed_config.count
puts "Virtual servers: #{virtual_server_count}"

pp parsed_config[0]