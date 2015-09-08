require 'parslet'
require 'parslet/convenience'
require 'pp'

class QuickParser < Parslet::Parser
  root(:config)

  rule(:config)           { (virtual | ignore).repeat }

  rule(:lines)            { line.repeat }
  rule(:line)             { (mask | string.as(:generic_option)) >> newline >> space? }
  rule(:newline)          { str("\n") }
  rule(:space)            { match('\s').repeat(1) }
  rule(:space?)           { space.maybe }

  rule(:string)           { (word >> str(" ").maybe).repeat(1)}
  rule(:word)             { match('[\w!-:]').repeat(1) >> str(" ").maybe }
  rule(:generic_line)     { (match('[\w!-:{}]').repeat(1) >> str(" ").maybe).repeat(1)}

  rule(:ignore)           { (str('virtual').absent? >> generic_line.as(:generic_line) >> newline).repeat(1) }

  rule(:virtual)          { str('virtual ') >> word.as(:virtual_name) >> 
                            space? >> str("{") >> space >> lines >> str('}') >> newline }
  rule(:mask)             { (str('mask ') >> string.as(:mask)) }
  
  
end

test_string = <<-END
test
# blah config what is this shit
{}
fill it 
two
virtual onephonebookapisaml.prod.http {
   destination 10.120.13.235:http
   snatpool onephonebookapisaml.prod.http.snatpool
   ip protocol tcp
   profile fastL4
   mask 255.255.255.0
   persist source_addr_20mins
   pool onephonebookapisaml.prod.http.pool
}
END

pp test_string
pp QuickParser.new.parse_with_debug(test_string)