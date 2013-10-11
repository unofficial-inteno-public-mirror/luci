local require = require
local tonumber = tonumber
local sys = require "luci.sys"
local uci = require "luci.model.uci"

module "luci.model.bwtest"
_uci_real  = cursor or _uci_real or uci.cursor()

function init(cursor)
	return _M
end


function initialize_tptest(self)
	sys.exec("rm /var/tptest*")
	_uci_real:foreach("speedtest", "testserver",
		function(s)
			sys.exec("echo %s:%s >> /var/tptestservers" %{s.server, s.port})
		end)
end

function startspt(self, opts) -- Start speed test
	local server = sys.exec("echo %s | awk -F':' '{print$1}'" %opts:sub(1))
	local port = sys.exec("echo %s | awk -F':' '{print$2}'" %opts:sub(1))
	local url = server.." "..port
	local dpack, upack

	sys.exec("echo %q > /var/tptesturl" %url)
	sys.exec("echo %s | awk -F':' '{print$3}' > /var/tptestmode" %opts:sub(1))

	if theinterface() == "WAN" then
		dpack, upack = sys.exec("uci get speedtest.@packetsize[-1].ethernet"):match("(%d+)/(%d+)") or 100,10
	elseif theinterface() == "VDSL" then
		dpack, upack = sys.exec("uci get speedtest.@packetsize[-1].vdsl"):match("(%d+)/(%d+)") or 50,5
	elseif theinterface() == "ADSL" then
		dpack, upack = sys.exec("uci get speedtest.@packetsize[-1].adsl"):match("(%d+)/(%d+)") or 25,1
	end

	if dpack and upack then
		return sptrun(dpack, upack, url)
	else
		return 1
	end
end

function sptrun(dwnMBytes, upMBytes, url) -- Run the test and update the results
	local dwnBytes = dwnMBytes * 1000000
	local upBytes = upMBytes * 1000000
	local mode = tonumber(sys.exec("cat /var/tptestmode"))

	if mode == 1 then
		sys.exec("tptest -n 1 -m tcp-receive 60 %d -v 2 $(cat /var/tptesturl) > /var/tptestresultsdown" %dwnBytes)
		sys.exec("tptest -n 1 -m tcp-send 60 %d -v 2 $(cat /var/tptesturl) > /var/tptestresultsup" %upBytes)
	elseif mode == 2 then
		sys.exec("tptest -n 1 -m tcp-receive 60 %d -v 2 $(cat /var/tptesturl) > /var/tptestresultsdown" %dwnBytes)
	elseif mode == 3 then
		sys.exec("tptest -n 1 -m tcp-send 60 %d -v 2 $(cat /var/tptesturl) > /var/tptestresultsup" %upBytes)
	end
	return 1
end

function theinterface(self) -- Decide the Interface
	local vdsl = tonumber(sys.exec("cat /var/state/layer2_interface | grep 'vdsl' | grep -c 'up'"))
	local adsl = tonumber(sys.exec("cat /var/state/layer2_interface | grep 'adsl' | grep -c 'up'"))
	local wan = tonumber(sys.exec("route -n | grep 'UG' | tail -1 | egrep -c 'eth|br-'"))

	if vdsl > 0 then
		return "VDSL"
	elseif adsl > 0 then
		return "ADSL"
	elseif wan > 0 then
		return "WAN"	
	else
		return "NONE"
	end
end

function sptstarttime(self) -- Test Start Time
	local mode = tonumber(sys.exec("cat /var/tptestmode"))
	if mode == 1 or mode == 2 then
		return sys.exec("cat /var/tptestresultsdown | grep 'Test started:' | awk -F'Test started: ' '{print$2}'")
	elseif mode == 3 then
		return sys.exec("cat /var/tptestresultsup | grep 'Test started:' | awk -F'Test started: ' '{print$2}'")
	end
end

function sptendtime(self) -- Test End Time
	local mode = tonumber(sys.exec("cat /var/tptestmode"))
	if mode == 1 or mode == 3 then
		return sys.exec("cat /var/tptestresultsup | grep 'Test ended:' | awk -F'Test ended:   ' '{print$2}'")
	elseif mode == 2 then
		return sys.exec("cat /var/tptestresultsdown | grep 'Test ended:' | awk -F'Test ended:   ' '{print$2}'")
	end
end

function sptbytes(self) -- SPT Transferred Bytes
	local mode = tonumber(sys.exec("cat /var/tptestmode"))
	local ret
	if mode == 1 or mode == 2 then
		ret = tonumber(sys.exec("cat /var/tptestresultsdown | grep 'Bytes rcvd:' | awk -F'Bytes rcvd: ' '{print$2}'"))
	elseif mode == 3 then
		ret = tonumber(sys.exec("cat /var/tptestresultsup | grep 'Bytes sent:' | awk -F'Bytes sent: ' '{print$2}'"))
	end
	return ret or 0
end

function sptdwnresults(self) -- Download Speed
	return sys.exec("cat /var/tptestresultsdown | grep 'Throughput:' | awk -F'(' '{print$2}' | awk -F')' '{print$1}'")
end

function sptupresults(self) -- Upload Speed
	return sys.exec("cat /var/tptestresultsup | grep 'Throughput:' | awk -F'(' '{print$2}' | awk -F')' '{print$1}'")

end
