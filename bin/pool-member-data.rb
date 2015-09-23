require_relative '../lib/bigip-parser'

config    = BIGIP_Audit.new('../input/test.conf')
config.parse_virtuals
config.parse_pools
config.parse_snatpools
pp config.build

output_filename = "../output/output.csv"
output_file     = File.open(output_filename, "w")

config.build.each do |line|
  output_file.puts line.to_csv
end