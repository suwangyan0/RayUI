local R, L, P = unpack(select(2, ...)) --Inport: Engine, Locales, ProfileDB
local IF = R:GetModule("InfoBar")

local function LoadMemory()
	local infobar = _G["RayUITopInfoBar3"]
	local Status = infobar.Status
	infobar.Text:SetText("0 MB")

	local int, int2 = 6, 5
	local bandwidthString = "%.2f Mbps"
	local percentageString = "%.2f%%"
	local homeLatencyString = "%d ms"
	local kiloByteString = "%d KB"
	local megaByteString = "%.2f MB"
	local enteredFrame = false

	if Is64BitClient() then
		Status:SetMinMaxValues(0,15000)
	else
		Status:SetMinMaxValues(0,10000)
	end

	local function formatMem(memory)
		local mult = 10^1
		if memory > 999 then
			local mem = ((memory/1024) * mult) / mult
			return string.format(megaByteString, mem)
		else
			local mem = (memory * mult) / mult
			return string.format(kiloByteString, mem)
		end
	end

	local memoryTable = {}
	local cpuTable = {}

	local function RebuildAddonList(self)
		local addOnCount = GetNumAddOns()
		if (addOnCount == #memoryTable) then return end
		memoryTable = {}
		cpuTable = {}
		for i = 1, addOnCount do
			memoryTable[i] = { i, select(2, GetAddOnInfo(i)), 0, IsAddOnLoaded(i) }
			cpuTable[i] = { i, select(2, GetAddOnInfo(i)), 0, IsAddOnLoaded(i) }
		end
		self:SetAllPoints(infobar)
	end

	local function UpdateMemory()
		UpdateAddOnMemoryUsage()
		local addOnMem = 0
		local totalMemory = 0
		for i = 1, #memoryTable do
			addOnMem = GetAddOnMemoryUsage(memoryTable[i][1])
			memoryTable[i][3] = addOnMem
			totalMemory = totalMemory + addOnMem
		end
		table.sort(memoryTable, function(a, b)
			if a and b then
				return a[3] > b[3]
			end
		end)
		return totalMemory
	end

	local function UpdateCPU()
		UpdateAddOnCPUUsage()
		local addOnCPU = 0
		local totalCPU = 0
		for i = 1, #cpuTable do
			addOnCPU = GetAddOnCPUUsage(cpuTable[i][1])
			cpuTable[i][3] = addOnCPU
			totalCPU = totalCPU + addOnCPU
		end
		table.sort(cpuTable, function(a, b)
			if a and b then
				return a[3] > b[3]
			end
		end)
		return totalCPU
	end

	local function OnEnter(self)
		enteredFrame = true
		local bandwidth = GetAvailableBandwidth()
		local home_latency = select(3, GetNetStats())
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, 0)
		GameTooltip:ClearLines()

		if bandwidth ~= 0 then
			GameTooltip:AddDoubleLine(L["带宽"]..": " , string.format(bandwidthString, bandwidth),0.69, 0.31, 0.31,0.84, 0.75, 0.65)
			GameTooltip:AddDoubleLine(L["下载"]..": " , string.format(percentageString, GetDownloadedPercentage() *100),0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
			GameTooltip:AddLine(" ")
		end
		if IsAltKeyDown() then
			local totalCPU = UpdateCPU()
			GameTooltip:AddDoubleLine(L["总CPU使用"]..": ",  format("%dms", totalCPU), 0.69, 0.31, 0.31,0.84, 0.75, 0.65)
			GameTooltip:AddLine(" ")
			for i = 1, #cpuTable do
				if (cpuTable[i][4]) then
					local red = cpuTable[i][3] / totalCPU
					local green = 1 - red
					GameTooltip:AddDoubleLine(cpuTable[i][2], format("%dms", cpuTable[i][3]), 1, 1, 1, red, green + .5, 0)
				end
			end
		else
			local totalMemory = UpdateMemory()
			GameTooltip:AddDoubleLine(L["总内存使用"]..": ", formatMem(totalMemory), 0.69, 0.31, 0.31,0.84, 0.75, 0.65)
			GameTooltip:AddLine(" ")
			for i = 1, #memoryTable do
				if (memoryTable[i][4]) then
					local red = memoryTable[i][3] / totalMemory
					local green = 1 - red
					GameTooltip:AddDoubleLine(memoryTable[i][2], formatMem(memoryTable[i][3]), 1, 1, 1, red, green + .5, 0)
				end
			end
		end
		GameTooltip:Show()
	end

	local function OnLeave()
		enteredFrame = false
		GameTooltip_Hide()
	end

	local function OnUpdate(self, t)
		int = int - t
		int2 = int2 - t

		if int < 0 then
			RebuildAddonList(self)
			local total = UpdateMemory()
			infobar.Text:SetText(formatMem(total))
			Status:SetValue(total)
			local r, g, b = R:ColorGradient(total/10000, IF.InfoBarStatusColor[3][1], IF.InfoBarStatusColor[3][2], IF.InfoBarStatusColor[3][3], 
																	IF.InfoBarStatusColor[2][1], IF.InfoBarStatusColor[2][2], IF.InfoBarStatusColor[2][3],
																	IF.InfoBarStatusColor[1][1], IF.InfoBarStatusColor[1][2], IF.InfoBarStatusColor[1][3])
			Status:SetStatusBarColor(r, g, b)
			int = 10
		end
		if int2 < 0 then
			if enteredFrame then
				OnEnter(self)
			end
			int2 = 1
		end
	end

	Status:SetScript("OnMouseDown", function(self)
		UpdateAddOnMemoryUsage()
		local before = gcinfo()
		collectgarbage()
		UpdateAddOnMemoryUsage()
		R:Print(L["共释放内存"], formatMem(before - gcinfo()))
	end)
	Status:SetScript("OnUpdate", OnUpdate)
	Status:SetScript("OnEnter", OnEnter)
	Status:SetScript("OnLeave", OnLeave)

	hooksecurefunc("collectgarbage", function() OnUpdate(Status, 10) end)
end

IF:RegisterInfoText("Memory", LoadMemory)