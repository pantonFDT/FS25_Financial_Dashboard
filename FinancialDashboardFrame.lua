FinancialDashboardFrame = {}
FinancialDashboardFrame_mt = Class(FinancialDashboardFrame, TabbedMenuFrameElement)
function FinancialDashboardFrame.new()
    local self = FinancialDashboardFrame:superClass().new(nil, FinancialDashboardFrame_mt)
    self.name = "FinancialDashboardFrame"
    self.backButtonInfo = {inputAction = InputAction.MENU_BACK}
    self.refreshMs = 0
    self.viewDays = 30
    self.graphMode = "balance"
    self.lastViewDays = nil
    return self
end
function FinancialDashboardFrame:onFrameOpen()
    FinancialDashboardFrame:superClass().onFrameOpen(self)
    if FinancialDashboard ~= nil then FinancialDashboard:initializeBaseline() end
    self:refreshDashboard()
end
function FinancialDashboardFrame:onFrameClose()
    FinancialDashboardFrame:superClass().onFrameClose(self)
end
function FinancialDashboardFrame:getMenuButtonInfo()
    return {self.backButtonInfo}
end
function FinancialDashboardFrame:update(dt)
    FinancialDashboardFrame:superClass().update(self, dt)
    self.refreshMs = self.refreshMs + (dt or 0)
    if self.refreshMs >= 1000 then
        self.refreshMs = 0
        self:refreshDashboard()
    end
end
local function formatMoney(n)
    local sign = n < 0 and "-" or ""
    local digits = string.format("%.0f", math.abs(n))
    return sign .. digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end
function FinancialDashboardFrame:onClick7Days() self.viewDays=7;self:refreshDashboard() end
function FinancialDashboardFrame:onClickBalance() self.graphMode="balance";self:refreshDashboard() end
function FinancialDashboardFrame:onClickIncome() self.graphMode="income";self:refreshDashboard() end
function FinancialDashboardFrame:onClickOutflow() self.graphMode="outflow";self:refreshDashboard() end
function FinancialDashboardFrame:onClick30Days()
    self.viewDays = 30
    self:refreshDashboard()
end
function FinancialDashboardFrame:onClick60Days()
    self.viewDays = 60
    self:refreshDashboard()
end
function FinancialDashboardFrame:refreshDashboard()
    local fd=FinancialDashboard
    if fd then fd:recordBalance() end
    local stored=fd and fd.history or {}
    local daily=fd and fd.daily or {}
    local mission=g_currentMission
    local day=mission and mission.environment and tonumber(mission.environment.currentDay)
    local money=mission and mission.getMoney and tonumber(mission:getMoney())
    if self.balanceText then self.balanceText:setText("CURRENT BALANCE: "..(money and formatMoney(money) or "unavailable")) end
    if self.view7Button then self.view7Button:setText(self.viewDays==7 and "[7 DAYS]" or "7 DAYS") end
    if self.view30Button then self.view30Button:setText(self.viewDays==30 and "[30 DAYS]" or "30 DAYS") end
    if self.view60Button then self.view60Button:setText(self.viewDays==60 and "[60 DAYS]" or "60 DAYS") end
    if self.modeBalanceButton then self.modeBalanceButton:setText(self.graphMode=="balance" and "[BALANCE]" or "BALANCE") end
    if self.modeIncomeButton then self.modeIncomeButton:setText(self.graphMode=="income" and "[INFLOWS]" or "INFLOWS") end
    if self.modeOutflowButton then self.modeOutflowButton:setText(self.graphMode=="outflow" and "[OUTFLOWS]" or "OUTFLOWS") end
    if self.windowTitleText then self.windowTitleText:setText("FINANCIAL HISTORY | "..self.viewDays.." DAYS | "..string.upper(self.graphMode)) end
    local history={}
    if day then
        for _,v in ipairs(stored or {}) do if v.day>day-self.viewDays and v.day<=day then history[#history+1]=v end end
    end
    local income,outflow,changes=0,0,0
    local largestIncrease,largestDecrease=0,0
    if day then
        for d=day-self.viewDays+1,day do
            local rec=daily[d]
            if rec then
                income=income+(rec.income or 0);outflow=outflow+(rec.outflow or 0);changes=changes+(rec.changes or 0)
            end
        end
    end
    for _,v in ipairs(history) do
        local delta=v.delta or 0
        if delta>largestIncrease then largestIncrease=delta end
        if -delta>largestDecrease then largestDecrease=-delta end
    end
    local today=day and daily[day] or nil
    local yesterday=day and daily[day-1] or nil
    local todayNet=today and (today.income or 0)-(today.outflow or 0) or 0
    local yesterdayNet=yesterday and (yesterday.income or 0)-(yesterday.outflow or 0) or 0
    local net=income-outflow
    if self.summaryText then self.summaryText:setText("NET CHANGE: "..(net>=0 and "+" or "")..formatMoney(net).." | DETECTED MOVEMENTS: "..changes) end
    if self.expenseText then self.expenseText:setText("INFLOWS (EST.): "..formatMoney(income).." | OUTFLOWS (EST.): "..formatMoney(outflow)) end
    if self.extremesText then self.extremesText:setText("TODAY NET: "..formatMoney(todayNet).." | PREVIOUS DAY: "..formatMoney(yesterdayNet)) end
    if self.graphText then self.graphText:setText("LARGEST DETECTED INCREASE: +"..formatMoney(largestIncrease).." | DECREASE: -"..formatMoney(largestDecrease)) end
    if self.statusText then self.statusText:setText("v2.0 | Panton / Factory Development Team | Per-savegame history | Estimated movements") end
    self.flowIn=income;self.flowOut=outflow
    self.graphSamples={}
    if self.graphMode=="balance" then
        for _,v in ipairs(history) do self.graphSamples[#self.graphSamples+1]={day=v.day,balance=v.balance} end
    elseif day then
        for d=day-self.viewDays+1,day do
            local rec=daily[d]
            self.graphSamples[#self.graphSamples+1]={day=d,balance=rec and (rec[self.graphMode] or 0) or 0}
        end
    end
    local lo,hi=0,0
    local baseline=self.graphMode=="balance" and self.graphSamples[1] and self.graphSamples[1].balance or 0
    for _,v in ipairs(self.graphSamples) do
        local val=v.balance-baseline
        lo=math.min(lo,val);hi=math.max(hi,val)
    end
    local extent=math.max(math.abs(lo),math.abs(hi))
    if self.axisHighText then self.axisHighText:setText("+"..formatMoney(extent)) end
    if self.axisLowText then self.axisLowText:setText("-"..formatMoney(extent)) end
    if self.axisStartText then self.axisStartText:setText("DAY "..tostring(self.graphSamples[1] and self.graphSamples[1].day or "-")) end
    if self.axisEndText then self.axisEndText:setText("DAY "..tostring(self.graphSamples[#self.graphSamples] and self.graphSamples[#self.graphSamples].day or "-")) end
end

-- FDT v1.2 Phase 1: futuristic graph renderer. Visual-only replacement.
-- Persistence, financial calculations, menu registration and icon are untouched.
local function panel(x,y,w,h,r,g,b,a)
    if type(drawFilledRect)=="function" then drawFilledRect(x,y,w,h,r,g,b,a or 1) end
end
local function stroke(x1,y1,x2,y2,thickness,r,g,b,a)
    local dx,dy=x2-x1,y2-y1
    local steps=math.max(1,math.ceil(math.max(math.abs(dx)*1920,math.abs(dy)*1080)/5))
    for j=0,steps do
        local t=j/steps
        panel(x1+dx*t-thickness/2,y1+dy*t-thickness/2,thickness,thickness,r,g,b,a)
    end
end
function FinancialDashboardFrame:draw()
    FinancialDashboardFrame:superClass().draw(self)
    if type(drawFilledRect)~="function" then return end
    local samples=self.graphSamples or {}
    local x0,y0,w,h=0.30,0.295,0.56,0.185
    -- Phase 2 graph-only polish: preserve layout, controls and all accounting code.
    panel(x0-0.006,y0-0.008,w+0.012,h+0.018,0.030,0.060,0.085,0.97)
    panel(x0-0.006,y0-0.008,0.0013,h+0.018,0.18,0.72,0.93,0.82)
    panel(x0-0.006,y0+h+0.007,w+0.012,0.0010,0.17,0.53,0.65,0.78)
    for j=0,4 do
        local yy=y0+0.012+(h-0.024)*j/4
        panel(x0+0.008,yy,w-0.016,0.00055,0.17,0.36,0.43,0.29)
    end
    for j=1,7 do
        local xx=x0+0.012+(w-0.024)*j/8
        panel(xx,y0+0.009,0.00035,h-0.018,0.13,0.28,0.36,0.20)
    end
    -- Low-cost horizontal comparison bars, always bounded to the panel.
    local inflow=math.max(0,self.flowIn or 0)
    local outflow=math.max(0,self.flowOut or 0)
    local scale=math.max(1,inflow,outflow)
    local bx,bw=0.30,0.56
    -- Minimal financial indicators: quiet tracks and slim, muted value fills.
    -- Bar geometry stays in the original comparison area; values/scaling unchanged.
    for _,bar in ipairs({{0.180,inflow,0.22,0.61,0.65},{0.146,outflow,0.76,0.39,0.51}}) do
        local by,value,r,g,b=unpack(bar)
        local barHeight=0.0048
        local centerY=by+0.0065
        panel(bx,centerY-barHeight/2,bw,barHeight,0.13,0.20,0.25,0.46)
        if value>0 then
            panel(bx,centerY-barHeight/2,bw*(value/scale),barHeight,r,g,b,0.69)
        end
    end
    if #samples==0 then return end
    local baseline=self.graphMode=="balance" and samples[1].balance or 0
    local extent=1
    for _,sample in ipairs(samples) do extent=math.max(extent,math.abs(sample.balance-baseline)) end
    local mid=y0+h/2
    panel(x0+0.008,mid,w-0.016,0.00085,0.28,0.53,0.63,0.58)
    local n=#samples
    local maxPoints=math.min(n,100)
    local lastX,lastY,lastVal=nil,nil,nil
    local positive=self.graphMode=="income"
    for k=1,maxPoints do
        local idx=maxPoints==1 and 1 or math.floor((k-1)*(n-1)/(maxPoints-1))+1
        local val=samples[idx].balance-baseline
        local xx=x0+0.012+(w-0.024)*(maxPoints==1 and 0 or (k-1)/(maxPoints-1))
        local yy=mid+((h-0.030)/2)*(val/extent)*0.94
        if lastX then
            local r,g,b=0.23,0.78,0.97
            if self.graphMode=="outflow" or (self.graphMode=="balance" and val<(lastVal or 0)) then r,g,b=1.0,0.43,0.59
            elseif self.graphMode=="income" then r,g,b=0.26,0.91,0.74 end
            -- Soft glow and crisp core; interpolation remains monotonic.
            stroke(lastX,lastY,xx,yy,0.0032,r,g,b,0.12)
            stroke(lastX,lastY,xx,yy,0.00145,r,g,b,0.97)
        end
        lastX,lastY,lastVal=xx,yy,val
    end
    if lastX then
        panel(lastX-0.003,lastY-0.003,0.006,0.006,0.20,0.85,1.0,0.22)
        panel(lastX-0.0018,lastY-0.0018,0.0036,0.0036,0.94,0.99,1.0,1)
    end
end
