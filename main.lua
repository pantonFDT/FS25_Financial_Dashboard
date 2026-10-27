FinancialDashboard = { modDir = g_currentModDirectory or "", registered = false, attempts = 0 }
local FD = FinancialDashboard
print("[FinancialDashboard] Phase 12.9 Lua loaded")
source(FD.modDir .. "scripts/FinancialDashboardFrame.lua")
function FD:registerMenu()
    if self.registered then return true end
    if g_gui == nil or g_gui.screenControllers == nil or InGameMenu == nil then return false end
    local menu = g_gui.screenControllers[InGameMenu]
    if menu == nil or menu.pagingElement == nil or menu.registerPage == nil or menu.addPageTab == nil then return false end
    if menu.pageFinancialDashboard ~= nil then
        self.registered = true
        return true
    end
    local frame = FinancialDashboardFrame.new()
    g_gui:loadGui(self.modDir .. "gui/FinancialDashboardFrame.xml", "FinancialDashboardFrame", frame, true)
    if menu.controlIDs ~= nil then menu.controlIDs.pageFinancialDashboard = nil end
    menu.pageFinancialDashboard = frame
    menu.pagingElement:addElement(frame)
    menu:exposeControlsAsFields("pageFinancialDashboard")
    menu.pagingElement:updateAbsolutePosition()
    menu.pagingElement:updatePageMapping()
    local pos = #menu.pagingElement.elements
    for i, element in ipairs(menu.pagingElement.elements) do
        if element == frame then pos = i break end
    end
    menu:registerPage(frame, pos, function() return true end)
    menu:addPageTab(frame, Utils.getFilename("images/menuIcon.dds", self.modDir), GuiUtils.getUVs({0,0,1024,1024}))
    menu:rebuildTabList()
    self.registered = true
    print("[FinancialDashboard] Phase 12 MENU REGISTERED")
    return true
end
-- v1.1 alpha: compact per-day aggregates and bounded balance samples.
-- Observed changes are estimates, not transaction-classified accounting.
FD.maxSamples = 500
FD.windowDays = 365
FD.persistInterval = 30000
local function safeDay(m)
    return m and m.environment and tonumber(m.environment.currentDay)
end
local function safeBalance(m)
    return m and m.getMoney and tonumber(m:getMoney())
end
function FD:getSavePath()
    local m = g_currentMission
    local info = m and m.missionInfo
    local dir = info and info.savegameDirectory
    if type(dir) ~= "string" or dir == "" then
        local slot = info and tonumber(info.savegameIndex)
        if slot ~= nil and slot > 0 and type(getUserProfileAppPath) == "function" then
            local root = getUserProfileAppPath()
            if type(root) == "string" and root ~= "" then
                dir = root .. "savegame" .. tostring(math.floor(slot))
            end
        end
    end
    if type(dir) ~= "string" or dir == "" then
        if not self.pathWarningShown then
            print("[FinancialDashboard] Persistence WARNING: cannot resolve savegame directory (savegameIndex=" .. tostring(info and info.savegameIndex) .. ")")
            self.pathWarningShown = true
        end
        return nil
    end
    return dir .. "/financialDashboard.xml"
end
function FD:initializeBaseline()
    if self.baselineInitialized then return end
    local m = g_currentMission
    local day, money = safeDay(m), safeBalance(m)
    if day == nil or money == nil then return end
    self.history = {{day=day,balance=money,delta=0}}
    self.daily = self.daily or {}
    self.daily[day] = self.daily[day] or {income=0,outflow=0,changes=0,opening=money,closing=money}
    self.baselineInitialized = true
    self.dirty = true
    print("[FinancialDashboard] Tracking initialized on loaded farm")
end
function FD:loadHistory()
    local path = self:getSavePath()
    if path == nil or type(fileExists) ~= "function" or not fileExists(path) or type(loadXMLFile) ~= "function" then
        print("[FinancialDashboard] No readable history XML at " .. tostring(path))
        return false
    end
    local xml = loadXMLFile("financialDashboardHistory", path)
    if xml == nil or xml == 0 then return false end
    local ok, result = pcall(function()
        local version = getXMLInt(xml,"financialDashboard#version")
        if version ~= 1 then return false end
        local farmId = getXMLInt(xml,"financialDashboard#farmId")
        local m = g_currentMission
        if m == nil then return false end
        local currentFarmId = m.player and m.player.farmId or 0
        if farmId ~= currentFarmId then
            print("[FinancialDashboard] History farm ID mismatch: saved=" .. tostring(farmId) .. " current=" .. tostring(currentFarmId))
            return false
        end
        local day, money = safeDay(m), safeBalance(m)
        if day == nil or money == nil then return false end
        local savedDay = getXMLInt(xml,"financialDashboard#lastDay")
        if savedDay == nil or savedDay > day then return false end
        local history, daily = {}, {}
        for i=0,499 do
            local k="financialDashboard.samples.sample("..i..")"
            local d=getXMLInt(xml,k.."#day")
            if d == nil then break end
            local bal=getXMLFloat(xml,k.."#balance")
            local delta=getXMLFloat(xml,k.."#delta")
            if bal ~= nil and delta ~= nil and d <= day then history[#history+1]={day=d,balance=bal,delta=delta} end
        end
        for i=0,365 do
            local k="financialDashboard.days.day("..i..")"
            local d=getXMLInt(xml,k.."#number")
            if d == nil then break end
            if d <= day then
                daily[d]={income=getXMLFloat(xml,k.."#income") or 0,outflow=getXMLFloat(xml,k.."#outflow") or 0,changes=getXMLInt(xml,k.."#changes") or 0,opening=getXMLFloat(xml,k.."#opening") or 0,closing=getXMLFloat(xml,k.."#closing") or 0}
            end
        end
        if #history == 0 then return false end
        self.history,self.daily=history,daily
        self.baselineInitialized=true
        -- Treat changes while the game was closed as unknown; do not invent revenue.
        if history[#history].day ~= day or history[#history].balance ~= money then
            history[#history+1]={day=day,balance=money,delta=0}
            daily[day]=daily[day] or {income=0,outflow=0,changes=0,opening=money,closing=money}
        end
        return true
    end)
    if type(delete) == "function" then delete(xml) elseif type(deleteXMLFile)=="function" then deleteXMLFile(xml) end
    if not ok then print("[FinancialDashboard] History load failed: "..tostring(result))
    elseif not result then print("[FinancialDashboard] History XML rejected (version, farm, day or sample validation)") end
    return ok and result
end
function FD:saveHistory(force, directory)
    if not self.baselineInitialized then
        print("[FinancialDashboard] Persistence: save skipped; baseline not initialized")
        return
    end
    if not force and not self.dirty then return end
    local path = (type(directory) == "string" and directory ~= "") and (directory .. "/financialDashboard.xml") or self:getSavePath()
    if path == nil then return end
    if type(createXMLFile) ~= "function" or type(saveXMLFile) ~= "function" then
        if not self.xmlWarningShown then
            print("[FinancialDashboard] Persistence ERROR: XML writer functions unavailable")
            self.xmlWarningShown = true
        end
        return
    end
    local m=g_currentMission
    local farmId=m and m.player and m.player.farmId or 0
    local ok,err=pcall(function()
        local xml=createXMLFile("financialDashboardHistory",path,"financialDashboard")
        if xml == nil or xml == 0 then error("createXMLFile returned no XML handle: " .. tostring(path)) end
        setXMLInt(xml,"financialDashboard#version",1)
        setXMLInt(xml,"financialDashboard#farmId",farmId)
        setXMLInt(xml,"financialDashboard#lastDay",safeDay(m) or 0)
        for i,s in ipairs(self.history or {}) do
            local k="financialDashboard.samples.sample("..(i-1)..")"
            setXMLInt(xml,k.."#day",s.day)
            setXMLFloat(xml,k.."#balance",s.balance)
            setXMLFloat(xml,k.."#delta",s.delta or 0)
        end
        local days={}
        for d in pairs(self.daily or {}) do days[#days+1]=d end
        table.sort(days)
        for i,d in ipairs(days) do
            local s=self.daily[d]
            local k="financialDashboard.days.day("..(i-1)..")"
            setXMLInt(xml,k.."#number",d)
            setXMLFloat(xml,k.."#income",s.income or 0)
            setXMLFloat(xml,k.."#outflow",s.outflow or 0)
            setXMLInt(xml,k.."#changes",s.changes or 0)
            setXMLFloat(xml,k.."#opening",s.opening or 0)
            setXMLFloat(xml,k.."#closing",s.closing or 0)
        end
        saveXMLFile(xml)
        if type(fileExists) == "function" and not fileExists(path) then
            error("XML file was not created: " .. tostring(path))
        end
        print("[FinancialDashboard] History saved to " .. tostring(path))
        if type(delete)=="function" then delete(xml) elseif type(deleteXMLFile)=="function" then deleteXMLFile(xml) end
        self.dirty=false
    end)
    if not ok then print("[FinancialDashboard] History save failed: "..tostring(err)) end
end
function FD:recordBalance()
    if not self.baselineInitialized then self:initializeBaseline() end
    if not self.baselineInitialized then return end
    local m=g_currentMission
    local day,money=safeDay(m),safeBalance(m)
    if day == nil or money == nil then return end
    local history=self.history
    local last=history[#history]
    if last == nil then return end
    if day < last.day then
        self.history={};self.daily={};self.baselineInitialized=false
        self:initializeBaseline();return
    end
    if day==last.day and money==last.balance then return end
    local delta=money-last.balance
    local rec=self.daily[day]
    if rec == nil then
        rec={income=0,outflow=0,changes=0,opening=last.balance,closing=money}
        self.daily[day]=rec
    end
    if delta>0 then rec.income=rec.income+delta elseif delta<0 then rec.outflow=rec.outflow-delta end
    if delta~=0 then rec.changes=rec.changes+1 end
    rec.closing=money
    history[#history+1]={day=day,balance=money,delta=delta}
    while #history>self.maxSamples do table.remove(history,2) end
    for d in pairs(self.daily) do if day-d>=self.windowDays then self.daily[d]=nil end end
    self.dirty=true
end
function FD:loadMap(name)
    self.registered=false;self.attempts=0;self.registrationFailed=false
    self.history={};self.daily={};self.baselineInitialized=false
    self.sampleElapsed=0;self.persistElapsed=0;self.dirty=false
    self.loadedSave=false;self.pathWarningShown=false;self.xmlWarningShown=false;self.farmWarningShown=false
    self:tryRegister()
end
function FD:tryRegister()
    if self.registered then return end
    self.attempts = self.attempts + 1
    local ok, result = pcall(self.registerMenu, self)
    if not ok then
        print("[FinancialDashboard] Phase 12 registration ERROR: " .. tostring(result))
        self.registrationFailed = true
    elseif result then
        print("[FinancialDashboard] Phase 12 registration SUCCESS")
    elseif self.attempts == 1 then
        print("[FinancialDashboard] Phase 12 waiting for in-game menu")
    end
end
function FD:update(dt)
    if not self.loadedSave then
        local m=g_currentMission
        if safeDay(m) ~= nil and safeBalance(m) ~= nil then
            self.loadedSave=true
            if not self:loadHistory() then self:initializeBaseline() else print("[FinancialDashboard] History restored from savegame") end
        end
    end
    self.sampleElapsed=(self.sampleElapsed or 0)+(dt or 0)
    if self.sampleElapsed>=1000 then self.sampleElapsed=0;self:recordBalance() end
    self.persistElapsed=(self.persistElapsed or 0)+(dt or 0)
    if self.persistElapsed>=self.persistInterval then self.persistElapsed=0;self:saveHistory() end
    if not self.registered and not self.registrationFailed and self.attempts<10 then
        self.elapsed=(self.elapsed or 0)+(dt or 0)
        if self.elapsed>=1500 then self.elapsed=0;self:tryRegister() end
    end
end
function FD:deleteMap()
    self:recordBalance();self:saveHistory()
    self.registered=false;self.registrationFailed=false;self.elapsed=0
    self.history=nil;self.daily=nil;self.baselineInitialized=false
    self.sampleElapsed=0;self.persistElapsed=0;self.loadedSave=false
end
-- Follow the working Employees mod: save from FS25's actual savegame lifecycle.
if FSBaseMission ~= nil and FSBaseMission.saveSavegame ~= nil and Utils ~= nil then
    FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, function(mission)
        if mission ~= nil and mission.getIsServer ~= nil and mission:getIsServer() then
            print("[FinancialDashboard] Savegame hook invoked")
            FD:recordBalance()
            FD:saveHistory(true, mission.missionInfo and mission.missionInfo.savegameDirectory)
        end
    end)
    print("[FinancialDashboard] Savegame hook registered")
else
    print("[FinancialDashboard] Persistence WARNING: savegame hook unavailable")
end
addModEventListener(FD)
