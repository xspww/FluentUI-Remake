--[[
	Checks the parts of the window that can run outside Roblox.

	The tab module keeps the state of the tabs, so the checks here cover
	the selection of a tab.
]]

-- The tab module, with the parts that need Roblox taken out.
local TabModule = {}
TabModule.Tabs = {}
TabModule.Containers = {}
TabModule.SelectedTab = 0
TabModule.TabCount = 0

function TabModule:GetCurrentTabPos()
	local TabPos = self.Tabs[self.SelectedTab].Frame.AbsolutePosition.Y
	return TabPos
end

function TabModule:SelectTab(Tab)
	local Target = self.Tabs[Tab]
	if not Target then
		return
	end

	self.SelectedTab = Tab

	for _, TabObject in next, self.Tabs do
		TabObject.SetTransparency(1)
		TabObject.Selected = false
	end

	Target.SetTransparency(0.89)
	Target.Selected = true
end

-- A stand in for a tab.
local function makeTab(Name)
	return {
		Name = Name,
		Selected = false,
		Frame = { AbsolutePosition = { Y = 0 } },
		SetTransparency = function() end,
	}
end

return function()
	describe("the tab module", function()
		it("should select the tab that was asked for", function()
			TabModule.Tabs = { makeTab("First"), makeTab("Second") }
			TabModule.SelectedTab = 0

			TabModule:SelectTab(2)

			expect(TabModule.SelectedTab).to.equal(2)
			expect(TabModule.Tabs[2].Selected).to.equal(true)
			expect(TabModule.Tabs[1].Selected).to.equal(false)
		end)

		it("should ignore a tab that does not exist", function()
			TabModule.Tabs = { makeTab("First") }
			TabModule.SelectedTab = 0

			TabModule:SelectTab(5)

			-- The tab that was selected before stays selected.
			expect(TabModule.SelectedTab).to.equal(0)
		end)
	end)
end
