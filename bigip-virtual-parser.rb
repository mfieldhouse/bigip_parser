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
  rule(:line)             { (mask | destination | ip_protocol | disabled | ip_forward | pool | string.as(:generic_option)) >> newline >> space? }
  rule(:mask)             { (str('mask ') >> string.as(:mask)) }
  rule(:destination)      { (str('destination ') >> string.as(:destination)) }
  rule(:pool)             { (str('pool ') >> string.as(:pool)) }
  rule(:ip_forward)       { str('ip forward').as(:ip_forward) }
  rule(:ip_protocol)      { (str('ip protocol ') >> string.as(:ip_protocol)) }
  rule(:disabled)         { str('disable').as(:disabled) }

  rule(:ignore)           { (str('virtual').absent? >> any.as(:generic_line) >> newline.maybe).repeat(1) }

  rule(:newline)          { str("\n") }
  rule(:space)            { match('\s').repeat(1) }
  rule(:space?)           { space.maybe }

  rule(:string)           { (word >> str(" ").maybe).repeat(1)}
  rule(:word)             { match('[\w!-:=]').repeat(1) >> str(" ").maybe } 
end

class Virtual_Parser
  attr_accessor :config, :parse, :name

  def initialize(config_filename)
    @config = File.read(config_filename)
  end

  def parse
    @vips = BIGIP_v9_Parser.new.parse_with_debug(@config)
    @vips = @vips.map { |vip| vip.extend Hashie::Extensions::DeepFind }
    build(@vips)
  end

  def count
    @count = @vips.count
  end

  def name  
    @vips.deep_find(:name).to_s.gsub(' ', '')
  end

  def ip
    dest = @vips.deep_find :destination
    dest.to_s.split(':')[0]
  end

  def mask
    mask = @vips.deep_find(:mask).to_s
    if mask.empty?
      "255.255.255.255"
    else
      mask
    end
  end

  def port
    dest = @vips.deep_find :destination
    dest.to_s.split(':')[1]
  end

  def type
    ip_forward = @vips.deep_find(:ip_forward).to_s
    ip_forward.empty? ? "RESOURCE_TYPE_POOL" : "RESOURCE_TYPE_IP_FORWARDING"
  end

  def protocol
    protocol = @vips.deep_find(:ip_protocol).to_s
    if protocol == "tcp"
      "PROTOCOL_TCP"
    elsif protocol == "udp"
      "PROTOCOL_UDP"
    elsif protocol.empty?
      "PROTOCOL_ANY"
    end
  end

  def state
    state = @vips.deep_find(:disabled).to_s
    state.empty? ? "ENABLED_STATUS_ENABLED" : "ENABLED_STATUS_DISABLED"
  end

  def build(vips)
    pp vips
    pp vips[0].respond_to? :deep_find
    # [parse.name, parse.ip, parse.mask, parse.port, parse.type, parse.protocol, parse.state]
  end
end

config = Virtual_Parser.new('sample-config.txt')
config.parse

# Access the virtual server name
# pp config.parse[0][:virtual_server][0][:name].class

