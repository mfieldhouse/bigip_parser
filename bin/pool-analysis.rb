require_relative '../lib/bigip-parser'

config    = BIGIP_Audit.new('../input/LDVSF4CS04-v9.conf')
config.parse_virtuals
config.parse_pools
config.parse_snatpools

output_filename = "../output/pool-analysis.csv"
output_file     = File.open(output_filename, "w")

output_file.puts "Load Balancer,VIP Name,VIP IP,VIP Mask,VIP Port,Pool Name,Pool Member IP,Pool Member Port,SNAT Type,Snatpool Name,Snatpool Member"

config.pool_analysis.each do |line|
  output_file.puts line.to_csv
end