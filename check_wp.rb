#!/usr/bin/env ruby

require 'optparse'
require 'json'
require 'active_support/inflector'

options = {}
OptionParser.new do |opt|
	opt.on('-u WWWUSER', '--wwwuser=WWWUSER', 'User web server runs as') { |o| options[:server_user] = o }
	opt.on('-d DOCROOT', '--docroot=DOCROOT', 'Document root') { |o| options[:doc_root] = o }
	opt.on('-p', '--plugins', 'Check plugins') { |o| options[:plugins] = true }
	opt.on('-t', '--themes', 'Check themes') { |o| options[:themes] = true }
	opt.on('-c', '--count', 'Show number of updates available') { |o| options[:count] = true }
	opt.on('-l', '--list', 'List updates available') { |o| options[:list] = true }
end.parse!

if (options[:plugins] && options[:themes])
	puts "Pick plugins or themes, not both"
	exit 1
end

if (options[:plugins] || options[:themes])
	if options[:plugins] == true
		to_check = "plugin"
	elsif options[:themes] == true
		to_check = "theme"
	end
	updates_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp " + to_check + " list --path=" + options[:doc_root] + "  --update=available --format=count"
	updates_result=`#{updates_command}`
	if options[:count] == true
		puts updates_result.to_i
		exit 0
	end
	if options[:list] == true 
		case
		when updates_result.to_i == 0
			exit 0
		when updates_result.to_i >= 1
			call_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp " + to_check + " list --path=" + options[:doc_root] + " --update=available --format=json --fields=title,name,update"
			call_result=`#{call_command}`
			result=call_result && call_result.length >= 2 ? JSON.parse(call_result,{:symbolize_names=>true}) : result
			name_list=result && call_result.length >= 2 ? result.collect{|x| x[:title]} : result[:name]
			puts name_list.join(", ")
			exit 0
		end
	end
else
	#check for core updates
	updates_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp core check-update --path=" + options[:doc_root] + "  --format=count"
	updates_result=`#{updates_command}`
	if options[:count] == true
		puts updates_result.to_i
		exit 0
	end
	if options[:list] == true
		case
		when updates_result.to_i == 0
			exit 0
		when updates_result.to_i >= 1
			call_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp core check-update --path=" + options[:doc_root] + " --format=json"
			call_result=`#{call_command}`
			result=JSON.parse(call_result,{:symbolize_names=>true})
			version_list=result.collect{|x| x[:version]}
			puts version_list
			exit 0
		end
	end
end
