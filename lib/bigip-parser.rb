require 'parslet'
require 'parslet/convenience'
require 'hashie'
require 'pp'
require 'csv'

class BIGIP_Parser < Parslet::Parser
  rule(:newline)          { str("\n") }
  rule(:space)            { match('\s').repeat(1) }
  rule(:space?)           { space.maybe }
  rule(:string)           { (str(" ").maybe >> word >> str(" ").maybe).repeat(1)}
  rule(:word)             { match('[\w!-:=]').repeat(1) }
  rule(:generic_option)   { string.as(:generic_option) }
end

class Virtual_Parser < BIGIP_Parser
  root(:config)
  rule(:config)           { (virtual | ignore).repeat }

  rule(:begin_virtual )   { (str('virtual ') >> word.as(:name) >> space >> str("{")) }

  rule(:virtual)          { begin_virtual.present? >> (begin_virtual >> 
                            space >> virtual_options >> str("}")).as(:virtual_server) }
  rule(:virtual_options)  { ((destination | mask | pool | snatpool | generic_option) >> newline >> space?).repeat }
  rule(:destination)      { (str('destination ') >> string.as(:destination)) }
  rule(:mask)             { (str('mask ') >> word.as(:mask)) }
  rule(:snatpool)         { (str('snatpool ') >> string.as(:snatpool)) }
  rule(:pool)             { (str('pool ') >> string.as(:pool)) }

  rule(:ignore)           { (begin_virtual.absent? >> any).repeat(1) }
end

class Snatpool_Parser < BIGIP_Parser
  root(:config)
  rule(:config)           { (snatpool_stanza | ignore).repeat }

  rule(:begin_snatpool )  { (str('snatpool ') >> word.as(:name) >> space >> str("{")) }
  rule(:snatpool_stanza)  { begin_snatpool.present? >> (begin_snatpool >> space >> 
                            snatpool_member >> str("}")).as(:snatpool_stanza) >> newline }
  rule(:snatpool_member)  { ((str('member ') >> word.as(:snatpool_member)) >> newline >> space?).repeat }
  rule(:ignore)           { (begin_snatpool.absent? >> any).repeat(1) }
end

class Pool_Parser < BIGIP_Parser
  root(:config)
  rule(:config)           { (pool_stanza | ignore).repeat }

  rule(:begin_pool )      { (str('pool ') >> word.as(:name) >> space >> str("{")) }
  rule(:pool_stanza)      { begin_pool.present? >> (begin_pool >> space >> pool_options >> 
                            str("}")).as(:pool_stanza) >> newline.maybe }
  rule(:member)           { (str('member ') >> word.as(:pool_member) >> string.maybe) }
  rule(:pool_options)     { ((member | generic_option) >> newline >> space?).repeat.maybe }

  rule(:ignore)           { (begin_pool.absent? >> any >> newline.maybe).repeat(1) }
end

class BIGIP_Audit
  attr_accessor :vips, :snatpools, :config
  @output = []

  def initialize(config_filename)
    @filename = config_filename
    @config = File.read(config_filename)
  end

  def parse_virtuals
    @vips = Virtual_Parser.new.parse_with_debug(@config)
    @vips = @vips.map { |x| x.extend Hashie::Extensions::DeepFind }
    self.vips
  end

  def parse_snatpools
    @snatpools = Snatpool_Parser.new.parse_with_debug(@config)
    @snatpools = @snatpools.map { |x| x.extend Hashie::Extensions::DeepFind }
    self.snatpools
  end

  def parse_pools
    @pools = Pool_Parser.new.parse_with_debug(@config)
    @pools = @pools.map { |x| x.extend Hashie::Extensions::DeepFind }
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

  def pool_name vip
    vip.deep_find(:pool).to_s
  end

  def snat_type
    type = vip.deep_find(:ip_protocol).to_s
    if protocol == "tcp"
      "SNAT_TYPE_"
    else
      "SNAT_TYPE_NONE"
    end
  end

  def pool_members(pools, pool_name)
    members = []
    pools.each do |pool|
      pool[:pool_stanza].each do |x|
        a = x.values_at(:name) if !x.values_at(:name).empty? 
        name = a[0].to_s.strip
        if name == pool_name 
          pool[:pool_stanza].each do |x|
            member = x.values_at(:pool_member)[0].to_s 
            if ! member.empty?
              members << member
            end
          end
        end
      end
    end
    members
  end

  def snatpool_members(snatpools, snatpool_name)
    members = []
    snatpools.each do |snatpool|
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
    members
  end

  def build
    final_output = []
    @vips.each do |vip|

      if pool_name(vip) == ""
        output = []
        output << "LDVSF4CS04" << name(vip) << ip(vip) << mask(vip) << port(vip)
        final_output << output
      end

      unless pool_name(vip) == ""
        pool_members = pool_members(@pools, pool_name(vip))
        pool_members.each do |member|
          output = []
          output << "LDVSF4CS04" << name(vip) << ip(vip) << mask(vip) << 
          port(vip) << pool_name(vip) << member.to_s.split(':')[0] << member.to_s.split(':')[1]
          final_output << output
        end
      end

      unless snatpool(vip) == ""
        snatpool_members = snatpool_members(@snatpools, snatpool(vip))
        snatpool_members.each do |member|
          output = []
          output << "LDVSF4CS04" << name(vip) << ip(vip) << mask(vip) << 
          port(vip) << "" << "" << "" << snatpool(vip) << member
          final_output << output
        end
      end
    end
    final_output.map { |x| x.flatten }
  end
end