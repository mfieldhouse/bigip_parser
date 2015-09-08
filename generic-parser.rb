require 'parslet'
require 'parslet/convenience'
require 'pp'

class QuickParser < Parslet::Parser
  root(:lines)

  rule(:lines)            { line.repeat }
  rule(:line)             { (mask | string.as(:generic_line)) >> newline >> space? }
  rule(:mask)             { (str('mask ') >> string.as(:mask)) }
  rule(:newline)          { str("\n") }

  rule(:string)           { (word >> str(" ").maybe).repeat(1)}
  rule(:word)             { match('[\w!-:]').repeat(1) >> str(" ").maybe }
  
  rule(:space)            { match('\s').repeat(1) }
  rule(:space?)           { space.maybe }
end

test_string = <<-END
configuration one
mask 255.255.255.0
configuration two
END

pp test_string
pp QuickParser.new.parse_with_debug(test_string)

