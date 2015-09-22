require 'parslet'
require 'parslet/convenience'
require 'hashie'
require 'pp'
require 'csv'

class BIGIP_v9_Parser < Parslet::Parser
  root(:config)
  rule(:config)           { (virtual_address | virtual | pool_stanza | 
                            snatpool_stanza | ignore).repeat }

  rule(:virtual_address)  { (str('virtual address ') >> word.as(:name).repeat.maybe >> 
                            space? >> str("{") >> space >> virtual_options >> 
                            str("}")) >> newline.maybe }

  # BEGIN virtual server
  rule(:virtual)          { (str('virtual ') >> word.as(:name).repeat.maybe >> 
                            space? >> str("{") >> space >> virtual_options >> 
                            str("}")).as(:virtual_server) >> newline.maybe }
  rule(:destination)      { (str('destination ') >> string.as(:destination)) }
  rule(:mask)             { (str('mask ') >> word.as(:mask)) }
  rule(:snatpool)         { (str('snatpool ') >> string.as(:snatpool)) }
  rule(:pool)             { (str('pool ') >> string.as(:pool)) }
  # END virtual server

  # BEGIN snatpool
  rule(:snatpool_stanza)  { (str('snatpool ') >> word.as(:name).repeat.maybe >> 
                            space? >> str("{") >> space >> snatpool_options >> 
                            str("}")).as(:snatpool_stanza) >> newline.maybe }
  rule(:snatpool_member)  { (str('member ') >> word.as(:snatpool_member)) }
  # END snatpool

  # BEGIN pool
  rule(:pool_stanza)      { (str('pool ') >> word.as(:name).repeat.maybe >> 
                            space? >> str("{") >> space >> pool_options >> 
                            str("}")).as(:pool_stanza) >> newline.maybe }
  rule(:pool_member)      { (str('member ') >> word.as(:pool_member)) }
  # END pool



  rule(:ignore)           { (str('virtual').absent? >> any.as(:generic_line) >>                        newline.maybe).repeat(1) }


  # rule(:lines)            { line.repeat }
  rule(:virtual_options)  { ((destination | mask | pool | snatpool | 
                            string.as(:generic_option)) >> newline >> space?).repeat }
  rule(:pool_options)     { ((pool_member | string.as(:generic_option)) >>  newline >> space?).repeat }
  rule(:snatpool_options) { ((snatpool_member | string.as(:generic_option)) >> newline >> space?).repeat }
  rule(:generic_options)  { (string.as(:generic_option) >> newline >> space?).repeat }
  rule(:newline)          { str("\n") }
  rule(:space)            { match('\s').repeat(1) }
  rule(:space?)           { space.maybe }
  rule(:string)           { (word >> str(" ").maybe).repeat(1)}
  rule(:word)             { match('[\w!-:=]').repeat(1) >> str(" ").maybe } 
end

class Virtual_Parser < Parslet::Parser
  root(:config)
  rule(:config)           { (virtual_address | virtual | ignore).repeat }

  rule(:virtual_address)  { (str('virtual address ') >> word.as(:name).repeat.maybe >> 
                            space? >> str("{") >> space >> virtual_options >> str("}")) >> newline.maybe }

  # BEGIN virtual server
  rule(:virtual)          { (str('virtual ') >> word.as(:name).repeat.maybe >> 
                            space? >> str("{") >> space >> virtual_options >> str("}")).as(:virtual_server) >> newline.maybe }
  rule(:virtual_options)  { ((destination | mask | pool | snatpool | string.as(:generic_option)) >> newline >> space?).repeat }
  rule(:destination)      { (str('destination ') >> string.as(:destination)) }
  rule(:mask)             { (str('mask ') >> word.as(:mask)) }
  rule(:snatpool)         { (str('snatpool ') >> string.as(:snatpool)) }
  rule(:pool)             { (str('pool ') >> string.as(:pool)) }
  # END virtual server

  rule(:ignore)           { (str('virtual').absent? >> any.as(:generic_line) >>                        newline.maybe).repeat(1) }
  rule(:generic_options)  { (string.as(:generic_option) >> newline >> 
                            space?).repeat }
  rule(:newline)          { str("\n") }
  rule(:space)            { match('\s').repeat(1) }
  rule(:space?)           { space.maybe }
  rule(:string)           { (word >> str(" ").maybe).repeat(1)}
  rule(:word)             { match('[\w!-:=]').repeat(1) >> str(" ").maybe } 
end

class Snatpool_Parser < Parslet::Parser
  root(:config)
  rule(:config)           { (snatpool_stanza | ignore).repeat }

  # BEGIN snatpool
  rule(:snatpool_stanza)  { begin_snatpool.present? >> (str('snatpool ') >> word.as(:name) >> 
                            space? >> str("{") >> space >> snatpool_member >> str("}")).as(:snatpool_stanza) >> newline.maybe }
  rule(:snatpool_member)  { ((str('member ') >> word.as(:snatpool_member)) >> newline >> space?).repeat.maybe }
  # END snatpool

  rule(:begin_snatpool )  { (str('snatpool ') >> word.as(:name) >> space? >> str("{")) }

  rule(:ignore)           { (begin_snatpool.absent? >> any.as(:generic_line) >> newline.maybe).repeat(1) }

  rule(:virtual_options)  { ((destination | mask | pool | snatpool | string.as(:generic_option)) >> newline >> space?).repeat }
  rule(:pool_options)     { ((pool_member | string.as(:generic_option)) >> newline >> space?).repeat }
  rule(:snatpool_options) { ((snatpool_member | string.as(:generic_option)) >> newline >> space?).repeat }
  rule(:generic_options)  { (string.as(:generic_option) >> newline >> space?).repeat }
  rule(:newline)          { str("\n") }
  rule(:space)            { match('\s').repeat(1) }
  rule(:space?)           { space.maybe }
  rule(:string)           { (word >> str(" ").maybe).repeat(1)}
  rule(:word)             { match('[\w!-:=]').repeat(1) >> str(" ").maybe } 
end

class BIGIP_Parser
  attr_accessor :vips, :snatpools
  @output = []

  def initialize(config_filename)
    @filename = config_filename
    @config = File.read(config_filename)
  end

  def parse_vips
    @vips = Virtual_Parser.new.parse_with_debug(@config)
    @vips = @vips.map { |x| x.extend Hashie::Extensions::DeepFind }
    self.vips
  end

  def parse_snatpools
    @snatpools = Snatpool_Parser.new.parse_with_debug(@config)
    @snatpools = @snatpools.map { |x| x.extend Hashie::Extensions::DeepFind }
    self.snatpools
  end

  def name vip
    name = vip.deep_find(:name).to_s.gsub(' ', '')
  end

  def ip vip
    dest = vip.deep_find :destination
    dest.to_s.split(':')[0]
  end

  def mask vip
    mask = vip.deep_find(:mask).to_s
    if mask.empty?
      "255.255.255.255"
    else
      mask
    end
  end

  def port vip
    dest = vip.deep_find :destination
    dest.to_s.split(':')[1]
  end

  def type vip
    ip_forward = vip.deep_find(:ip_forward).to_s
    ip_forward.empty? ? "RESOURCE_TYPE_POOL" : "RESOURCE_TYPE_IP_FORWARDING"
  end

  def protocol vip
    protocol = vip.deep_find(:ip_protocol).to_s
    if protocol == "tcp"
      "PROTOCOL_TCP"
    elsif protocol == "udp"
      "PROTOCOL_UDP"
    elsif protocol.empty?
      "PROTOCOL_ANY"
    end
  end

  def profile vip
    profile = vip.deep_find(:profile).to_s
  end

  def state vip
    state = vip.deep_find(:disabled).to_s
    state.empty? ? "ENABLED_STATUS_ENABLED" : "ENABLED_STATUS_DISABLED"
  end

  def snatpool vip
    vip.deep_find(:snatpool).to_s
  end

  def build vip
    output = []
    host   = @filename.gsub('')
    output << "LDVSF4CS04" << name(vip) << ip(vip) << mask(vip) << port(vip) << profile(vip) << type(vip) << protocol(vip) << state(vip)
  end
end

def snatpool_name x
  x[:snatpool_stanza][0][:name].to_s.gsub(' ', '')
end

def vip_snatpool_name vip
  name = vip.deep_find(:snatpool).to_s.gsub(' ', '')
end



# out = config.parse_snatpools
# pp Transformer.new.apply(out)

# Get snatpool name from snatpool
# config.parse_snatpools.each { |x| snatpool_name(x) }

# Get snatpool name from virtual
# config.parse_vips.each do |vip|
#   snatpool_name = vip_snatpool_name(vip)
#   puts snatpool_name

def snatpool_members snatpool_name
  config = BIGIP_Parser.new('LDVSF4CS04_v9_bigip.conf')
  members = []
  config.parse_snatpools.each do |snatpool|
    snatpool[:snatpool_stanza].each do |x|
      a = x.values_at(:name) if !x.values_at(:name).empty? 
      name = a[0].to_s.strip
      if name == snatpool_name 
        snatpool[:snatpool_stanza].each do |x|
          member = x.values_at(:snatpool_member)[0].to_s 
          if ! member.empty?
            members << member
          end
        end
      end
    end
  end
  members  # returns an array of members
end

pp snatpool_members("FTPLDN042_snat")[0].class

# pp config.parse_snatpools[0][:snatpool_stanza].each { |x| puts x.values_at(:snatpool_member)  }



# config.parse_snatpools.each do |snatpool|
#  snatpool[:snatpool_stanza].each { |x| pp x.values_at(:snatpool_member)[0].to_s }
#   end

# snatpools = config.snatpools

# snatpools.each { |x| pp snatpool_name(x) }



# snatpools.each { |x| puts x[:snatpool_stanza][1]}

# output_filename = "output.csv"
# output_file     = File.open(output_filename, "w")
# output_file.puts "Hostname,Virtual,IP,Mask,Port,Profile,Type,Protocol,State"

# config.parse.each do |line|
#   output_file.puts line.to_csv
# end
