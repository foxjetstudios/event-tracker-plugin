--!strict

--[[
Module script / TrackerUtils.luau
]]

local TrackerUtils = {}

local PATTERNS = {
	RemoteEvent = { fire = {"FireServer","FireClient","FireAllClients"}, listen = {"OnServerEvent","OnClientEvent"} },
	UnreliableRemoteEvent = { fire = {"FireServer","FireClient","FireAllClients"}, listen = {"OnServerEvent","OnClientEvent"} },
	BindableEvent = { fire = {"Fire"}, listen = {"Event"} },
}

for _, config in pairs(PATTERNS) do
	config.firePats = {}
	config.listenPats = {}
	for _, m in ipairs(config.fire) do table.insert(config.firePats, "[:%.]" .. m) end
	for _, m in ipairs(config.listen) do table.insert(config.listenPats, "[:%.]" .. m) end
end

local METHOD_HINTS = {
	"FireServer", "FireClient", "FireAllClients",
	"OnServerEvent", "OnClientEvent",
	":Fire(", ".Event",
}

local sourceCache = nil
local scriptSourceCache = {}
local resultCache = {}

local function ensureCache()
	if sourceCache then return end
	sourceCache = {}
	for _, desc in ipairs(game:GetDescendants()) do
		if desc:IsA("LuaSourceContainer") then
			table.insert(sourceCache, desc)
		end
	end
	game.DescendantAdded:Connect(function(d)
		if d:IsA("LuaSourceContainer") then
			table.insert(sourceCache, d)
		end
	end)
	game.DescendantRemoving:Connect(function(d)
		if d:IsA("LuaSourceContainer") then
			scriptSourceCache[d] = nil
			for i = #sourceCache, 1, -1 do
				if sourceCache[i] == d then table.remove(sourceCache, i); break end
			end
		end
	end)
end

local function getSource(desc)
	if scriptSourceCache[desc] ~= nil then return scriptSourceCache[desc] end
	local ok, src = pcall(function() return desc.Source end)
	src = ok and src or ""
	scriptSourceCache[desc] = src
	return src
end

local function getAncestorNames(instance)
	local names = {}
	local cur = instance.Parent
	while cur and cur ~= game do
		table.insert(names, cur.Name)
		cur = cur.Parent
	end
	return names
end

local function extractQualifierTokens(line, name)
	local before = line:match("(.+)%." .. name .. "%f[^%w_]")
	if not before then
		before = line:match('(.+)%[%s*"' .. name .. '"%s*%]')
	end
	if not before then
		before = line:match("(.+)%[%s*'" .. name .. "'%s*%]")
	end
	if not before then return {} end

	local tokens = {}
	for tok in before:gmatch('%[%s*"([^"]+)"%s*%]') do table.insert(tokens, tok) end
	for tok in before:gmatch("%[%s*'([^']+)'%s*%]") do table.insert(tokens, tok) end
	for tok in before:gmatch("[%w_]+") do table.insert(tokens, tok) end
	return tokens
end

local function buildSet(list)
	local s = {}
	for _, v in ipairs(list) do s[v] = true end
	return s
end

local function scoreAncestors(ancestors, tokenSet)
	local score = 0
	for _, a in ipairs(ancestors) do
		if tokenSet[a] then score += 1 else break end
	end
	return score
end

local function pickEntries(entries, tokenSet)
	if not tokenSet or #entries <= 1 then return entries end

	local best = 0
	for _, entry in ipairs(entries) do
		local s = scoreAncestors(entry.ancestors, tokenSet)
		if s > best then best = s end
	end

	if best == 0 then return entries end

	local winners = {}
	for _, entry in ipairs(entries) do
		if scoreAncestors(entry.ancestors, tokenSet) == best then
			table.insert(winners, entry)
		end
	end
	return winners
end

local function analyzeScript(source, desc, relevantNames, patCache, nameToEntries, results)
	local shadowed = {}
	local varName = {}
	local varQualTokens = {}

	for _, name in ipairs(relevantNames) do
		shadowed[name] = false
		varName[name] = nil
		for line in source:gmatch("([^\n]*)\n?") do
			local eq = line:find("=", 1, true)
			if eq then
				local lhs = line:sub(1, eq - 1):match("([%w_]+)%s*$")
				if lhs == name and not line:sub(eq + 1):find(patCache[name].strict) then
					shadowed[name] = true
					break
				end
			end
		end
	end

	local lineNum = 0
	for line in source:gmatch("([^\n]*)\n?") do
		lineNum += 1
		for _, name in ipairs(relevantNames) do
			local pats = patCache[name]
			local entries = nameToEntries[name]

			local cap = line:match(pats.assign)
			if cap and cap ~= "local" then
				varName[name] = cap
				varQualTokens[cap] = buildSet(extractQualifierTokens(line, name))
			end

			local target = varName[name] or (not shadowed[name] and name or nil)
			if not target then continue end
			if not line:find(target, 1, true) then continue end

			local targetPat = target == name and pats.strict or ("%f[%w]".. target .."%f[^%w]")
			if not line:find(targetPat) then continue end

			local tokenSet
			if target ~= name then
				tokenSet = varQualTokens[target]
			else
				tokenSet = buildSet(extractQualifierTokens(line, name))
			end

			local candidates = pickEntries(entries, tokenSet)

			for _, entry in ipairs(candidates) do
				local cfg = entry.config
				local isFire, isListen = false, false

				for mi, m in ipairs(cfg.fire) do
					if line:find(m, 1, true) and line:find(cfg.firePats[mi]) then
						isFire = true; break
					end
				end
				if not isFire then
					for mi, m in ipairs(cfg.listen) do
						if line:find(m, 1, true) and line:find(cfg.listenPats[mi]) then
							isListen = true; break
						end
					end
				end

				if isFire or isListen then
					local res = results[entry.idx]
					if isFire then res.Stats.Fired += 1 else res.Stats.Listened += 1 end
					table.insert(res.Locations, {
						Script = desc,
						Path = desc:GetFullName(),
						Line = lineNum,
						Type = isListen and "Listener" or "Fired",
						SourcePreview = line:match("^%s*(.-)%s*$"),
					})
				end
			end
		end
	end
end

function TrackerUtils.invalidatepluginCache()
	resultCache = {}
end

function TrackerUtils.bulkAnalyze(instanceList, cancelToken)
	if not instanceList or #instanceList == 0 then return {} end
	ensureCache()

	local nameToEntries = {}
	local results = {}

	for i, entry in ipairs(instanceList) do
		local config = PATTERNS[entry.Instance.ClassName]
		if not config then continue end
		local name = entry.Instance.Name
		if not nameToEntries[name] then nameToEntries[name] = {} end
		table.insert(nameToEntries[name], {
			idx = i,
			config = config,
			ancestors = getAncestorNames(entry.Instance),
		})
		results[i] = { Stats = { Fired = 0, Listened = 0 }, Locations = {} }
	end

	local patCache = {}
	for name in pairs(nameToEntries) do
		local strict = "%f[%w]" .. name .. "%f[^%w]"
		patCache[name] = { strict = strict, assign = "([%w_]+)%s*=%s*.-"..strict }
	end

	for si, desc in ipairs(sourceCache) do
		if cancelToken and cancelToken.cancelled then return results end

		local source = getSource(desc)
		if source ~= "" then
			local hasMethod = false
			for _, m in ipairs(METHOD_HINTS) do
				if source:find(m, 1, true) then hasMethod = true; break end
			end

			if hasMethod then
				local relevant = {}
				for name in pairs(nameToEntries) do
					if source:find(name, 1, true) then table.insert(relevant, name) end
				end
				if #relevant > 0 then
					analyzeScript(source, desc, relevant, patCache, nameToEntries, results)
				end
			end
		end

		if si % 25 == 0 then
			task.wait()
			if cancelToken and cancelToken.cancelled then return results end
		end
	end

	for i, entry in ipairs(instanceList) do
		if results[i] then
			resultCache[entry.Instance] = {
				Instance = entry.Instance,
				Stats = results[i].Stats,
				Locations = results[i].Locations,
			}
		end
	end

	return results
end

function TrackerUtils.GetListenersForInstance(targetInstance)
	if not targetInstance then return nil end
	if resultCache[targetInstance] then return resultCache[targetInstance] end
	local config = PATTERNS[targetInstance.ClassName]
	if not config then return nil end
	TrackerUtils.bulkAnalyze({{Instance = targetInstance}})
	return resultCache[targetInstance]
end

return TrackerUtils