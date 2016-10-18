#!/usr/bin/env ruby

require 'optparse'
require 'json'
require 'active_support/inflector'

options = {}
OptionParser.new do |opt|
	opt.on('-u WWWUSER', '--wwwuser=WWWUSER', 'User web server runs as') { |o| options[:server_user] = o }
	opt.on('-d DOCROOT', '--docroot=DOCROOT', 'Document root') { |o| options[:doc_root] = o }
	opt.on('-p', '--plugins', 'Check plugins') { |o| options[:plugins] = true }
end.parse!

if options[:plugins] == true
	#check for plugin updates
	updates_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp plugin list --path=" + options[:doc_root] + "  --update=available --format=count"
	call_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp plugin list --path=" + options[:doc_root] + " --update=available --format=json"
	call_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp plugin list --path=" + options[:doc_root] + " --update=available --format=json --fields=title,name,update"
	updates_result=`#{updates_command}`

	case
	when updates_result.to_i == 0
		puts "OK: all plugins up to date."
		exit 0
	when updates_result.to_i >= 1
		call_result=`#{call_command}`
		result=JSON.parse(call_result,{:symbolize_names=>true})
		name_list=result.collect{|x| x[:title]}
		puts "WARNING: " + updates_result + " plugin " + "update".pluralize(updates_result.to_i) + " available (" + name_list.join(", ") + ")"
	else
		puts "UNKNOWN: No valid update count returned"
		exit 3
	end
else
	#check for core updates
	updates_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp core check-update --path=" + options[:doc_root] + "  --format=count"
        call_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp plugin list --path=" + options[:doc_root] + " --update=available --field=title"

        updates_result=`#{updates_command}`

        case
        when updates_result.to_i == 0
                puts "OK: Wordpress is up to date."
                exit 0
        when updates_result.to_i >= 1
                puts "WARNING: " + updates_result + " plugin " + "update".pluralize(updates_result.to_i) + " available"
        else
                puts "UNKNOWN: No valid update count returned"
	end
end
