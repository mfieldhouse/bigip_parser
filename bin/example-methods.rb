require_relative '../lib/bigip-parser'

config.parse_virtuals
config.parse_snatpools
config.parse_pools

config.parse_virtuals.count