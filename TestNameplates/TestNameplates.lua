local addon_name = ...
local lastChildren, WorldFrame, C_NamePlate = 0, WorldFrame, C_NamePlate
local UnitThreatSituation, UnitGUID, UnitAffectingCombat, UnitIsPlayer, UnitClass = UnitThreatSituation, UnitGUID, UnitAffectingCombat, UnitIsPlayer, UnitClass
local playerGuid = UnitGUID("player")
local GetStaticPlateIcon, playerTargetGuid

local function utf8sub(string, i, dots)
  if not string then return end
  local bytes = string:len()
  if (bytes <= i) then
    return string
  else
    local len, pos = 0, 1
    while (pos <= bytes) do
      len = len + 1
      local c = string:byte(pos)
      if (c > 0 and c <= 127) then
        pos = pos + 1
      elseif (c >= 192 and c <= 223) then
        pos = pos + 2
      elseif (c >= 224 and c <= 239) then
        pos = pos + 3
      elseif (c >= 240 and c <= 247) then
        pos = pos + 4
      end
      if (len == i) then break end
    end

    if (len == i and pos <= bytes) then
      return string:sub(1, pos - 1) .. (dots and '..' or '')
    else
      return string
    end
  end
end

local function Abbrev(str)
  local letters, lastWord = "", string.match(str, ".+%s(.+)$")
  if lastWord then
    for word in gmatch(str, ".-%s") do
      local firstLetter = string.utf8sub(gsub(word, "^[%s%p]*", ""), 1, 1)
      if firstLetter ~= string.utf8lower(firstLetter) then
        letters = format("%s%s. ", letters, firstLetter)
      end
    end
    str = format("%s%s", letters, lastWord)
  end
  return str
end

local function desaturateColor(r, g, b, factor)
  r = r * factor
  g = g * factor
  b = b * factor
  return r, g, b
end

local function hexToDecimal(hex)
  local r = tonumber(string.sub(hex, 1, 2), 16) / 255
  local g = tonumber(string.sub(hex, 3, 4), 16) / 255
  local b = tonumber(string.sub(hex, 5, 6), 16) / 255
  return r, g, b
end

local function brightenColor(r, g, b, factor)
  r = math.min(r * factor, 255)
  g = math.min(g * factor, 255)
  b = math.min(b * factor, 255)
  return r, g, b
end

local classColors = {
  ["DEATHKNIGHT"] = "C41F3B",
  ["DRUID"] = "FF7D0A",
  ["HUNTER"] = "A9D271",
  ["MAGE"] = "40C7EB",
  ["PALADIN"] = "F58CBA",
  ["PRIEST"] = "FFFFFF",
  ["ROGUE"] = "FFF569",
  ["SHAMAN"] = "0070DE",
  ["WARLOCK"] = "8787ED",
  ["WARRIOR"] = "C79C6E",
}

--local npNamePoints={}
--local npCBPoints={}
local npHBPoints={}
-- local npOverlayPoints={}
-- local noglowPoints={}
-- local npspellIconRegionPoints={}
local npHooked={}

--local function npOnShow(self)
    --local nameRegion = select(7, self:GetRegions())
    --local levelRegion = select(8, self:GetRegions())
    --levelRegion:SetText(" ")
    --nameRegion:SetText(" ") 
    --levelRegion:Hide()
    --nameRegion:Hide() 
    --nameplate.guid=guid
   ---print(guid)
--end
  
local function npOnUpdate(self,...)
    --print(self.origSavedName)
    local nameRegion = select(7, self:GetRegions())
    local levelRegion = select(8, self:GetRegions())
    local spellIconRegion = select(5, self:GetRegions())
    local castbarOverlay = select(3, self:GetRegions()) -- задник каста, ныне его бордер
    local overlayRegion = select(2, self:GetRegions()) -- задник каста, ныне его бордер
    
      local shieldedRegion = select(4, self:GetRegions())
      local glowRegion = select(1, self:GetRegions())
      local highlightRegion = select(6, self:GetRegions())
      local bossIconRegion = select(9, self:GetRegions())
      local EliteNameplateIcon = select(11, self:GetRegions())
      local levelRegion = select(8, self:GetRegions())
      local raidIcon = select(10, self:GetRegions())
    
    local healthBar, castBar = self:GetChildren()
    --print(healthBar:GetObjectType(),castBar:GetObjectType())
    
    local hpMax = select(2,healthBar:GetMinMaxValues())
    local hpCur = healthBar:GetValue()
    
    
      if self.nameplateToken then
          if not self.guid then
            self.guid = UnitGUID(self.nameplateToken)
          end
          if not self.class then
            self.class = select(2, UnitClass(self.nameplateToken))
          end
          if not self.isPlayer then
            self.isPlayer = UnitIsPlayer(self.nameplateToken)
          end
      end
      
      
      
      if (not self.origSavedName) or self.origSavedName=="" or self.origSavedName==STRING_SCHOOL_UNKNOWN then
        local origSavedName = nameRegion:GetText()
        if origSavedName then
          self.origSavedName = origSavedName
        end
      end
    
      shieldedRegion:Hide()  
      bossIconRegion:Hide()  
      highlightRegion:Hide()
      glowRegion:Hide()
      EliteNameplateIcon:Hide()
    levelRegion:Hide() 
    
    --nameRegion:Hide() 
    --spellIconRegion:Hide() 
    --castbarOverlay:Hide() 
    --highlightRegion:SetSize(140,100)
    healthBar:SetSize(65.6,6.5)
    --print(glowRegion:GetTexture())
    castBar:SetSize(65.6,3)


  nameRegion:SetFont("Interface\\addons\\"..addon_name.."\\PTSansNarrow.ttf", 9, 'outline')
  nameRegion:SetShadowOffset(0,0)
  --print(nameRegion:GetDrawLayer())--BACKGROUND
  --print(nameRegion:GetDrawLayer(),overlayRegion:GetDrawLayer(),castbarOverlay:GetDrawLayer())


    local nameColored,borderColored,unitReaction,forceShow,forceHide,thiccBorder
    local r, g, b, a = healthBar:GetStatusBarColor()
    local _, _, _, an = nameRegion:GetTextColor()
  local newName = self.origSavedName or ""
  local curName = nameRegion:GetText()
  
  if self.origSavedName and #self.origSavedName:gsub('[\128-\191]', '') > 12 then
    newName = Abbrev(self.origSavedName)
    if #newName:gsub('[\128-\191]', '') > 12 then
      newName = utf8sub(newName, 12, true)
    end
  end
  
  if (self.nameplateToken and UnitAffectingCombat(self.nameplateToken)) then
    newName = "" .. newName .. "|T" .. "Interface\\addons\\"..addon_name.."\\combat2" .. ":12|t"
  end

  if (GetStaticPlateIcon and self.origSavedName and self.guid and GetStaticPlateIcon(self.origSavedName,self.guid) ~= nil) then
    newName = "" .. newName .. "|T" .. GetStaticPlateIcon(self.origSavedName,self.guid) .. ":12|t"
    forceShow=1
  end
  
  local isTargetingMe = self.nameplateToken and playerGuid==UnitGUID(self.nameplateToken.."target")
  
  if isTargetingMe then
    newName = "" .. newName .. "|T" .. "Interface\\addons\\"..addon_name.."\\dang" .. ":12|t"
    --print(self.nameplateToken,playerGuid,UnitGUID(self.nameplateToken.."target"))
  end
  
  if curName~=newName then
    nameRegion:SetText(newName)
  end

    --print(curName,newName)

    if self.isPlayer and self.class then
      local colorHex = classColors[self.class] or "ffdddd"
      local r, g, b = hexToDecimal(colorHex)
      local desaturatedR, desaturatedG, desaturatedB = desaturateColor(r, g, b, 0.5)
      local brightenedR, brightenedG, brightenedB = brightenColor(desaturatedR, desaturatedG, desaturatedB, 2)
      nameRegion:SetTextColor(brightenedR, brightenedG, brightenedB, an)
      nameColored=1
    end
    
    -- reaction
    if g + b == 0 then --враждебный
      --healthBar:SetStatusBarColor(0.7, 0.1, 0.1, a)
      if not nameColored then nameRegion:SetTextColor(0.8, 0.7, 0.7, an) end
      unitReaction = 4   -- enemy
    elseif r + b == 0 then --дружественный NPC
      --healthBar:SetStatusBarColor(0.2, 0.7, 0.2, a)
      if not nameColored then nameRegion:SetTextColor(0.7, 0.8, 0.7, an) end
      unitReaction = 3   -- friend
    elseif r + g == 0 then --Дружественный игрок
      --healthBar:SetStatusBarColor(0.2, 0.3, 0.8, a)
      if not nameColored then nameRegion:SetTextColor(0.6, 0.6, 0.8, an) end
      unitReaction = 2                      -- friend
    elseif 2 - (r + g) < 0.05 and b == 0 then -- нейтральный игрок или NPC -- частичный кусок кода с математикой от дримлолза
      --healthBar:SetStatusBarColor(0.8, 0.8, 0.3, a) 
      if not nameColored then nameRegion:SetTextColor(0.8, 0.8, 0.6, an) end
      unitReaction = 1 -- neutral
    else                 -- цвет класса
      --healthBar:SetStatusBarColor(r * 0.75, g * 0.75, b * 0.75, a)
      if not nameColored then nameRegion:SetTextColor(r * 0.7, g * 0.7, b * 0.7, an) end
      unitReaction = 0 -- class color
    end
    
    local isMyTarget,isMyFocus,isMouseover
    
    if C_NamePlate~=nil then
     isMyTarget = C_NamePlate.GetNamePlateForUnit('target') and self==C_NamePlate.GetNamePlateForUnit('target')
     isMyFocus = C_NamePlate.GetNamePlateForUnit('focus') and self==C_NamePlate.GetNamePlateForUnit('focus')
     isMouseover = C_NamePlate.GetNamePlateForUnit('mouseover') and self==C_NamePlate.GetNamePlateForUnit('mouseover')
    else
      forceShow=1
    end
    
    

        -- --if overlayRegion:IsShown() and overlayRegion:GetTexture()~="Interface\\addons\\"..addon_name.."\\Nameplate-Border-white" then
          -- overlayRegion:SetTexture("Interface\\addons\\"..addon_name.."\\Nameplate-Border-white")
          -- --print(1,borderColored)
        -- --end
        
        -- --if castbarOverlay:IsShown() and castbarOverlay:GetTexture()~="Interface\\addons\\"..addon_name.."\\cast-top-white" then
          -- castbarOverlay:SetTexture("Interface\\addons\\"..addon_name.."\\cast-top-white")
        -- --end
    

    
    if (isMyTarget or isMouseover) then
      if (unitReaction==2 or unitReaction==3) then
        overlayRegion:SetVertexColor(0.5, 0.9, 0.9)
        castbarOverlay:SetVertexColor(0.5, 0.9, 0.9)
        thiccBorder=1
        -- if overlayRegion:GetTexture()~="Interface\\addons\\"..addon_name.."\\Nameplate-Border-cyan2" then 
          -- overlayRegion:SetTexture("Interface\\addons\\"..addon_name.."\\Nameplate-Border-cyan2")
        -- end
        -- if castbarOverlay:IsShown() and castbarOverlay:GetTexture()~="Interface\\addons\\"..addon_name.."\\cast-top-cyan2" then
          -- castbarOverlay:SetTexture("Interface\\addons\\"..addon_name.."\\cast-top-cyan2")
          -- --print('sadasdsad')
        -- end
        --print('tar/mo')
      elseif unitReaction==4 then
        overlayRegion:SetVertexColor(0, 0.7, 0.7)
        castbarOverlay:SetVertexColor(0, 0.7, 0.7)
        thiccBorder=1
        -- if overlayRegion:GetTexture()~="Interface\\addons\\"..addon_name.."\\Nameplate-Border-cyan" then
          -- overlayRegion:SetTexture("Interface\\addons\\"..addon_name.."\\Nameplate-Border-cyan")
        -- end
        -- if castbarOverlay:IsShown() and castbarOverlay:GetTexture()~="Interface\\addons\\"..addon_name.."\\cast-top-cyan" then
          -- --print(castbarOverlay:GetTexture())
          -- castbarOverlay:SetTexture("Interface\\addons\\"..addon_name.."\\cast-top-cyan")
        -- end
        --print('tar/mo unitReaction==4')
      else
        overlayRegion:SetVertexColor(0.5, 0.9, 0.9)
        castbarOverlay:SetVertexColor(0.5, 0.9, 0.9)
        thiccBorder=1
        -- if overlayRegion:GetTexture()~="Interface\\addons\\"..addon_name.."\\Nameplate-Border-cyan2" then
          -- overlayRegion:SetTexture("Interface\\addons\\"..addon_name.."\\Nameplate-Border-cyan2")
        -- end
        -- if castbarOverlay:IsShown() and castbarOverlay:GetTexture()~="Interface\\addons\\"..addon_name.."\\cast-top-cyan2" then
          -- castbarOverlay:SetTexture("Interface\\addons\\"..addon_name.."\\cast-top-cyan2")
        -- end
      end
      borderColored=1
      forceShow=1
    elseif isMyFocus then
      forceShow=1
    end
    

    if not borderColored then
      if ((isTargetingMe and unitReaction==4) or (not self.isPlayer and self.nameplateToken and UnitThreatSituation("player", self.nameplateToken) )) then -- угроза или враг таргетит нас
        -- if overlayRegion:IsShown() and overlayRegion:GetTexture()~="Interface\\addons\\"..addon_name.."\\Nameplate-Border-orange" then
          -- overlayRegion:SetTexture("Interface\\addons\\"..addon_name.."\\Nameplate-Border-orange")
        -- end
        -- if castbarOverlay:IsShown() and castbarOverlay:GetTexture()~="Interface\\addons\\"..addon_name.."\\cast-top-orange" then
          -- castbarOverlay:SetTexture("Interface\\addons\\"..addon_name.."\\cast-top-orange")
        -- end
        overlayRegion:SetVertexColor(0.9, 0.5, 0)
        castbarOverlay:SetVertexColor(0.9, 0.5, 0)
        forceShow=1
        thiccBorder=1
        --print(nameplateToken,UnitThreatSituation("player", nameplateToken) )
      else
        overlayRegion:SetVertexColor(0, 0, 0)
        castbarOverlay:SetVertexColor(0, 0, 0)
        -- if overlayRegion:IsShown() and overlayRegion:GetTexture()~="Interface\\addons\\"..addon_name.."\\Nameplate-Border-black" then
          -- overlayRegion:SetTexture("Interface\\addons\\"..addon_name.."\\Nameplate-Border-black")
          -- --print(1,borderColored)
        -- end
        -- if castbarOverlay:IsShown() and castbarOverlay:GetTexture()~="Interface\\addons\\"..addon_name.."\\cast-top-black" then
          -- castbarOverlay:SetTexture("Interface\\addons\\"..addon_name.."\\cast-top-black")
          -- --print('cast-top-black')
        -- end
        if raidIcon:IsShown() then
          forceShow=1
        elseif not forceShow and ((not self.isPlayer and unitReaction <=3) or ((not self.isPlayer or (self.isPlayer and unitReaction <=3)) and hpCur==hpMax)) then -- прячем хп там де оно не нада
          if not (self.nameplateToken and UnitAffectingCombat(self.nameplateToken)) then
            healthBar:Hide()
            overlayRegion:Hide()
            --print('ghgfhfghfg')
            --print(nameRegion:GetText(),self.isPlayer)
            --castbarOverlay:Hide()
            --spellIconRegion:Hide()
            --castBar:Hide()
          else
            --healthBar:SetAlpha(0) -- альфа 0 потому шо если спрятать то значение не будет обновляться
            --overlayRegion:Hide()
            --print('aaaaaaaaaaaa')
            forceHide=1
            --castbarOverlay:SetAlpha(0)
            --spellIconRegion:SetAlpha(0)
            --castBar:SetAlpha(0)
          end
        else
          forceShow=1
        end
      end
    end

    
    local alpha=1

    if forceShow then
        --local isMyTarget = playerTargetGuid and self.guid and self.guid == playerTargetGuid
        healthBar:Show()
        overlayRegion:Show()
        if isMyTarget then
          alpha=0.9
        elseif not playerTargetGuid then
          alpha=0.9 -- 1
        else
          alpha=0.9
        end
    elseif forceHide then
        alpha=0
        overlayRegion:Hide()
    elseif not playerTargetGuid then
        alpha=0.8
    else
        alpha=0.9 -- 1
    end
    
    
      healthBar:SetAlpha(alpha)
      overlayRegion:SetAlpha(alpha)
      nameRegion:SetAlpha(alpha==0 and 1 or alpha)
      
      -- скрыто хп? скрываем и каст но ток альфа канал а то с прятками типа хайда всё сложна
      if healthBar:GetAlpha()<0.1 or not healthBar:IsShown() then
        spellIconRegion:SetAlpha(0)
        castbarOverlay:SetAlpha(0)
        castBar:SetAlpha(0)
      else
        spellIconRegion:SetAlpha(alpha)
        castbarOverlay:SetAlpha(alpha)
        castBar:SetAlpha(alpha)
      end
    
    
    -- тексты менять ток после show или проверка на шовн ваще не нужна??
    if thiccBorder==1 then
        if overlayRegion:IsShown() and overlayRegion:GetTexture()~="Interface\\addons\\"..addon_name.."\\Nameplate-Border-white" then
          overlayRegion:SetTexture("Interface\\addons\\"..addon_name.."\\Nameplate-Border-white")
          --print(1,borderColored)
        end
        if castbarOverlay:IsShown() and castbarOverlay:GetTexture()~="Interface\\addons\\"..addon_name.."\\cast-top-white" then
          castbarOverlay:SetTexture("Interface\\addons\\"..addon_name.."\\cast-top-white")
          --print('cast-top-black')
        end
    else
        if overlayRegion:IsShown() and overlayRegion:GetTexture()~="Interface\\addons\\"..addon_name.."\\Nameplate-Border-white-thin" then
          overlayRegion:SetTexture("Interface\\addons\\"..addon_name.."\\Nameplate-Border-white-thin")
          --print(1,borderColored)
        end
        if castbarOverlay:IsShown() and castbarOverlay:GetTexture()~="Interface\\addons\\"..addon_name.."\\cast-top-white-thin" then
          castbarOverlay:SetTexture("Interface\\addons\\"..addon_name.."\\cast-top-white-thin")
          --print('cast-top-black')
        end
    end
    
    
        if npHBPoints[self] then
          local point, relativeTo, relativePoint, xOfs, yOfs = npHBPoints[self].point, npHBPoints[self].relativeTo, npHBPoints[self].relativePoint, npHBPoints[self].xOfs, npHBPoints[self].yOfs
          --healthBar:SetPoint(point, relativeTo, relativePoint, xOfs+10, yOfs+12.8)
          healthBar:SetPoint(point, relativeTo, relativePoint, xOfs+9.8, yOfs+12.6 )--test
          --nameRegion:SetPoint(point, relativeTo, relativePoint, xOfs+10, yOfs+12.4)--test
          nameRegion:SetPoint("bottom", healthBar, 0, -9)
          
          if raidIcon:IsShown() then
            --raidIcon:SetSize(20,20)
            if castBar:IsShown() and castBar:GetAlpha() > 0.01 then
              raidIcon:SetPoint("right", healthBar, "CENTER", 10, 18)
            elseif healthBar:IsShown() and healthBar:GetAlpha() > 0.01 then
              raidIcon:SetPoint("right", healthBar, "CENTER", 10, 15)
            else
              raidIcon:SetPoint("right", healthBar, "CENTER", 10, 8)
            end
          end
        end
        --print(raidIcon:GetSize(),raidIcon:IsShown())
        -- if npspellIconRegionPoints[self] then
          -- local point, relativeTo, relativePoint, xOfs, yOfs = npspellIconRegionPoints[self].point, npspellIconRegionPoints[self].relativeTo, npspellIconRegionPoints[self].relativePoint, npspellIconRegionPoints[self].xOfs, npspellIconRegionPoints[self].yOfs
          -- spellIconRegion:SetPoint(point, relativeTo, relativePoint, xOfs+50, yOfs-50)
        -- end
        
        -- if npCBPoints[self] then
          -- local point, relativeTo, relativePoint, xOfs, yOfs = npCBPoints[self].point, npCBPoints[self].relativeTo, npCBPoints[self].relativePoint, npCBPoints[self].xOfs, npCBPoints[self].yOfs
          -- castbarOverlay:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs+20)
        -- end
        
        --if npNamePoints[self] then
        --  local point, relativeTo, relativePoint, xOfs, yOfs = npNamePoints[self].point, npNamePoints[self].relativeTo, npNamePoints[self].relativePoint, npNamePoints[self].xOfs, npNamePoints[self].yOfs
          --nameRegion:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs-16)
          --nameRegion:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs-5.5) --perfect!
        --end
    
        -- if npNamePoints[self] then
          -- local point, relativeTo, relativePoint, xOfs, yOfs = npNamePoints[self].point, npNamePoints[self].relativeTo, npNamePoints[self].relativePoint, npNamePoints[self].xOfs, npNamePoints[self].yOfs
          -- overlayRegion:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs+60)
        -- end
    
    --overlayRegion:SetVertexColor(0, 0.7, 0.7) -- -
    --overlayRegion:SetBackdropBorderColor(0, 0.7, 0.7)
    
    levelRegion:SetFont("Interface\\addons\\"..addon_name.."\\PTSansNarrow.ttf", 7)
    levelRegion:SetShadowOffset(0,0)
    
        castbarOverlay:SetSize(90.3,23)
        castbarOverlay:SetPoint("CENTER", healthBar, -0.3, -4)
        castBar:SetPoint("BOTTOMRIGHT", healthBar, 0, 6) --++
        spellIconRegion:SetSize(12,12)
        spellIconRegion:SetPoint("CENTER", healthBar, 39.8, 2)
    
    -- do
      -- if npCBPoints[self] then
        -- local point, relativeTo, relativePoint, xOfs, yOfs = npCBPoints[self].point, npCBPoints[self].relativeTo, npCBPoints[self].relativePoint, npCBPoints[self].xOfs, npCBPoints[self].yOfs
        -- --castBar:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs+17)
        -- --castbarOverlay:SetTexture("Interface\\addons\\"..addon_name.."\\cast-top-black")
        -- --castbarOverlay:SetPoint("TOPLEFT", castBar, -1, 1)
        -- --castbarOverlay:SetAllPoints(self)

        -- --print(castbarOverlay:GetTexture())
      -- end
    -- end
    
    -- do
      -- if npCBPoints[self] and npspellIconRegionPoints[self] then
        -- local point, relativeTo, relativePoint, xOfs, yOfs = npCBPoints[self].point, npCBPoints[self].relativeTo, npCBPoints[self].relativePoint, npCBPoints[self].xOfs, npCBPoints[self].yOfs
        -- spellIconRegion:SetPoint(point, relativeTo, relativePoint, xOfs-38.5, yOfs+14.5)
      -- end
    -- end
end

-- то шо делаем при хайде плейты
local function npDel(nameplate)
      nameplate.guid = nil
      nameplate.class = nil
      nameplate.isPlayer = nil
      nameplate.origSavedName = nil
      nameplate.nameplateToken = nil
       --npHooked[nameplate]=nil 
      -- --nameplate:SetScript('OnShow',nil)
       --nameplate:SetScript('OnUpdate',nil)
      -- npNamePoints[nameplate]=nil -- симс ту би удалять оригинальные поинты такая себя идея
      -- npCBPoints[nameplate]=nil
      -- npspellIconRegionPoints[nameplate]=nil
      -- npHBPoints[nameplate]=nil
end

-- то шо делаем при появлении плейты
local function npOnShow(nameplate,nameplateToken)
  
      nameplate.guid = nil
      nameplate.class = nil
      nameplate.isPlayer = nil
      nameplate.origSavedName = nil
      nameplate.nameplateToken = nil
      
      -- не мусор
      local nameRegion = select(7, nameplate:GetRegions())
      local spellIconRegion = select(5, nameplate:GetRegions())
      local raidIcon = select(10, nameplate:GetRegions())
      
      -- условно не мусор
      local overlayRegion = select(2, nameplate:GetRegions())
      local castbarOverlay = select(3, nameplate:GetRegions())
      
      -- мусор
      local shieldedRegion = select(4, nameplate:GetRegions())
      local glowRegion = select(1, nameplate:GetRegions())
      local highlightRegion = select(6, nameplate:GetRegions())
      local bossIconRegion = select(9, nameplate:GetRegions())
      local EliteNameplateIcon = select(11, nameplate:GetRegions())
      local levelRegion = select(8, nameplate:GetRegions())
      
      
      -- не мусор
      local healthBar, castBar = nameplate:GetChildren()
      
            --healthBar:Show()
            healthBar:Hide()
            --overlayRegion:Show()
            overlayRegion:Hide()
  nameRegion:SetDrawLayer('BACKGROUND')
  overlayRegion:SetDrawLayer("BACKGROUND")
  castbarOverlay:SetDrawLayer("BACKGROUND")
  raidIcon:SetSize(20,20)

          if not nameplate.nameplateToken then
            nameplate.nameplateToken = nameplateToken
          end
      
        --if overlayRegion:IsShown() and overlayRegion:GetTexture()~="Interface\\addons\\"..addon_name.."\\Nameplate-Border-white" then
          --overlayRegion:SetTexture("Interface\\addons\\"..addon_name.."\\Nameplate-Border-white")
          --print(1,borderColored)
        --end
        
        --if castbarOverlay:IsShown() and castbarOverlay:GetTexture()~="Interface\\addons\\"..addon_name.."\\cast-top-white" then
          --castbarOverlay:SetTexture("Interface\\addons\\"..addon_name.."\\cast-top-white")
        --end

      -- local guid = UnitGUID("nameplate"..k)
      -- nameplate.guid=guid
      -- if UnitGUID('target')==nameplate.guid then
        -- --print(select(12, nameplate:GetRegions()))
      -- end
      
      --print(nameplate:GetObjectType())
      shieldedRegion:SetTexture(nil) -- хз
      shieldedRegion:Hide()  
      
      bossIconRegion:SetTexture(nil) 
      bossIconRegion:Hide()  
      
      highlightRegion:SetTexture(nil) -- подсвет при наведении - Interface\Tooltips\Nameplate-Glow
      highlightRegion:Hide()
      
      --print(highlightRegion:GetTexture())
      glowRegion:SetTexture(nil) -- красная хрень вокруг когда нпц агрится - Interface\TargetingFrame\UI-TargetingFrame-Flash
      glowRegion:Hide()
      
      --overlayRegion:SetTexture(nil) -- задник хп - Interface\Tooltips\Nameplate-Border
      EliteNameplateIcon:SetTexture(nil)
      EliteNameplateIcon:Hide()

      -- if nameRegion  then
        -- if not npNamePoints[nameplate] then
          -- local point, relativeTo, relativePoint, xOfs, yOfs = nameRegion:GetPoint()
          -- if yOfs then
            -- npNamePoints[nameplate] = {point=point, relativeTo=relativeTo, relativePoint=relativePoint, xOfs=xOfs, yOfs=yOfs}
          -- end
        -- end
      -- end

      
      
      -- if castBar then
        -- if not npCBPoints[nameplate] then
          -- local point, relativeTo, relativePoint, xOfs, yOfs = castBar:GetPoint()
          -- if yOfs then
            -- npCBPoints[nameplate] = {point=point, relativeTo=relativeTo, relativePoint=relativePoint, xOfs=xOfs, yOfs=yOfs}
            -- --print(point, relativeTo, relativePoint, xOfs, yOfs)
          -- end
        -- end
      -- end
        
      -- if spellIconRegion then
        -- if not npspellIconRegionPoints[nameplate] then
          -- local point, relativeTo, relativePoint, xOfs, yOfs = spellIconRegion:GetPoint()
          -- if yOfs then
            -- npspellIconRegionPoints[nameplate] = {point=point, relativeTo=relativeTo, relativePoint=relativePoint, xOfs=xOfs, yOfs=yOfs}
            -- --print(point, relativeTo, relativePoint, xOfs, yOfs)
          -- end
        -- end
      -- end
      
      if healthBar then
        if not npHBPoints[nameplate] then
          local point, relativeTo, relativePoint, xOfs, yOfs = healthBar:GetPoint()
          if yOfs then
            npHBPoints[nameplate] = {point=point, relativeTo=relativeTo, relativePoint=relativePoint, xOfs=xOfs, yOfs=yOfs}
            --print(point, relativeTo, relativePoint, xOfs, yOfs)
          end
        end

      end
      
      -- if glowRegion then
        -- if not noglowPoints[nameplate] then
          -- local point, relativeTo, relativePoint, xOfs, yOfs = glowRegion:GetPoint()
          -- if yOfs then
            -- noglowPoints[nameplate] = {point=point, relativeTo=relativeTo, relativePoint=relativePoint, xOfs=xOfs, yOfs=yOfs}
            -- --print(point, relativeTo, relativePoint, xOfs, yOfs)
          -- end
        -- end      
      --end
      
      -- for i=1,11 do
        -- local test=select(i, nameplate:GetRegions())
        -- if test:GetObjectType() == "Texture" then
          -- print(i,":",test:GetTexture())
        -- end
      -- end

      if not npHooked[nameplate] and nameplate:HasScript("OnUpdate") then
        npHooked[nameplate]=true
        --nameplate:HookScript('OnShow',npOnShow)
        nameplate:HookScript('OnUpdate',npOnUpdate)
      end

end

-- дефолт функции по скану ворлдфрейма и выявления на нем плейтов оставлены для гурманов без awesomewotlk
local function IsNamePlateFrame(obj)
  local Object = obj
  local Name = Object:GetName()
  local OverlayRegion = select(2, Object:GetRegions())
  if (Name) then
    return
  end
  return OverlayRegion and OverlayRegion:GetObjectType() == "Texture" and
OverlayRegion:GetTexture() == [=[Interface\Tooltips\Nameplate-Border]=] or OverlayRegion:GetTexture():find("Interface\\addons\\"..addon_name.."\\Nameplate-Border")
end

local function ScanWorldFrameChildren(n, ...)
  for i = 1, n do
    local nameplate = select(i, ...)
    if nameplate:IsShown() and IsNamePlateFrame(nameplate) then
      npOnShow(nameplate)
    end
  end
end

local function FindNameplates()
  if C_NamePlate~=nil then
    -- for _,nameplate in ipairs(C_NamePlate.GetNamePlates()) do
      -- if nameplate:IsShown() then
        -- npOnShow(nameplate)
      -- end
    -- end
  else
    local curChildren = WorldFrame:GetNumChildren()
    if curChildren ~= lastChildren then
      lastChildren = curChildren
      ScanWorldFrameChildren(curChildren, WorldFrame:GetChildren())
    end
  end
end

local f=CreateFrame('frame')
f:SetScript('OnUpdate', function()
  FindNameplates()
end) 

if C_NamePlate~=nil then
  f:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  f:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
  f:RegisterEvent("NAME_PLATE_CREATED")
end
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_TARGET_CHANGED")

f:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_ENTERING_WORLD" then
    GetStaticPlateIcon = _G.GetStaticPlateIcon
    f:UnregisterEvent("PLAYER_ENTERING_WORLD")
    playerGuid=UnitGUID("player")
  elseif event == "ADDON_LOADED" and arg1==addon_name then
    GetStaticPlateIcon = _G.GetStaticPlateIcon
    f:UnregisterEvent("ADDON_LOADED")
  elseif event == "PLAYER_TARGET_CHANGED" then
    playerTargetGuid=UnitGUID("target")
  elseif event == "NAME_PLATE_CREATED" then
    -- local q=...
    -- for _, region in ipairs({q:GetChildren()}) do
        -- local regionType = region:GetObjectType()
        -- print("Регион:", region:GetName(), "Тип:", regionType)
        -- if regionType == "FontString" then
            -- print("Текст:", region:GetText())
        -- end
    -- end
  elseif event == "NAME_PLATE_UNIT_REMOVED" then
    local nameplateToken = ...
    if (nameplateToken) then
      local nameplate = C_NamePlate.GetNamePlateForUnit(nameplateToken)
      if (nameplate) then
        --print(nameplate.origSavedName,nameplateToken)
        npDel(nameplate)
      end
    end
  elseif (event == "NAME_PLATE_UNIT_ADDED") then
    local nameplateToken = ...
    --print(nameplateToken)
    if (nameplateToken) then
      local nameplate = C_NamePlate.GetNamePlateForUnit(nameplateToken)
      if (nameplate) then
        npOnShow(nameplate,nameplateToken)
      end
    end
  end
end)

