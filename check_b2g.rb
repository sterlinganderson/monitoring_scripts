#! /usr/bin/env ruby

require 'date'
require 'optparse'
require 'active_support/inflector'

options = {}
OptionParser.new do |opt|
        opt.on('-w WARNING', '--warning=WARNING') { |o| options[:warning] = o }
        opt.on('-c CRITICAL', '--critical=CRITICAL') { |o| options[:critical] = o }
end.parse!


workstations = %x[/usr/local/aw/bin/nsdchat -c Workstation names]
b2g_clients = Hash.new
okay_clients = Hash.new
warn_clients = Hash.new
crit_clients = Hash.new

workstations.split(" ").each do |workstation|
	enabled = %x[/usr/local/aw/bin/nsdchat -c Workstation #{workstation} enabled].to_s.strip == "1" ? TRUE : FALSE
	name = %x[/usr/local/aw/bin/nsdchat -c Workstation #{workstation} describe].to_s.strip
	lastendEpoch = %x[/usr/local/aw/bin/nsdchat -c Workstation #{workstation} lastend]
	lastendDateTime = Time.at(lastendEpoch.to_f).utc.to_datetime.to_s
	lastbeginEpoch = %x[/usr/local/aw/bin/nsdchat -c Workstation #{workstation} lastbegin]
	lastbeginDateTime = Time.at(lastbeginEpoch.to_f).utc.to_datetime.to_s
	
	#puts workstation + ": " + name
	#puts " lastend:   " + lastendDateTime
	#puts " lastbegin: " + lastbeginDateTime

	timesince = Time.new() - Time.at(lastendEpoch.to_f)
	#puts " days since last complete: " + (timesince / 86400).to_i.to_s

	b2g_clients[workstation] = {client_name: name,
				    is_enabled: enabled,
				    last_begin: lastbeginDateTime,
				    last_end: lastendDateTime,
				    days_since: (timesince / 86400).to_i}

end

b2g_clients.each do |name, client|
	if client[:is_enabled] then
		case
		when client[:days_since] < options[:warning].to_i
			okay_clients[name] = client
		when client[:days_since] > options[:warning].to_i && client[:days_since] <= options[:critical].to_i
			warn_clients[name] = client
		when client[:days_since] > options[:critical].to_i
			crit_clients[name] = client
		end
	end
end

if crit_clients.count >= 1 then
	puts "CRITICAL: " + crit_clients.count.to_s + " client".pluralize(crit_clients.count) + " haven not been backed up in " + options[:critical].to_s + " or more days. (" + crit_clients.collect{|key, value| value[:client_name]}.join(", ") + ")"
	exit 2
end

if warn_clients.count >= 1 then
	puts "WARNING: " + warn_clients.count.to_s + " client".pluralize(warn_clients.count) + " haven not been backed up in " + options[:warning].to_s + " or more days. (" + warn_clients.collect{|key, value| value[:client_name]}.join(", ") + ")"
	exit 1
end
if okay_clients.count >= 1 then
	puts "OK: " + okay_clients.count.to_s + " client".pluralize(okay_clients.count) + " have been backed up."
	exit 0
else
	puts "UNKNOWN: No backup information found."
	exit 3
end
