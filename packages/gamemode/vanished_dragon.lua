local desc_vanished_dragon = [[
  # 忠胆英杰（明忠模式）简介

  ---

  ## 身份说明

  游戏由八名玩家进行，身份分配和一般身份局一样，为1主2忠4反1内。

  其中一名忠臣改为「**明忠**」。抽取身份后，**主公不需要亮明身份，改为明忠亮明身份**。

  胜负判定：和一般身份局一致。

  ---

  ## 游戏流程

  1. **明忠如一般身份局的主公一样，先选将并展示**，其他人（包括主公）再选将。明忠的额外选将为 崔琰 和 皇甫嵩；

  2. 明忠根据体力上限和性别获得相应的“**忠臣技**”，即：

  - 体力上限不大于3的男性武将获得〖**洞察**〗（游戏开始时，随机一名反贼的身份对你可见。准备阶段开始时，你可以弃置场上的一张牌）；

  - 体力上限不小于4的男性武将和所有女性武将获得〖**舍身**〗（锁定技，主公处于濒死状态即将死亡时，你令其体力上限+1，回复体力至X点（X为你的体力值），获得你所有牌，然后你死亡）；

  3. 如一般身份局的主公一样，**明忠体力上限和体力值+1**，且为一号位；

  4. **明忠死亡后，主公亮明身份**，获得武将牌上的主公技，但不增加体力上限。

  ---

  ## 击杀奖惩

  1. 任何角色击杀反贼，摸三张牌；

  2. 除主公外的角色击杀明忠，摸三张牌；

  3. 暗主击杀明忠，弃置所有牌；

  4. 暗主击杀暗忠，不弃牌；

  5. 明忠击杀暗忠，弃置所有牌。

  ---

  ## 专属游戏牌

  【**声东击西**】（替换【顺手牵羊】）普通锦囊：出牌阶段，对距离为1的一名角色使用。你交给目标角色一张手牌，然后其将两张牌交给一名由你选择的除其以外的角色。

  【**草木皆兵**】（替换【兵粮寸断】），延时锦囊：出牌阶段，对一名其他角色使用。将【草木皆兵】置于目标角色判定区里。若判定结果不为♣：摸牌阶段，少摸一张牌；摸牌阶段结束时，与其距离为1的角色各摸一张牌。

  【**增兵减灶**】（替换【无中生有】和【五谷丰登】），普通锦囊：出牌阶段，对一名角色使用。目标角色摸三张牌，然后选择一项：1. 弃置一张非基本牌；2. 弃置两张牌。

  【**弃甲曳兵**】（替换【借刀杀人】），普通锦囊：出牌阶段，对一名装备区里有牌的其他角色使用。目标角色选择一项：1. 弃置手牌区和装备区里所有的武器和进攻坐骑；2. 弃置手牌区和装备区里所有的防具和防御坐骑。

  【**金蝉脱壳**】（替换【无懈可击】），普通锦囊：当你成为其他角色使用牌的目标时，若你的手牌里只有【金蝉脱壳】，使目标锦囊牌或基本牌对你无效，你摸两张牌。当你因弃置而失去【金蝉脱壳】时，你摸一张牌。

  【**浮雷**】（替换【闪电】），延时锦囊：出牌阶段，对你使用。将【浮雷】放置于你的判定区里，若判定结果为♠，则目标角色受到X点雷电伤害（X为此牌判定结果为♠的次数）。判定完成后，将此牌移动到下家的判定区里。

  【**烂银甲**】（替换【八卦阵】），防具：你可以将一张手牌当【闪】使用或打出。【烂银甲】不会被无效或无视。当你受到【杀】造成的伤害时，你弃置装备区里的【烂银甲】。

  【**七宝刀**】（替换【青釭剑】），武器，攻击范围２：锁定技，你使用【杀】无视目标防具，若目标角色未损失体力值，此【杀】伤害+1。

  【**衠钢槊**】（替换【青龙偃月刀】），武器，攻击范围３：当你使用【杀】指定一名角色为目标后，你可令其弃置你的一张手牌，然后你弃置其一张手牌。
]]

local vanished_dragon_getLogic = function()
  local vanished_dragon_logic = GameLogic:subclass("vanished_dragon_logic")

  function vanished_dragon_logic:initialize(room)
    GameLogic.initialize(self, room)
    self.role_table = {nil, nil, nil, nil, nil, 
    {"hidden", "loyalist", "rebel", "rebel", "rebel", "renegade"},
    {"hidden", "loyalist", "loyalist", "rebel", "rebel", "rebel", "renegade"}, 
    {"hidden", "loyalist", "loyalist", "rebel", "rebel", "rebel", "rebel", "renegade"} }
  end

  function vanished_dragon_logic:assignRoles()
    local room = self.room
    local players = room.players
    local n = #players
    local roles = self.role_table[n]
    table.shuffle(roles)

    room:setTag("ShownLoyalist", nil)
    for i = 1, n do
      local p = players[i]
      p.role = roles[i]
      if p.role == "loyalist" and not room:getTag("ShownLoyalist") then
        p.role_shown = true
        room:broadcastProperty(p, "role")
        room:setTag("ShownLoyalist", p.id)
        p.role = "lord"
      else
        room:notifyProperty(p, p, "role")
      end
    end
  end

  function vanished_dragon_logic:prepareDrawPile()
    local room = self.room
    local allCardIds = Fk:getAllCardIds()
    local blacklist = {"snatch", "supply_shortage", "ex_nihilo", "amazing_grace", "collateral", "nullification", "lightning", "eight_diagram", "qinggang_sword", "blade"}
    local whitelist = {"diversion", "paranoid", "reinforcement", "abandoning_armor", "crafty_escape", "floating_thunder", "glittery_armor", "seven_stars_sword", "steel_lance"}
    for i = #allCardIds, 1, -1 do
      local card = Fk:getCardById(allCardIds[i])
      local name = card.name
      if (card.is_derived and not table.contains(whitelist, name)) or table.contains(blacklist, name) then
        local id = allCardIds[i]
        table.removeOne(allCardIds, id)
        table.insert(room.void, id)
        room:setCardArea(id, Card.Void, nil)
      end
    end
  
    table.shuffle(allCardIds)
    room.draw_pile = allCardIds
    for _, id in ipairs(room.draw_pile) do
      room:setCardArea(id, Card.DrawPile, nil)
    end
  end

  function vanished_dragon_logic:chooseGenerals()
    local room = self.room
    local generalNum = room.settings.generalNum
    local n = room.settings.enableDeputy and 2 or 1
    local lord = room:getLord()
    room.current = lord
    lord.role = "loyalist"
    for _, p in ipairs(room.players) do
      if p.role == "hidden" then
        p.role = "lord"
        room:notifyProperty(p, p, "role")
      end
    end

    room:doBroadcastNotify("ShowToast", "<b>" .. lord._splayer:getScreenName() .. "</b>" .. Fk:translate("vd_intro"))

    local lord_generals = {}

    if lord ~= nil then
      local generals = {}
      local lordlist = {}
      local lordpools = {}
      table.insertTable(generals, Fk:getGeneralsRandomly(generalNum, Fk:getAllGenerals(), table.map(generals, function (g)
        return g.name
      end)))
      for _, general in ipairs({"cuiyan", "ty__huangfusong"}) do
        if not table.contains(room.disabled_packs, Fk.generals[general].package.name) and
          not table.contains(room.disabled_generals, general) and not table.find(generals, function(g)
            return g.trueName == "cuiyan" or g.trueName == "huangfusong"
          end) then
          table.insert(lordlist, general)
        end
      end
      for i = 1, #generals do
        generals[i] = generals[i].name
      end
      lordpools = table.simpleClone(generals)
      table.insertTable(lordpools, lordlist)
      lord_generals = room:askForGeneral(lord, lordpools, n)
      local lord_general, deputy
      if type(lord_generals) == "table" then
        deputy = lord_generals[2]
        lord_general = lord_generals[1]
      else
        lord_general = lord_generals
        lord_generals = {lord_general}
      end

      room:setPlayerGeneral(lord, lord_general, true)
      room:askForChooseKingdom({lord})
      room:broadcastProperty(lord, "general")
      room:broadcastProperty(lord, "kingdom")
      room:setDeputyGeneral(lord, deputy)
      room:broadcastProperty(lord, "deputyGeneral")
    end

    local nonlord = room:getOtherPlayers(lord, true)
    local generals = Fk:getGeneralsRandomly(#nonlord * generalNum, nil, lord_generals)
    table.shuffle(generals)
    for _, p in ipairs(nonlord) do
      local arg = {}
      for i = 1, generalNum do
        table.insert(arg, table.remove(generals, 1).name)
      end
      p.request_data = json.encode{ arg, n }
      p.default_reply = table.random(arg, n)
    end

    room:notifyMoveFocus(nonlord, "AskForGeneral")
    room:doBroadcastRequest("AskForGeneral", nonlord)

    for _, p in ipairs(nonlord) do
      if p.general == "" and p.reply_ready then
        local generals = json.decode(p.client_reply)
        local general = generals[1]
        local deputy = generals[2]
        room:setPlayerGeneral(p, general, true, true)
        room:setDeputyGeneral(p, deputy)
      else
        room:setPlayerGeneral(p, p.default_reply[1], true, true)
        room:setDeputyGeneral(p, p.default_reply[2])
      end
      p.default_reply = ""
    end

    room:askForChooseKingdom(nonlord)
  end

  function vanished_dragon_logic:broadcastGeneral()
    local room = self.room
    local players = room.players
    local lord = room:getTag("ShownLoyalist")

    for _, p in ipairs(players) do
      assert(p.general ~= "")
      local general = Fk.generals[p.general]
      local deputy = Fk.generals[p.deputyGeneral]
      p.maxHp = deputy and math.floor((deputy.maxHp + general.maxHp) / 2)
        or general.maxHp
      p.hp = deputy and math.floor((deputy.hp + general.hp) / 2) or general.hp
      p.shield = math.min(general.shield + (deputy and deputy.shield or 0), 5)
      -- TODO: setup AI here

      if p.id ~= lord then
        room:broadcastProperty(p, "general")
        room:broadcastProperty(p, "kingdom")
        room:broadcastProperty(p, "deputyGeneral")
      elseif #players >= 5 then
        p.maxHp = p.maxHp + 1
        p.hp = p.hp + 1
      end
      room:broadcastProperty(p, "maxHp")
      room:broadcastProperty(p, "hp")
      room:broadcastProperty(p, "shield")
    end
  end

  function vanished_dragon_logic:attachSkillToPlayers()
    local room = self.room
    local players = room.players
    local lord = room:getTag("ShownLoyalist")
  
    local addRoleModSkills = function(player, skillName)
      local skill = Fk.skills[skillName]
      if skill.lordSkill then
        return
      end
  
      if #skill.attachedKingdom > 0 and not table.contains(skill.attachedKingdom, player.kingdom) then
        return
      end
  
      room:handleAddLoseSkills(player, skillName, nil, false)
    end
    for _, p in ipairs(room.alive_players) do
      local skills = Fk.generals[p.general].skills
      for _, s in ipairs(skills) do
        addRoleModSkills(p, s.name)
      end
      for _, sname in ipairs(Fk.generals[p.general].other_skills) do
        addRoleModSkills(p, sname)
      end
  
      local deputy = Fk.generals[p.deputyGeneral]
      if deputy then
        skills = deputy.skills
        for _, s in ipairs(skills) do
          addRoleModSkills(p, s.name)
        end
        for _, sname in ipairs(deputy.other_skills) do
          addRoleModSkills(p, sname)
        end
      end

      if p.id == lord then
        local skill = (p.maxHp <= 4 and p.gender == General.Male) and "vd_dongcha" or "vd_sheshen"
        room:doBroadcastNotify("ShowToast", Fk:translate("vd_loyalist_skill") .. Fk:translate(skill))
        room:handleAddLoseSkills(p, skill, nil, false)
      end
    end
  end

  return vanished_dragon_logic
end

--明主杀暗忠呢
---@param killer ServerPlayer
local function rewardAndPunish(killer, victim, room)
  if killer.dead then return end
  local shownLoyalist = room:getTag("ShownLoyalist")
  if (victim.id == shownLoyalist and killer.role == "lord") or (victim.role == "loyalist" and killer.id == shownLoyalist) then
    killer:throwAllCards("he")
  elseif victim.role == "rebel" or victim.id == shownLoyalist then
    killer:drawCards(3, "kill")
  end
end

local vanished_dragon_rule = fk.CreateTriggerSkill{
  name = "#vanished_dragon_rule",
  priority = 0.001,
  refresh_events = {fk.GameStart, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then return player.seat == 1 end
    if target ~= player then return false end
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:setTag("SkipNormalDeathProcess", true)
    elseif event == fk.Deathed then 
      local damage = data.damage
      if damage and damage.from then
        local killer = damage.from
        rewardAndPunish(killer, player, room)
      end

      local shownLoyalist = room:getTag("ShownLoyalist")
      if player.id == shownLoyalist then
        local lord = room:getLord()
        lord.role_shown = true
        room:broadcastProperty(lord, "role")
        room:doBroadcastNotify("ShowToast", Fk:translate("vd_lord_exploded") .. Fk:translate(lord.general))
        local skills = Fk.generals[lord.general].skills
        local addLordSkills = function(player, skillName)
          local skill = Fk.skills[skillName]
          if not skill.lordSkill then
            return
          end
          room:handleAddLoseSkills(player, skillName, nil, false)
        end
        for _, s in ipairs(skills) do
          addLordSkills(lord, s.name)
        end
        for _, sname in ipairs(Fk.generals[lord.general].other_skills) do
          addLordSkills(lord, sname)
        end
        local deputy = Fk.generals[lord.deputyGeneral]
        if deputy then
          skills = deputy.skills
          for _, s in ipairs(skills) do
            addLordSkills(lord, s.name)
          end
          for _, sname in ipairs(deputy.other_skills) do
            addLordSkills(lord, sname)
          end
        end
      end
    end
  end,
}

local vanished_dragon = fk.CreateGameMode{
  name = "vanished_dragon",
  minPlayer = 6,
  maxPlayer = 8,
  rule = vanished_dragon_rule,
  logic = vanished_dragon_getLogic,
  surrender_func = function(self, playedTime)
    return Fk.game_modes["aaa_role_mode"]:surrenderFunc(self, playedTime)
  end,
}

local vd_dongcha = fk.CreateTriggerSkill{
  name = "vd_dongcha",
  anim_type = "control",
  events = {fk.GameStart, fk.EventPhaseStart}, --游戏开始时，随机一名反贼的身份对你可见。准备阶段开始时，你可以弃置场上的一张牌。
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player and (event == fk.GameStart or (player.phase == Player.Start and table.find(player.room.alive_players, function(p) return not p:isAllNude() end)))
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      local targets = table.map(table.filter(room.alive_players, function(p) return not p:isAllNude() end), Util.IdMapper)
      if #targets == 0 then return false end
      local target = room:askForChoosePlayers(player, targets, 1, 1, "#vd_dongcha-ask", self.name, true)
      if #target > 0 then
        self.cost_data = target[1]
        return true
      end
      return false
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local players = table.simpleClone(room.alive_players)
      table.shuffle(players)
      for _, p in ipairs(players) do
        if p.role == "rebel" then
          room:notifyProperty(player, p, "role")
          break
        end
      end
      room:doBroadcastNotify("ShowToast", Fk:translate("vd_dongcha_rebel"))
    else
      local target = room:getPlayerById(self.cost_data)
      local card = room:askForCardChosen(player, target, "hej", self.name)
      room:throwCard({card}, self.name, target, player)
    end
  end,
}
Fk:addSkill(vd_dongcha)

local vd_sheshen = fk.CreateTriggerSkill{ --锁定技，主公处于濒死状态即将死亡时，你令其体力上限+1，回复体力至X点（X为你的体力值），获得你所有牌，然后你死亡。
  name = "vd_sheshen",
  anim_type = "big",
  events = {fk.AskForPeachesDone},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.role == "lord" and target.hp <= 0 and target.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(target, 1)
    room:recover({
      who = target,
      num = player.hp - target.hp,
      recoverBy = player,
      skillName = self.name,
    })
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player:getCardIds{Player.Hand, Player.Equip})
    if #dummy.subcards > 0 then
      room:obtainCard(target, dummy, false, fk.ReasonJustMove)
    end
    if not player.dead then
      room:killPlayer({who = player.id})
    end
  end,
}
Fk:addSkill(vd_sheshen)

Fk:loadTranslationTable{
  ["vanished_dragon"] = "忠胆英杰",
  [":vanished_dragon"] = desc_vanished_dragon,
  ["vd_intro"] = "是<b>明忠</b>，<b>开始选将</b><br>明忠是代替主公亮出身份牌的忠臣，明忠死后主公再翻出身份牌",
  ["vd_loyalist_skill"] = "明忠获得忠臣技：",
  ["vd_dongcha_rebel"] = "明忠发动了〖洞察〗，一名反贼的身份已被其知晓",
  ["vd_lord_exploded"] = "明忠阵亡，主公暴露：",

  ["vd_dongcha"] = "洞察",
  [":vd_dongcha"] = "游戏开始时，随机一名反贼的身份对你可见。准备阶段开始时，你可以弃置场上的一张牌。",
  ["vd_sheshen"] = "舍身",
  [":vd_sheshen"] = "锁定技，主公处于濒死状态即将死亡时，你令其体力上限+1，回复体力至X点（X为你的体力值），获得你所有牌，然后你死亡。",
  ["$vd_sheshen1"] = "舍身为主，死而无憾！",
  ["$vd_sheshen2"] = "捐躯赴国难，视死忽如归。",

  ["#vd_dongcha-ask"] = "洞察：你可以选择一名角色，弃置其场上一张牌",
}

return vanished_dragon
