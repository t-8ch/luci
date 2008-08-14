--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--
require("luci.model.uci")
require("luci.sys")
require("luci.util")

m = Map("dhcp", "DHCP")

s = m:section(TypedSection, "dhcp", "")
s.addremove = true
s.anonymous = true

iface = s:option(ListValue, "interface", translate("interface"))
luci.model.uci.foreach("network", "interface",
	function (section)
		if section[".name"] ~= "loopback" then
			iface.default = iface.default or section[".name"]
			iface:value(section[".name"])
			s:depends("interface", section[".name"])
		end
	end)

luci.model.uci.foreach("network", "alias",
	function (section)
		iface:value(section[".name"])
		s:depends("interface", section[".name"])
	end)

s:option(Value, "start", translate("start")).rmempty = true

s:option(Value, "limit", translate("limit")).rmempty = true

s:option(Value, "leasetime").rmempty = true

s:option(Flag, "dynamicdhcp").rmempty = true

s:option(Value, "name", translate("name")).optional = true

ignore = s:option(Flag, "ignore")
ignore.optional = true

s:option(Value, "netmask", translate("netmask")).optional = true

s:option(Flag, "force").optional = true

for i, line in pairs(luci.util.execl("dnsmasq --help dhcp")) do
	k, v = line:match("([^ ]+) +([^ ]+)")
	s:option(Value, "dhcp"..k, v).optional = true
end


for i, n in ipairs(s.children) do
	if n ~= iface and n ~= ignore then
		n:depends("ignore", "")
	end
end


m2 = Map("luci_ethers", translate("luci_ethers"))

s = m2:section(TypedSection, "static_lease", "")
s.addremove = true
s.anonymous = true
s.template = "cbi/tblsection"

mac = s:option(Value, "macaddr", translate("macaddress"))
ip = s:option(Value, "ipaddr", translate("ipaddress"))
for i, dataset in ipairs(luci.sys.net.arptable()) do
	ip:value(dataset["IP address"])
	mac:value(dataset["HW address"],
	 dataset["HW address"] .. " (" .. dataset["IP address"] .. ")")
end

	
return m, m2
