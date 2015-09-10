require 'parslet'
require 'parslet/convenience'
require 'pp'
require 'hashie'

class BIGIP_v9_Parser < Parslet::Parser
  root(:config)

  rule(:config)           { (virtual_address | virtual | ignore).repeat }

  rule(:virtual)          { (str('virtual ') >> word.as(:name).repeat.maybe >> 
                            space? >> str("{") >> space >> lines >> str("}")).as(:virtual_server) >> newline.maybe }

  rule(:virtual_address)  { (str('virtual address ') >> word.as(:name).repeat.maybe >> 
                            space? >> str("{") >> space >> lines >> str("}")) >> newline.maybe }

  rule(:lines)            { line.repeat }
  rule(:line)             { (mask | destination | ip_protocol | disabled | ip_forward | string.as(:generic_option)) >> newline >> space? }
  rule(:mask)             { (str('mask ') >> string.as(:mask)) }
  rule(:ip_protocol)      { (str('ip protocol ') >> string.as(:ip_protocol)) }
  rule(:destination)      { (str('destination ') >> string.as(:destination)) }
  rule(:disabled)         { str('disable').as(:disabled) }
  rule(:ip_forward)       { str('ip forward').as(:ip_forward) }

  rule(:ignore)           { (str('virtual').absent? >> any.as(:generic_line) >> newline.maybe).repeat(1) }

  rule(:newline)          { str("\n") }
  rule(:space)            { match('\s').repeat(1) }
  rule(:space?)           { space.maybe }

  rule(:string)           { (word >> str(" ").maybe).repeat(1)}
  rule(:word)             { match('[\w!-:=]').repeat(1) >> str(" ").maybe } 
end

class Virtual_Parser
  attr_accessor :config, :parse, :count

  def initialize(config_filename)
    @config = File.read(config_filename)
  end

  def parse
    @parse = BIGIP_v9_Parser.new.parse_with_debug(@config)
  end

  def count
    @count = @parse.count
  end

  def name
    vip = self.parse[0]
    vip.extend Hashie::Extensions::DeepFind
    vip.deep_find :name
  end

  def destination
    vip = self.parse[0]
    vip.extend Hashie::Extensions::DeepFind
    vip.deep_find :destination
  end
end

config = Virtual_Parser.new('sample-config.txt')
puts config.name
puts config.destination
puts config.count

# v = vips[0]
# v.extend Hashie::Extensions::DeepFind

# puts v.deep_find :destination


# puts "#{config.count} virtual servers found"

