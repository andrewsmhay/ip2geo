#!/usr/bin/env ruby
require 'open-uri'
require 'zlib'
require 'geoip'
require 'ipaddress'

class Analysis
	class << self
		def working_dir
			Dir.pwd
		end
		def ip_convert geo
      		GeoIP.new('GeoLiteCity.dat').city(geo.to_s)
      	end
      	def convert ipaddress
      		target_geo = Analysis.ip_convert("#{ipaddress}")
			puts target_geo.latitude.to_s+","+target_geo.longitude.to_s
      	end
      	def geodb
      		geo_dat_city = "http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz"
      		open('GeoLiteCity.dat.gz', 'w') do |local_file|
				open(geo_dat_city) do |remote_file|
    				local_file.write(Zlib::GzipReader.new(remote_file).read)
				end
			end
		File.rename("GeoLiteCity.dat.gz", working_dir+"/GeoLiteCity.dat")
		puts "[+] Using GeoLiteCity database: #{working_dir}/GeoLiteCity.dat"
      	end
      	def opt_sel_err
      		"
[-] Usage: ./ip2geo.rb <option> <type>

<option>
--fetch | -f	- Fetch the latest GeoLiteCity database from MaxMind
--local | -l 	- Use the local GeoLiteCity database

<type>
--ip 	| -i 	- Convert a single IP address from STDIN
--read	| -r 	- Convert a list of IP addresses from a specified file

(C) Andrew Hay, 2014
http://www.andrewhay.ca
https://twitter.com/andrewsmhay
      		"
      	end
    end
end

commands = []
ARGV.each {|arg| commands << arg}
if ARGV[1] == "-i" || ARGV[1] == "--ip"
	ip = IPAddress(ARGV[2])
	if ip.ipv4?
		if ARGV[0] == "--fetch" || ARGV[0] == "-f"
			Analysis.geodb
			Analysis.convert(ip)

		elsif ARGV[0] == "--local" || ARGV[0] == "-l"
			Analysis.convert(ip)	

		else puts opt_sel_err
		end
	elsif ip.ipv6?
		puts "Not yet supported..."
	else puts Analysis.opt_sel_err
	end
elsif ARGV[1] == "-r" || ARGV[1] == "--read"
	iplist = Analysis.working_dir+"/"+ARGV[2]
	stats = File.open(iplist, "a")
	if File.exist?(iplist)
		if ARGV[0] == "--fetch" || ARGV[0] == "-f"
			Analysis.geodb
			IO.foreach(stats) do |x|
				y = IPAddress(x.chomp)
				if y.ipv4?
					Analysis.convert(y)
				end
			end
			

		elsif ARGV[0] == "--local" || ARGV[0] == "-l"
			
			IO.foreach(stats) do |x|
				y = IPAddress(x.chomp)
				if y.ipv4?
					Analysis.convert(y)
				end
			end
			
			###
		elsif ARGV[0] == "--help" || ARGV[0] == "-h"
			puts Analysis.opt_sel_err
		else puts Analysis.opt_sel_err
		end
	elsif ip.ipv6?
		puts "[+] File does not exist..."
	else puts Analysis.opt_sel_err
	end
	stats.close

else puts Analysis.opt_sel_err
end
