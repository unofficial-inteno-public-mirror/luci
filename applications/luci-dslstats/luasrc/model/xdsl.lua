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

function get_xtmstats()
	local xtm = sys.exec("xtmctl operate intf --stats")
	local rv = { }

	rv = {
		inoct = xtm:match("in octets%s+(%d+)") or 0,
		outoct = xtm:match("out octets%s+(%d+)") or 0,
		inpac = xtm:match("in packets%s+(%d+)") or 0,
		outpac = xtm:match("out packets%s+(%d+)") or 0,
		inoam = xtm:match("in OAM cells%s+(%d+)") or 0,
		outoam = xtm:match("out OAM cells%s+(%d+)") or 0,
		inasm = xtm:match("in ASM cells%s+(%d+)") or 0,
		outasm = xtm:match("out ASM cells%s+(%d+)") or 0,
		inperr = xtm:match("in packet errors%s+(%d+)") or 0,
		incerr = xtm:match("in cell errors%s+(%d+)") or 0
	}

	return rv
end

function get_xdslstats()
	local xdsl = sys.exec("xdslctl info --stats")
	local rv = { }

	rv = {
		mode	= xdsl:match("Mode:%s+(%S+)") or "",
		traffic	= xdsl:match("TPS%S+:%s+(%S+)%s+%S+") or "",
		status	= xdsl:match("Status:%s+(%S+)") or "",
		lps	= xdsl:match("Link Power State:%s+(%S+)") or "",
		trldn   = xdsl:match("Trellis:%s+%S+%s+/D:(%S+)%s+") or "",
		trlup   = xdsl:match("Trellis:%s+U:(%S+)%s+%S+") or "",
		snrdn   = xdsl:match("SNR%s+%S+%s+(%S+)%s+%S+") or 0,
		snrup   = xdsl:match("SNR%s+%S+%s+%S+%s+(%S+)") or 0,
		atndn   = xdsl:match("Attn%S+%s+(%S+)%s+%S+") or 0,
		atnup   = xdsl:match("Attn%S+%s+%S+%s+(%S+)") or 0,
		opwdn	= xdsl:match("Pwr%S+%s+(%S+)%s+%S+") or 0,
		opwup	= xdsl:match("Pwr%S+%s+%S+%s+(%S+)") or 0,
		artdn	= xdsl:match("Max:%s+%S+%s+%S+%s+%S+%s+%d+%s+%S+%s+Downstream rate = (%d+)%s+%S+") or 0,
		artup	= xdsl:match("Max:%s+Upstream rate = (%d+)%s+") or 0,
		rtedn	= xdsl:match("Bearer:%s+%d+%S+%s+%S+%s+%S+%s+%S+%s+%d+%s+%S+%s+Downstream rate = (%d+)%s+%S+") or 0,
		rteup	= xdsl:match("Bearer:%s+%d+%S+%s+Upstream rate = (%d+)%s+") or 0,
		msgdn   = xdsl:match("MSGc:%s+(%S+)%s+%S+") or 0,
		msgup   = xdsl:match("MSGc:%s+%S+%s+(%S+)") or 0,
		Bdn	= xdsl:match("B:%s+(%S+)%s+%S+") or 0,
		Bup	= xdsl:match("B:%s+%S+%s+(%S+)") or 0,
		Mdn	= xdsl:match("M:%s+(%S+)%s+%S+") or 0,
		Mup	= xdsl:match("M:%s+%S+%s+(%S+)") or 0,
		Tdn	= xdsl:match("T:%s+(%S+)%s+%S+") or 0,
		Tup	= xdsl:match("T:%s+%S+%s+(%S+)") or 0,
		Rdn	= xdsl:match("R:%s+(%S+)%s+%S+") or 0,
		Rup	= xdsl:match("R:%s+%S+%s+(%S+)") or 0,
		Sdn	= xdsl:match("S:%s+(%S+)%s+%S+") or 0,
		Sup	= xdsl:match("S:%s+%S+%s+(%S+)") or 0,
		Ldn	= xdsl:match("L:%s+(%S+)%s+%S+") or 0,
		Lup	= xdsl:match("L:%s+%S+%s+(%S+)") or 0,
		Ddn	= xdsl:match("D:%s+(%S+)%s+%S+") or 0,
		Dup	= xdsl:match("D:%s+%S+%s+(%S+)") or 0,
		dlydn	= xdsl:match("delay:%s+(%S+)%s+%S+") or 0,
		dlyup	= xdsl:match("delay:%s+%S+%s+(%S+)") or 0,
		inpdn	= xdsl:match("INP:%s+(%S+)%s+%S+") or 0,
		inpup	= xdsl:match("INP:%s+%S+%s+(%S+)") or 0,
		frmdn	= xdsl:match("SF:%s+(%S+)%s+%S+") or 0,
		frmup	= xdsl:match("SF:%s+%S+%s+(%S+)") or 0,
		sprdn	= xdsl:match("SFErr:%s+(%S+)%s+%S+") or 0,
		sprup	= xdsl:match("SFErr:%s+%S+%s+(%S+)") or 0,
		rswdn	= xdsl:match("RS:%s+(%S+)%s+%S+") or 0,
		rswup	= xdsl:match("RS:%s+%S+%s+(%S+)") or 0,
		rscdn	= xdsl:match("RSCorr:%s+(%S+)%s+%S+") or 0,
		rscup	= xdsl:match("RSCorr:%s+%S+%s+(%S+)") or 0,
		rsudn	= xdsl:match("RSUnCorr:%s+(%S+)%s+%S+") or 0,
		rsuup	= xdsl:match("RSUnCorr:%s+%S+%s+(%S+)") or 0,
		hecdn	= xdsl:match("HEC:%s+(%S+)%s+%S+") or 0,
		hecup	= xdsl:match("HEC:%s+%S+%s+(%S+)") or 0,
		ocddn	= xdsl:match("OCD:%s+(%S+)%s+%S+") or 0,
		ocdup	= xdsl:match("OCD:%s+%S+%s+(%S+)") or 0,
		lcddn	= xdsl:match("LCD:%s+(%S+)%s+%S+") or 0,
		lcdup	= xdsl:match("LCD:%s+%S+%s+(%S+)") or 0,
		tcldn	= xdsl:match("Total Cells:%s+(%S+)%s+%S+") or 0,
		tclup	= xdsl:match("Total Cells:%s+%S+%s+(%S+)") or 0,
		dcldn	= xdsl:match("Data Cells:%s+(%S+)%s+%S+") or 0,
		dclup	= xdsl:match("Data Cells:%s+%S+%s+(%S+)") or 0,
		berdn	= xdsl:match("Bit Errors:%s+(%S+)%s+%S+") or 0,
		berup	= xdsl:match("Bit Errors:%s+%S+%s+(%S+)") or 0,
		tesdn	= xdsl:match("ES:%s+(%S+)%s+%S+") or 0,
		tesup	= xdsl:match("ES:%s+%S+%s+(%S+)") or 0,
		tssdn	= xdsl:match("SES:%s+(%S+)%s+%S+") or 0,
		tssup	= xdsl:match("SES:%s+%S+%s+(%S+)") or 0,
		tuadn	= xdsl:match("UAS:%s+(%S+)%s+%S+") or 0,
		tuaup	= xdsl:match("UAS:%s+%S+%s+(%S+)") or 0
	}

	return rv
end

function get_bertstats()
	local bert = sys.exec("xdslctl bert --show")
	local st, status, total, elapsed, tested, errored
	local rv = { }

	sta = bert:match("BERT Status = (%S+)") or ""
	total = tonumber(bert:match("BERT Total Time   = (%d+) sec")) or 0
	elapsed = tonumber(bert:match("BERT Elapsed Time = (%d+) sec")) or 0
	tested = bert:match("BERT Bits Tested = (%S+) bits") or 0
	errored = bert:match("BERT Err Bits = (%S+) bits") or 0

	if total == 0 and elapsed == 0 then
		status = "NOT STARTED"
	elseif total == elapsed then
		status = "FINISHED"
	elseif sta == "RUNNING" then
		status = "RUNNING"
	else
		status = "STOPPED"	
	end

	rv = {
		status	= status,
		total	= total,
		elapsed	= elapsed,
		tested	= tested,
		errored	= errored
	}

	return rv
end
