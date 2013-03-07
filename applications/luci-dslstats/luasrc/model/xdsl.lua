local tonumber = tonumber
local require = require
local sys = require "luci.sys"

module "luci.model.xdsl"

function init(cursor)
	return _M
end

function reset_tm(self) -- Reset xDSL statistics
	return sys.exec("xtmctl operate intf --stats 1 reset")
end

function reset_dsl(self) -- Reset xDSL statistics
	return sys.exec("xdslctl info --reset")
end

function berstart_dsl(self, time) -- Start BER Test
	return sys.exec("xdslctl bert --start %d" %time)
end

function berstop_dsl(self) -- Stop BER Test
	return sys.exec("xdslctl bert --stop")
end
function tminoct(self) -- TM In Octets
	return sys.exec("xtmctl operate intf --stats | grep 'in octets' | awk -F' ' '{print$3}'")
end

function tmoutoct(self) -- TM Out Octets
	return sys.exec("xtmctl operate intf --stats | grep 'out octets' | awk -F' ' '{print$3}'")
end

function tminpac(self) -- TM In Packets
	return sys.exec("xtmctl operate intf --stats | grep 'in packets' | awk -F' ' '{print$3}'")
end

function tmoutpac(self) -- TM Out Packets
	return sys.exec("xtmctl operate intf --stats | grep 'out packets' | awk -F' ' '{print$3}'")
end

function tminoam(self) -- TM In OAM Cells
	return sys.exec("xtmctl operate intf --stats | grep 'in OAM' | awk -F' ' '{print$4}'")
end

function tmoutoam(self) -- TM Out OAM Cells
	return sys.exec("xtmctl operate intf --stats | grep 'out OAM' | awk -F' ' '{print$4}'")
end

function tminasm(self) -- TM In ASM Cells
	return sys.exec("xtmctl operate intf --stats | grep 'in ASM' | awk -F' ' '{print$4}'")
end

function tmoutasm(self) -- TM Out ASM Cells
	return sys.exec("xtmctl operate intf --stats | grep 'out ASM' | awk -F' ' '{print$4}'")
end

function tminpackerr(self) -- TM In Packet Errors
	return sys.exec("xtmctl operate intf --stats | grep 'in packet errors' | awk -F' ' '{print$4}'")
end

function tmincellerr(self) -- TM In Cell Errors
	return sys.exec("xtmctl operate intf --stats | grep 'in cell errors' | awk -F' ' '{print$4}'")
end

function dslmode(self) -- DSL Mode
	return sys.exec("xdslctl info --stats | grep 'Mode:' | awk -F' ' '{print$2}'")
end

function dsltraffic(self) -- DSL Traffic Type
	return sys.exec("xdslctl info --stats | grep 'TPS-TC' | awk -F' ' '{print$2}'")
end

function dslstatus(self) -- DSL Status
	return sys.exec("xdslctl info --stats | grep 'Status:' | sed -n 1p | awk -F' ' '{print$2}'")
end

function dsllps(self) -- DSL Link Power State
	return sys.exec("xdslctl info --stats | grep 'Link Power State' | awk -F' ' '{print$4}'")
end

function dsltrellis(self, w) -- DSL Line Coding
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'Trellis:' | awk -F'/' '{print$2}' | awk -F':' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'Trellis:' | awk -F' ' '{print$2}' | awk -F':' '{print$2}'")
	end
end

function dslsnr(self, w) -- DSL SNR Margin
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'SNR' | awk -F' ' '{print$3}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'SNR' | awk -F' ' '{print$4}'")
	end
end

function dslatten(self, w) -- DSL Attenuation
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'Attn(dB)' | awk -F' ' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'Attn(dB)' | awk -F' ' '{print$3}'")
	end
end

function dslopwr(self, w) -- DSL Output Power
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'Pwr(dBm)' | awk -F' ' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'Pwr(dBm)' | awk -F' ' '{print$3}'")
	end
end

function dslarate(self, w) -- DSL Attainable Rate
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'Max:' | awk -F'Downstream' '{print$2}' | awk -F' ' '{print$3}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'Max:' | awk -F'Upstream rate =' '{print$2}' | awk -F' ' '{print$1}'")
	end
end

function dslrate(self, w) -- DSL Rate
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'Bearer:' | awk -F'Downstream' '{print$2}' | awk -F' ' '{print$3}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'Bearer:' | awk -F'Upstream rate =' '{print$2}' | awk -F' ' '{print$1}'")
	end
end

function dslmsgc(self, w) -- DSL MSGc
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'MSGc' | awk -F' ' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'MSGc' | awk -F' ' '{print$3}'")
	end
end

function dslB(self, w) -- DSL B
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'B:' | awk -F' ' '{print$2}' | sed -n 1p")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'B:' | awk -F' ' '{print$3}' | sed -n 1p")
	end
end

function dslM(self, w) -- DSL M
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'M:' | awk -F' ' '{print$2}' | sed -n 1p")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'M:' | awk -F' ' '{print$3}' | sed -n 1p")
	end
end

function dslT(self, w) -- DSL T
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'T:' | awk -F' ' '{print$2}' | sed -n 1p")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'T:' | awk -F' ' '{print$3}' | sed -n 1p")
	end
end

function dslR(self, w) -- DSL R
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'R:' | awk -F' ' '{print$2}' | sed -n 1p")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'R:' | awk -F' ' '{print$3}' | sed -n 1p")
	end
end

function dslS(self, w) -- DSL S
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'S:' | awk -F' ' '{print$2}' | sed -n 1p")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'S:' | awk -F' ' '{print$3}' | sed -n 1p")
	end
end

function dslL(self, w) -- DSL L
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'L:' | awk -F' ' '{print$2}' | sed -n 1p")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'L:' | awk -F' ' '{print$3}' | sed -n 1p")
	end
end

function dslD(self, w) -- DSL D
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'D:' | awk -F' ' '{print$2}' | sed -n 2p")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'D:' | awk -F' ' '{print$3}' | sed -n 2p")
	end
end

function dsldelay(self, w) -- DSL Delay
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'delay:' | awk -F' ' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'delay:' | awk -F' ' '{print$3}'")
	end
end

function dslinp(self, w) -- DSL INP
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'INP:' | awk -F' ' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'INP:' | awk -F' ' '{print$3}'")
	end
end

function dslsprframe(self, w) -- DSL Super Frames
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'SF:' | awk -F' ' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'SF:' | awk -F' ' '{print$3}'")
	end
end

function dslsprframerr(self, w) -- DSL Super Frame Errors
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'SFErr:' | awk -F' ' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'SFErr:' | awk -F' ' '{print$3}'")
	end
end

function dslrsw(self, w) -- DSL RS Words
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'RS:' | awk -F' ' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'RS:' | awk -F' ' '{print$3}'")
	end
end

function dslrsce(self, w) -- DSL RS Correctable Errors
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'RSCorr:' | awk -F' ' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'RSCorr:' | awk -F' ' '{print$3}'")
	end
end

function dslrsue(self, w) -- DSL RS Uncorrectable Errors
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'RSUnCorr:' | awk -F' ' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'RSUnCorr:' | awk -F' ' '{print$3}'")
	end
end

function dslhec(self, w) -- DSL HEC Errors
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'HEC:' | awk -F' ' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'HEC:' | awk -F' ' '{print$3}'")
	end
end

function dslocd(self, w) -- DSL OCD Errors
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'OCD:' | awk -F' ' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'OCD:' | awk -F' ' '{print$3}'")
	end
end

function dsllcd(self, w) -- DSL LCD Errors
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'LCD:' | awk -F' ' '{print$2}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'LCD:' | awk -F' ' '{print$3}'")
	end
end

function dsltcells(self, w) -- DSL Total Cells
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'Total Cells:' | awk -F' ' '{print$3}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'Total Cells:' | awk -F' ' '{print$4}'")
	end
end

function dsldcells(self, w) -- DSL Data Cells
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'Data Cells:' | awk -F' ' '{print$3}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'Data Cells:' | awk -F' ' '{print$4}'")
	end
end

function dslberrs(self, w) -- DSL Bit Errors
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'Bit Errors:' | awk -F' ' '{print$3}'")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'Bit Errors:' | awk -F' ' '{print$4}'")
	end
end

function dsltes(self, w) -- DSL Total ES
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'ES:' | awk -F' ' '{print$2}' | sed -n 1p")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'ES:' | awk -F' ' '{print$3}' | sed -n 1p")
	end
end

function dsltses(self, w) -- DSL Total SES
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'SES:' | awk -F' ' '{print$2}' | sed -n 1p")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'SES:' | awk -F' ' '{print$3}' | sed -n 1p")
	end
end

function dsltuas(self, w) -- DSL Total UAS
	if w == 0 then
		return sys.exec("xdslctl info --stats | grep 'UAS:' | awk -F' ' '{print$2}' | sed -n 1p")
	elseif w == 1 then
		return sys.exec("xdslctl info --stats | grep 'UAS:' | awk -F' ' '{print$3}' | sed -n 1p")
	end
end

function bertstatus(self) -- BERT Status
	local sta = tonumber(sys.exec("xdslctl bert --show | grep -c 'NOT'"))
	local tot = tonumber(sys.exec("xdslctl bert --show | grep 'Total Time' | awk -F' ' '{print$5}'"))
	local elp = tonumber(sys.exec("xdslctl bert --show | grep 'Elapsed Time' | awk -F' ' '{print$5}'"))
	if tot == 0 and elp == 0 then
		return "NOT STARTED"
	elseif tot == elp then
		return "FINISHED"
	elseif sta == 0 then
		return "RUNNING"
	else
		return "STOPPED"	
	end
end

function berttotal(self) -- BERT Total Time
	return "%d seconds" %sys.exec("xdslctl bert --show | grep 'Total Time' | awk -F' ' '{print$5}'")
end

function bertelapsed(self) -- BERT Elapsed Time
	return "%d seconds" %sys.exec("xdslctl bert --show | grep 'Elapsed Time' | awk -F' ' '{print$5}'")
end

function berttested(self) -- BERT Tested Bits
	return sys.exec("xdslctl bert --show | grep 'Bits Tested' | awk -F' ' '{print$5}'")
end

function berterror(self) -- BERT Error Bits
	return sys.exec("xdslctl bert --show | grep 'Err Bits' | awk -F' ' '{print$5}'")
end
