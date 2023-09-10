local extension = Package("tenyear_huicui2")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_huicui2"] = "十周年-群英荟萃2",
  ["mu"] = "乐",
}

--江湖之远：管宁 黄承彦 胡昭 王烈 孟节
local guanning = General(extension, "guanning", "qun", 3, 7)
local dunshi = fk.CreateViewAsSkill{
  name = "dunshi",
  pattern = "slash,jink,peach,analeptic",
  interaction = function()
    local all_names, names = {"slash", "jink", "peach", "analeptic"}, {}
    local mark = Self:getMark("dunshi")
    for _, name in ipairs(all_names) do
      if type(mark) ~= "table" or not table.contains(mark, name) then
        local to_use = Fk:cloneCard(name)
        if ((Fk.currentResponsePattern == nil and to_use.skill:canUse(Self, to_use) and not Self:prohibitUse(to_use)) or
            (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
          table.insertIfNeed(names, name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    if not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, "dunshi_name-turn", use.card.trueName)
  end,
  enabled_at_play = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 then return false end
    local names = {"slash", "jink", "peach", "analeptic"}
    local mark = player:getMark("dunshi")
    for _, name in ipairs(names) do
      if type(mark) ~= "table" or not table.contains(mark, name) then
        local to_use = Fk:cloneCard(name)
        if to_use.skill:canUse(player, to_use) and not player:prohibitUse(to_use) then
          return true
        end
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 then return false end
    local names = {"slash", "jink", "peach", "analeptic"}
    local mark = player:getMark("dunshi")
    for _, name in ipairs(names) do
      if type(mark) ~= "table" or not table.contains(mark, name) then
        local to_use = Fk:cloneCard(name)
        if (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use)) then
          return true
        end
      end
    end
  end,
}
local dunshi_record = fk.CreateTriggerSkill{
  name = "#dunshi_record",
  anim_type = "special",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes("dunshi", Player.HistoryTurn) > 0 and target and target.phase ~= Player.NotActive then
      if target:getMark("dunshi-turn") == 0 then
        player.room:addPlayerMark(target, "dunshi-turn", 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"dunshi1", "dunshi2", "dunshi3"}
    for i = 1, 2, 1 do
      local choice = room:askForChoice(player, choices, self.name)
      table.removeOne(choices, choice)
      if choice == "dunshi1" then
        local skills = {}
        for _, general in ipairs(Fk:getAllGenerals()) do
          for _, skill in ipairs(general.skills) do
            local str = Fk:translate(skill.name)
            if not target:hasSkill(skill) and
              (string.find(str, "仁") or string.find(str, "义") or string.find(str, "礼") or string.find(str, "智") or string.find(str, "信")) then
              table.insertIfNeed(skills, skill.name)
            end
          end
        end
        if #skills > 0 then
          local skill = room:askForChoice(player, table.random(skills, math.min(3, #skills)), self.name, "#dunshi-chooseskill::"..target.id, true)
          room:handleAddLoseSkills(target, skill, nil, true, false)
        end
      elseif choice == "dunshi2" then
        room:changeMaxHp(player, -1)
        if not player.dead and player:getMark("dunshi") ~= 0 then
          player:drawCards(#player:getMark("dunshi"), "dunshi")
        end
      elseif choice == "dunshi3" then
        local mark = player:getMark("dunshi")
        if mark == 0 then
          mark = {}
        end
        table.insert(mark, player:getMark("dunshi_name-turn"))
        room:setPlayerMark(player, "dunshi", mark)

        local UImark = player:getMark("@$dunshi")
        if type(UImark) == "table" then
          table.removeOne(UImark, player:getMark("dunshi_name-turn"))
          room:setPlayerMark(player, "@$dunshi", UImark)
        end
      end
    end
    if not table.contains(choices, "dunshi1") then
      return true
    end
  end,

  refresh_events = {fk.EventLoseSkill, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill then
      player.room:setPlayerMark(player, "@$dunshi", {"slash", "jink", "peach", "analeptic"})
    else
      player.room:setPlayerMark(player, dunshi.name, 0)
      player.room:setPlayerMark(player, "@$dunshi", 0)
    end
  end,
}
dunshi:addRelatedSkill(dunshi_record)
guanning:addSkill(dunshi)
Fk:loadTranslationTable{
  ["guanning"] = "管宁",
  ["dunshi"] = "遁世",
  [":dunshi"] = "每回合限一次，你可视为使用或打出一张【杀】，【闪】，【桃】或【酒】。然后当前回合角色本回合下次造成伤害时，你选择两项：<br>"..
  "1.防止此伤害，选择1个包含“仁义礼智信”的技能令其获得；<br>"..
  "2.减1点体力上限并摸X张牌（X为你选择3的次数）；<br>"..
  "3.删除你本次视为使用的牌名。",
  ["#dunshi_record"] = "遁世",
  ["@$dunshi"] = "遁世",
  ["dunshi1"] = "防止此伤害，选择1个“仁义礼智信”的技能令其获得",
  ["dunshi2"] = "减1点体力上限并摸X张牌",
  ["dunshi3"] = "删除你本次视为使用的牌名",
  ["#dunshi-chooseskill"] = "遁世：选择令%dest获得的技能",

  ["$dunshi1"] = "失路青山隐，藏名白水游。",
  ["$dunshi2"] = "隐居青松畔，遁走孤竹丘。",
  ["~guanning"] = "高节始终，无憾矣。",
}

local huangchengyan = General(extension, "ty__huangchengyan", "qun", 3)
local jiezhen = fk.CreateActiveSkill{
  name = "jiezhen",
  anim_type = "control",
  prompt = "#jiezhen-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("@@jiezhen") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "@@jiezhen", 1)
    room:setPlayerMark(target, "jiezhen_source", effect.from)
    if not target:hasSkill("bazhen", true) then
      room:addPlayerMark(target, "jiezhen_tmpbazhen")
      room:handleAddLoseSkills(target, "bazhen", nil, true, false)
    end
  end,
}
local jiezhen_trigger = fk.CreateTriggerSkill{
  name = "#jiezhen_trigger",
  events = {fk.FinishJudge, fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jiezhen.name) then
      if event == fk.FinishJudge then
        return not target.dead and table.contains({"bazhen", "eight_diagram"}, data.reason) and
        target:getMark("jiezhen_source") == player.id
      elseif event == fk.TurnStart then
        if target == player then
          for _, p in ipairs(player.room.alive_players) do
            if p:getMark("jiezhen_source") == player.id then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    if event == fk.TurnStart then
      tos = table.filter(room.alive_players, function (p) return p:getMark("jiezhen_source") == player.id end)
    else
      table.insert(tos, target)
    end
    room:doIndicate(player.id, table.map(tos, function (p) return p.id end))
    for _, to in ipairs(tos) do
      if player.dead then break end
      room:setPlayerMark(to, "jiezhen_source", 0)
      room:setPlayerMark(to, "@@jiezhen", 0)
      if to:getMark("jiezhen_tmpbazhen") > 0 then
        room:handleAddLoseSkills(to, "-bazhen", nil, true, false)
      end
      if not to:isAllNude() then
        local card = room:askForCardChosen(player, to, "hej", jiezhen.name)
        room:obtainCard(player.id, card, false, fk.ReasonPrey)
      end
    end
  end,
}
local jiezhen_invalidity = fk.CreateInvaliditySkill {
  name = "#jiezhen_invalidity",
  invalidity_func = function(self, from, skill)
    if from:getMark("@@jiezhen") > 0 then
      return not (table.contains({Skill.Compulsory, Skill.Limited, Skill.Wake}, skill.frequency) or
        skill.name:endsWith("&") or skill.lordSkill)
    end
  end
}
local zecai = fk.CreateTriggerSkill{
  name = "zecai",
  frequency = Skill.Limited,
  events = {fk.RoundEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) < 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local player_table = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data[1]
      if use.card.type == Card.TypeTrick then
        local from = use.from
        player_table[from] = (player_table[from] or 0) + 1
      end
    end, Player.HistoryRound)
    local max_time, max_pid = 0, nil
    for pid, time in pairs(player_table) do
      if time > max_time then
        max_pid, max_time = pid, time
      elseif time == max_time then
        max_pid = 0
      end
    end
    local max_p = nil
    if max_pid ~= 0 then
      max_p = room:getPlayerById(max_pid)
    end
    if max_p and not max_p.dead then
      room:setPlayerMark(max_p, "@@zecai_extra", 1)
    end
    local to = room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, "#zecai-choose", self.name, true)
    if max_p and not max_p.dead then
      room:setPlayerMark(max_p, "@@zecai_extra", 0)
    end
    if #to > 0 then
      self.cost_data = {to[1], max_pid}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tar = room:getPlayerById(self.cost_data[1])
    if not tar:hasSkill("ex__jizhi", true) then
      room:addPlayerMark(tar, "zecai_tmpjizhi")
      room:handleAddLoseSkills(tar, "ex__jizhi", nil, true, false)
    end
    if self.cost_data[1] == self.cost_data[2] then
      tar:gainAnExtraTurn()
    end
  end,

  refresh_events = {fk.RoundEnd},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("zecai_tmpjizhi") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-ex__jizhi", nil, true, false)
  end,
}
local yinshih = fk.CreateTriggerSkill{
  name = "yinshih",
  frequency = Skill.Compulsory,
  anim_type = "defensive",
  events = {fk.FinishJudge, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.FinishJudge then
        return table.contains({"bazhen", "eight_diagram"}, data.reason) and player.room:getCardArea(data.card) == Card.Processing
      elseif event == fk.DamageInflicted then
        return player == target and (not data.card or data.card.color == Card.NoColor) and player:getMark("yinshih_defensive-turn") == 0 and
        #player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          local damage = e.data[5]
          if damage and damage.to == player and (not damage.card or damage.card.color == Card.NoColor) then
            return true
          end
        end, Player.HistoryTurn) == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.FinishJudge then
      player.room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    elseif event == fk.DamageInflicted then
      player.room:setPlayerMark(player, "yinshih_defensive-turn", 1)
      return true
    end
  end,
}
jiezhen:addRelatedSkill(jiezhen_trigger)
jiezhen:addRelatedSkill(jiezhen_invalidity)
huangchengyan:addSkill(jiezhen)
huangchengyan:addSkill(zecai)
huangchengyan:addSkill(yinshih)
Fk:loadTranslationTable{
  ["ty__huangchengyan"] = "黄承彦",
  ["jiezhen"] = "解阵",
  ["#jiezhen_trigger"] = "解阵",
  [":jiezhen"] = "出牌阶段限一次，你可令一名其他角色的所有技能替换为〖八阵〗（锁定技、限定技、觉醒技、主公技除外），"..
  "你的下回合开始或当其【八卦阵】判定后，其失去〖八阵〗并获得原技能，然后你获得其区域里的一张牌。",
  ["zecai"] = "择才",
  [":zecai"] = "限定技，一轮结束时，你可令一名其他角色获得〖集智〗直到下一轮结束，若其是本轮使用锦囊牌数唯一最多的角色，其执行一个额外的回合。",
  ["yinshih"] = "隐世",
  [":yinshih"] = "锁定技，你每回合首次受到无色牌或非游戏牌造成的伤害时，防止此伤害。当场上有角色判定【八卦阵】时，你获得其生效的判定牌。",

  ["#jiezhen-active"] = "发动解阵，将一名角色的技能替换为八阵",
  ["@@jiezhen"] = "解阵",
  ["#zecai-choose"] = "你可以发动择才，令一名其他角色获得集智直到下轮结束",
  ["@@zecai_extra"] = "择才 额外回合",

  ["$jiezhen1"] = "八阵无破，唯解死而向生。",
  ["$jiezhen2"] = "此阵，可由景门入、生门出。",
  ["$zecai1"] = "诸葛良才，可为我佳婿。",
  ["$zecai2"] = "梧桐亭亭，必引凤而栖。",
  ["$yinshih1"] = "南阳隐世，耕读传家。",
  ["$yinshih2"] = "手扶耒耜，不闻风雷。",
  ["~ty__huangchengyan"] = "卧龙出山天伦逝，悔教吾婿离南阳……",
}

Fk:loadTranslationTable{
  ["huzhao"] = "胡昭",
  ["midu"] = "弥笃",
  [":midu"] = "出牌阶段限一次，你可以选择一项：1.废除任意个装备栏或判定区，令一名角色摸等量的牌；2.恢复一个被废除的装备栏或判定区，"..
  "你获得〖活墨〗直到你下个回合开始。",
  ["xianwang"] = "贤望",
  [":xianwang"] = "锁定技，若你有废除的装备栏，其他角色计算与你的距离+1，你计算与其他角色的距离-1；若你有至少三个废除的装备栏，以上数字改为2。",
}

local wanglie = General(extension, "wanglie", "qun", 3)
local chongwang = fk.CreateTriggerSkill{
  name = "chongwang",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target ~= player and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then
      local mark = player:getMark(self.name)
      if mark ~= 0 and #mark > 1 then
        return mark[2] == player.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"Cancel", "chongwang2"}
    if player.room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, 2, "chongwang1")
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#chongwang-invoke::"..target.id)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if self.cost_data == "chongwang1" then
      player.room:obtainCard(target, data.card, true, fk.ReasonJustMove)
    else
      if data.toCard ~= nil then
        data.toCard = nil
      else
        data.nullifiedTargets = TargetGroup:getRealTargets(data.tos)
      end
    end
  end,

  refresh_events = {fk.CardUsing, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return player:hasSkill(self.name, true)
    else
      return data == self
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      if target == player and player:hasSkill(self.name) then
        room:setPlayerMark(player, "@@chongwang", 1)
      else
        room:setPlayerMark(player, "@@chongwang", 0)
      end
      local mark = player:getMark(self.name)
      if mark == 0 then mark = {} end
      if #mark == 2 then
        mark[2] = mark[1]  --mark2上一张牌使用者，mark1这张牌使用者
        mark[1] = data.from
      else
        table.insert(mark, 1, data.from)
      end
      room:setPlayerMark(player, self.name, mark)
    else
      --[[local events = room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryPhase)
      room:addPlayerMark(player, "zuojian-phase", #events)
      room:addPlayerMark(player, "@zuojian-phase", #events)]]  --TODO: 需要一个反向查找记录
    end
  end,
}
local huagui = fk.CreateTriggerSkill{
  name = "huagui",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), function(p) return p.id end)
    if #targets == 0 then return end
    local nums = {0, 0, 0}
    for _, p in ipairs(room.alive_players) do
      if p.role == "lord" or p.role == "loyalist" then
        nums[1] = nums[1] + 1
      elseif p.role == "rebel" then
        nums[2] = nums[2] + 1
      else
        nums[3] = nums[3] + 1
      end
    end
    local n = math.max(table.unpack(nums))
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#huagui-choose:::"..tostring(n), self.name, true, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.map(self.cost_data, function(id) return room:getPlayerById(id) end)

    local extraData = {
      num = 1,
      min_num = 1,
      include_equip = true,
      pattern = ".",
      reason = self.name,
    }
    for _, p in ipairs(tos) do
      p.request_data = json.encode({ "choose_cards_skill", "#huagui-card:"..player.id, true, json.encode(extraData) })
    end
    room:notifyMoveFocus(room.alive_players, self.name)
    room:doBroadcastRequest("AskForUseActiveSkill", tos)
    for _, p in ipairs(tos) do
      local id
      if p.reply_ready then
        local replyCard = json.decode(p.client_reply).card
        id = json.decode(replyCard).subcards[1]
      else
        id = table.random(p:getCardIds{Player.Hand, Player.Equip})
      end
      room:setPlayerMark(p, "huagui-phase", id)
    end

    for _, p in ipairs(tos) do
      local id = p:getMark("huagui-phase")
      local choices = {"huagui1"}
      if room:getCardArea(id) == Player.Hand then
        table.insert(choices, "huagui2")
      end
      local card = Fk:getCardById(id)
      p.request_data = json.encode({ choices, choices, self.name, "#huagui-choice:"..player.id.."::"..card:toLogString() })
    end
    room:notifyMoveFocus(room.alive_players, self.name)
    room:doBroadcastRequest("AskForChoice", tos)
    local get = true
    for _, p in ipairs(tos) do
      local choice
      if p.reply_ready then
        choice = p.client_reply
      else
        choice = "huagui1"
      end
      local card = Fk:getCardById(p:getMark("huagui-phase"))
      if choice == "huagui1" then
        get = false
        room:obtainCard(player, card, false, fk.ReasonGive)
      else
        p:showCards({card})
      end
    end

    if get then
      room:delay(2000)
    end
    for _, p in ipairs(tos) do
      if get then
        local card = Fk:getCardById(p:getMark("huagui-phase"))
        room:obtainCard(player, card, false, fk.ReasonPrey)
      end
      room:setPlayerMark(p, "huagui-phase", 0)
    end
  end,
}
wanglie:addSkill(chongwang)
wanglie:addSkill(huagui)
Fk:loadTranslationTable{
  ["wanglie"] = "王烈",
  ["chongwang"] = "崇望",
  [":chongwang"] = "其他角色使用一张基本牌或普通锦囊牌时，若你为上一张牌的使用者，你可令其获得其使用的牌或令该牌无效。",
  ["huagui"] = "化归",
  [":huagui"] = "出牌阶段开始时，你可秘密选择至多X名其他角色（X为最大阵营存活人数），这些角色同时选择一项：交给你一张牌；或展示一张牌。"..
  "若均选择展示牌，你获得这些牌。",
  ["@@chongwang"] = "崇望",
  ["#chongwang-invoke"] = "崇望：你可以令 %dest 对%arg执行的一项",
  ["chongwang1"] = "其获得此牌",
  ["chongwang2"] = "此牌无效",
  ["#huagui-choose"] = "化归：你可以秘密选择至多%arg名角色，各选择交给你一张牌或展示一张牌",
  ["#huagui-card"] = "化归：选择一张牌，交给 %src 或展示之",
  ["#huagui-choice"] = "化归：选择将%arg交给 %src 或展示之",
  ["huagui1"] = "交出",
  ["huagui2"] = "展示",

  ["$chongwang1"] = "乡人所崇者，烈之义行也。",
  ["$chongwang2"] = "诸家争讼曲直，可质于我。",
  ["$huagui1"] = "烈不才，难为君之朱紫。",
  ["$huagui2"] = "一身风雨，难坐高堂。",
  ["~wanglie"] = "烈尚不能自断，何断人乎？",
}

local mengjie = General(extension, "mengjie", "qun", 3)
local yinlu = fk.CreateTriggerSkill{
  name = "yinlu",
  events = {fk.GameStart, fk.EventPhaseStart, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start
      else
        for i = 1, 4, 1 do
          if target:getMark("@@yinlu"..i) > 0 then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    elseif event == fk.EventPhaseStart then
      local targets = {}
      for _, p in ipairs(player.room:getAlivePlayers()) do
        for i = 1, 4, 1 do
          if p:getMark("@@yinlu"..i) > 0 then
            table.insert(targets, p.id)
          end
        end
      end
      if #targets > 0 then
        local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#yinlu_move-invoke1", self.name, true)
        if #to > 0 then
          self.cost_data = to[1]
          return true
        end
      end
    else
      if player.room:askForSkillInvoke(player, self.name, nil, "#yinlu_move-invoke2::"..target.id) then
        self.cost_data = target.id
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local targets = table.map(room:getAlivePlayers(), function(p) return p.id end)
      for i = 1, 3, 1 do
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#yinlu-give"..i, self.name)
        if #to > 0 then
          to = to[1]
        else
          to = table.random(targets)
        end
        room:setPlayerMark(room:getPlayerById(to), "@@yinlu"..i, 1)
      end
      room:setPlayerMark(player, "@@yinlu4", 1)
      room:addPlayerMark(player, "@yunxiang", 1)  --开局自带一个小芸香标记
    else
      local to = room:getPlayerById(self.cost_data)
      local choices = {}
      for i = 1, 4, 1 do
        if to:getMark("@@yinlu"..i) > 0 then
          table.insert(choices, "@@yinlu"..i)
        end
      end
      if event == fk.Death then
        table.insert(choices, "Cancel")
      end
      while true do
        local choice = room:askForChoice(player, choices, self.name, "#yinlu-choice")
        if choice == "Cancel" then return end
        table.removeOne(choices, choice)
        local targets = table.map(room:getOtherPlayers(to), function(p) return p.id end)
        local dest
        if #targets > 1 then
          dest = room:askForChoosePlayers(player, targets, 1, 1, "#yinlu-move:::"..choice, self.name, false)
          if #dest > 0 then
            dest = dest[1]
          else
            dest = table.random(targets)
          end
        else
          dest = targets[1]
        end
        dest = room:getPlayerById(dest)
        room:setPlayerMark(to, choice, 0)
        room:setPlayerMark(dest, choice, 1)
        if event == fk.EventPhaseStart then return end
      end
    end
  end,

  refresh_events = {fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true, true) and
      not table.find(player.room.alive_players, function(p) return p:hasSkill(self.name, true) end)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      for i = 1, 4, 1 do
        room:setPlayerMark(p, "@@yinlu"..i, 0)
      end
    end
  end,
}
local yinlu1 = fk.CreateTriggerSkill{
  name = "#yinlu1",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yinlu1") > 0 and player.phase == Player.Finish and player:isWounded() and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, true, "yinlu", true, ".|.|diamond", "#yinlu1-invoke") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = "yinlu",
    }
  end,
}
local yinlu2 = fk.CreateTriggerSkill{
  name = "#yinlu2",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yinlu2") > 0 and player.phase == Player.Finish and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, true, "yinlu", true, ".|.|heart", "#yinlu2-invoke") > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, "yinlu")
  end,
}
local yinlu3 = fk.CreateTriggerSkill{
  name = "#yinlu3",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yinlu3") > 0 and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    if player:isNude() or #player.room:askForDiscard(player, 1, 1, true, "yinlu", true, ".|.|spade", "#yinlu3-invoke") == 0 then
      player.room:loseHp(player, 1, "yinlu")
    end
  end,
}
local yinlu4 = fk.CreateTriggerSkill{
  name = "#yinlu4",
  mute = true,
  events = {fk.EventPhaseStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseStart then
        return player:getMark("@@yinlu4") > 0 and player.phase == Player.Finish and not player:isNude()
      else
        return player:getMark("@yunxiang") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return #player.room:askForDiscard(player, 1, 1, true, "yinlu", true, ".|.|club", "#yinlu4-invoke") > 0
    else
      return player.room:askForSkillInvoke(player, "yinlu", nil, "#yinlu-yunxiang")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:addPlayerMark(player, "@yunxiang", 1)
    else
      local num = player:getMark("@yunxiang")
      room:setPlayerMark(player, "@yunxiang", 0)
      if data.damage > num then
        data.damage = data.damage - num
      else
        return true
      end
    end
  end,
}
local youqi = fk.CreateTriggerSkill{
  name = "youqi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.skillName == "yinlu" and move.from and move.from ~= player.id then
          self.cost_data = move
          local x = 1 - (math.min(5, player:distanceTo(player.room:getPlayerById(move.from))) / 10)
          return x > math.random()  --据说，距离1 0.9概率，距离5以上 0.5概率
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, info in ipairs(self.cost_data.moveInfo) do
      player.room:obtainCard(player.id, info.cardId, true, fk.ReasonJustMove)
    end
  end,
}
yinlu:addRelatedSkill(yinlu1)
yinlu:addRelatedSkill(yinlu2)
yinlu:addRelatedSkill(yinlu3)
yinlu:addRelatedSkill(yinlu4)
mengjie:addSkill(yinlu)
mengjie:addSkill(youqi)
Fk:loadTranslationTable{
  ["mengjie"] = "孟节",
  ["yinlu"] = "引路",
  [":yinlu"] = "游戏开始时，你令三名角色依次获得以下一个标记：“乐泉”、“藿溪”、“瘴气”，然后你获得一个“芸香”。<br>"..
  "准备阶段，你可以移动一个标记；有标记的角色死亡时，你可以移动其标记。拥有标记的角色获得对应的效果：<br>"..
  "乐泉：结束阶段，你可以弃置一张<font color='red'>♦</font>牌，然后回复1点体力；<br>"..
  "藿溪：结束阶段，你可以弃置一张<font color='red'>♥</font>牌，然后摸两张牌；<br>"..
  "瘴气：结束阶段，你需要弃置一张♠牌，否则失去1点体力；<br>"..
  "芸香：结束阶段，你可以弃置一张♣牌，获得一个“芸香”；当你受到伤害时，你可以移去所有“芸香”并防止等量的伤害。",
  ["youqi"] = "幽栖",
  [":youqi"] = "锁定技，其他角色因“引路”弃置牌时，你有概率获得此牌，该角色距离你越近，概率越高。",
  ["#yinlu-give1"] = "引路：请选择获得“乐泉”（回复体力）的角色",
  ["#yinlu-give2"] = "引路：请选择获得“藿溪”（摸牌）的角色",
  ["#yinlu-give3"] = "引路：请选择获得“瘴气”（失去体力）的角色",
  ["#yinlu-give4"] = "引路：请选择获得“芸香”（防止伤害）的角色",
  ["@@yinlu1"] = "<font color='red'>♦</font>乐泉",
  ["@@yinlu2"] = "<font color='red'>♥</font>藿溪",
  ["@@yinlu3"] = "♠瘴气",
  ["@@yinlu4"] = "♣芸香",
  ["@yunxiang"] = "芸香",
  ["#yinlu_move-invoke1"] = "引路：你可以移动一个标记",
  ["#yinlu_move-invoke2"] = "引路：你可以移动 %dest 的标记",
  ["#yinlu-choice"] = "引路：请选择要移动的标记",
  ["#yinlu-move"] = "引路：请选择获得“%arg”的角色",
  ["#yinlu1"] = "<font color='red'>♦</font>乐泉",
  ["#yinlu2"] = "<font color='red'>♥</font>藿溪",
  ["#yinlu3"] = "♠瘴气",
  ["#yinlu4"] = "♣芸香",
  ["#yinlu1-invoke"] = "<font color='red'>♦</font>乐泉：你可以弃置一张<font color='red'>♦</font>牌，回复1点体力",
  ["#yinlu2-invoke"] = "<font color='red'>♥</font>藿溪：你可以弃置一张<font color='red'>♥</font>牌，摸两张牌",
  ["#yinlu3-invoke"] = "♠瘴气：你需弃置一张♠牌，否则失去1点体力",
  ["#yinlu4-invoke"] = "♣芸香：你可以弃置一张♣牌，获得一个可以防止1点伤害的“芸香”标记",
  ["#yinlu-yunxiang"] = "♣芸香：你可以消耗所有“芸香”，防止等量的伤害",
  
  ["$yinlu1"] = "南疆苦瘴，非土人不得过。",
  ["$yinlu2"] = "闻丞相南征，某特来引之。",
  ["$youqi1"] = "寒烟锁旧山，坐看云起出。",
  ["$youqi2"] = "某隐居山野，不慕富贵功名。",
  ["~mengjie"] = "蛮人无知，请丞相教之……",
}

--悬壶济世：吉平 孙寒华 郑浑 刘宠骆俊
--吉平

local sunhanhua = General(extension, "ty__sunhanhua", "wu", 3, 3, General.Female)
local huiling = fk.CreateTriggerSkill{
  name = "huiling",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and #player.room.discard_pile > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local red = #table.filter(room.discard_pile, function(id) return Fk:getCardById(id).color == Card.Red end)
    local black = #table.filter(room.discard_pile, function(id) return Fk:getCardById(id).color == Card.Black end)
    player:broadcastSkillInvoke(self.name)
    if red > black then
      if player:isWounded() then
        room:notifySkillInvoked(player, self.name, "support")
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
      if data.card.color == Card.Black then
        room:notifySkillInvoked(player, self.name, "special")
        room:addPlayerMark(player, "@ty__sunhanhua_ling", 1)
      end
    elseif black > red then
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isAllNude() end), function(p) return p.id end)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#huiling-choose", self.name, false)
        if #to > 0 then
          room:notifySkillInvoked(player, self.name, "control")
          to = room:getPlayerById(to[1])
          local id = room:askForCardChosen(player, to, "hej", self.name)
          room:throwCard({id}, self.name, to, player)
        end
      end
      if data.card.color == Card.Red then
        room:notifySkillInvoked(player, self.name, "special")
        room:addPlayerMark(player, "@ty__sunhanhua_ling", 1)
      end
    end
  end,
}
local chongxu = fk.CreateActiveSkill{
  name = "chongxu",
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  prompt = function(self)
    return "#chongxu:::"..Self:getMark("@ty__sunhanhua_ling")
  end,
  can_use = function(self, player)
    return player:getMark("@ty__sunhanhua_ling") > 3 and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player:hasSkill("huiling", true)
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:handleAddLoseSkills(player, "-huiling", nil, true, false)
    room:changeMaxHp(player, player:getMark("@ty__sunhanhua_ling"))
    room:setPlayerMark(player, "@ty__sunhanhua_ling", 0)
    room:handleAddLoseSkills(player, "taji|qinghuang", nil, true, false)
  end
}
local function doTaji(player, n)
  local room = player.room
  if n == 1 then
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isAllNude() end), function(p) return p.id end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#taji-choose", "taji", false)
    if #to > 0 then
      room:notifySkillInvoked(player, "taji", "control")
      to = room:getPlayerById(to[1])
      local id = room:askForCardChosen(player, to, "he", "taji")
      room:throwCard({id}, "taji", to, player)
    end
  elseif n == 2 then
    room:notifySkillInvoked(player, "taji", "drawcard")
    player:drawCards(1, "taji")
  elseif n == 3 then
    if player:isWounded() then
      room:notifySkillInvoked(player, "taji", "support")
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = "taji",
      }
    end
  elseif n == 4 then
    room:notifySkillInvoked(player, "taji", "offensive")
    room:addPlayerMark(player, "@taji", 1)
  end
end
local taji = fk.CreateTriggerSkill{
  name = "taji",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local index = {}
    for _, move in ipairs(data) do
      if move.from == player.id then
        player:broadcastSkillInvoke(self.name)
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            if move.moveReason == fk.ReasonUse then
              table.insert(index, 1)
            elseif move.moveReason == fk.ReasonResonpse then
              table.insert(index, 2)
            elseif move.moveReason == fk.ReasonDiscard then
              table.insert(index, 3)
            else
              table.insert(index, 4)
            end
          end
        end
      end
    end
    for _, i in ipairs(index) do
      if player.dead then return end
      doTaji(player, i)
      if not player.dead and player:getMark("@@qinghuang-turn") > 0 then
        local nums = {1, 2, 3, 4}
        table.removeOne(nums, i)
        doTaji(player, table.random(nums))
      end
    end
  end,
}
local taji_trigger = fk.CreateTriggerSkill{
  name = "#taji_trigger",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to ~= player and player:getMark("@taji") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("@taji")
    player.room:setPlayerMark(player, "@taji", 0)
  end,
}
local qinghuang = fk.CreateTriggerSkill{
  name = "qinghuang",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qinghuang-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not player.dead then
      room:setPlayerMark(player, "@@qinghuang-turn", 1)
    end
  end,
}
taji:addRelatedSkill(taji_trigger)
sunhanhua:addSkill(huiling)
sunhanhua:addSkill(chongxu)
sunhanhua:addRelatedSkill(taji)
sunhanhua:addRelatedSkill(qinghuang)
Fk:loadTranslationTable{
  ["ty__sunhanhua"] = "孙寒华",
  ["huiling"] = "汇灵",
  [":huiling"] = "锁定技，你使用牌时，若弃牌堆中的红色牌数量多于黑色牌，你回复1点体力；"..
  "黑色牌数量多于红色牌，你可以弃置一名其他角色区域内的一张牌；牌数较少的颜色与你使用牌的颜色相同，你获得一个“灵”标记。",
  ["chongxu"] = "冲虚",
  [":chongxu"] = "限定技，出牌阶段，若“灵”的数量不小于4，你可以失去〖汇灵〗，增加等量的体力上限，并获得〖踏寂〗和〖清荒〗。",
  ["taji"] = "踏寂",
  [":taji"] = "当你失去手牌后，你根据此牌的失去方式执行效果：<br>使用-弃置一名其他角色一张牌；<br>打出-摸一张牌；<br>弃置-回复1点体力；<br>"..
  "其他-你下次对其他角色造成的伤害+1。",
  ["qinghuang"] = "清荒",
  [":qinghuang"] = "出牌阶段开始时，你可以减1点体力上限，然后你本回合发动〖踏寂〗时随机额外执行一种效果。",
  ["@ty__sunhanhua_ling"] = "灵",
  ["#huiling-choose"] = "汇灵：你可以弃置一名其他角色区域内的一张牌",
  ["#chongxu"] = "冲虚：你可以失去〖汇灵〗，加%arg点体力上限，获得〖踏寂〗和〖清荒〗",
  ["@taji"] = "踏寂",
  ["#taji-choose"] = "踏寂：你可以弃置一名其他角色一张牌",
  ["#taji_trigger"] = "踏寂",
  ["#qinghuang-invoke"] = "清荒：你可以减1点体力上限，令你本回合发动〖踏寂〗时随机额外执行一种效果",
  ["@@qinghuang-turn"] = "清荒",

  ["$huiling1"] = "天地有灵，汇于我眸间。",
  ["$huiling2"] = "撷四时钟灵，拈芳兰毓秀。",
  ["$chongxu1"] = "慕圣道冲虚，有求者皆应。",
  ["$chongxu2"] = "养志无为，遗冲虚于物外。",
  ["$taji1"] = "仙途本寂寥，结发叹长生。",
  ["$taji2"] = "仙者不言，手执春风。",
  ["$qinghuang1"] = "上士无争，焉生妄心。",
  ["$qinghuang2"] = "心有草木，何畏荒芜？",
  ["~ty__sunhanhua"] = "长生不长乐，悔觅仙途……",
}

local zhenghun = General(extension, "zhenghun", "wei", 3)
local qiangzhiz = fk.CreateActiveSkill{
  name = "qiangzhiz",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and
      #Fk:currentRoom():getPlayerById(to_select):getCardIds{Player.Hand, Player.Equip} + #Self:getCardIds{Player.Hand, Player.Equip} > 2
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card_data = {}
    if #target:getCardIds(Player.Hand) > 0 then
      local handcards = {}
      --FIXME：如何手动判定自动明牌的逻辑？
      for _ = 1, #target:getCardIds(Player.Hand), 1 do
        table.insert(handcards, -1)
      end
      table.insert(card_data, { "needhand", handcards })
    end
    if #target:getCardIds(Player.Equip) > 0 then
      table.insert(card_data, { "needequip", target:getCardIds(Player.Equip) })
    end
    if #player:getCardIds(Player.Hand) > 0 then
      table.insert(card_data, { "wordhand", player:getCardIds(Player.Hand) })
    end
    if #player:getCardIds(Player.Equip) > 0 then
      table.insert(card_data, { "wordequip", player:getCardIds(Player.Equip) })
    end
    local cards = room:askForCardsChosen(player, target, 3, 3, { card_data = card_data }, self.name)
    local cards1 = table.filter(cards, function(id) return table.contains(player:getCardIds{Player.Hand, Player.Equip}, id) end)
    local cards2 = table.filter(cards, function(id) return table.contains(target:getCardIds{Player.Hand, Player.Equip}, id) end)
    local moveInfos = {}
    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = player.id,
        ids = cards1,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moveInfos, {
        from = target.id,
        ids = cards2,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
    if not player.dead and not target.dead then
      if #cards1 == 3 then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      elseif #cards2 == 3 then
        room:damage{
          from = target,
          to = player,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
local pitian = fk.CreateTriggerSkill{
  name = "pitian",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove, fk.Damaged, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            return true
          end
        end
      elseif event == fk.Damaged then
        return target == player
      else
        return target == player and player.phase == Player.Finish and player:getHandcardNum() < player:getMaxCards()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#pitian-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      player:drawCards(math.min(player:getMaxCards() - player:getHandcardNum(), 5), self.name)
      player.room:setPlayerMark(player, "@pitian", 0)
    else
      player.room:addPlayerMark(player, "@pitian", 1)
    end
  end,
}
local pitian_maxcards = fk.CreateMaxCardsSkill{
  name = "#pitian_maxcards",
  correct_func = function(self, player)
    return player:getMark("@pitian")
  end,
}
pitian:addRelatedSkill(pitian_maxcards)
zhenghun:addSkill(qiangzhiz)
zhenghun:addSkill(pitian)
Fk:loadTranslationTable{
  ["zhenghun"] = "郑浑",
  ["qiangzhiz"] = "强峙",
  [":qiangzhiz"] = "出牌阶段限一次，你可以弃置你和一名其他角色共计三张牌。若有角色因此弃置三张牌，其对另一名角色造成1点伤害。",
  ["pitian"] = "辟田",
  [":pitian"] = "当你的牌因弃置而进入弃牌堆后或当你受到伤害后，你的手牌上限+1。结束阶段，若你的手牌数小于手牌上限，"..
  "你可以将手牌摸至手牌上限（最多摸五张），然后重置因此技能而增加的手牌上限。",
  ["#qiangzhiz-choose"] = "强峙：弃置双方共计三张牌",
  ["#pitian-invoke"] = "辟田：你可以将手牌摸至手牌上限，然后重置本技能增加的手牌上限",
  ["@pitian"] = "辟田",

  ["wordhand"] = "我的手牌",
  ["wordequip"] = "我的装备",
  ["needhand"] = "对方手牌",
  ["needequip"] = "对方装备",

  ["$qiangzhiz1"] = "吾民在后，岂惧尔等魍魉。",
  ["$qiangzhiz2"] = "凶兵来袭，当长戈相迎。",
  ["$pitian1"] = "此间辟地数旬，必成良田千亩。",
  ["$pitian2"] = "民以物力为天，物力唯田可得。",
  ["~zhenghun"] = "此世为官，未辱青天之名……",
}

local liuchongluojun = General(extension, "liuchongluojun", "qun", 3)
local minze = fk.CreateActiveSkill{
  name = "minze",
  anim_type = "support",
  min_card_num = 1,
  max_card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("@@minze-phase") == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:getCardById(to_select).trueName ~= Fk:getCardById(selected[1]).trueName
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and Self:getHandcardNum() > target:getHandcardNum() and target:getMark("minze-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = player:getMark("@$minze-turn")
    if mark == 0 then mark = {} end
    for _, id in ipairs(effect.cards) do
      table.insertIfNeed(mark, Fk:getCardById(id).trueName)
    end
    room:setPlayerMark(player, "@$minze-turn", mark)
    room:setPlayerMark(target, "minze-phase", 1)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:obtainCard(target, dummy, false, fk.ReasonGive)
    if target:getHandcardNum() > player:getHandcardNum() then
      room:setPlayerMark(player, "@@minze-phase", 1)
    end
  end,
}
local minze_trigger = fk.CreateTriggerSkill{
  name = "#minze_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("minze") and player.phase == Player.Finish and
      player:getMark("@$minze-turn") ~= 0 and player:getHandcardNum() < math.min(#player:getMark("@$minze-turn"), 5)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("minze")
    room:notifySkillInvoked(player, "minze", "drawcard")
    player:drawCards(math.min(#player:getMark("@$minze-turn"), 5) - player:getHandcardNum(), "minze")
  end,
}
local jini = fk.CreateTriggerSkill{
  name = "jini",
  anim_type = "masochism",
  events ={fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not player:isKongcheng() and player:getMark("jini-turn") < player.maxHp
  end,
  on_cost = function(self, event, target, player, data)
    local n = player.maxHp - player:getMark("jini-turn")
    local prompt = "#jini1-invoke:::"..n
    if data.from and data.from ~= player and not data.from.dead then
      prompt = "#jini2-invoke::"..data.from.id..":"..n
    end
    local cards = player.room:askForCard(player, 1, n, false, self.name, true, ".", prompt)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #self.cost_data
    room:moveCards({
      ids = self.cost_data,
      from = player.id,
      toArea = Card.DiscardPile,
      skillName = self.name,
      moveReason = fk.ReasonPutIntoDiscardPile,
      proposer = target.id
    })
    room:sendLog{
      type = "#RecastBySkill",
      from = player.id,
      card = self.cost_data,
      arg = self.name,
    }
    local cards = player:drawCards(n, self.name)
    room:addPlayerMark(player, "jini-turn", n)
    if player.dead or not data.from or data.from == player or data.from.dead then return end
    if table.find(cards, function(id) return Fk:getCardById(id, true).trueName == "slash" end) then
      local use = room:askForUseCard(player, "slash", "slash", "#jini-slash::"..data.from.id, true,
        {must_targets = {data.from.id}, bypass_distances = true, bypass_times = true})
      if use then
        use.disresponsiveList = {data.from.id}
        room:useCard(use)
      end
    end
  end,
}
minze:addRelatedSkill(minze_trigger)
liuchongluojun:addSkill(minze)
liuchongluojun:addSkill(jini)
Fk:loadTranslationTable{
  ["liuchongluojun"] = "刘宠骆俊",
  ["minze"] = "悯泽",
  [":minze"] = "出牌阶段每名角色限一次，你可以将至多两张牌名不同的牌交给一名手牌数小于你的角色，然后若其手牌数大于你，本阶段此技能失效。"..
  "结束阶段，你将手牌补至X张（X为本回合你因此技能失去牌的牌名数，至多为5）。",
  ["jini"] = "击逆",
  [":jini"] = "当你受到伤害后，你可以重铸任意张手牌（每回合以此法重铸的牌数不能超过你的体力上限），若你以此法获得了【杀】，"..
  "你可以对伤害来源使用一张无距离限制且不可响应的【杀】。",
  ["@@minze-phase"] = "悯泽失效",
  ["@$minze-turn"] = "悯泽",
  ["#jini1-invoke"] = "击逆：你可以重铸至多%arg张手牌",
  ["#jini2-invoke"] = "击逆：你可以重铸至多%arg张手牌，若摸到了【杀】，你可以对 %dest 使用一张无距离限制且不可响应的【杀】",
  ["#jini-slash"] = "击逆：你可以对 %dest 使用一张无距离限制且不可响应的【杀】",

  ["$minze1"] = "百姓千载皆苦，勿以苛政待之。",
  ["$minze2"] = "黎庶待哺，人主当施恩德泽。",
  ["$jini1"] = "备劲弩强刃，待恶客上门。",
  ["$jini2"] = "逆贼犯境，诸君当共击之。",
  ["~liuchongluojun"] = "袁术贼子，折我大汉基业……",
}

--纵横捭阖：陆郁生 祢衡 华歆 荀谌 冯熙 邓芝 宗预 羊祜
local luyusheng = General(extension, "luyusheng", "wu", 3, 3, General.Female)
local zhente = fk.CreateTriggerSkill{
  name = "zhente",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 and data.from ~= player.id then
      return data.card:isCommonTrick() or data.card.type == Card.TypeBasic
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, nil,
    "#zhente-invoke:".. data.from .. "::" .. data.card:toLogString() .. ":" .. data.card:getColorString()) then
      player.room:doIndicate(player.id, {data.from})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.from)
    local color = data.card:getColorString()
    local choice = room:askForChoice(to, {
      "zhente_negate::" .. tostring(player.id) .. ":" .. data.card.name,
      "zhente_colorlimit:::" .. color
    }, self.name)
    if choice:startsWith("zhente_negate") then
      table.insertIfNeed(data.nullifiedTargets, player.id)
    else
      local colorsRecorded = type(to:getMark("@zhente-turn")) == "table" and to:getMark("@zhente-turn") or {}
      table.insertIfNeed(colorsRecorded, color)
      room:setPlayerMark(to, "@zhente-turn", colorsRecorded)
    end
  end,
}
local zhente_prohibit = fk.CreateProhibitSkill{
  name = "#zhente_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getMark("@zhente-turn")
    return type(mark) == "table" and table.contains(mark, card:getColorString())
  end,
}
local zhiwei = fk.CreateTriggerSkill{
  name = "zhiwei",
  events = {fk.GameStart, fk.TurnStart, fk.AfterCardsMove, fk.Damage, fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      elseif event == fk.TurnStart then
        return player == target and player:getMark(self.name) == 0
      elseif event == fk.AfterCardsMove then
        if player.phase ~= Player.Discard then return false end
        local zhiwei_id = player:getMark(self.name)
        if zhiwei_id == 0 then return false end
        local room = player.room
        local to = room:getPlayerById(zhiwei_id)
        if to == nil or to.dead then return false end
        for _, move in ipairs(data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              room:getCardArea(info.cardId) == Card.DiscardPile then
                return true
              end
            end
          end
        end
      elseif event == fk.Damage then
        return target ~= nil and not target.dead and player:getMark(self.name) == target.id
      elseif event == fk.Damaged then
        return target ~= nil and not target.dead and player:getMark(self.name) == target.id and not player:isKongcheng()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TurnStart then
      local room = player.room
      local targets = table.map(room:getOtherPlayers(player, false), function(p) return p.id end)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiwei-choose", self.name, true, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
      return false
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      room:notifySkillInvoked(player, self.name, "special")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(player, self.name, self.cost_data)
    elseif event == fk.GameStart then
      room:notifySkillInvoked(player, self.name, "special")
      player:broadcastSkillInvoke(self.name)
      local targets = table.map(room:getOtherPlayers(player, false), function(p) return p.id end)
      if #targets == 0 then return false end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiwei-choose", self.name, false, true)
      if #to > 0 then
        room:setPlayerMark(player, self.name, to[1])
      end
    elseif event == fk.AfterCardsMove then
      local zhiwei_id = player:getMark(self.name)
      if zhiwei_id == 0 then return false end
      local to = room:getPlayerById(zhiwei_id)
      if to == nil or to.dead then return false end
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            room:getCardArea(info.cardId) == Card.DiscardPile then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      if #cards > 0 then
        room:notifySkillInvoked(player, self.name, "support")
        player:broadcastSkillInvoke(self.name)
        room:setPlayerMark(player, "@zhiwei", to.general)
        room:moveCards({
        ids = cards,
        to = zhiwei_id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
      end
    elseif event == fk.Damage then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(player, "@zhiwei", target.general)
      room:drawCards(player, 1, self.name)
    elseif event == fk.Damaged then
      local cards = player:getCardIds(Player.Hand)
      if #cards > 0 then
        room:notifySkillInvoked(player, self.name, "negative")
        player:broadcastSkillInvoke(self.name)
        room:setPlayerMark(player, "@zhiwei", target.general)
        room:throwCard(table.random(cards, 1), self.name, player, player)
      end
    end
  end,

  refresh_events = {fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) == target.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, 0)
    room:setPlayerMark(player, "@zhiwei", 0)
  end,
}
zhente:addRelatedSkill(zhente_prohibit)
luyusheng:addSkill(zhente)
luyusheng:addSkill(zhiwei)
Fk:loadTranslationTable{
  ["luyusheng"] = "陆郁生",
  ["zhente"] = "贞特",
  [":zhente"] = "每名角色的回合限一次，当你成为其他角色使用基本牌或普通锦囊牌的目标后，你可令其选择一项：1.本回合不能再使用此颜色的牌；2.此牌对你无效。",
  ["zhiwei"] = "至微",
  [":zhiwei"] = "游戏开始时，你选择一名其他角色，该角色造成伤害后，你摸一张牌；该角色受到伤害后，你随机弃置一张手牌。"..
  "你弃牌阶段弃置的牌均被该角色获得。准备阶段，若场上没有“至微”角色，你可以重新选择一名其他角色。",
  --实测：目标死亡时（具体时机不确定）会发动一次技能，推测是清理标记
  --实测：只在目标死亡的下个准备阶段（具体时机不确定）可以重新选择角色，若取消则此后不会再询问了
  --懒得按这个逻辑做

  ["#zhente-invoke"] = "是否使用贞特，令%src选择令【%arg】对你无效或不能再使用%arg2牌",
  ["zhente_negate"] = "令【%arg】对%dest无效",
  ["zhente_colorlimit"] = "本回合不能再使用%arg牌",
  ["@zhente-turn"] = "贞特",
  ["#zhiwei-choose"] = "至微：选择一名其他角色",
  ["@zhiwei"] = "至微",

  ["$zhente1"] = "抗声昭节，义形于色。",
  ["$zhente2"] = "少履贞特之行，三从四德。",
  ["$zhiwei1"] = "体信贯于神明，送终以礼。",
  ["$zhiwei2"] = "昭德以行，生不能侍奉二主。",
  ["~luyusheng"] = "父亲，郁生甚是想念……",
}

local miheng = General(extension, "ty__miheng", "qun", 3)
local kuangcai = fk.CreateTriggerSkill{
  name = "kuangcai",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if player.phase == Player.Discard then
        local n = 0
        for _, v in pairs(player.cardUsedHistory) do
          if v[Player.HistoryTurn] > 0 then
            n = 1
            break
          end
        end
        if n == 0 then
          return true
        else
          return player:getMark("@kuangcai-turn") == 0 and player:getMaxCards() > 0
        end
      elseif player.phase == Player.Finish then
        return player:getMark("@kuangcai-turn") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if player.phase == Player.Discard then
      local n = 0
      for _, v in pairs(player.cardUsedHistory) do
        if v[Player.HistoryTurn] > 0 then
          n = 1
          break
        end
      end
      if n == 0 then
        room:notifySkillInvoked(player, self.name, "support")
        room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
      else
        room:notifySkillInvoked(player, self.name, "negative")
        room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
      end
    elseif player.phase == Player.Finish then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(math.min(player:getMark("@kuangcai-turn"), 5))
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase < Player.Finish
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "kuangcai-turn", data.damage)
    if player:hasSkill(self.name, true) then
      room:setPlayerMark(player, "@kuangcai-turn", player:getMark("kuangcai-turn"))
    end
  end,
}
local kuangcai_targetmod = fk.CreateTargetModSkill{
  name = "#kuangcai_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill("kuangcai") and scope == Player.HistoryPhase and player.phase ~= Player.NotActive
  end,
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill("kuangcai") and player.phase ~= Player.NotActive
  end,
}
local shejian = fk.CreateTriggerSkill{
  name = "shejian",
  anim_type = "control",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from ~= player.id and #AimGroup:getAllTargets(data.tos) == 1 and
      #player:getCardIds("he") > 1 and player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 2, 999, false, self.name, true, ".|.|.|hand", "#shejian-card::"..data.from, true)
    if #cards > 1 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local n = #self.cost_data
    room:throwCard(self.cost_data, self.name, player, player)
    if not (player.dead or from.dead) then
      room:doIndicate(player.id, {data.from})
      local choices = {"damage1"}
      if #from:getCardIds("he") >= n then
        table.insert(choices, 1, "discard_skill")
      end
      local choice = room:askForChoice(player, choices, self.name, "#shejian-choice::"..data.from)
      if choice == "discard_skill" then
        local cards = room:askForCardsChosen(player, from, n, n, "he", self.name)
        room:throwCard(cards, self.name, from, player)
      else
        room:damage{
          from = player,
          to = from,
          damage = 1,
          skillName = self.name
        }
      end
    end
  end,
}
kuangcai:addRelatedSkill(kuangcai_targetmod)
miheng:addSkill(kuangcai)
miheng:addSkill(shejian)
Fk:loadTranslationTable{
  ["ty__miheng"] = "祢衡",
  ["kuangcai"] = "狂才",
  [":kuangcai"] = "①锁定技，你的回合内，你使用牌无距离和次数限制。<br>②弃牌阶段开始时，若你本回合：没有使用过牌，你的手牌上限+1；"..
  "使用过牌且没有造成伤害，你手牌上限-1。<br>③结束阶段，若你本回合造成过伤害，你摸等于伤害值数量的牌（最多摸五张）。",
  ["shejian"] = "舌剑",
  [":shejian"] = "每回合限两次，当你成为其他角色使用牌的唯一目标后，你可以弃置至少两张手牌，然后弃置其等量的牌或对其造成1点伤害。",
  ["@kuangcai-turn"] = "狂才",
  ["#shejian-card"] = "舌剑：你可以弃置至少两张手牌，弃置 %dest 等量的牌或对其造成1点伤害",
  ["damage1"] = "造成1点伤害",
  ["#shejian-choice"] = "舌剑：选择对 %dest 执行的一项",

  ["$kuangcai1"] = "耳所瞥闻，不忘于心。",
  ["$kuangcai2"] = "吾焉能从屠沽儿耶？",
  ["$shejian1"] = "伤人的，可不止刀剑！	",
  ["$shejian2"] = "死公！云等道？",
  ["~ty__miheng"] = "恶口……终至杀身……",
}

local huaxin = General(extension, "ty__huaxin", "wei", 3)
local wanggui = fk.CreateTriggerSkill{
  name = "wanggui",
  mute = true,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      return (event == fk.Damage and player:getMark("wanggui-turn") == 0) or event == fk.Damaged
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets, prompt = {}, ""
    if event == fk.Damage then
      targets = table.map(table.filter(room.alive_players, function(p)
        return p.kingdom ~= player.kingdom end), function(p) return p.id end)
      prompt = "#wanggui1-choose"
    else
      targets = table.map(table.filter(room.alive_players, function(p)
        return p.kingdom == player.kingdom end), function(p) return p.id end)
      prompt = "#wanggui2-choose"
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if event == fk.Damage then
      room:setPlayerMark(player, "wanggui-turn", 1)
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name,
      }
    else
      to:drawCards(1, self.name)
      if to ~= player then
        player:drawCards(1, self.name)
      end
    end
  end,
}
local xibing = fk.CreateTriggerSkill{
  name = "xibing",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Play and data.firstTarget and
      data.card.color == Card.Black and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      target:getHandcardNum() < math.min(target.hp, 5) and #AimGroup:getAllTargets(data.tos) == 1 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xibing-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    target:drawCards(math.min(target.hp, 5) - target:getHandcardNum())
    player.room:setPlayerMark(target, "xibing-turn", 1)
  end,
}
local xibing_prohibit = fk.CreateProhibitSkill{
  name = "#xibing_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("xibing-turn") > 0
  end,
}
xibing:addRelatedSkill(xibing_prohibit)
huaxin:addSkill(wanggui)
huaxin:addSkill(xibing)
Fk:loadTranslationTable{
  ["ty__huaxin"] = "华歆",
  ["wanggui"] = "望归",
  [":wanggui"] = "当你造成伤害后，你可以对与你势力不同的一名角色造成1点伤害（每回合限一次）；当你受到伤害后，你可令一名与你势力相同的角色摸一张牌，"..
  "若不为你，你也摸一张牌。",
  ["xibing"] = "息兵",
  [":xibing"] = "每回合限一次，当一名其他角色在其出牌阶段内使用黑色【杀】或黑色普通锦囊牌指定唯一角色为目标后，你可令该角色将手牌摸至体力值"..
  "（至多摸至五张），然后其本回合不能再使用牌。",
  ["#wanggui1-choose"] = "望归：你可以对一名势力与你不同的角色造成1点伤害",
  ["#wanggui2-choose"] = "望归：你可以令一名势力与你相同的角色摸一张牌，若不为你，你也摸一张牌",
  ["#xibing-invoke"] = "息兵：你可以令 %dest 将手牌摸至体力值（至多五张），然后其本回合不能使用牌",
  
  ["$wanggui1"] = "存志太虚，安心玄妙。",
  ["$wanggui2"] = "礼法有度，良德才略。",
  ["$xibing1"] = "千里运粮，非用兵之利。",
  ["$xibing2"] = "宜弘一代之治，绍三王之迹。",
  ["~ty__huaxin"] = "大举发兵，劳民伤国。",
}

local xunchen = General(extension, "ty__xunchen", "qun", 3)
local ty__fenglve = fk.CreateActiveSkill{
  name = "ty__fenglve",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      local dummy = Fk:cloneCard("dilu")
      if #target:getCardIds{Player.Hand, Player.Equip, Player.Judge} < 3 then
        dummy:addSubcards(target:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      else
        local cards = room:askForCardsChosen(target, target, 2, 2, "hej", self.name)
        dummy:addSubcards(cards)
      end
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, false, fk.ReasonGive)
      end
    elseif pindian.results[target.id].winner == target then
      if room:getCardArea(pindian.fromCard.id) == Card.DiscardPile then
        room:delay(1000)
        room:obtainCard(target, pindian.fromCard.id, true, fk.ReasonJustMove)
      end
    else
      player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
    end
  end,
}
local anyong = fk.CreateTriggerSkill{
  name = "anyong",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.from and data.from.phase ~= Player.NotActive and data.to ~= data.from then
      if data.from:getMark("anyong-turn") == 0 then
        player.room:addPlayerMark(data.from, "anyong-turn", 1)
        return data.damage == 1 and not data.to.dead and not player:isNude()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#anyong-invoke::"..data.to.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    room:doIndicate(player.id, {data.to.id})
    room:damage{
      from = player,
      to = data.to,
      damage = 1,
      skillName = self.name,
    }
  end,
}
xunchen:addSkill(ty__fenglve)
xunchen:addSkill(anyong)
Fk:loadTranslationTable{
  ["ty__xunchen"] = "荀谌",
  ["ty__fenglve"] = "锋略",
  [":ty__fenglve"] = "出牌阶段限一次，你可以和一名其他角色拼点。若你赢，该角色交给你其区域内的两张牌；若点数相同，此技能视为未发动过；"..
  "若你输，该角色获得你拼点的牌。",
  ["anyong"] = "暗涌",
  [":anyong"] = "当一名角色于其回合内第一次对另一名角色造成伤害后，若此伤害值为1，你可以弃置一张牌对受到伤害的角色造成1点伤害。",
  ["#anyong-invoke"] = "暗涌：你可以弃置一张牌，对 %dest 造成1点伤害",
  
  ["$ty__fenglve1"] = "当今敢称贤者，唯袁氏本初一人！",
  ["$ty__fenglve2"] = "冀州宝地，本当贤者居之！",
  ["$anyong1"] = "殿上太守且相看，殿下几人还拥韩？",
  ["$anyong2"] = "冀州暗潮汹涌，群士居危思变。",
  ["~ty__xunchen"] = "为臣当不贰，贰臣不当为……",
}

local fengxi = General(extension, "fengxiw", "wu", 3)
local yusui = fk.CreateTriggerSkill{
  name = "yusui",
  anim_type = "offensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from ~= player.id and data.card.color == Card.Black and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.from)
    room:loseHp(player, 1, self.name)
    if player.dead then return end
    local choices = {}
    if #to.player_cards[Player.Hand] > #player.player_cards[Player.Hand] then
      table.insert(choices, "yusui_discard")
    end
    if to.hp > player.hp then
      table.insert(choices, "yusui_loseHp")
    end
    if #choices > 0 then
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "yusui_discard" then
        if player:isKongcheng() then
          to:throwAllCards("h")
        else
          local n = #to.player_cards[Player.Hand] - #player.player_cards[Player.Hand]
          room:askForDiscard(to, n, n, false, self.name, false)
        end
      else
        room:loseHp(to, to.hp - player.hp, self.name)
      end
    end
  end,
}
local boyan = fk.CreateActiveSkill{
  name = "boyan",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local n = math.min(target.maxHp, 5) - target:getHandcardNum()
    if n > 0 then
      target:drawCards(n, self.name)
    end
    room:addPlayerMark(target, "boyan-turn", 1)
  end,
}
local boyan_prohibit = fk.CreateProhibitSkill{
  name = "#boyan_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("boyan-turn") > 0
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("boyan-turn") > 0
  end,
}
boyan:addRelatedSkill(boyan_prohibit)
fengxi:addSkill(yusui)
fengxi:addSkill(boyan)
Fk:loadTranslationTable{
  ["fengxiw"] = "冯熙",
  ["yusui"] = "玉碎",
  [":yusui"] = "每回合限一次，当你成为其他角色使用黑色牌的目标后，你可以失去1点体力，然后选择一项：1.令其弃置手牌至与你相同；2.令其失去体力值至与你相同。",
  ["boyan"] = "驳言",
  [":boyan"] = "出牌阶段限一次，你可以选择一名其他角色，该角色将手牌摸至体力上限（最多摸至5张），其本回合不能使用或打出手牌。",
  ["yusui_discard"] = "令其弃置手牌至与你相同",
  ["yusui_loseHp"] = "令其失去体力值至与你相同",

  ["$yusui1"] = "宁为玉碎，不为瓦全！",
  ["$yusui2"] = "生义相左，舍生取义。",
  ["$boyan1"] = "黑白颠倒，汝言谬矣！",
  ["$boyan2"] = "魏王高论，实为无知之言。",
  ["~fengxiw"] = "乡音未改双鬓苍，身陷北国有义求。",
}

local dengzhi = General(extension, "ty__dengzhi", "shu", 3)
local jianliang = fk.CreateTriggerSkill{
  name = "jianliang",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw and
      not table.every(player.room.alive_players, function(p) return player:getHandcardNum() >= p:getHandcardNum() end)
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room.alive_players,
      function(p) return p.id end), 1, 2, "#jianliang-invoke", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p.dead then
        p:drawCards(1, self.name)
      end
    end
  end,
}
local weimeng = fk.CreateActiveSkill{
  name = "weimeng",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = function (self, selected, selected_cards)
    return "#weimeng:::"..Self.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:askForCardsChosen(player, target, 1, player.hp, "h", self.name)
    local n1 = 0
    for _, id in ipairs(cards) do
      n1 = n1 + Fk:getCardById(id).number
    end
    local dummy1 = Fk:cloneCard("dilu")
    dummy1:addSubcards(cards)
    room:obtainCard(player, dummy1, false, fk.ReasonPrey)
    if player.dead or player:isNude() or target.dead then return end
    local cards2
    if #player:getCardIds("he") <= #cards then
      cards2 = player:getCardIds("he")
    else
      cards2 = room:askForCard(player, #cards, #cards, true, self.name, false, ".",
        "#weimeng-give::"..target.id..":"..#cards..":"..n1)
      if #cards2 < #cards then
        cards2 = table.random(player:getCardIds("he"), #cards)
      end
    end
    local n2 = 0
    for _, id in ipairs(cards2) do
      n2 = n2 + Fk:getCardById(id).number
    end
    local dummy2 = Fk:cloneCard("dilu")
    dummy2:addSubcards(cards2)
    room:obtainCard(target, dummy2, false, fk.ReasonGive)
    if n1 < n2 then
      if not player.dead then
        player:drawCards(1, self.name)
      end
    elseif n1 > n2 then
      if not (player.dead or target.dead or target:isAllNude()) then
        local id = room:askForCardChosen(player, target, "hej", self.name)
        room:throwCard({id}, self.name, target, player)
      end
    end
  end,
}
dengzhi:addSkill(jianliang)
dengzhi:addSkill(weimeng)
Fk:loadTranslationTable{
  ["ty__dengzhi"] = "邓芝",
  ["jianliang"] = "简亮",
  [":jianliang"] = "摸牌阶段开始时，若你的手牌数不为全场最多，你可以令至多两名角色各摸一张牌。",
  ["weimeng"] = "危盟",
  [":weimeng"] = "出牌阶段限一次，你可以获得一名其他角色至多X张手牌，然后交给其等量的牌（X为你的体力值）。"..
  "若你给出的牌点数之和：大于获得的牌，你摸一张牌；小于获得的牌，你弃置其区域内一张牌。",
  ["#jianliang-invoke"] = "简亮：你可以令至多两名角色各摸一张牌",
  ["#weimeng"] = "危盟：获得一名其他角色至多%arg张牌，交还等量牌，根据点数执行效果",
  ["#weimeng-give"] = "危盟：交还 %dest %arg张牌，若点数大于%arg2则摸一张牌，若小于则弃置其一张牌",
  
  ["$jianliang1"] = "岂曰少衣食，与君共袍泽！",
  ["$jianliang2"] = "义士同心力，粮秣应期来！",
  ["$weimeng1"] = "此礼献于友邦，共赴兴汉大业！",
  ["$weimeng2"] = "吴有三江之守，何故委身侍魏？",
  ["~ty__dengzhi"] = "伯约啊，我帮不了你了……",
}

local zongyu = General(extension, "ty__zongyu", "shu", 3)
local qiao = fk.CreateTriggerSkill{
  name = "qiao",
  anim_type = "control",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.firstTarget and data.from ~= player.id and
      not player.room:getPlayerById(data.from):isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qiao-invoke::"..data.from)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local id = room:askForCardChosen(player, from, "he", self.name)
    room:throwCard({id}, self.name, from, player)
    if not player:isNude() then
      room:askForDiscard(player, 1, 1, true, self.name, false)
    end
  end,
}
local chengshang = fk.CreateTriggerSkill{
  name = "chengshang",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.tos and
      table.find(TargetGroup:getRealTargets(data.tos), function(id) return id ~= player.id end) and not data.damageDealt and
      data.card.suit ~= Card.NoSuit and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil,
      "#chengshang-invoke:::"..data.card:getSuitString()..":"..tostring(data.card.number))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|"..tostring(data.card.number).."|"..data.card:getSuitString())
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    else
      player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
    end
  end,
}
zongyu:addSkill(qiao)
zongyu:addSkill(chengshang)
Fk:loadTranslationTable{
  ["ty__zongyu"] = "宗预",
  ["qiao"] = "气傲",
  [":qiao"] = "每回合限两次，当你成为其他角色使用牌的目标后，你可以弃置其一张牌，然后你弃置一张牌。",
  ["chengshang"] = "承赏",
  [":chengshang"] = "出牌阶段内限一次，你使用指定其他角色为目标的牌结算后，若此牌没有造成伤害，你可以获得牌堆中所有与此牌花色点数均相同的牌。"..
  "若你没有因此获得牌，此技能视为未发动过。",
  ["#qiao-invoke"] = "气傲：你可以弃置 %dest 一张牌，然后你弃置一张牌",
  ["#chengshang-invoke"] = "承赏：你可以获得牌堆中所有的%arg%arg2牌",
  
  ["$qiao1"] = "吾六十何为不受兵邪？",
  ["$qiao2"] = "芝性骄傲，吾独不为屈。",
  ["$chengshang1"] = "嘉其抗直，甚爱待之。",
  ["$chengshang2"] = "为国鞠躬，必受封赏。",
  ["~ty__zongyu"] = "吾年逾七十，唯少一死耳……",
}

local yanghu = General(extension, "ty__yanghu", "wei", 3)
local deshao = fk.CreateTriggerSkill{
  name = "deshao",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.firstTarget and data.card.color == Card.Black and
      data.from ~= player.id and player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#deshao-invoke::"..data.from)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    local from = room:getPlayerById(data.from)
    if from:getHandcardNum() >= player:getHandcardNum() then
      local id = room:askForCardChosen(player, from, "he", self.name)
      room:throwCard(id, self.name, from, player)
    end
  end,
}
local mingfa = fk.CreateTriggerSkill{
  name = "mingfa",
  anim_type = "offensive",
  events = {fk.CardUseFinished, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.CardUseFinished then
        return target == player and player.phase == Player.Play and #player:getPile(self.name) == 0 and
          (data.card.trueName == "slash" or data.card:isCommonTrick()) and player.room:getCardArea(data.card) == Card.Processing and
          not data.card:isVirtual() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
      else
        return target.phase == Player.Finish and player:getMark(self.name) ~= 0 and #player:getPile(self.name) > 0 and
          player:getMark(self.name) == target.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      local room = player.room
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
        return p.id end), 1, 1, "#mingfa-choose:::"..data.card:toLogString(), self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      player:addToPile(self.name, data.card, true, self.name)
      room:setPlayerMark(player, self.name, self.cost_data)
      local to = room:getPlayerById(self.cost_data)
      local mark = to:getMark("@@mingfa")
      if mark == 0 then mark = {} end
      table.insert(mark, player.id)
      room:setPlayerMark(to, "@@mingfa", mark)
    else
      local card = Fk:cloneCard(Fk:getCardById(player:getPile(self.name)[1]).name)
      if card.trueName ~= "nullification" and card.name ~= "collateral" and not player:isProhibited(target, card) then
        --据说没有合法性检测甚至无懈都能虚空用，甚至不合法目标还能触发贞烈。我不好说
        local n = math.max(target:getHandcardNum(), 1)
        n = math.min(n, 5)
        for i = 1, n, 1 do
          if target.dead then break end
          room:useCard({
            card = card,
            from = player.id,
            tos = {{target.id}},
            skillName = self.name,
          })
        end
      end
      room:setPlayerMark(player, self.name, 0)
      if not target.dead then
        local mark = target:getMark("@@mingfa")
        table.removeOne(mark, player.id)
        if #mark == 0 then mark = 0 end
        room:setPlayerMark(target, "@@mingfa", mark)
      end
      room:moveCards({
        from = player.id,
        ids = player:getPile(self.name),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
    end
  end,

  refresh_events = {fk.EventLoseSkill, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if #player:getPile(self.name) > 0 and player:getMark(self.name) ~= 0 then
      if event == fk.EventLoseSkill then
        return target == player and data == self
      else
        return target == player or target:getMark("@@mingfa") ~= 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventLoseSkill or (event == fk.Death and target == player) then
      local to = room:getPlayerById(player:getMark(self.name))
      room:setPlayerMark(player, self.name, 0)
      room:moveCards({
        from = player.id,
        ids = player:getPile(self.name),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
      if not to.dead then
        local mark = to:getMark("@@mingfa")
        table.removeOne(mark, player.id)
        if #mark == 0 then mark = 0 end
        room:setPlayerMark(to, "@@mingfa", mark)
      end
    else
      local mark = target:getMark("@@mingfa")
      if table.contains(mark, player.id) then
        table.removeOne(mark, player.id)
        if #mark == 0 then mark = 0 end
        room:setPlayerMark(target, "@@mingfa", mark)
        room:setPlayerMark(player, self.name, 0)
        room:moveCards({
          from = player.id,
          ids = player:getPile(self.name),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
          specialName = self.name,
        })
      end
    end
  end,
}
yanghu:addSkill(deshao)
yanghu:addSkill(mingfa)
Fk:loadTranslationTable{
  ["ty__yanghu"] = "羊祜",
  ["deshao"] = "德劭",
  [":deshao"] = "每回合限两次，当你成为其他角色使用黑色牌的目标后，你可以摸一张牌，然后若其手牌数大于等于你，你弃置其一张牌。",
  ["mingfa"] = "明伐",
  [":mingfa"] = "出牌阶段内限一次，你使用【杀】或普通锦囊牌结算完毕后，若你没有“明伐”牌，可将此牌置于武将牌上并选择一名其他角色。"..
  "该角色的结束阶段，视为你对其使用X张“明伐”牌（X为其手牌数，最少为1，最多为5），然后移去“明伐”牌。",
  ["#deshao-invoke"] = "德劭：你可以摸一张牌，然后若 %dest 手牌数不少于你，你弃置其一张牌",
  ["#mingfa-choose"] = "明伐：将%arg置为“明伐”，选择一名角色，其结束阶段视为对其使用其手牌张数次“明伐”牌",
  ["@@mingfa"] = "明伐",
  
  ["$deshao1"] = "名德远播，朝野俱瞻。",
  ["$deshao2"] = "增修德信，以诚服人。",
  ["$mingfa1"] = "煌煌大势，无须诈取。",
  ["$mingfa2"] = "开示公道，不为掩袭。",
  ["~ty__yanghu"] = "臣死之后，杜元凯可继之……",
}

--匡鼎炎汉：刘巴 黄权 霍峻 傅肜傅佥 向朗
local liuba = General(extension, "ty__liuba", "shu", 3)
local ty__zhubi = fk.CreateTriggerSkill{
  name = "ty__zhubi",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).suit == Card.Diamond then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if table.find(room.draw_pile, function(id) return Fk:getCardById(id).name == "ex_nihilo" end) or
      table.find(room.discard_pile, function(id) return Fk:getCardById(id).name == "ex_nihilo" end) then
      return room:askForSkillInvoke(player, self.name, nil, "#ty__zhubi-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule("ex_nihilo")
    if #cards > 0 then
      local id = cards[1]
      table.removeOne(room.draw_pile, id)
      table.insert(room.draw_pile, 1, id)
    else
      cards = room:getCardsFromPileByRule("ex_nihilo", 1, "discardPile")
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          fromArea = Card.DiscardPile,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = self.name,
        })
      end
    end
  end,
}
local liuzhuan = fk.CreateTriggerSkill{
  name = "liuzhuan",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    local room = player.room
    local current = room.current
    if current == nil or current == player or current.phase == Player.NotActive then return false end
    for _, move in ipairs(data) do
      if current.phase ~= Player.Draw and move.to == current.id and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == current then
            return true
          end
        end
      end
      local mark = player:getMark("liuzhuan_record")
      if move.toArea == Card.DiscardPile and type(mark) == "table" then
        for _, info in ipairs(move.moveInfo) do
          --for stupid manjuan
          if info.fromArea ~= Card.DiscardPile and table.contains(mark, info.cardId) and room:getCardArea(info.cardId) == Card.DiscardPile then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("liuzhuan_record")
    if mark == 0 then mark = {} end
    local current = room.current
    local toObtain = {}
    for _, move in ipairs(data) do
      if current and current.phase ~= Player.Draw and move.to == current.id and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == current then
            table.insertIfNeed(mark, id)
            room:setCardMark(Fk:getCardById(id), "@@liuzhuan", 1)
          end
        end
      end
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          --for stupid manjuan
          if info.fromArea ~= Card.DiscardPile and table.contains(mark, info.cardId) and room:getCardArea(info.cardId) == Card.DiscardPile then
            table.insertIfNeed(toObtain, id)
          end
        end
      end
    end
    room:setPlayerMark(player, "liuzhuan_record", mark)

    if #toObtain > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(toObtain)
      room:obtainCard(player, dummy, true, fk.ReasonJustMove)
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.AfterTurnEnd, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Death and player ~= target then return false end
    return type(player:getMark("liuzhuan_record")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("liuzhuan_record")
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if room.current and move.to ~= room.current.id and (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip) then
          for _, info in ipairs(move.moveInfo) do
            table.removeOne(mark, info.cardId)
            room:setCardMark(Fk:getCardById(info.cardId), "@@liuzhuan", 0)
          end
        end
      end
      room:setPlayerMark(player, "liuzhuan_record", mark)
    elseif event == fk.AfterTurnEnd then
      for _, id in ipairs(mark) do
        room:setCardMark(Fk:getCardById(id), "@@liuzhuan", 0)
      end
      room:setPlayerMark(player, "liuzhuan_record", 0)
    elseif event == fk.Death then
      for _, id in ipairs(mark) do
        if table.every(room.alive_players, function (p)
          local p_mark = p:getMark("liuzhuan_record")
          return not (type(p_mark) == "table" and table.contains(p_mark, id))
        end) then
        room:setCardMark(Fk:getCardById(id), "@@liuzhuan", 0)
        end
      end
      room:setPlayerMark(player, "liuzhuan_record", 0)
    end
  end,
}
local liuzhuan_prohibit = fk.CreateProhibitSkill{
  name = "#liuzhuan_prohibit",
  is_prohibited = function(self, from, to, card)
    if to:hasSkill(liuzhuan.name) and to:getMark("liuzhuan_record") ~= 0 and #to:getMark("liuzhuan_record") > 0 then
      if table.contains(to:getMark("liuzhuan_record"), card:getEffectiveId()) then
        return true
      end
      if #card.subcards > 0 then
        for _, id in ipairs(card.subcards) do
          if table.contains(to:getMark("liuzhuan_record"), id) then
            return true
          end
        end
      end
    end
  end,
}
liuzhuan:addRelatedSkill(liuzhuan_prohibit)
liuba:addSkill(ty__zhubi)
liuba:addSkill(liuzhuan)
Fk:loadTranslationTable{
  ["ty__liuba"] = "刘巴",
  ["ty__zhubi"] = "铸币",
  [":ty__zhubi"] = "当<font color='red'>♦</font>牌因弃置而进入弃牌堆后，你可从牌堆或弃牌堆将一张【无中生有】置于牌堆顶。",
  ["liuzhuan"] = "流转",
  [":liuzhuan"] = "锁定技，其他角色的回合内，其于摸牌阶段外获得的牌无法对你使用，这些牌本回合进入弃牌堆后，你获得之。",
  ["#ty__zhubi-invoke"] = "铸币：是否将一张【无中生有】置于牌堆顶？",
  ["@@liuzhuan"] = "流转",

  ["$ty__zhubi1"] = "铸币平市，百货可居。",
  ["$ty__zhubi2"] = "做钱直百，府库皆实。",
  ["$liuzhuan1"] = "身似浮萍，随波逐流。",
  ["$liuzhuan2"] = "辗转四方，宦游八州。",
  ["~ty__liuba"] = "竹蕴于林，风必摧之。",
}

local huangquan = General(extension, "ty__huangquan", "shu", 3)
local quanjian = fk.CreateActiveSkill{
  name = "quanjian",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("quanjian1-turn") == 0 or player:getMark("quanjian2-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 and to_select ~= Self.id then
      if Self:getMark("quanjian2-turn") == 0 then
        return true
      else
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          if Fk:currentRoom():getPlayerById(to_select):inMyAttackRange(p) then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if target:inMyAttackRange(p) then
        table.insert(targets, p.id)
      end
    end
    local choices = {}
    if player:getMark("quanjian1-turn") == 0 and #targets > 0 then
      table.insert(choices, "quanjian1")
    end
    if player:getMark("quanjian2-turn") == 0 then
      table.insert(choices, "quanjian2")
    end
    local choice = room:askForChoice(player, choices, self.name)
    room:addPlayerMark(player, choice.."-turn", 1)
    local to
    if choice == "quanjian1" then
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#quanjian-choose", self.name)
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
      room:doIndicate(target.id, {to})
    end
    local choices2 = {"quanjian_cancel"}
    if choice == "quanjian1" then
      table.insert(choices2, 1, "quanjian_damage")
    else
      table.insert(choices2, 1, "quanjian_draw")
    end
    local choice2 = room:askForChoice(target, choices2, self.name)
    if choice2 == "quanjian_damage" then
      room:damage{
        from = target,
        to = room:getPlayerById(to),
        damage = 1,
        skillName = self.name,
      }
    elseif choice2 == "quanjian_draw" then
      if #target.player_cards[Player.Hand] < math.min(target:getMaxCards(), 5) then
        target:drawCards(math.min(target:getMaxCards(), 5) - #target.player_cards[Player.Hand])
      end
      if #target.player_cards[Player.Hand] > target:getMaxCards() then
        local n = #target.player_cards[Player.Hand] - target:getMaxCards()
        room:askForDiscard(target, n, n, false, self.name, false)
      end
      room:addPlayerMark(target, "quanjian_prohibit-turn", 1)
    else
      room:addPlayerMark(target, "quanjian_damage-turn", 1)
    end
  end,
}
local quanjian_prohibit = fk.CreateProhibitSkill{
  name = "#quanjian_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("quanjian_prohibit-turn") > 0
  end,
}
local quanjian_record = fk.CreateTriggerSkill{
  name = "#quanjian_record",
  anim_type = "offensive",

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target:getMark("quanjian_damage-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + target:getMark("quanjian_damage-turn")
    player.room:setPlayerMark(target, "quanjian_damage-turn", 0)
  end,
}
local tujue = fk.CreateTriggerSkill{
  name = "tujue",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and not player:isNude() and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#tujue-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player.player_cards[Player.Hand])
    dummy:addSubcards(player.player_cards[Player.Equip])
    local n = #dummy.subcards
    room:obtainCard(self.cost_data, dummy, false, fk.ReasonGive)
    room:recover({
      who = player,
      num = math.min(n, player.maxHp - player.hp),
      recoverBy = player,
      skillName = self.name
    })
    player:drawCards(n, self.name)
  end,
}
quanjian:addRelatedSkill(quanjian_prohibit)
quanjian:addRelatedSkill(quanjian_record)
huangquan:addSkill(quanjian)
huangquan:addSkill(tujue)
Fk:loadTranslationTable{
  ["ty__huangquan"] = "黄权",
  ["quanjian"] = "劝谏",
  [":quanjian"] = "出牌阶段每项限一次，你选择以下一项令一名其他角色选择是否执行：1.对一名其攻击范围内你指定的角色造成1点伤害。"..
  "2.将手牌调整至手牌上限（最多摸到5张），其不能使用手牌直到回合结束。若其不执行，则其本回合下次受到的伤害+1。",
  ["tujue"] = "途绝",
  [":tujue"] = "限定技，当你处于濒死状态时，你可以将所有牌交给一名其他角色，然后你回复等量的体力值并摸等量的牌。",
  ["quanjian1"] = "对一名其攻击范围内你指定的角色造成1点伤害",
  ["quanjian2"] = "将手牌调整至手牌上限（最多摸到5张），其不能使用手牌直到回合结束",
  ["#quanjian-choose"] = "劝谏：选择一名其攻击范围内的角色",
  ["quanjian_damage"] = "对指定的角色造成1点伤害",
  ["quanjian_draw"] = "将手牌调整至手牌上限（最多摸到5张），不能使用手牌直到回合结束",
  ["quanjian_cancel"] = "不执行，本回合下次受到的伤害+1",
  ["#tujue-choose"] = "途绝：你可以将所有牌交给一名其他角色，然后回复等量的体力值并摸等量的牌",

  ["$quanjian1"] = "陛下宜后镇，臣请为先锋！",
  ["$quanjian2"] = "吴人悍战，陛下万不可涉险！",
  ["$tujue1"] = "归蜀无路，孤臣泪尽江北。",
  ["$tujue2"] = "受吾主殊遇，安能降吴！",
  ["~ty__huangquan"] = "败军之将，何言忠乎？",
}

local huojun = General(extension, "ty__huojun", "shu", 4)
local gue = fk.CreateViewAsSkill{
  name = "gue",
  anim_type = "defensive",
  pattern = "slash,jink",
  prompt = "#gue",
  interaction = function()
    local names = {"slash", "jink"}
    for _, name in ipairs(names) do
      local card = Fk:cloneCard(name)
      if ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, card) and not Self:prohibitUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names }
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return false
  end,
  enabled_at_response = function(self, player, response)
    return not player:isKongcheng() and player.phase == Player.NotActive and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
}
local gue_trigger = fk.CreateTriggerSkill{
  name = "#gue_trigger",
  events = {fk.PreCardUse, fk.PreCardRespond},
  mute = true,
  priority = 10,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "gue")
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player:showCards(player:getCardIds("h"))
    if player.dead then return end
    local n = #table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash" or Fk:getCardById(id).trueName == "jink" end)
    if n > 1 then
      return true
    end
    return false
  end,
}
local sigong = fk.CreateTriggerSkill{
  name = "sigong",
  anim_type = "offensive",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target ~= player and player:getMark("@@sigong-round") == 0 and
      target and not target.dead and not player:isProhibited(target, Fk:cloneCard("slash")) then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        return use.responseToEvent and use.responseToEvent.from == target.id
      end, Player.HistoryTurn)
      if #events > 0 then return true end
      events = player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e)
        local response = e.data[1]
        return response.responseToEvent and response.responseToEvent.from == target.id
      end, Player.HistoryTurn)
      if #events > 0 then return true end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player:getHandcardNum() > 1 then
      local n = player:getHandcardNum() - 1
      local cards = player.room:askForDiscard(player, n, n, false, self.name, true, ".|.|.|hand", "#sigong-discard::"..target.id, true)
      if #cards == n then
        self.cost_data = cards
        return true
      end
    else
      local prompt = "#sigong-invoke::"..target.id
      if player:isKongcheng() then
        prompt = "#sigong-draw::"..target.id
      end
      if player.room:askForSkillInvoke(player, self.name, nil, prompt) then
        self.cost_data = {}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isKongcheng() then
      player:drawCards(1, self.name)
    else
      room:throwCard(self.cost_data, self.name, player, player)
    end
    local use = {
      from = player.id,
      tos = {{target.id}},
      card = Fk:cloneCard("slash"),
      extraUse = true,
    }
    use.card.skillName = self.name
    if #self.cost_data > 0 then
      use.extra_data = use.extra_data or {}
      use.extra_data.sigong = #self.cost_data
    end
    use.additionalDamage = (use.additionalDamage or 0) + 1
    room:useCard(use)
    if not player.dead and use.damageDealt then
      room:setPlayerMark(player, "@@sigong-round", 1)
    end
  end,

  refresh_events = {fk.PreCardEffect},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.sigong then
      data.fixedResponseTimes = data.fixedResponseTimes or {}
      data.fixedResponseTimes["jink"] = data.extra_data.sigong
    end
  end,
}
gue:addRelatedSkill(gue_trigger)
huojun:addSkill(gue)
huojun:addSkill(sigong)
Fk:loadTranslationTable{
  ["ty__huojun"] = "霍峻",
  ["gue"] = "孤扼",
  [":gue"] = "每名其他角色的回合内限一次，当你需要使用或打出【杀】或【闪】时，你可以展示所有手牌，若其中【杀】和【闪】的总数不大于1，视为你使用或打出之。",
  ["sigong"] = "伺攻",
  [":sigong"] = "其他角色的回合结束时，若其本回合内使用牌被响应过，你可以将手牌调整至一张，视为对其使用一张需要X张【闪】抵消且伤害+1的【杀】"..
  "（X为你以此法弃置牌数且至少为1）。若此【杀】造成伤害，此技能本轮失效。",
  ["#gue"] = "孤扼：你可以展示所有手牌，若【杀】【闪】总数不大于1，视为你使用或打出之",
  ["@@sigong-round"] = "伺攻失效",
  ["#sigong-discard"] = "伺攻：你可以将手牌弃至一张，视为对 %dest 使用【杀】",
  ["#sigong-invoke"] = "伺攻：你可以视为对 %dest 使用【杀】",
  ["#sigong-draw"] = "伺攻：你可以摸一张牌，视为对 %dest 使用【杀】",
  
  ["$gue1"] = "哀兵必胜，况吾众志成城。",
  ["$gue2"] = "扼守孤城，试问万夫谁开？",
  ["$sigong1"] = "善守者亦善攻，不可死守。",
  ["$sigong2"] = "璋军疲敝，可伺机而攻。",
  ["~ty__huojun"] = "蒙君知恩，奈何早薨……",
}

local furongfuqian = General(extension, "furongfuqian", "shu", 4, 6)
local ty__xuewei = fk.CreateTriggerSkill{
  name = "ty__xuewei",
  anim_type = "defensive",
  events = {fk.EventPhaseStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish
      else
        return target:getMark("@@ty__xuewei") > 0 and player.tag[self.name][1] == target.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local to = player.room:askForChoosePlayers(player, table.map(table.filter(player.room:getAlivePlayers(), function(p)
        return p.hp <= player.hp end), function (p) return p.id end), 1, 1, "#ty__xuewei-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:addPlayerMark(room:getPlayerById(self.cost_data), "@@ty__xuewei", 1)
      player.tag[self.name] = {self.cost_data}
    else
      room:loseHp(player, 1, self.name)
      if not player.dead then
        player:drawCards(1, self.name)
      end
      if not target.dead then
        target:drawCards(1, self.name)
      end
      return true
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and
      player.tag[self.name] and #player.tag[self.name] > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player.tag[self.name][1])
    room:setPlayerMark(to, "@@ty__xuewei", 0)
    player.tag[self.name] = {}
  end,
}
local yuguan = fk.CreateTriggerSkill{
  name = "yuguan",
  anim_type = "drawcard",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and
      table.every(player.room:getOtherPlayers(player), function (p) return p:getLostHp() <= player:getLostHp() end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yuguan-invoke:::"..math.max(0, player:getLostHp() - 1))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not player.dead and player:getLostHp() > 0 then
      local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
        return #p.player_cards[Player.Hand] < p.maxHp end), function(p) return p.id end)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, player:getLostHp(), "#yuguan-choose:::"..player:getLostHp(), self.name, false)
      if #tos == 0 then
        tos = {player.id}
      end
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        p:drawCards(p.maxHp - #p.player_cards[Player.Hand], self.name)
      end
    end
  end,
}
furongfuqian:addSkill(ty__xuewei)
furongfuqian:addSkill(yuguan)
Fk:loadTranslationTable{
  ["furongfuqian"] = "傅肜傅佥",
  ["ty__xuewei"] = "血卫",
  [":ty__xuewei"] = "结束阶段，你可以选择一名体力值不大于你的角色。直到你的下回合开始前，该角色受到伤害时，防止此伤害，然后你失去1点体力并与其各摸一张牌。",
  ["yuguan"] = "御关",
  [":yuguan"] = "每个回合结束时，若你是损失体力值最多的角色，你可以减1点体力上限，然后令至多X名角色将手牌摸至体力上限（X为你已损失的体力值）。",
  ["@@ty__xuewei"] = "血卫",
  ["#ty__xuewei-choose"] = "血卫：你可以指定一名体力值不大于你的角色<br>直到你下回合开始前防止其受到的伤害，你失去1点体力并与其各摸一张牌",
  ["#yuguan-invoke"] = "御关：你可以减1点体力上限，令至多%arg名角色将手牌摸至体力上限",
  ["#yuguan-choose"] = "御关：令至多%arg名角色将手牌摸至体力上限",
  
  ["$ty__xuewei1"] = "慷慨赴国难，青山侠骨香。",
  ["$ty__xuewei2"] = "舍身卫主之志，死犹未悔！",
  ["$yuguan1"] = "城后即为汉土，吾等无路可退！",
  ["$yuguan2"] = "舍身卫关，身虽死而志犹在。",
  ["~furongfuqian"] = "此间，何有汉将军降者！",
}

local xianglang = General(extension, "xianglang", "shu", 3)
local kanji = fk.CreateActiveSkill{
  name = "kanji",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    local suits = {}
    for _, id in ipairs(cards) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        if table.contains(suits, suit) then
          return
        else
          table.insert(suits, suit)
        end
      end
    end
    local suits1 = #suits
    player:drawCards(2, self.name)
    if suits1 == 4 then return end
    suits = {}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    if #suits == 4 then
      player:skip(Player.Discard)
    end
  end,
}
local qianzheng = fk.CreateTriggerSkill{
  name = "qianzheng",
  anim_type = "drawcard",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.firstTarget and data.from ~= player.id and
      (data.card:isCommonTrick() or data.card.trueName == "slash") and #player:getCardIds{Player.Hand, Player.Equip} > 1 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#qianzheng1-card:::"..data.card:getTypeString()..":"..data.card:toLogString()
    if data.card:isVirtual() and not data.card:getEffectiveId() then
      prompt = "#qianzheng2-card"
    end
    local cards = player.room:askForCard(player, 2, 2, true, self.name, true, ".", prompt)
    if #cards == 2 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data
    if Fk:getCardById(cards[1]).type ~= data.card.type and Fk:getCardById(cards[2]).type ~= data.card.type then
      data.extra_data = data.extra_data or {}
      data.extra_data.qianzheng = player.id
    end
    room:recastCard(cards, player, self.name)
  end,
}
local qianzheng_trigger = fk.CreateTriggerSkill{
  name = "#qianzheng_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.qianzheng and data.extra_data.qianzheng == player.id and
      player.room:getCardArea(data.card) == Card.Processing and not player.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "qianzheng", nil, "#qianzheng-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
  end,
}
qianzheng:addRelatedSkill(qianzheng_trigger)
xianglang:addSkill(kanji)
xianglang:addSkill(qianzheng)
Fk:loadTranslationTable{
  ["xianglang"] = "向朗",
  ["kanji"] = "勘集",
  [":kanji"] = "出牌阶段限两次，你可以展示所有手牌，若花色均不同，你摸两张牌，然后若因此使手牌包含四种花色，则你跳过本回合的弃牌阶段。",
  ["qianzheng"] = "愆正",
  [":qianzheng"] = "每回合限两次，当你成为其他角色使用普通锦囊牌或【杀】的目标时，你可以重铸两张牌，若这两张牌与使用牌类型均不同，"..
  "此牌结算后进入弃牌堆时你可以获得之。",
  ["#qianzheng1-card"] = "愆正：你可以重铸两张牌，若均不为%arg，结算后获得%arg2",
  ["#qianzheng2-card"] = "愆正：你可以重铸两张牌",
  ["#qianzheng-invoke"] = "愆正：你可以获得此%arg",
  
  ["$kanji1"] = "览文库全书，筑文心文胆。",
  ["$kanji2"] = "世间学问，皆载韦编之上。",
  ["$qianzheng1"] = "悔往昔之种种，恨彼时之切切。",
  ["$qianzheng2"] = "罪臣怀咎难辞，有愧国恩。",
  ["~xianglang"] = "识文重义而徇私，恨也……",
}

--太平甲子：管亥 张闿 刘辟 张楚 裴元绍
local guanhai = General(extension, "guanhai", "qun", 4)
local suoliang = fk.CreateTriggerSkill{
  name = "suoliang",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      not data.to.dead and not data.to:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#suoliang-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForCardsChosen(player, data.to, 1, math.min(data.to.maxHp, 5), "he", self.name)
    if #cards > 0 then
      local dummy = Fk:cloneCard("dilu")
      for _, id in ipairs(cards) do
        if Fk:getCardById(id).suit == Card.Heart or Fk:getCardById(id).suit == Card.Club then
          dummy:addSubcard(id)
        end
      end
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, true, fk.ReasonPrey)
      else
        room:throwCard(cards, self.name, data.to, player)
      end
    end
  end,
}
local qinbao = fk.CreateTriggerSkill{
  name = "qinbao",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #table.filter(player.room:getOtherPlayers(player), function(p) return p:getHandcardNum() >= player:getHandcardNum() end) > 0
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player), function(p)
      return p:getHandcardNum() >= player:getHandcardNum() end)
    if #targets > 0 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(targets) do
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    end
  end,
}
guanhai:addSkill(suoliang)
guanhai:addSkill(qinbao)
Fk:loadTranslationTable{
  ["guanhai"] = "管亥",
  ["suoliang"] = "索粮",
  [":suoliang"] = "每回合限一次，你对一名其他角色造成伤害后，选择其至多X张牌（X为其体力上限且最多为5），获得其中的<font color='red'>♥</font>和♣牌。"..
  "若你未获得牌，则弃置你选择的牌。",
  ["qinbao"] = "侵暴",
  [":qinbao"] = "锁定技，手牌数大于等于你的其他角色不能响应你使用的【杀】或普通锦囊牌。",
  ["#suoliang-invoke"] = "索粮：你可以选择 %dest 最多其体力上限张牌，获得其中的<font color='red'>♥</font>和♣牌，若没有则弃置这些牌",
  
  ["$suoliang1"] = "奉上万石粮草，吾便退兵！",
  ["$suoliang2"] = "听闻北海富庶，特来借粮。",
  ["$qinbao1"] = "赤箓护身，神鬼莫当。",
  ["$qinbao2"] = "头裹黄巾，代天征伐。",
  ["~guanhai"] = "这红脸汉子，为何如此眼熟……",
}

local zhangkai = General(extension, "zhangkai", "qun", 4)
local xiangshuz = fk.CreateTriggerSkill{
  name = "xiangshuz",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self.name) and target.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return target:getHandcardNum() >= target.hp
      else
        return player:usedSkillTimes(self.name, Player.HistoryPhase) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#xiangshuz-invoke::"..target.id)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:doIndicate(player.id, {target.id})
      local choices = {}
      for i = 0, 5, 1 do
        table.insert(choices, tostring(i))
      end
      local choice = room:askForChoice(player, choices, self.name, "#xiangshuz-choice::"..target.id)
      local mark = self.name
      if player:isKongcheng() or #room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#xiangshuz-discard") == 0 then
        mark = "@"..self.name
      end
      room:setPlayerMark(target, mark, choice)
    else
      room:doIndicate(player.id, {target.id})
      local n1 = target:getHandcardNum()
      local n2 = math.max(tonumber(target:getMark(self.name)), tonumber(target:getMark("@"..self.name)))
      room:setPlayerMark(target, self.name, 0)
      room:setPlayerMark(target, "@"..self.name, 0)
      if math.abs(n1 - n2) < 2 and not target:isNude() then
        local id = room:askForCardChosen(player, target, "he", self.name)
        room:obtainCard(player.id, id, false, fk.ReasonPrey)
      end
      if n1 == n2 then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
zhangkai:addSkill(xiangshuz)
Fk:loadTranslationTable{
  ["zhangkai"] = "张闿",
  ["xiangshuz"] = "相鼠",
  [":xiangshuz"] = "其他角色出牌阶段开始时，若其手牌数不小于体力值，你可以声明一个0~5的数字（若你弃置一张手牌，则数字不公布）。"..
  "此阶段结束时，若其手牌数与你声明的数：相差1以内，你获得其一张牌；相等，你对其造成1点伤害。",
  ["#xiangshuz-invoke"] = "相鼠：猜测 %dest 此阶段结束时手牌数，若相差1以内，获得其一张牌；相等，再对其造成1点伤害",
  ["#xiangshuz-choice"] = "相鼠：猜测 %dest 此阶段结束时的手牌数",
  ["#xiangshuz-discard"] = "相鼠：你可以弃置一张手牌令你猜测的数值不公布",
  ["@xiangshuz"] = "相鼠",

  ["$xiangshuz1"] = "要财还是要命，选一个吧！",
  ["$xiangshuz2"] = "有什么好东西，都给我交出来！",
  ["~zhangkai"] = "报应竟来得这么快……",
}

local liupi = General(extension, "liupi", "qun", 4)
local juying = fk.CreateTriggerSkill{
  name = "juying",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play then
      local n = 1
      if player.room.settings.gameMode == "m_1v2_mode" and player.role == "lord" then
        n = 2
      end
      local status_skills = player.room.status_skills[TargetModSkill] or Util.DummyTable
      for _, skill in ipairs(status_skills) do
        local correct = skill:getResidueNum(player, skill, Player.HistoryPhase, Fk:cloneCard("slash"), nil)
        if correct == nil then correct = 0 end
        n = n + correct
      end
      return player:usedCardTimes("slash", Player.HistoryPhase) < n
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    local choices = {"Cancel", "juying1", "juying2", "juying3"}
    for i = 1, 3, 1 do
      local choice = room:askForChoice(player, choices, self.name, "#juying-choice")
      if choice == "Cancel" then break end
      if choice == "juying1" then
        room:addPlayerMark(player, self.name, 1)
      elseif choice == "juying2" then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 2)
      else
        player:drawCards(3, self.name)
      end
      table.removeOne(choices, choice)
      n = n + 1
    end
    if n > 0 and n > player.hp then
      n = n - player.hp
      if #player:getCardIds{Player.Hand, Player.Equip} < n then return end
      room:askForDiscard(player, n, n, true, self.name, false)
    end
  end,

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
  end,
}
local juying_targetmod = fk.CreateTargetModSkill{
  name = "#juying_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("juying") > 0 and scope == Player.HistoryPhase then
      return player:getMark("juying")
    end
  end,
}
juying:addRelatedSkill(juying_targetmod)
liupi:addSkill(juying)
Fk:loadTranslationTable{
  ["liupi"] = "刘辟",
  ["juying"] = "踞营",
  [":juying"] = "出牌阶段结束时，若你本阶段使用【杀】的次数小于次数上限，你可以选择任意项：1.下个回合出牌阶段使用【杀】次数上限+1；"..
  "2.本回合手牌上限+2；3.摸三张牌。若你选择的选项数大于你的体力值，每多一项你弃置一张牌（不足则不弃）。",
  ["#juying-choice"] = "踞营：你可以选择任意项，每比体力值多选一项便弃一张牌",
  ["juying1"] = "下个回合出牌阶段使用【杀】上限+1",
  ["juying2"] = "本回合手牌上限+2",
  ["juying3"] = "摸三张牌",

  ["$juying1"] = "垒石为寨，纵万军亦可阻。",
  ["$juying2"] = "如虎踞汝南，攻守自有我。",
  ["~liupi"] = "玄德公高义，辟宁死不悔！",
}

local zhangchu = General(extension, "zhangchu", "qun", 3, 3, General.Female)
local jizhong = fk.CreateActiveSkill{
  name = "jizhong",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(2, self.name)
    if target:getMark("@@xinzhong") > 0 then
      if #target.player_cards[Player.Hand] <= 3 then
        target:throwAllCards("h")
      else
        room:askForDiscard(target, 3, 3, false, self.name, false, ".", "#jizhong-discard2")
      end
    else
      if #target.player_cards[Player.Hand] < 3 then
        room:setPlayerMark(target, "@@xinzhong", 1)
      else
        local cards = room:askForDiscard(target, 3, 3, false, self.name, true, ".", "#jizhong-discard1")
        if #cards == 0 then
          room:setPlayerMark(target, "@@xinzhong", 1)
        end
      end
    end
  end,
}
local rihui = fk.CreateTriggerSkill{
  name = "rihui",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      (data.card:isCommonTrick() or (data.card.type == Card.TypeBasic and data.card.color == Card.Black)) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] ~= player.id
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if to.dead then return end
    if to:getMark("@@xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@xinzhong") > 0 then
          return room:askForSkillInvoke(player, self.name, data, "#rihui-use::" .. to.id .. ":" .. data.card.name)
        end
      end
    else
      if to:isAllNude() then return end
      return room:askForSkillInvoke(player, self.name, data, "#rihui-get::" .. to.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if to:getMark("@@xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@xinzhong") > 0 then
          if to.dead or p.dead then return end
          room:useVirtualCard(data.card.name, nil, p, to, self.name, true)
        end
      end
    else
      local id = room:askForCardChosen(player, to, "hej", self.name)
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
}
local guangshi = fk.CreateTriggerSkill{
  name = "guangshi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.Start and
      table.every(player.room:getOtherPlayers(player), function (p)
        return p:getMark("@@xinzhong") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
    player:drawCards(2, self.name)
  end,
}
zhangchu:addSkill(jizhong)
zhangchu:addSkill(rihui)
zhangchu:addSkill(guangshi)
Fk:loadTranslationTable{
  ["zhangchu"] = "张楚",
  ["jizhong"] = "集众",
  [":jizhong"] = "出牌阶段限一次，你可以令一名其他角色摸两张牌，然后若其不是“信众”，则其选择一项：1.成为“信众”；"..
  "2.弃置三张手牌；若其是“信众”，则其弃置三张手牌（不足则全弃）。",
  ["rihui"] = "日慧",
  [":rihui"] = "每回合限一次，当你使用指定唯一其他角色为目标的普通锦囊牌或黑色基本牌后，若其：不是“信众”，所有“信众”均视为对其使用此牌；"..
  "是“信众”，你可以获得其区域内的一张牌。",
  ["guangshi"] = "光噬",
  [":guangshi"] = "锁定技，准备阶段，若所有其他角色均是“信众”，你失去1点体力并摸两张牌。",
  ["@@xinzhong"] = "信众",
  ["#jizhong-discard1"] = "集众：你需弃置三张手牌，否则成为“信众”",
  ["#jizhong-discard2"] = "集众：你需弃置三张手牌",
  ["#rihui-use"] = "日慧：你可以令所有“信众”视为对 %dest 使用一张【%arg】",
  ["#rihui-get"] = "日慧：你可以获得 %dest 区域内一张牌",

  ["$jizhong1"] = "聚八方之众，昭黄天之明。",
  ["$jizhong2"] = "联苦厄黎庶，传大道太平。",
  ["$rihui1"] = "甲子双至，黄巾再起。",
  ["$rihui2"] = "日中必彗，操刀必割。",
  ["$guangshi1"] = "舍身饲火，光耀人间。",
  ["$guangshi2"] = "愿为奉光之薪柴，照太平于人间。",
  ["~zhangchu"] = "苦难不尽，黄天不死……",
}

local peiyuanshao = General(extension, "peiyuanshao", "qun", 4)
local moyu = fk.CreateActiveSkill{
  name = "moyu",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("@@moyu-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target ~= Self and target:getMark("moyu-turn") == 0 and not target:isAllNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "hej", self.name)
    room:obtainCard(player.id, id, false, fk.ReasonPrey)
    if target.dead then return end
    room:setPlayerMark(target, "moyu-turn", 1)
    local use = room:askForUseCard(target, "slash", "slash", "#moyu-slash::"..player.id..":"..player:usedSkillTimes(self.name), true,
      {must_targets = {player.id}, bypass_distances = true, bypass_times = true})
    if use then
      use.additionalDamage = (use.additionalDamage or 0) + player:usedSkillTimes(self.name) - 1
      room:useCard(use)
      if not player.dead and use.damageDealt and use.damageDealt[player.id] then
        room:setPlayerMark(player, "@@moyu-turn", 1)
      end
    end
  end,
}
peiyuanshao:addSkill(moyu)
Fk:loadTranslationTable{
  ["peiyuanshao"] = "裴元绍",
  ["moyu"] = "没欲",
  [":moyu"] = "出牌阶段每名角色限一次，你可以获得一名其他角色区域内的一张牌，然后该角色可以对你使用一张无距离限制且伤害值为X的【杀】"..
  "（X为本回合本技能发动次数），若此【杀】对你造成了伤害，本技能于本回合失效。",
  ["#moyu-slash"] = "没欲：你可以对 %dest 使用一张【杀】，伤害基数为%arg",
  ["@@moyu-turn"] = "没欲失效",

  ["$moyu1"] = "人之所有，我之所欲。",
  ["$moyu2"] = "胸有欲壑千丈，自当饥不择食。",
  ["~peiyuanshao"] = "好生厉害的白袍小将……",
}

--异军突起：公孙度
local gongsundu = General(extension, "gongsundu", "qun", 4)
local zhenze = fk.CreateTriggerSkill{
  name = "zhenze",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Discard
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"zhenze_lose", "zhenze_recover"}, self.name)
    if choice == "zhenze_lose" then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if ((p:getHandcardNum() > p.hp) ~= (player:getHandcardNum() > player.hp) or
          (p:getHandcardNum() == p.hp) ~= (player:getHandcardNum() == player.hp) or
          (p:getHandcardNum() < p.hp) ~= (player:getHandcardNum() < player.hp)) then
            room:loseHp(p, 1, self.name)
        end
      end
    else
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:isWounded() and
          ((p:getHandcardNum() > p.hp) and (player:getHandcardNum() > player.hp) or
          (p:getHandcardNum() == p.hp) and (player:getHandcardNum() == player.hp) or
          (p:getHandcardNum() < p.hp) and (player:getHandcardNum() < player.hp)) then
            room:recover({
              who = p,
              num = 1,
              recoverBy = player,
              skillName = self.name
            })
        end
      end
    end
  end,
}
local anliao = fk.CreateActiveSkill{
  name = "anliao",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    local n = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p.kingdom == "qun" then
        n = n + 1
      end
    end
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < n
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "he", self.name)
    room:recastCard({id}, target, self.name)
  end,
}
gongsundu:addSkill(zhenze)
gongsundu:addSkill(anliao)
Fk:loadTranslationTable{
  ["gongsundu"] = "公孙度",
  ["zhenze"] = "震泽",
  [":zhenze"] = "弃牌阶段开始时，你可以选择一项：1.令所有手牌数和体力值的大小关系与你不同的角色失去1点体力；"..
  "2.令所有手牌数和体力值的大小关系与你相同的角色回复1点体力。",
  ["anliao"] = "安辽",
  [":anliao"] = "出牌阶段限X次（X为群势力角色数），你可以重铸一名角色的一张牌。",
  ["zhenze_lose"] = "手牌数和体力值的大小关系与你不同的角色失去1点体力",
  ["zhenze_recover"] = "所有手牌数和体力值的大小关系与你相同的角色回复1点体力",

  ["$zhenze1"] = "名震千里，泽被海东。",
  ["$zhenze2"] = "施威除暴，上下咸服。",
  ["$anliao1"] = "地阔天高，大有可为。",
  ["$anliao2"] = "水草丰沛，当展宏图。",
  ["~gongsundu"] = "为何都不愿出仕！",
}

--正音雅乐：蔡文姬
local caiwenji = General(extension, "mu__caiwenji", "qun", 3, 3, General.Female)
local shuangjia = fk.CreateTriggerSkill{
  name = "shuangjia",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      player.room:setCardMark(Fk:getCardById(id), "@@shuangjia", 1)
    end
    player.room:setPlayerMark(player, "shuangjia", player:getHandcardNum())
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
  local room = player.room
    for _, move in ipairs(data) do
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerHand then
          if Fk:getCardById(info.cardId):getMark("@@shuangjia") > 0 then
            room:setCardMark(Fk:getCardById(info.cardId), "@@shuangjia", 0)
            room:removePlayerMark(room:getPlayerById(move.from), "shuangjia", 1)
          end
        end
      end
    end
  end,
}
local shuangjia_maxcards = fk.CreateMaxCardsSkill{
  name = "#shuangjia_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@shuangjia") > 0
  end,
}
local shuangjia_distance = fk.CreateDistanceSkill{
  name = "#shuangjia_distance",
  correct_func = function(self, from, to)
    if to:hasSkill("shuangjia") and to:getMark("shuangjia") > 0 then
      return math.min(to:getMark("shuangjia"), 5)
    end
  end,
}
local beifen = fk.CreateTriggerSkill{
  name = "beifen",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.extra_data and move.extra_data.beifen then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
    local cards = {}
    while #suits > 0 do
      local pattern = table.random(suits)
      if not table.find(player.player_cards[Player.Hand], function(id)
        return Fk:getCardById(id):getMark("@@shuangjia") > 0 and Fk:getCardById(id):getSuitString() == pattern end) then
        table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
      end
      table.removeOne(suits, pattern)
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@shuangjia") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        local n = 0
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@shuangjia") > 0 then
            n = n + 1
          end
        end
        if n > 0 then
          move.extra_data = move.extra_data or {}
          move.extra_data.beifen = n
        end
      end
    end
  end,
}
local beifen_targetmod = fk.CreateTargetModSkill{
  name = "#beifen_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill("beifen") and player:getHandcardNum() > 2 * player:getMark("shuangjia")
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill("beifen") and player:getHandcardNum() > 2 * player:getMark("shuangjia")
  end,
}
shuangjia:addRelatedSkill(shuangjia_maxcards)
shuangjia:addRelatedSkill(shuangjia_distance)
beifen:addRelatedSkill(beifen_targetmod)
caiwenji:addSkill(shuangjia)
caiwenji:addSkill(beifen)
Fk:loadTranslationTable{
  ["mu__caiwenji"] = "蔡文姬",
  ["shuangjia"] = "霜笳",
  [":shuangjia"] = "锁定技，游戏开始时，你的初始手牌增加“胡笳”标记且不计入手牌上限。你每拥有一张“胡笳”，其他角色计算与你距离+1（最多+5）。",
  ["beifen"] = "悲愤",
  [":beifen"] = "锁定技，当你失去“胡笳”后，你获得与手中“胡笳”花色均不同的牌各一张。你手中“胡笳”少于其他牌时，你使用牌无距离和次数限制。",
  ["@@shuangjia"] = "胡笳",

  ["$shuangjia1"] = "塞外青鸟匿，不闻折柳声。",
  ["$shuangjia2"] = "向晚吹霜笳，雪落白发生。",
  ["$beifen1"] = "此心如置冰壶，无物可暖。",
  ["$beifen2"] = "年少爱登楼，欲说语还休。",
  ["~mu__caiwenji"] = "天何薄我，天何薄我……",
}

return extension
