require 'parslet'
require 'parslet/convenience'
require 'pp'

class QuickParser < Parslet::Parser
  root(:virtual)

  rule(:lines)            { line.repeat }
  rule(:line)             { (mask | string.as(:generic_option)) >> newline >> space? }
  rule(:newline)          { str("\n") }
  rule(:space)            { match('\s').repeat(1) }
  rule(:space?)           { space.maybe }

  rule(:string)           { (word >> str(" ").maybe).repeat(1)}
  rule(:word)             { match('[\w!-:]').repeat(1) >> str(" ").maybe }

  rule(:virtual)          { str('virtual ') >> word.as(:virtual_name) >> 
                            space? >> str("{") >> space >> lines >> str('}') >> newline }
  rule(:mask)             { (str('mask ') >> string.as(:mask)) }
  
  
end

test_string = <<-END
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

test