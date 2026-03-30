--!strict

--[[
Script / Plugin.luau
]]

local TrackerUtils = require(script.Parent.TrackerUtils)
local UIFactory = require(script.Parent.UIFactory)

local toolbar = plugin:CreateToolbar("Fox Jet Studios's Plugins")
local button = toolbar:CreateButton(
	"Event Tracker",
	"View and manage all your experience's events",
	"rbxassetid://95011315458887"
)
local ui = UIFactory.CreateMainWidget(plugin)
local widget = ui.Widget
local scrollFrame = ui.ScrollFrame


local SUPPORTED_EVTCL = {UnreliableRemoteEvent = true,RemoteEvent = true,BindableEvent = true,}
local currentData = {}
local currentScroller = nil
local analysisToken = nil

local function hasUnusedEvnts()
	for _, d in ipairs(currentData) do
		if d.References and d.References.Fired == 0 and d.References.Listened == 0 then
			return true
		end
	end
	return false
end

local function MakeActions(onDelete)
	return {
		onDeleted = function(removedIdx)
			if removedIdx then table.remove(currentData, removedIdx) end
			if onDelete then
				onDelete()
			elseif currentScroller then
				currentScroller.Refresh(currentData)
			end
			ui.EmptyState.Visible = (#currentData == 0)
			ui.UpdateCleanupVisibility(hasUnusedEvnts())
		end,
		onSelect = function(evData)
			game:GetService("Selection"):Set({evData.Instance})
		end,
		onViewCode = function(evData)
			UIFactory.ShowCodeWindow(plugin, ui.Root, evData)
		end,
	}
end

local function RefreshList(filter)
	if analysisToken then
		analysisToken.cancelled = true
		analysisToken = nil
	end

	TrackerUtils.invalidatepluginCache()

	local lowerFilter = filter and filter ~= "" and string.lower(filter) or nil
	local stubs = {}

	for _, desc in ipairs(game:GetDescendants()) do
		if SUPPORTED_EVTCL[desc.ClassName] then
			local name = desc.Name
			local path = desc:GetFullName()
			local passes = true
			if lowerFilter then
				passes = string.find(string.lower(name), lowerFilter, 1, true)
					or string.find(string.lower(path), lowerFilter, 1, true)
			end
			if passes then
				table.insert(stubs, {
					Instance = desc,
					Name = name,
					Type = desc.ClassName,
					Path = path,
					References = nil,
					Locations = nil,
				})
			end
		end
	end

	currentData = stubs
	ui.EmptyState.Visible = (#currentData == 0)
	ui.UpdateCleanupVisibility(false)

	local actions = MakeActions(function()
		RefreshList(ui.SearchBox.Text)
	end)

	if currentScroller then currentScroller.Destroy() end
	currentScroller = UIFactory.AttachVirtualScroll(scrollFrame, currentData, actions)

	if #currentData == 0 then return end

	local token = {cancelled = false}
	analysisToken = token

	task.defer(function()
		local bulkResults = TrackerUtils.bulkAnalyze(currentData, token)
		if token.cancelled then return end

		local foundUnused = false
		for i, entry in ipairs(currentData) do
			if token.cancelled then return end
			local res = bulkResults[i]
			if res then
				entry.References = res.Stats
				entry.Locations = res.Locations
				if res.Stats.Fired == 0 and res.Stats.Listened == 0 then
					foundUnused = true
				end
				if currentScroller then
					currentScroller.UpdateCard(i, entry)
				end
			end
			if i % 20 == 0 then
				task.wait()
				if token.cancelled then return end
			end
		end

		if not token.cancelled then
			ui.UpdateCleanupVisibility(foundUnused)
		end
	end)
end

ui.CleanupButton.MouseButton1Click:Connect(function()
	UIFactory.ShowCleanupWindow(ui.Root, currentData, function()
		RefreshList(ui.SearchBox.Text)
	end)
end)
ui.RefreshButton.MouseButton1Click:Connect(function()
	RefreshList(ui.SearchBox.Text)
end)

local searchDebounce = false
ui.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if searchDebounce then return end
	searchDebounce = true
	task.delay(0.25, function()
		searchDebounce = false
		RefreshList(ui.SearchBox.Text)
	end)
end)
button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	if widget.Enabled then RefreshList() end
end)