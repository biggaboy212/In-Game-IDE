--[[
@ author biggaboy212
@ description Tab switcher for my Editor module.

	* Notes
		To make your own Tab Button Design, make sure the item named 'Tab' is a [TextButton, ImageButton] and is parented directly under this module, also you must have the following elements in the 'Tab' Button
		[-] 'Elements' GuiObject
			[-] 'Close' TextButton, ImageButton
			[-] 'Title' TextObject
		[-] 'ToggledIndicator' GuiObject
		
	* Updates
		[+] Added tab rename (visual only, the tab instances won't be updated and will keep the original name for simplicity)
]]

local TweenService = game:GetService('TweenService')

local TabModule = {}

-- Variables
local currentTabIndex = -1
local activeTab = nil
local tabInstances = {}
local tabTextContent = {}

local TweenSettings = {
	Style = Enum.EasingStyle.Linear,
	HoverTime = 0.15,
	ClickTime = 0.1,
	ToggledTransparency = 0.92,
	DefaultTransparency = 1,
	HoverTransparency = 0.97
}

local function tweenProperties(instance, time, properties)
	TweenService:Create(instance, TweenInfo.new(time, TweenSettings.Style, Enum.EasingDirection.InOut), properties):Play()
end

local function generateUniqueTabName(baseName)
	local uniqueName = baseName
	local counter = 1
	local nameExists
	repeat
		nameExists = false
		for _, tab in pairs(tabInstances) do
			if tab.Elements.Title.Text == uniqueName then
				nameExists = true
				uniqueName = baseName .. " (" .. counter .. ")"
				counter = counter + 1
				break
			end
		end
	until not nameExists
	return uniqueName
end

local function updateTabVisuals(selectedTab)
	local uniqueName = nil
	for _, tab in pairs(tabInstances) do
		local isSelected = (tab == selectedTab)
		tweenProperties(tab, TweenSettings.ClickTime, {BackgroundTransparency = isSelected and TweenSettings.ToggledTransparency or TweenSettings.DefaultTransparency})
		if tab.ToggledIndicator then
			tab.ToggledIndicator.Visible = isSelected
		end
		if isSelected then
			uniqueName = tab.Name
		end
	end
	return uniqueName
end

local function saveCurrentTabText(NewIDE)
	if activeTab then
		tabTextContent[activeTab.Name] = NewIDE:GetText()
	end
end

local function updateIDEVisibility(NewIDE: Instance)
	NewIDE.Gui.Visible = #tabInstances > 0 and activeTab ~= nil
end

function TabModule.AddTab(NewIDE, TabsContainer, presetText, Name)
	Name = Name or "Tab"
	saveCurrentTabText(NewIDE)

	currentTabIndex += 1
	local extension = "lua"
	local baseName = Name .. "." .. extension
	local uniqueName = generateUniqueTabName(baseName)

	local newTab = script.Tab:Clone()
	newTab.Parent = TabsContainer
	newTab.Name = uniqueName
	newTab.LayoutOrder = currentTabIndex
	table.insert(tabInstances, newTab)
	tabTextContent[uniqueName] = presetText or ""
	
	local Title = newTab.Elements.Title
	Title.Text = uniqueName

	newTab.Elements.Close.MouseButton1Click:Connect(function()
		currentTabIndex -= 1
		local tabIndex = table.find(tabInstances, newTab)
		table.remove(tabInstances, tabIndex)
		tabTextContent[uniqueName] = nil
		newTab:Destroy()

		if activeTab == newTab then
			activeTab = nil
			if tabIndex > 1 then
				local previousTab = tabInstances[tabIndex - 1]
				NewIDE:SetText(tabTextContent[previousTab.Name] or "")
				updateTabVisuals(previousTab)
				activeTab = previousTab
			elseif #tabInstances > 0 then
				local firstTab = tabInstances[1]
				NewIDE:SetText(tabTextContent[firstTab.Name] or "")
				updateTabVisuals(firstTab)
				activeTab = firstTab
			end
		end
		updateIDEVisibility(NewIDE)
	end)
	
	newTab.MouseButton2Click:Connect(function()
		if Title:IsA("TextBox") then
			Title:CaptureFocus()
		end
	end)
	
	if Title:IsA("TextBox") then
		Title.ClearTextOnFocus = false
		Title.Focused:Connect(function()
			Title.PlaceholderText = Title.Text
			Title.Text = ""
			Title.Active = true
			Title.Interactable = true
		end)
		
		Title.FocusLost:Connect(function()
			Title.Text = generateUniqueTabName(Title.Text .. "." .. extension)
			Title.Active = false
			Title.Interactable = false
		end)
	end

	local function Switch()
		saveCurrentTabText(NewIDE)
		NewIDE:SetText(tabTextContent[uniqueName] or "")
		updateTabVisuals(newTab)
		activeTab = newTab
		updateIDEVisibility(NewIDE)
		NewIDE:Refresh()
	end

	newTab.MouseButton1Click:Connect(Switch)
	
	Switch()
end

return TabModule
