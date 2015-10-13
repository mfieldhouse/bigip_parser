require_relative '../lib/bigip-parser'

config    = BIGIP_Audit.new('../input/LDVSF4CS04-v9.conf')
config.parse_virtuals
config.parse_pools
config.parse_snatpools
config.build

output_filename = "../output/output.csv"
output_file     = File.open(output_filename, "w")

output_file.puts "Load Balancer,VIP Name,VIP IP,VIP Mask,VIP Port,Pool Name,Pool Member IP,Pool Member Port,Snatpool Name,Snatpool Member"

config.build.each do |line|
  output_file.puts line.to_csv
end