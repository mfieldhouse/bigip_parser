require 'parslet'
require 'parslet/convenience'
require 'pp'

class QuickParser < Parslet::Parser
  root(:config)

  rule(:config)           { (virtual | ignore).repeat }

  rule(:lines)            { line.repeat }
  rule(:line)             { (mask | destination | string.as(:generic_option)) >> newline >> space? }
  rule(:newline)          { str("\n") }
  rule(:space)            { match('\s').repeat(1) }
  rule(:space?)           { space.maybe }

  rule(:string)           { (word >> str(" ").maybe).repeat(1)}
  rule(:word)             { match('[\w!-:=]').repeat(1) >> str(" ").maybe }
  rule(:generic_line)     { any }

  rule(:ignore)           { (str('virtual').absent? >> any.as(:generic_line) >> newline.maybe).repeat(1) }

  rule(:virtual)          { (str('virtual ') >> word.as(:name).repeat.maybe >> 
                            space? >> str("{") >> space >> lines >> str("}")).as(:virtual_server) >> newline.maybe }
  rule(:mask)             { (str('mask ') >> string.as(:mask)) }
  rule(:destination)      { (str('destination ') >> string.as(:destination)) }
  
  
end

test_string = File.read('sample-config.txt')
pp QuickParser.new.parse_with_debug(test_string)