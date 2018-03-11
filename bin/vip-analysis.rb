require_relative '../lib/bigip-parser'

config    = BIGIP_Audit.new('../input/bigip.conf')
config.parse_virtuals

output_filename = "../output/vip-analysis.csv"
output_file     = File.open(output_filename, "w")

output_file.puts "Load Balancer,Virtual,IP,Mask,Port,Type,Protocol,State"

config.vip_analysis.each do |line|
  output_file.puts line.to_csv
end
