local extension = Package("tenyear_sp2")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_sp2"] = "十周年-限定专属2",
  ["wm"] = "武",
}

--笔舌如椽：杨修 骆统 王昶 程秉 杨彪 阮籍
local yangxiu = General(extension, "ty__yangxiu", "wei", 3)
local ty__danlao = fk.CreateTriggerSkill{
  name = "ty__danlao",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and
      #AimGroup:getAllTargets(data.tos) > 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__danlao-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
}
local ty__jilei = fk.CreateTriggerSkill{
  name = "ty__jilei",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__jilei-invoke::"..data.from.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"basic", "trick", "equip"}, self.name)
    local mark = data.from:getMark("@ty__jilei")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, choice .. "_char")
    room:setPlayerMark(data.from, "@ty__jilei", mark)
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ty__jilei") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty__jilei", 0)
  end,
}
local ty__jilei_prohibit = fk.CreateProhibitSkill{
  name = "#ty__jilei_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getMark("@ty__jilei")
    if type(mark) == "table" and table.contains(mark, card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getMark("@ty__jilei")
    if type(mark) == "table" and table.contains(mark, card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_discard = function(self, player, card)
    local mark = player:getMark("@ty__jilei")
    return type(mark) == "table" and table.contains(mark, card:getTypeString() .. "_char")
  end,
}
ty__jilei:addRelatedSkill(ty__jilei_prohibit)
yangxiu:addSkill(ty__danlao)
yangxiu:addSkill(ty__jilei)
Fk:loadTranslationTable{
  ["ty__yangxiu"] = "杨修",
  ["ty__danlao"] = "啖酪",
  [":ty__danlao"] = "当你成为【杀】或锦囊牌的目标后，若你不是唯一目标，你可以摸一张牌，然后此牌对你无效。",
  ["ty__jilei"] = "鸡肋",
  [":ty__jilei"] = "当你受到伤害后，你可以声明一种牌的类别，伤害来源不能使用、打出或弃置你声明的此类手牌直到其下回合开始。",
  ["#ty__danlao-invoke"] = "啖酪：你可以摸一张牌，令 %arg 对你无效",
  ["#ty__jilei-invoke"] = "鸡肋：是否令 %dest 不能使用、打出、弃置一种类别的牌直到其下回合开始？",
  ["@ty__jilei"] = "鸡肋",
  
  ["$ty__danlao1"] = "此酪味美，诸君何不与我共食之？",
  ["$ty__danlao2"] = "来来来，丞相美意，不可辜负啊。",
  ["$ty__jilei1"] = "今进退两难，势若鸡肋，魏王必当罢兵而还。",
  ["$ty__jilei2"] = "汝可令士卒收拾行装，魏王明日必定退兵。",
  ["~ty__yangxiu"] = "自作聪明，作茧自缚，悔之晚矣……",
}

local luotong = General(extension, "ty__luotong", "wu", 3)
local renzheng = fk.CreateTriggerSkill{
  name = "renzheng",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DamageFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if data.extra_data and data.extra_data.renzheng_invoke then
        return true
      end
      if data.to:getMark("renzheng-phase") > 0 then
        player.room:setPlayerMark(data.to, "renzheng-phase", 0)--FIXME: 伪实现！！！
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.PreDamage, fk.AfterSkillEffect, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.PreDamage then
      data.extra_data = data.extra_data or {}
      data.extra_data.renzheng = data.damage
      player.room:setPlayerMark(data.to, "renzheng-phase", 1)--FIXME
    elseif event == fk.AfterSkillEffect then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.Damage)
      if e then
        local dat = e.data[1]
        if dat.extra_data and dat.extra_data.renzheng and dat.damage < dat.extra_data.renzheng then
          dat.extra_data.renzheng_invoke = true
        end
      end
    elseif event == fk.Damaged then
      player.room:setPlayerMark(data.to, "renzheng-phase", 0)--FIXME
    end
  end,
}
local jinjian = fk.CreateTriggerSkill{
  name = "jinjian",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    if player:usedSkillTimes(self.name, Player.HistoryTurn) % 2 == 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#jinjian1-invoke::"..data.to.id)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if player:usedSkillTimes(self.name, Player.HistoryTurn) % 2 == 1 then
      room:notifySkillInvoked(player, self.name, "offensive")
      data.damage = data.damage + 1
    else
      room:notifySkillInvoked(player, self.name, "negative")
      data.damage = data.damage - 1
    end
  end,
}
local jinjian_trigger = fk.CreateTriggerSkill{
  name = "#jinjian_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    if player:usedSkillTimes(self.name, Player.HistoryTurn) % 2 == 0 then
      return player.room:askForSkillInvoke(player, "jinjian", nil, "#jinjian2-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("jinjian")
    if player:usedSkillTimes(self.name, Player.HistoryTurn) % 2 == 1 then
      room:notifySkillInvoked(player, "jinjian", "defensive")
      data.damage = data.damage - 1
    else
      room:notifySkillInvoked(player, "jinjian", "negative")
      data.damage = data.damage + 1
    end
  end,
}
jinjian:addRelatedSkill(jinjian_trigger)
luotong:addSkill(renzheng)
luotong:addSkill(jinjian)
Fk:loadTranslationTable{
  ["ty__luotong"] = "骆统",
  ["renzheng"] = "仁政",  --这两个烂大街的技能名大概率撞车叭……
  [":renzheng"] = "锁定技，当有伤害被减少或防止后，你摸两张牌。",
  ["jinjian"] = "进谏",
  [":jinjian"] = "当你造成伤害时，你可令此伤害+1，若如此做，你此回合下次造成的伤害-1且不能发动〖进谏〗；当你受到伤害时，你可令此伤害-1，"..
  "若如此做，你此回合下次受到的伤害+1且不能发动〖进谏〗。",
  ["#jinjian1-invoke"] = "进谏：你可以令对 %dest 造成的伤害+1",
  ["#jinjian2-invoke"] = "进谏：你可以令受到的伤害-1",

  ["$renzheng1"] = "仁政如水，可润万物。",
  ["$renzheng2"] = "为官一任，当造福一方。",
  ["$jinjian1"] = "臣代天子牧民，闻苛自当谏之。",
  ["$jinjian2"] = "为将者死战，为臣者死谏！",
  ["~ty__luotong"] = "而立之年，奈何早逝。",
}

local wangchang = General(extension, "ty__wangchang", "wei", 3)
local ty__kaiji = fk.CreateActiveSkill{
  name = "ty__kaiji",
  anim_type = "switch",
  switch_skill_name = "ty__kaiji",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      player:drawCards(player.maxHp, self.name)
    else
      room:askForDiscard(player, 1, player.maxHp, true, self.name, false, ".", "#ty__kaiji-discard:::"..player.maxHp)
    end
  end,
}
local pingxi = fk.CreateTriggerSkill{
  name = "pingxi",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and player:getMark("pingxi-turn") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("pingxi-turn")
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end), function(p) return p.id end)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#pingxi-choose:::"..player:getMark("pingxi-turn"), self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p:isNude() then
        local card = room:askForCardChosen(player, p, "he", self.name)
        room:throwCard({card}, self.name, p, player)
      end
    end
    for _, id in ipairs(self.cost_data) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        room:useVirtualCard("slash", nil, player, p, self.name, true)
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
        player.room:addPlayerMark(player, "pingxi-turn", #move.moveInfo)
      end
    end
  end,
}
wangchang:addSkill(ty__kaiji)
wangchang:addSkill(pingxi)
Fk:loadTranslationTable{
  ["ty__wangchang"] = "王昶",
  ["ty__kaiji"] = "开济",
  [":ty__kaiji"] = "转换技，出牌阶段限一次，阳：你可以摸等于体力上限张数的牌；阴：你可以弃置至多等于体力上限张数的牌（至少一张）。",
  ["pingxi"] = "平袭",
  [":pingxi"] = "结束阶段，你可选择至多X名其他角色（X为本回合因弃置而进入弃牌堆的牌数），弃置这些角色各一张牌，然后视为对这些角色各使用一张【杀】。",
  ["#ty__kaiji-discard"] = "开济：你可以弃置至多%arg张牌",
  ["#pingxi-choose"] = "平袭：你可以选择至多%arg名角色，弃置这些角色各一张牌并视为对这些角色各使用一张【杀】",
}

local chengbing = General(extension, "chengbing", "wu", 3)
local jingzao = fk.CreateActiveSkill{
  name = "jingzao",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("jingzao-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("jingzao-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "jingzao-phase", 1)
    local n = 3 + player:getMark("jingzao_num-turn")
    local cards = room:getNCards(n)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    if not target:isNude() then
      local pattern = table.concat(table.map(cards, function(id) return Fk:getCardById(id, true).trueName end), ",")
      if #room:askForDiscard(target, 1, 1, true, self.name, true, pattern, "#jingzao-discard:"..player.id) > 0 then
        room:addPlayerMark(player, "jingzao_num-turn", 1)
        room:moveCards({
          ids = cards,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
        })
        return
      end
    end
    local dummy = Fk:cloneCard("dilu")
    while #cards > 0 do
      local id = table.random(cards)
      if not table.find(dummy.subcards, function(c) return Fk:getCardById(c, true).trueName == Fk:getCardById(id, true).trueName end) then
        dummy:addSubcard(id)
      end
      table.removeOne(cards, id)
    end
    room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    room:setPlayerMark(player, "jingzao-turn", 1)
  end,
}
local enyu = fk.CreateTriggerSkill{
  name = "enyu",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from ~= player.id and (data.card:isCommonTrick() or
      data.card.type == Card.TypeBasic) and player:getMark("enyu-turn") ~= 0 and
      #table.filter(player:getMark("enyu-turn"), function(name) return name == data.card.trueName end) > 1
  end,
  on_use = function(self, event, target, player, data)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,

  refresh_events = {fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.from ~= player.id and (data.card:isCommonTrick() or data.card.type == Card.TypeBasic)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("enyu-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, data.card.trueName)
    room:setPlayerMark(player, "enyu-turn", mark)
  end,
}
chengbing:addSkill(jingzao)
chengbing:addSkill(enyu)
Fk:loadTranslationTable{
  ["chengbing"] = "程秉",
  ["jingzao"] = "经造",
  [":jingzao"] = "出牌阶段每名角色限一次，你可以选择一名其他角色并亮出牌堆顶三张牌，然后该角色选择一项："..
  "1.弃置一张与亮出牌同名的牌，然后此技能本回合亮出的牌数+1；2.令你随机获得这些牌中牌名不同的牌各一张，然后此技能本回合失效。",
  ["enyu"] = "恩遇",
  [":enyu"] = "锁定技，当你成为其他角色使用基本牌或普通锦囊牌的目标后，若你本回合已成为过同名牌的目标，此牌对你无效。",
  ["#jingzao-discard"] = "经造：弃置一张同名牌使本回合“经造”亮出牌+1，或点“取消”令 %src 获得其中不同牌名各一张",
}

local yangbiao = General(extension, "ty__yangbiao", "qun", 3)
local ty__zhaohan = fk.CreateTriggerSkill{
  name = "ty__zhaohan",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,

  refresh_events = {fk.AfterDrawNCards},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 and player:getHandcardNum() > 1
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p:isKongcheng() end), function(p) return p.id end)
    local prompt = "#zhaohan-discard"
    if #targets > 0 then
      prompt = "#zhaohan-give"
    end
    local cards = room:askForCard(player, 2, 2, false, self.name, false, ".", prompt)
    if #targets > 0 then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhaohan-choose", self.name, true)
      if #to > 0 then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(cards)
        room:obtainCard(to[1], dummy, false, fk.ReasonJustMove)
        return
      end
    end
    room:throwCard(cards, self.name, player, player)
  end
}
local jinjie = fk.CreateTriggerSkill{
  name = "jinjie",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    if player:getMark("jinjie-round") > 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#jinjie-draw::"..target.id)
    else
      local n = player:usedSkillTimes(self.name, Player.HistoryRound)
      if n == 0 then
        return player.room:askForSkillInvoke(player, self.name, nil, "#jinjie-invoke::"..target.id)
      else
        if player:getHandcardNum() < n then return end
        return #player.room:askForDiscard(player, n, n, false, self.name, true, ".", "#jinjie-discard::"..target.id..":"..n) > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if player:getMark("jinjie-round") > 0 then
      target:drawCards(1, self.name)
    else
      player.room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from == Player.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "jinjie-round", 1)
  end,
}
local jue = fk.CreateTriggerSkill{
  name = "jue",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isWounded() and not player:isProhibited(p, Fk:cloneCard("slash")) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#jue-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("slash", nil, player, player.room:getPlayerById(self.cost_data), self.name, true)
  end,
}
yangbiao:addSkill(ty__zhaohan)
yangbiao:addSkill(jinjie)
yangbiao:addSkill(jue)
Fk:loadTranslationTable{
  ["ty__yangbiao"] = "杨彪",
  ["ty__zhaohan"] = "昭汉",
  [":ty__zhaohan"] = "摸牌阶段，你可以多摸两张牌，然后选择一项：1.交给一名没有手牌的角色两张手牌；2.弃置两张手牌。",
  ["jinjie"] = "尽节",
  [":jinjie"] = "一名角色进入濒死状态时，若本轮你还没有进行回合，你可以弃置X张手牌令其回复1点体力（X为本轮此技能的发动次数）；若你已进行过回合，你可以令其摸一张牌。",
  ["jue"] = "举讹",
  [":jue"] = "准备阶段，你可以视为对一名满体力的角色使用一张【杀】。",
  ["#zhaohan-discard"] = "昭汉：弃置两张手牌",
  ["#zhaohan-give"] = "昭汉：选择两张手牌，交给一名没有手牌的角色或弃置之",
  ["#zhaohan-choose"] = "昭汉：选择一名没有手牌的角色获得这些牌，或点“取消”弃置之",
  ["#jinjie-draw"] = "尽节：你可以令 %dest 摸一张牌",
  ["#jinjie-invoke"] = "尽节：你可以令 %dest 回复1点体力",
  ["#jinjie-discard"] = "尽节：你可以弃置%arg张手牌，令 %dest 回复1点体力",
  ["#jue-choose"] = "举讹：你可以视为对一名未受伤的角色使用【杀】",
}

local ruanji = General(extension, "ruanji", "wei", 3)
local zhaowen = fk.CreateViewAsSkill{
  name = "zhaowen",
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#zhaowen",
  interaction = function()
    local names = {}
    local mark = Self:getMark("@$zhaowen-turn")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived then
        local c = Fk:cloneCard(card.name)
        if ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, c) and not Self:prohibitUse(c)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))) then
          if mark == 0 or (not table.contains(mark, card.trueName)) then
            table.insertIfNeed(names, card.name)
          end
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names }
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.color == Card.Black and card:getMark("@@zhaowen-turn") > 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getMark("@$zhaowen-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, use.card.trueName)
    player.room:setPlayerMark(player, "@$zhaowen-turn", mark)
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes("#zhaowen_trigger", Player.HistoryTurn) > 0 and
      table.find(player.player_cards[Player.Hand], function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen-turn") > 0 end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) and
      not player:isKongcheng() and player:usedSkillTimes("#zhaowen_trigger", Player.HistoryTurn) > 0 and
      table.find(player.player_cards[Player.Hand], function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen-turn") > 0 end)
  end,
}
local zhaowen_trigger = fk.CreateTriggerSkill{
  name = "#zhaowen_trigger",
  mute = true,
  events = {fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill("zhaowen") and player.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return not player:isKongcheng()
      else
        return data.card.color == Card.Red and not data.card:isVirtual() and data.card:getMark("@@zhaowen-turn") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, "zhaowen", nil, "#zhaowen-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("zhaowen")
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, "zhaowen", "special")
      local cards = table.simpleClone(player.player_cards[Player.Hand])
      player:showCards(cards)
      if not player.dead and not player:isKongcheng() then
        room:setPlayerMark(player, "zhaowen-turn", cards)
        for _, id in ipairs(cards) do
          room:setCardMark(Fk:getCardById(id, true), "@@zhaowen-turn", 1)
        end
      end
    else
      room:notifySkillInvoked(player, "zhaowen", "drawcard")
      player:drawCards(1, "zhaowen")
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Death and player ~= target then return end
    return player:getMark("zhaowen-turn") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("zhaowen-turn")
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.toArea ~= Card.Processing then
          for _, info in ipairs(move.moveInfo) do
            table.removeOne(mark, info.cardId)
            room:setCardMark(Fk:getCardById(info.cardId), "@@zhaowen-turn", 0)
          end
        end
      end
      room:setPlayerMark(player, "zhaowen-turn", mark)
    elseif event == fk.Death then
      for _, id in ipairs(mark) do
        room:setCardMark(Fk:getCardById(id), "@@zhaowen-turn", 0)
      end
    end
  end,
}
local jiudun = fk.CreateTriggerSkill{
  name = "jiudun",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.firstTarget and data.card.color == Card.Black and data.from ~= player.id and
      (player.drank == 0 or not player:isKongcheng())
  end,
  on_cost = function(self, event, target, player, data)
    if player.drank == 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#jiudun-invoke")
    else
      local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|.|hand", "#jiudun-card:::"..data.card:toLogString(), true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.drank == 0 then
      player:drawCards(1, self.name)
      room:useVirtualCard("analeptic", nil, player, player, self.name, false)
    else
      room:throwCard(self.cost_data, self.name, player, player)
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        AimGroup:cancelTarget(data, player.id)
      else
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    end
  end,

  refresh_events = {fk.EventPhaseStart, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target.phase == Player.NotActive and player.drank > 0
      else
        return player:getMark(self.name) > 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(player, self.name, player.drank)
    else
      player.drank = player:getMark(self.name)
      room:setPlayerMark(player, self.name, 0)
      room:broadcastProperty(player, "drank")
    end
  end,
}
zhaowen:addRelatedSkill(zhaowen_trigger)
ruanji:addSkill(zhaowen)
ruanji:addSkill(jiudun)
Fk:loadTranslationTable{
  ["ruanji"] = "阮籍",
  ["zhaowen"] = "昭文",
  [":zhaowen"] = "出牌阶段开始时，你可以展示所有手牌。若如此做，本回合其中的黑色牌可以当任意一张普通锦囊牌使用（每回合每种牌名限一次），"..
  "其中的红色牌你使用时摸一张牌。",
  ["jiudun"] = "酒遁",
  [":jiudun"] = "你的【酒】效果不会因回合结束而消失。当你成为其他角色使用黑色牌的目标后，若你未处于【酒】状态，你可以摸一张牌并视为使用一张【酒】；"..
  "若你处于【酒】状态，你可以弃置一张手牌令此牌对你无效。",
  ["#zhaowen"] = "昭文：将一张黑色“昭文”牌当任意普通锦囊牌使用（每回合每种牌名限一次）",
  ["@$zhaowen-turn"] = "昭文",
  ["#zhaowen_trigger"] = "昭文",
  ["#zhaowen-invoke"] = "昭文：你可以展示手牌，本回合其中黑色牌可以当任意锦囊牌使用，红色牌使用时摸一张牌",
  ["@@zhaowen-turn"] = "昭文",
  ["#jiudun-invoke"] = "酒遁：你可以摸一张牌，视为使用【酒】",
  ["#jiudun-card"] = "酒遁：你可以弃置一张手牌，令%arg对你无效",

  ["$zhaowen1"] = "我辈昭昭，正始之音浩荡。",
  ["$zhaowen2"] = "正文之昭，微言之绪，绝而复续。",
  ["$jiudun1"] = "籍不胜酒力，恐失言失仪。",
  ["$jiudun2"] = "秋月春风正好，不如大醉归去。",
  ["~ruanji"] = "诸君，欲与我同醉否？",
}

--豆蔻梢头：花鬘 薛灵芸 芮姬 段巧笑
local huaman = General(extension, "ty__huaman", "shu", 3, 3, General.Female)
local ty__manyi = fk.CreateTriggerSkill{
  name = "ty__manyi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.card.trueName == "savage_assault" and player.id == data.to
  end,
  on_use = function()
    return true
  end,
}
local mansi = fk.CreateViewAsSkill{
  name = "mansi",
  anim_type = "offensive",
  prompt = "#mansi",
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("savage_assault")
    card:addSubcards(Self:getCardIds(Player.Hand))
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
}
local mansi_trigger = fk.CreateTriggerSkill{
  name = "#mansi_trigger",
  events = {fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("mansi") and data.card and data.card.trueName == "savage_assault"
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, "@mansi")
    room:addPlayerMark(player, "@mansi", 1)
    player:broadcastSkillInvoke("mansi")
    room:notifySkillInvoked(player, "mansi", "drawcard")
  end,
}
local souying = fk.CreateTriggerSkill{
  name = "souying",
  mute = true,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.tos and data.firstTarget and #AimGroup:getAllTargets(data.tos) == 1 and
      not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local room = player.room
      local events = {}
      if target == player then
        if TargetGroup:getRealTargets(data.tos)[1] == player.id or room:getCardArea(data.card) ~= Card.Processing then return end
          events = room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
          local use = e.data[1]
          return use.from == player.id and table.contains(TargetGroup:getRealTargets(use.tos), TargetGroup:getRealTargets(data.tos)[1])
        end, Player.HistoryTurn)
      else
        if TargetGroup:getRealTargets(data.tos)[1] ~= player.id then return end
          events = room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
          local use = e.data[1]
          return use.from == target.id and table.contains(TargetGroup:getRealTargets(use.tos), player.id)
        end, Player.HistoryTurn)
      end
      return #events > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if target == player then
      prompt = "#souying1-invoke:::"..data.card:toLogString()
    else
      prompt = "#souying2-invoke:::"..data.card:toLogString()
    end
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", prompt, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    player:broadcastSkillInvoke(self.name)
    if target == player then
      room:notifySkillInvoked(player, self.name, "drawcard")
      if not player.dead and room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player, data.card, true, fk.ReasonJustMove)
      end
    else
      room:notifySkillInvoked(player, self.name, "defensive")
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        AimGroup:cancelTarget(data, player.id)
      else
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    end
  end,
}
local zhanyuan = fk.CreateTriggerSkill{
  name = "zhanyuan",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@mansi") > 6
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.gender == General.Male and not p:hasSkill("xili", true) end), function (p) return p.id end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhanyuan-choose", self.name, true)
    if #to > 0 then
      room:handleAddLoseSkills(player, "xili|-mansi", nil, true, false)
      room:handleAddLoseSkills(room:getPlayerById(to[1]), "xili", nil, true, false)
    end
  end,
}
local xili = fk.CreateTriggerSkill{
  name = "xili",
  anim_type = "support",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.from and target ~= player and
      target:hasSkill(self.name, true, true) and target.phase ~= Player.NotActive and
      not data.to:hasSkill(self.name, true) and not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#xili-invoke:"..data.from.id..":"..data.to.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    data.damage = data.damage + 1
    if not player.dead then
      player:drawCards(2, self.name)
    end
    if not target.dead then
      target:drawCards(2, self.name)
    end
  end,
}
mansi:addRelatedSkill(mansi_trigger)
huaman:addSkill(ty__manyi)
huaman:addSkill(mansi)
huaman:addSkill(souying)
huaman:addSkill(zhanyuan)
huaman:addRelatedSkill(xili)
Fk:loadTranslationTable{
  ["ty__huaman"] = "花鬘",
  ["ty__manyi"] = "蛮裔",
  [":ty__manyi"] = "锁定技，【南蛮入侵】对你无效。",
  ["mansi"] = "蛮嗣",
  [":mansi"] = "出牌阶段限一次，你可以将所有手牌当【南蛮入侵】使用；当一名角色受到【南蛮入侵】的伤害后，你摸一张牌。",
  ["souying"] = "薮影",
  [":souying"] = "每回合限一次，当你使用牌指定其他角色为唯一目标后，若此牌不是本回合你对其使用的第一张牌，你可以弃置一张牌获得之；"..
  "当其他角色使用牌指定你为唯一目标后，若此牌不是本回合其对你使用的第一张牌，你可以弃置一张牌令此牌对你无效。",
  ["zhanyuan"] = "战缘",
  [":zhanyuan"] = "觉醒技，准备阶段，若你发动〖蛮嗣〗获得不少于七张牌，你加1点体力上限并回复1点体力。然后你可以选择一名男性角色，"..
  "你与其获得技能〖系力〗，你失去技能〖蛮嗣〗。",
  ["xili"] = "系力",
  [":xili"] = "每回合限一次，其他拥有〖系力〗的角色于其回合内对没有〖系力〗的角色造成伤害时，你可以弃置一张牌令此伤害+1，然后你与其各摸两张牌。",
  ["#mansi"] = "蛮嗣：你可以将所有手牌当【南蛮入侵】使用",
  ["@mansi"] = "蛮嗣",
  ["#souying1-invoke"] = "薮影：你可以弃置一张牌，获得此%arg",
  ["#souying2-invoke"] = "薮影：你可以弃置一张牌，令此%arg对你无效",
  ["#zhanyuan-choose"] = "战缘：你可以与一名男性角色获得技能〖系力〗",
  ["#xili-invoke"] = "系力：你可以弃置一张牌，令 %src 对 %dest 造成的伤害+1，你与 %src 各摸两张牌",

  ["$ty__manyi1"] = "蛮族的力量，你可不要小瞧！",
  ["$ty__manyi2"] = "南蛮女子，该当英勇善战！",
  ["$mansi1"] = "多谢父母怜爱。",
  ["$mansi2"] = "承父母庇护，得此福气。",
  ["$souying1"] = "真薮影移，险战不惧！",
  ["$souying2"] = "幽薮影单，只身勇斗！",
  ["$zhanyuan1"] = "势不同，情相随。",
  ["$zhanyuan2"] = "战中结缘，虽苦亦甜。",
  ["$xili1"] = "系力而为，助君得胜。",
  ["$xili2"] = "有我在，将军此战必能一举拿下！",
  ["~ty__huaman"] = "南蛮之地的花，还在开吗……",
}

local xuelingyun = General(extension, "xuelingyun", "wei", 3, 3, General.Female)
local xialei = fk.CreateTriggerSkill{
  name = "xialei",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) or player:getMark("xialei-turn") > 2 then return false end
    local room = player.room
    local move_event = room.logic:getCurrentEvent()
    local parent_event = move_event.parent
    local card_ids = {}
    if parent_event ~= nil then
      if parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard then
        local parent_data = parent_event.data[1]
        if parent_data.from == player.id then
          card_ids = room:getSubcardsByRule(parent_data.card)
        end
      elseif parent_event.event == GameEvent.Pindian then
        local pindianData = parent_event.data[1]
        if pindianData.from == player then
          card_ids = room:getSubcardsByRule(pindianData.fromCard)
        else
          for toId, result in pairs(pindianData.results) do
            if player.id == toId then
              card_ids = room:getSubcardsByRule(result.toCard)
              break
            end
          end
        end
      end
    end
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        elseif #card_ids > 0 then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.Processing and table.contains(card_ids, info.cardId) and
            Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3 - player:getMark("xialei-turn"))
    local to_return = table.random(ids, 1)
    local choice = "xialei_top"
    if #ids > 1 then
      local result = room:askForCustomDialog(player, self.name,
        "packages/tenyear/qml/XiaLeiBox.qml", {
          ids,
          {"xialei_top", "xialei_bottom"}
        })
      if result ~= "" then
        local reply = json.decode(result)
        to_return = reply.cards
        choice = reply.choice
      end
    end
    local moveInfos = {
      ids = to_return,
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    }
    table.removeOne(ids, to_return[1])
    if #ids > 0 then
      if choice == "xialei_top" then
        for i = #ids, 1, -1 do
          table.insert(room.draw_pile, 1, ids[i])
        end
      else
        for _, id in ipairs(ids) do
          table.insert(room.draw_pile, id)
        end
      end
    end
    room:moveCards(moveInfos)
    room:addPlayerMark(player, "xialei-turn", 1)
  end,
}
local anzhi = fk.CreateActiveSkill{
  name = "anzhi",
  anim_type = "support",
  prompt = "#anzhi-active",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("anzhi-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      room:setPlayerMark(player, "xialei-turn", 0)
    elseif judge.card.color == Card.Black then
      room:addPlayerMark(player, "anzhi-turn", 1)
      local ids = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      ids = table.filter(ids, function (id) return room:getCardArea(id) == Card.DiscardPile end)
      if #ids == 0 then return end
      local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
        return p ~= room.current end), function(p) return p.id end), 1, 1, "#anzhi-choose", self.name, true)
      if #to > 0 then
        local get = {}
        if #ids > 2 then
          get = room:askForCardsChosen(player, player, 2, 2, {
            card_data = {
              { self.name, ids }
            }
          }, self.name)
        else
          get = ids
        end
        if #get > 0 then
          room:moveCards({
            ids = get,
            to = to[1],
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonPrey,
            proposer = player.id,
            skillName = self.name,
          })
        end
      end
    end
  end,
}
local anzhi_trigger = fk.CreateTriggerSkill{
  name = "#anzhi_trigger",
  anim_type = "support",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("anzhi-turn") == 0
  end,
  on_cost = function(self, event, target, player, data)
    player.room:askForUseActiveSkill(player, "anzhi", "#anzhi-invoke", true)
  end,
}
anzhi:addRelatedSkill(anzhi_trigger)
xuelingyun:addSkill(xialei)
xuelingyun:addSkill(anzhi)
Fk:loadTranslationTable{
  ["xuelingyun"] = "薛灵芸",
  ["xialei"] = "霞泪",
  [":xialei"] = "当你的红色牌进入弃牌堆后，你可观看牌堆顶的三张牌，然后你获得一张并可将其他牌置于牌堆底，你本回合观看牌数-1。",
  ["anzhi"] = "暗织",
  ["#anzhi_trigger"] = "暗织",
  [":anzhi"] = "出牌阶段或当你受到伤害后，你可以进行一次判定，若结果为：红色，重置〖霞泪〗；"..
  "黑色，你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌，且你本回合不能再发动此技能。",
  ["xialei_top"] = "将剩余牌置于牌堆顶",
  ["xialei_bottom"] = "将剩余牌置于牌堆底",
  ["#anzhi-active"] = "发动暗织，进行判定",
  ["#anzhi-invoke"] = "是否使用暗织，进行判定",
  ["#anzhi-choose"] = "暗织：你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌",

  ["$xialei1"] = "采霞揾晶泪，沾我青衫湿。",
  ["$xialei2"] = "登车入宫墙，垂泪凝如瑙。",
  ["$anzhi1"] = "深闱行彩线，唯手熟尔。",
  ["$anzhi2"] = "星月独照人，何谓之暗？",
  ["~xuelingyun"] = "寒月隐幕，难作衣裳。",
}

local ruiji = General(extension, "ty__ruiji", "wu", 4, 4, General.Female)
local wangyuan = fk.CreateTriggerSkill{
  name = "wangyuan",
  anim_type = "special",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.phase == Player.NotActive and #player:getPile("ruiji_wang") < #player.room.players then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wangyuan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id, true)
      if card.type ~= Card.TypeEquip and not table.find(player:getPile("ruiji_wang"), function(c)
        return card.trueName == Fk:getCardById(c, true).trueName end) then
        table.insertIfNeed(names, card.trueName)
      end
    end
    if #names > 0 then
      local card = room:getCardsFromPileByRule(table.random(names))
      player:addToPile("ruiji_wang", card[1], true, self.name)
    end
  end,
}
local lingyin = fk.CreateViewAsSkill{
  name = "lingyin",
  anim_type = "offensive",
  pattern = "duel",
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and (card.sub_type == Card.SubtypeWeapon or card.sub_type == Card.SubtypeArmor)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("duel")
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:getMark("lingyin-turn") > 0
  end,
}
local lingyin_trigger = fk.CreateTriggerSkill{
  name = "#lingyin_trigger",
  mute = true,
  expand_pile = "ruiji_wang",
  events = {fk.EventPhaseStart, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseStart then
        return player:hasSkill(self.name) and player.phase == Player.Play and #player:getPile("ruiji_wang") > 0
      else
        return player:getMark("lingyin-turn") > 0 and not data.chain and data.to ~= player
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local n = player.room:getTag("RoundCount")
      local cards = player.room:askForCard(player, 1, n, false, "liying", true,
        ".|.|.|ruiji_wang|.|.", "#lingyin-invoke:::"..tostring(n), "ruiji_wang")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      player:broadcastSkillInvoke("lingyin")
      room:notifySkillInvoked(player, "lingyin", "drawcard")
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(self.cost_data)
      room:obtainCard(player, dummy, false, fk.ReasonJustMove)
      if #player:getPile("ruiji_wang") == 0 or table.every(player:getPile("ruiji_wang"), function(id)
        return Fk:getCardById(id).color == Fk:getCardById(player:getPile("ruiji_wang")[1]).color end) then
        room:setPlayerMark(player, "lingyin-turn", 1)
      end
    else
      data.damage = data.damage + 1
    end
  end,
}
local liying = fk.CreateTriggerSkill{
  name = "liying",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.phase ~= Player.Draw and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(mark, info.cardId)
        end
      end
    end
    room:setPlayerMark(player, "liying-phase", mark)
    local prompt = "#liying1-invoke"
    if player.phase ~= Player.NotActive and #player:getPile("ruiji_wang") < #room.players then
      prompt = "#liying2-invoke"
    end
    local _, ret = player.room:askForUseActiveSkill(player, "liying_active", prompt, true)
    if ret then
      self.cost_data = ret
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ret = self.cost_data
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(ret.cards)
    room:obtainCard(room:getPlayerById(ret.targets[1]), dummy, false, fk.ReasonGive)
    if not player.dead then
      player:drawCards(1, self.name)
      if not player.dead and player.phase ~= Player.NotActive and #player:getPile("ruiji_wang") < #room.players then
        local skill = Fk.skills["wangyuan"]
        skill:use(event, target, player, data)
      end
    end
  end,
}
local liying_active = fk.CreateActiveSkill{
  name = "liying_active",
  mute = true,
  min_card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return Self:getMark("liying-phase") ~= 0 and table.contains(Self:getMark("liying-phase"), to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
}
lingyin:addRelatedSkill(lingyin_trigger)
Fk:addSkill(liying_active)
ruiji:addSkill(wangyuan)
ruiji:addSkill(lingyin)
ruiji:addSkill(liying)
Fk:loadTranslationTable{
  ["ty__ruiji"] = "芮姬",
  ["wangyuan"] = "妄缘",
  [":wangyuan"] = "当你于回合外失去牌后，你可以随机将牌堆中一张基本牌或锦囊牌置于你的武将牌上，称为“妄”（“妄”的牌名不重复且至多为游戏人数）。",
  ["lingyin"] = "铃音",
  [":lingyin"] = "出牌阶段开始时，你可以获得至多X张“妄”（X为游戏轮数）。然后若“妄”颜色均相同，你本回合对其他角色造成的伤害+1且"..
  "可以将武器或防具牌当【决斗】使用。",
  ["liying"] = "俐影",
  [":liying"] = "每回合限一次，当你于摸牌阶段外获得牌后，你可以将其中任意张牌交给一名其他角色，然后你摸一张牌。若此时是你的回合内，再增加一张“妄”。",
  ["#wangyuan-invoke"] = "妄缘：是否增加一张“妄”？",
  ["ruiji_wang"] = "妄",
  ["#lingyin-invoke"] = "铃音：获得至多%arg张“妄”，然后若“妄”颜色相同，你本回合伤害+1且可以将武器、防具当【决斗】使用",
  ["liying_active"] = "俐影",
  ["#liying1-invoke"] = "俐影：你可以将其中任意张牌交给一名其他角色，然后摸一张牌",
  ["#liying2-invoke"] = "俐影：你可以将其中任意张牌交给一名其他角色，然后摸一张牌并增加一张“妄”",

  ["$wangyuan1"] = "小女子不才，愿伴公子余生。",
  ["$wangyuan2"] = "纵有万钧之力，然不斩情丝。",
  ["$lingyin1"] = "环佩婉尔，心动情动铃儿动。",
  ["$lingyin2"] = "小鹿撞入我怀，银铃焉能不鸣？",
  ["$liying1"] = "飞影略白鹭，日暮栖君怀。",
  ["$liying2"] = "妾影婆娑，摇曳君心。",
  ["~ty__ruiji"] = "佳人芳华逝，空余孤铃鸣……",
}

local duanqiaoxiao = General(extension, "duanqiaoxiao", "wei", 3, 3, General.Female)
local caizhuang = fk.CreateActiveSkill{
  name = "caizhuang",
  anim_type = "drawcard",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    else
      return table.every(selected, function (id) return Fk:getCardById(to_select).suit ~= Fk:getCardById(id).suit end)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    while true do
      player:drawCards(1, self.name)
      local suits = {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        local suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit then
          table.insertIfNeed(suits, suit)
        end
      end
      if #suits >= #effect.cards then return end
    end
  end,
}
local huayi = fk.CreateTriggerSkill{
  name = "huayi",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#huayi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color ~= Card.NoColor then
      room:setPlayerMark(player, "@huayi", judge.card:getColorString())
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@huayi") ~= 0 and data.from == Player.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@huayi", 0)
  end,
}
local huayi_trigger = fk.CreateTriggerSkill{
  name = "#huayi_trigger",
  mute = true,
  events = {fk.TurnEnd, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@huayi") ~= 0 then
      if event == fk.TurnEnd then
        return target ~= player and player:getMark("@huayi") == "red"
      elseif event == fk.Damaged then
        return target == player and player:getMark("@huayi") == "black"
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      player:broadcastSkillInvoke("huayi")
      room:notifySkillInvoked(player, "huayi", "drawcard")
      player:drawCards(1, "huayi")
    elseif event == fk.Damaged then
      player:broadcastSkillInvoke("huayi")
      room:notifySkillInvoked(player, "huayi", "drawcard")
      player:drawCards(2, "huayi")
    end
  end,
}
huayi:addRelatedSkill(huayi_trigger)
duanqiaoxiao:addSkill(caizhuang)
duanqiaoxiao:addSkill(huayi)
Fk:loadTranslationTable{
  ["duanqiaoxiao"] = "段巧笑",
  ["caizhuang"] = "彩妆",
  [":caizhuang"] = "出牌阶段限一次，你可以弃置任意张花色各不相同的牌，然后重复摸牌直到手牌中的花色数等同于弃牌数。",
  ["huayi"] = "华衣",
  [":huayi"] = "结束阶段，你可以判定，然后直到你的下回合开始时根据结果获得以下效果：红色，其他角色回合结束时摸一张牌；黑色，受到伤害后摸两张牌。",
  ["#huayi-invoke"] = "华衣：你可以判定，根据颜色直到你下回合开始获得效果",
  ["@huayi"] = "华衣",

  ["$caizhuang1"] = "素手调脂粉，女子自有好颜色。",
  ["$caizhuang2"] = "为悦己者容，撷彩云为妆。",
  ["$huayi1"] = "皓腕凝霜雪，罗襦绣鹧鸪。",
  ["$huayi2"] = "绝色戴珠玉，佳人配华衣。",
  ["~duanqiaoxiao"] = "佳人时光少，君王总薄情……",
}

--皇家贵胄：曹髦 刘辩 刘虞 全惠解 丁尚涴 袁姬 谢灵毓 甘夫人糜夫人
local caomao = General(extension, "caomao", "wei", 3, 4)
local qianlong = fk.CreateTriggerSkill{
  name = "qianlong",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
    })
    local result = room:askForGuanxing(player, cards, {0, player:getLostHp()}, {}, self.name, true, {"qianlong_get", "qianlong_bottom"})
    if #result.top > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(result.top)
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    end
    if #result.bottom > 0 then
      for _, id in ipairs(result.bottom) do
        table.insert(room.draw_pile, id)
      end
      room:sendLog{
        type = "#GuanxingResult",
        from = player.id,
        arg = #result.top,
        arg2 = #result.bottom,
      }
    end
  end,
}
local fensi = fk.CreateTriggerSkill{
  name = "fensi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
      return p.hp >= player.hp end), function(p) return p.id end), 1, 1, "#fensi-choose", self.name, false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = player
    end
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = self.name,
    }
    if not to.dead and to ~= player then
      room:useVirtualCard("slash", nil, to, player, self.name, true)
    end
  end,
}
local juetao = fk.CreateTriggerSkill{
  name = "juetao",
  anim_type = "offensive",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player.hp == 1 and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id end), 1, 1, "#juetao-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    while true do
      if player.dead or to.dead then return end
      local id = room:getNCards(1, "bottom")[1]
      room:moveCards({
        ids = {id},
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
      local card = Fk:getCardById(id, true)
      local tos
      if (card.trueName == "slash") or
        ((table.contains({"dismantlement", "snatch", "chasing_near"}, card.name)) and not to:isAllNude()) or
        (table.contains({"fire_attack", "unexpectation"}, card.name) and not to:isKongcheng()) or
        (table.contains({"duel", "savage_assault", "archery_attack", "iron_chain", "raid_and_frontal_attack", "enemy_at_the_gates"}, card.name)) or
        (table.contains({"indulgence", "supply_shortage"}, card.name) and not to:hasDelayedTrick(card.name)) then
        tos = {{to.id}}
      elseif (table.contains({"amazing_grace", "god_salvation"}, card.name)) then
        tos = {{player.id}, {to.id}}
      elseif (card.name == "collateral" and to:getEquipment(Card.SubtypeWeapon)) then
        tos = {{to.id}, {player.id}}
      elseif (card.type == Card.TypeEquip) or
        (card.name == "peach" and player:isWounded()) or
        (card.name == "analeptic") or
        (table.contains({"ex_nihilo", "foresight"}, card.name)) or
        (card.name == "fire_attack" and not player:isKongcheng()) or
        (card.name == "lightning" and not player:hasDelayedTrick("lightning")) then
        tos = {{player.id}}
      end
      if tos and room:askForSkillInvoke(player, self.name, data, "#juetao-use:::"..card:toLogString()) then
        room:useCard({
          card = card,
          from = player.id,
          tos = tos,
          skillName = self.name,
          extraUse = true,
        })
      else
        room:delay(800)
        room:moveCards({
          ids = {id},
          fromArea = Card.Processing,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonJustMove,
        })
        return
      end
    end
  end,
}
local zhushi = fk.CreateTriggerSkill{
  name = "zhushi$",
  anim_type = "drawcard",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase ~= Player.NotActive and target.kingdom == "wei" and
      player:usedSkillTimes(self.name) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(target, {"zhushi_draw", "Cancel"}, self.name, "#zhushi-invoke:"..player.id)
    if choice == "zhushi_draw" then
      player:drawCards(1)
    end
  end,
}
caomao:addSkill(qianlong)
caomao:addSkill(fensi)
caomao:addSkill(juetao)
caomao:addSkill(zhushi)
Fk:loadTranslationTable{
  ["caomao"] = "曹髦",
  ["qianlong"] = "潜龙",
  [":qianlong"] = "当你受到伤害后，你可以展示牌堆顶的三张牌并获得其中至多X张牌（X为你已损失的体力值），然后将剩余的牌置于牌堆底。",
  ["fensi"] = "忿肆",
  [":fensi"] = "锁定技，准备阶段，你对一名体力值不小于你的角色造成1点伤害；若受伤角色不为你，则其视为对你使用一张【杀】。",
  ["juetao"] = "决讨",
  [":juetao"] = "限定技，出牌阶段开始时，若你的体力值为1，你可以选择一名角色并依次使用牌堆底的牌直到你无法使用，这些牌不能指定除你和该角色以外的角色为目标。",
  ["zhushi"] = "助势",
  [":zhushi"] = "主公技，其他魏势力角色每回合限一次，该角色回复体力时，你可以令其选择是否令你摸一张牌。",
  ["#qianlong-guanxing"] = "潜龙：获得其中至多%arg张牌（获得上方的牌，下方的牌置于牌堆底）",
  ["qianlong_get"] = "获得",
  ["qianlong_bottom"] = "置于牌堆底",
  ["#fensi-choose"] = "忿肆：你须对一名体力值不小于你的角色造成1点伤害，若不为你，视为其对你使用【杀】",
  ["#juetao-choose"] = "决讨：你可以指定一名角色，连续对其使用牌堆底牌直到不能使用！",
  ["#juetao-use"] = "决讨：是否使用%arg！",
  ["#zhushi-invoke"] = "助势：你可以令 %src 摸一张牌",
  ["zhushi_draw"] = "其摸一张牌",
  
  ["$qianlong1"] = "鸟栖于林，龙潜于渊。",
  ["$qianlong2"] = "游鱼惊钓，潜龙飞天。",
  ["$fensi1"] = "此贼之心，路人皆知！",
  ["$fensi2"] = "孤君烈忿，怒愈秋霜。",
  ["$juetao1"] = "登车拔剑起，奋跃搏乱臣！",
  ["$juetao2"] = "陵云决心意，登辇讨不臣！",
  ["$zhushi1"] = "可有爱卿愿助朕讨贼？",
  ["$zhushi2"] = "泱泱大魏，忠臣俱亡乎？",
  ["~caomao"] = "宁作高贵乡公死，不作汉献帝生……",
}

local liubian = General(extension, "liubian", "qun", 3)
local shiyuan = fk.CreateTriggerSkill{
  name = "shiyuan",
  anim_type = "drawcard",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.from ~= player.id then
      local from = player.room:getPlayerById(data.from)
      local n = 1
      if player:hasSkill("yuwei") and player.room.current.kingdom == "qun" then
        n = 2
      end
      return (from.hp > player.hp and player:getMark("shiyuan1-turn") < n) or
      (from.hp == player.hp and player:getMark("shiyuan2-turn") < n) or
      (from.hp < player.hp and player:getMark("shiyuan3-turn") < n)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    if from.hp > player.hp then
      player:drawCards(3, self.name)
      room:addPlayerMark(player, "shiyuan1-turn", 1)
    elseif from.hp == player.hp then
      player:drawCards(2, self.name)
      room:addPlayerMark(player, "shiyuan2-turn", 1)
    elseif from.hp < player.hp then
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "shiyuan3-turn", 1)
    end
  end,
}
local dushi = fk.CreateTriggerSkill{
  name = "dushi",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, false, true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
      return not p:hasSkill(self.name) end), function (p) return p.id end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#dushi-choose", self.name, false)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    room:handleAddLoseSkills(room:getPlayerById(to), self.name, nil, true, false)
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke(self.name)
    player.room:notifySkillInvoked(player, self.name)
  end,
}
local dushi_prohibit = fk.CreateProhibitSkill{
  name = "#dushi_prohibit",
  prohibit_use = function(self, player, card)
    if card.name == "peach" and not player.dying then
      return table.find(Fk:currentRoom().alive_players, function(p) return p.dying and p:hasSkill("dushi") and p ~= player end)
    end
  end,
}
local yuwei = fk.CreateTriggerSkill{
  name = "yuwei$",
  frequency = Skill.Compulsory,
}
dushi:addRelatedSkill(dushi_prohibit)
liubian:addSkill(shiyuan)
liubian:addSkill(dushi)
liubian:addSkill(yuwei)
Fk:loadTranslationTable{
  ["liubian"] = "刘辩",
  ["shiyuan"] = "诗怨",
  [":shiyuan"] = "每回合每项限一次，当你成为其他角色使用牌的目标后：1.若其体力值比你多，你摸三张牌；2.若其体力值与你相同，你摸两张牌；"..
  "3.若其体力值比你少，你摸一张牌。",
  ["dushi"] = "毒逝",
  [":dushi"] = "锁定技，你处于濒死状态时，其他角色不能对你使用【桃】。你死亡时，你选择一名其他角色获得〖毒逝〗。",
  ["yuwei"] = "余威",
  [":yuwei"] = "主公技，锁定技，其他群雄角色的回合内，〖诗怨〗改为“每回合每项限两次”。",
  ["#dushi-choose"] = "毒逝：令一名其他角色获得〖毒逝〗",
  
  ["$shiyuan1"] = "感怀诗于前，绝怨赋于后。",
  ["$shiyuan2"] = "汉宫楚歌起，四面无援矣。",
  ["$dushi1"] = "孤无病，此药无需服。",
  ["$dushi2"] = "辟恶之毒，为最毒。",
  ["~liubian"] = "侯非侯，王非王……",
}

local liuyu = General(extension, "ty__liuyu", "qun", 3)
local suifu = fk.CreateTriggerSkill{
  name = "suifu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Finish and player:getMark("suifu-turn") > 1 and
      not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#suifu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.reverse(target.player_cards[Player.Hand])
    room:moveCards({
      ids = cards,
      from = target.id,
      fromArea = Player.Hand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    room:useVirtualCard("amazing_grace", nil, player, table.filter(room:getAlivePlayers(), function (p)
      return not player:isProhibited(p, Fk:cloneCard("amazing_grace")) end), self.name, false)
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and (target == player or target.seat == 1)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "suifu-turn", data.damage)
  end,
}
local pijing = fk.CreateTriggerSkill{
  name = "pijing",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function (p)
      return p.id end), 1, 10, "#pijing-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:hasSkill("zimu", true) then
        room:handleAddLoseSkills(p, "-zimu", nil, true, false)
      end
    end
    if not table.contains(self.cost_data, player.id) then
      table.insert(self.cost_data, 1, player.id)
    end
    for _, id in ipairs(self.cost_data) do
      room:handleAddLoseSkills(room:getPlayerById(id), "zimu", nil, true, false)
    end
  end,
}
local zimu = fk.CreateTriggerSkill{
  name = "zimu",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:hasSkill("zimu", true) then
        p:drawCards(1, self.name)
      end
    end
    room:handleAddLoseSkills(player, "-zimu", nil, true, false)
  end,
}
liuyu:addSkill(suifu)
liuyu:addSkill(pijing)
liuyu:addRelatedSkill(zimu)
Fk:loadTranslationTable{
  ["ty__liuyu"] = "刘虞",
  ["suifu"] = "绥抚",
  [":suifu"] = "其他角色的结束阶段，若本回合你和一号位共计至少受到两点伤害，你可将当前回合角色的所有手牌置于牌堆顶，视为使用一张【五谷丰登】。",
  ["pijing"] = "辟境",
  [":pijing"] = "结束阶段，你可选择包含你的任意名角色，这些角色获得〖自牧〗直到下次发动〖辟境〗。",
  ["zimu"] = "自牧",
  [":zimu"] = "锁定技，当你受到伤害后，有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗。",
  ["#suifu-invoke"] = "绥抚：你可以将 %dest 所有手牌置于牌堆顶，你视为使用【五谷丰登】",
  ["#pijing-choose"] = "辟境：你可以令包括你的任意名角色获得技能〖自牧〗直到下次发动〖辟境〗<br>"..
  "（锁定技，当你受到伤害后，有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗）",
}

local quanhuijie = General(extension, "quanhuijie", "wu", 3, 3, General.Female)
local huishu = fk.CreateTriggerSkill{
  name = "huishu",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getMark("huishu1"), self.name)
    player.room:askForDiscard(player, player:getMark("huishu2"), player:getMark("huishu2"), false, self.name, false)
  end,

  refresh_events = {fk.GameStart, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        if player:usedSkillTimes(self.name) > 0 and player:getMark("huishu-turn") < player:getMark("huishu3") then
          for _, move in ipairs(data) do
            if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  player.room:addPlayerMark(player, "huishu-turn", 1)
                end
              end
            end
          end
          return player:getMark("huishu-turn") >= player:getMark("huishu3")
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:setPlayerMark(player, "huishu1", 3)
      room:setPlayerMark(player, "huishu2", 1)
      room:setPlayerMark(player, "huishu3", 2)
      room:setPlayerMark(player, "@" .. self.name, string.format("%d-%d-%d", 3, 1, 2))
    else
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|^basic", player:getMark("huishu-turn"), "discardPile")
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
    end
  end,
}
local yishu = fk.CreateTriggerSkill{
  name = "yishu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.phase ~= Player.Play then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local max = math.max(player:getMark("huishu1"), player:getMark("huishu2"), player:getMark("huishu3"))
    local min = math.min(player:getMark("huishu1"), player:getMark("huishu2"), player:getMark("huishu3"))
    local maxes, mins = {}, {}
    for _, mark in ipairs({"huishu1", "huishu2", "huishu3"}) do
      if player:getMark(mark) == max then
        table.insert(maxes, mark)
      end
      if player:getMark(mark) == min then
        table.insert(mins, mark)
      end
    end
    local choice1 = room:askForChoice(player, mins, self.name, "#yishu-add")
    local choice2 = room:askForChoice(player, maxes, self.name, "#yishu-lose")
    room:addPlayerMark(player, choice1, 2)
    room:removePlayerMark(player, choice2, 1)
    room:setPlayerMark(player, "@huishu", string.format("%d-%d-%d",
      player:getMark("huishu1"),
      player:getMark("huishu2"),
      player:getMark("huishu3")))
  end,
}
local ligong = fk.CreateTriggerSkill{
  name = "ligong",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("huishu1") > 4 or player:getMark("huishu2") > 4 or player:getMark("huishu3") > 4
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "-yishu", nil)
    local generals = Fk:getGeneralsRandomly(4, Fk:getAllGenerals(),
      table.map(room:getAllPlayers(), function(p) return p.general end),
      (function (p) return (p.kingdom ~= "wu" or p.gender ~= General.Female) end))
    local skills = {"Cancel"}
    for _, general in ipairs(generals) do
      for _, skill in ipairs(general.skills) do
        if skill.frequency ~= Skill.Wake and skill.frequency ~= Skill.Limited then
          table.insertIfNeed(skills, skill.name)
        end
      end
      for _, skill in ipairs(general.other_skills) do
        if skill.frequency ~= Skill.Wake and skill.frequency ~= Skill.Limited then
          table.insertIfNeed(skills, skill.name)
        end
      end
    end
    local choices = {}
    for i = 1, 2, 1 do
      local choice = room:askForChoice(player, skills, self.name, "#ligong-choice", true)
      table.insert(choices, choice)
      if choice == "Cancel" then break end
      table.removeOne(skills, choice)
    end
    if table.contains(choices, "Cancel") then
      player:drawCards(3, self.name)
    else
      room:handleAddLoseSkills(player, "-huishu|"..choices[1].."|"..choices[2], nil)
    end
  end,
}
quanhuijie:addSkill(huishu)
quanhuijie:addSkill(yishu)
quanhuijie:addSkill(ligong)
Fk:loadTranslationTable{
  ["quanhuijie"] = "全惠解",
  ["huishu"] = "慧淑",
  [":huishu"] = "摸牌阶段结束时，你可以摸3张牌然后弃置1张手牌。若如此做，你本回合弃置超过2张牌时，从弃牌堆中随机获得等量的非基本牌。",
  ["yishu"] = "易数",
  [":yishu"] = "锁定技，当你于出牌阶段外失去牌后，〖慧淑〗中最小的一个数字+2且最大的一个数字-1。",
  ["ligong"] = "离宫",
  [":ligong"] = "觉醒技，准备阶段，若〖慧淑〗有数字达到5，你加1点体力上限并回复1点体力，失去〖易数〗，然后从随机四个吴国女性武将中选择至多"..
  "两个技能获得（如果不获得技能则不失去〖慧淑〗并摸三张牌）。",
  ["@huishu"] = "慧淑",
  ["huishu1"] = "摸牌数",
  ["huishu2"] = "弃牌数",
  ["huishu3"] = "获得锦囊所需弃牌数",
  ["#yishu-add"] = "易数：请选择增加的一项",
  ["#yishu-lose"] = "易数：请选择减少的一项",
  ["#ligong-choice"] = "离宫：获得两个技能并失去“易数”和“慧淑”，或点“取消”不失去“慧淑”并摸三张牌",

  ["$huishu1"] = "心有慧镜，善解百般人意。",
  ["$huishu2"] = "袖着静淑，可揾夜阑之泪。",
  ["$yishu1"] = "此命由我，如织之数可易。",
  ["$yishu2"] = "易天定之数，结人定之缘。",
  ["$ligong1"] = "伴君离高墙，日暮江湖远。",
  ["$ligong2"] = "巍巍宫门开，自此不复来。",
  ["~quanhuijie"] = "妾有愧于陛下。",
}

local dingfuren = General(extension, "dingfuren", "wei", 3, 3, General.Female)
local fengyan = fk.CreateActiveSkill{
  name = "fengyan",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  interaction = function(self)
    local choices = {}
    if Self:getMark("fengyan1-phase") == 0 then
      table.insert(choices, "fengyan1-phase")
    end
    if Self:getMark("fengyan2-phase") == 0 then
      table.insert(choices, "fengyan2-phase")
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    return player:getMark("fengyan1-phase") == 0 or player:getMark("fengyan2-phase") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if self.interaction.data == "fengyan1-phase" then
        return target.hp <= Self.hp and not target:isKongcheng()
      elseif self.interaction.data == "fengyan2-phase" then
        return target:getHandcardNum() <= Self:getHandcardNum() and not Self:isProhibited(target, Fk:cloneCard("slash"))
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, self.interaction.data, 1)
    if self.interaction.data == "fengyan1-phase" then
      local card = room:askForCard(target, 1, 1, false, self.name, false, ".|.|.|hand", "#fengyan-give:"..player.id)
      room:obtainCard(player.id, card[1], false, fk.ReasonGive)
    elseif self.interaction.data == "fengyan2-phase" then
      room:useVirtualCard("slash", nil, player, target, self.name, true)
    end
  end,
}
local fudao = fk.CreateTriggerSkill{
  name = "fudao",
  anim_type = "support",
  mute = true,
  events = {fk.GameStart, fk.TargetSpecified, fk.Death, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if event == fk.Death then
      if player:hasSkill(self.name, false, (player == target)) then
        local to = player.room:getPlayerById(player:getMark(self.name))
        return to ~= nil and ((player == target and not to.dead) or to == target) and data.damage and data.damage.from and
          not data.damage.from.dead and data.damage.from ~= player and data.damage.from ~= to
      end
      return false
    end
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      elseif event == fk.TargetSpecified then
        local to = player.room:getPlayerById(data.to)
        return ((player == target and player:getMark(self.name) == to.id) or (player == to and player:getMark(self.name) == target.id)) and
          player:getMark("fudao_specified-turn") == 0
      elseif event == fk.TargetConfirmed then
        return target == player and data.from ~= player.id and player.room:getPlayerById(data.from):getMark("@@juelie") > 0 and
          data.card.color == Card.Black
      end
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name)
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#fudao-choose", self.name, false, true)
      if #tos > 0 then
        room:setPlayerMark(player, self.name, tos[1])
        room:setPlayerMark(player, "@@fudao", 1)
        room:setPlayerMark(room:getPlayerById(tos[1]), "@@fudao", 1)
      end
    elseif event == fk.TargetSpecified then
      room:notifySkillInvoked(player, self.name)
      room:addPlayerMark(player, "fudao_specified-turn")
      local targets = {player.id, player:getMark(self.name)}
      room:sortPlayersByAction(targets)
      room:doIndicate(player.id, targets)
      for _, pid in ipairs(targets) do
        local p = room:getPlayerById(pid)
        if p and not p.dead then
          room:drawCards(p, 2, self.name)
        end
      end
    elseif event == fk.Death then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(data.damage.from, "@@juelie", 1)
    elseif event == fk.TargetConfirmed then
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(room:getPlayerById(data.from), "@@fudao-turn", 1)
    end
  end,
}
local fudao_delay = fk.CreateTriggerSkill{
  name = "#fudao_delay",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("@@fudao") > 0 and data.to:getMark("@@juelie") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, fudao.name, "offensive")
    if player:hasSkill(fudao.name, true) then
      player:broadcastSkillInvoke(fudao.name)
    end
    data.damage = data.damage + 1
  end,
}
local fudao_prohibit = fk.CreateProhibitSkill{
  name = "#fudao_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@fudao-turn") > 0
  end,
}
fudao:addRelatedSkill(fudao_delay)
fudao:addRelatedSkill(fudao_prohibit)
dingfuren:addSkill(fengyan)
dingfuren:addSkill(fudao)
Fk:loadTranslationTable{
  ["dingfuren"] = "丁尚涴",
  ["fengyan"] = "讽言",
  [":fengyan"] = "出牌阶段每项限一次，你可以选择一名其他角色，若其体力值小于等于你，你令其交给你一张手牌；"..
  "若其手牌数小于等于你，你视为对其使用一张无距离和次数限制的【杀】。",
  ["fudao"] = "抚悼",
  ["#fudao_delay"] = "抚悼",
  [":fudao"] = "游戏开始时，你选择一名其他角色，你与其每回合首次使用牌指定对方为目标后，各摸两张牌。杀死你或该角色的其他角色获得“决裂”标记，"..
  "你或该角色对有“决裂”的角色造成的伤害+1；“决裂”角色使用黑色牌指定你为目标后，其本回合不能再使用牌。",
  ["fengyan1-phase"] = "令一名体力值不大于你的角色交给你一张手牌",
  ["fengyan2-phase"] = "视为对一名手牌数不大于你的角色使用【杀】",
  ["#fengyan-give"] = "讽言：你须交给 %src 一张手牌",
  ["@@fudao"] = "抚悼",
  ["#fudao-choose"] = "抚悼：请选择要“抚悼”的角色",
  ["@@juelie"] = "决裂",
  ["@@fudao-turn"] = "抚悼 不能出牌",

  ["$fengyan1"] = "既将我儿杀之，何复念之！",
  ["$fengyan2"] = "乞问曹公，吾儿何时归还？",
  ["$fudao1"] = "弑子之仇，不共戴天！",
  ["$fudao2"] = "眼中泪绝，尽付仇怆。",
  ["~dingfuren"] = "吾儿既丧，天地无光……",
}

local yuanji = General(extension, "yuanji", "wu", 3, 3, General.Female)
local fangdu = fk.CreateTriggerSkill{
  name = "fangdu",
  anim_type = "masochism",
  events = {fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self.name) or player.phase ~= Player.NotActive then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    if not damage_event then return false end
    local mark_name = "fangdu1_record-turn"
    if data.damageType == fk.NormalDamage then
      if not player:isWounded() then return false end
    else
      if data.from == nil or data.from == player or data.from:isKongcheng() then return false end
      mark_name = "fangdu2_record-turn"
    end
    local x = player:getMark(mark_name)
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local reason = e.data[3]
        if e.data[1] == player and reason == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event then
            local damage = first_damage_event.data[1]
            if damage.damageType == data.damageType then
              x = first_damage_event.id
              room:setPlayerMark(player, mark_name, x)
              return true
            end
          end
        end
      end, Player.HistoryTurn)
    end
    return damage_event.id == x
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.damageType == fk.NormalDamage then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    else
      local id = table.random(data.from.player_cards[Player.Hand])
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end
}
local jiexing = fk.CreateTriggerSkill{
  name = "jiexing",
  anim_type = "drawcard",
  events = {fk.HpChanged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.AfterCardsMove, fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == self.name then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
              room:setCardMark(Fk:getCardById(id), "@@jiexing-inhand", 1)
            end
          end
        end
      end
    elseif event == fk.AfterTurnEnd then
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        room:setCardMark(Fk:getCardById(id), "@@jiexing-inhand", 0)
      end
    end
  end,
}
local jiexing_maxcards = fk.CreateMaxCardsSkill{
  name = "#jiexing_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@jiexing-inhand") > 0
  end,
}
jiexing:addRelatedSkill(jiexing_maxcards)
yuanji:addSkill(fangdu)
yuanji:addSkill(jiexing)
Fk:loadTranslationTable{
  ["yuanji"] = "袁姬",
  ["fangdu"] = "芳妒",
  [":fangdu"] = "锁定技，你的回合外，你每回合第一次受到普通伤害后回复1点体力，你每回合第一次受到属性伤害后随机获得伤害来源一张手牌。",
  ["jiexing"] = "节行",
  [":jiexing"] = "当你的体力值变化后，你可以摸一张牌，此牌不计入你本回合的手牌上限。",

  ["#jiexing-invoke"] = "节行：你可以摸一张牌，此牌本回合不计入手牌上限",
  ["@@jiexing-inhand"] = "节行",

  ["$fangdu1"] = "浮萍却红尘，何意染是非？",
  ["$fangdu2"] = "我本无意争春，奈何群芳相妒。",
  ["$jiexing1"] = "女子有节，安能贰其行？",
  ["$jiexing2"] = "坐受雨露，皆为君恩。",
  ["~yuanji"] = "妾本蒲柳，幸荣君恩……",
}

local xielingyu = General(extension, "xielingyu", "wu", 3, 3, General.Female)
local yuandi = fk.CreateTriggerSkill{
  name = "yuandi",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target ~= player and target.phase == Player.Play and target:getMark("yuandi-phase") == 0 then
      player.room:addPlayerMark(target, "yuandi-phase", 1)
      if data.tos then
        for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
          if id ~= target.id then
            return
          end
        end
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yuandi-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"yuandi_draw"}
    if not target:isKongcheng() then
      table.insert(choices, 1, "yuandi_discard")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "yuandi_discard" then
      local id = room:askForCardChosen(player, target, "h", self.name)
      room:throwCard({id}, self.name, target, player)
    else
      player:drawCards(1, self.name)
      target:drawCards(1, self.name)
    end
  end,
}
local xinyou = fk.CreateActiveSkill{
  name = "xinyou",
  anim_type = "drawcard",
  can_use = function(self, player)
    return (player:isWounded() or player:getHandcardNum() < player.maxHp) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:isWounded() then
      room:recover({
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = self.name
      })
      room:addPlayerMark(player, "xinyou_recover-turn", 1)
    end
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, self.name)
      if n > 1 then
        room:addPlayerMark(player, "xinyou_draw-turn", 1)
      end
    end
  end
}
local xinyou_record = fk.CreateTriggerSkill{
  name = "#xinyou_record",
  anim_type = "negative",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and
      ((player:getMark("xinyou_recover-turn") > 0 and not player:isNude()) or player:getMark("xinyou_draw-turn") > 0)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("xinyou_recover-turn") > 0 and not player:isNude() then
      if #player:getCardIds{Player.Hand, Player.Equip} < 3 then
        player:throwAllCards("he")
      else
        room:askForDiscard(player, 2, 2, true, "xinyou", false)
      end
    end
    if player:getMark("xinyou_draw-turn") > 0 then
      room:loseHp(player, 1, "xinyou")
    end
  end,
}
xinyou:addRelatedSkill(xinyou_record)
xielingyu:addSkill(yuandi)
xielingyu:addSkill(xinyou)
Fk:loadTranslationTable{
  ["xielingyu"] = "谢灵毓",
  ["yuandi"] = "元嫡",
  [":yuandi"] = "其他角色于其出牌阶段使用第一张牌时，若此牌没有指定除其以外的角色为目标，你可以选择一项：1.弃置其一张手牌；2.你与其各摸一张牌。",
  ["xinyou"] = "心幽",
  [":xinyou"] = "出牌阶段限一次，你可以回复体力至体力上限并将手牌摸至体力上限。若你因此摸超过一张牌，结束阶段你失去1点体力；"..
  "若你因此回复体力，结束阶段你弃置两张牌。",
  ["#yuandi-invoke"] = "元嫡：你可以弃置 %dest 的一张手牌或与其各摸一张牌",
  ["yuandi_discard"] = "弃置其一张手牌",
  ["yuandi_draw"] = "你与其各摸一张牌",
  ["#xinyou_record"] = "心幽",

  ["$yuandi1"] = "此生与君为好，共结连理。",
  ["$yuandi2"] = "结发元嫡，其情唯衷孙郎。",
  ["$xinyou1"] = "我有幽月一斛，可醉十里春风。",
  ["$xinyou2"] = "心在方外，故而不闻市井之声。",
  ["~xielingyu"] = "翠瓦红墙处，最折意中人。",
}

local ganfurenmifuren = General(extension, "ganfurenmifuren", "shu", 3, 3, General.Female)
local chanjuan = fk.CreateTriggerSkill{
  name = "chanjuan",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (data.card:isCommonTrick() or data.card.type == Card.TypeBasic) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and
      (player:getMark("@$chanjuan") == 0 or not table.contains(player:getMark("@$chanjuan"), data.card.trueName))
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, {data.card.name, TargetGroup:getRealTargets(data.tos)[1]})
    self:doCost(event, target, player, data)
    room:setPlayerMark(player, self.name, 0)
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "chanjuan_viewas",
      "#chanjuan-invoke::"..TargetGroup:getRealTargets(data.tos)[1]..":"..data.card.name, true)
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard(player:getMark(self.name)[1])
    local mark = player:getMark("@$chanjuan")
    if mark == 0 then mark = {} end
    table.insert(mark, card.trueName)
    room:setPlayerMark(player, "@$chanjuan", mark)
    if #self.cost_data.targets == 1 and player:getMark(self.name) ~= 0 and self.cost_data.targets[1] == player:getMark(self.name)[2] then
      player:drawCards(1, self.name)
    end
    room:useCard{
      from = player.id,
      tos = table.map(self.cost_data.targets, function(id) return {id} end),
      card = card,
    }
  end,
}
local chanjuan_viewas = fk.CreateViewAsSkill{
  name = "chanjuan_viewas",
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    if Self:getMark("chanjuan") == 0 then return end
    local card = Fk:cloneCard(Self:getMark("chanjuan")[1])
    card.skillName = "chanjuan"
    return card
  end,
}
local chanjuan_targetmod = fk.CreateTargetModSkill{
  name = "#chanjuan_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "chanjuan")
  end,
}
local xunbie = fk.CreateTriggerSkill{
  name = "xunbie",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local generals = {}
    if not table.find(room.alive_players, function(p) return p.general == "ty__ganfuren" end) then
      table.insert(generals, "ty__ganfuren")
    end
    if not table.find(room.alive_players, function(p) return p.general == "ty__mifuren" end) then
      table.insert(generals, "ty__mifuren")
    end
    if #generals > 0 then
      local general = room:askForGeneral(player, generals, 1)
      room:changeHero(player, general, false, false, true)
      if not player.dead and player:isWounded() then
        room:recover({
          who = player,
          num = 1 - player.hp,
          recoverBy = player,
          skillName = self.name
        })
      end
    end
    room:setPlayerMark(player, "@@xunbie-turn", 1)
  end,
}
local xunbie_trigger = fk.CreateTriggerSkill{
  name = "#xunbie_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("xunbie", Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("xunbie")
    player.room:notifySkillInvoked(player, "xunbie")
    return true
  end,
}
chanjuan_viewas:addRelatedSkill(chanjuan_targetmod)
Fk:addSkill(chanjuan_viewas)
xunbie:addRelatedSkill(xunbie_trigger)
ganfurenmifuren:addSkill(chanjuan)
ganfurenmifuren:addSkill(xunbie)
Fk:loadTranslationTable{
  ["ganfurenmifuren"] = "甘夫人糜夫人",
  ["chanjuan"] = "婵娟",
  [":chanjuan"] = "你使用指定唯一目标的基本牌或普通锦囊牌结算完毕后，你可以视为使用一张同名牌，若目标完全相同，你摸一张牌。每种牌名限一次。",
  ["xunbie"] = "殉别",
  [":xunbie"] = "限定技，当你进入濒死状态时，你可以将武将牌改为甘夫人或糜夫人，然后回复体力至1并防止你受到的伤害直到回合结束。",
  ["@$chanjuan"] = "婵娟",
  ["#chanjuan-invoke"] = "婵娟：你可以视为使用【%arg】，若目标为 %dest ，你摸一张牌",
  ["chanjuan_viewas"] = "婵娟",
  ["@@xunbie-turn"] = "殉别",

  ["$chanjuan1"] = "姐妹一心，共侍玄德无忧。",
  ["$chanjuan2"] = "双姝从龙，姊妹宠荣与共。",
  ["$xunbie1"] = "既为君之妇，何惧为君之鬼。",
  ["$xunbie2"] = "今临难将罹，唯求不负皇叔。",
  ["~ganfurenmifuren"] = "人生百年，奈何于我十不存一……",
}

local ganfuren = General(extension, "ty__ganfuren", "shu", 3, 3, General.Female)
local ty__shushen = fk.CreateTriggerSkill{
  name = "ty__shushen",
  anim_type = "support",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.num do
      if self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#ty__shushen-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {"ty__shushen_draw"}
    if to:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(player, choices, self.name, "#ty__shushen-choice::"..to.id)
    if choice == "ty__shushen_draw" then
      player:drawCards(1, self.name)
      to:drawCards(1, self.name)
    else
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local ty__shenzhi = fk.CreateTriggerSkill{
  name = "ty__shenzhi",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and
      player:getHandcardNum() > player.hp and player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#ty__shenzhi-invoke", true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
ganfuren:addSkill(ty__shushen)
ganfuren:addSkill(ty__shenzhi)
Fk:loadTranslationTable{
  ["ty__ganfuren"] = "甘夫人",
  ["ty__shushen"] = "淑慎",
  [":ty__shushen"] = "当你回复1点体力后，你可以选择一名其他角色，令其回复1点体力或与其各摸一张牌。",
  ["ty__shenzhi"] = "神智",
  [":ty__shenzhi"] = "准备阶段，若你手牌数大于体力值，你可以弃置一张手牌并回复1点体力。",
  ["#ty__shushen-choose"] = "淑慎：你可以令一名其他角色回复1点体力或与其各摸一张牌",
  ["#ty__shushen-choice"] = "淑慎：选择令 %dest 执行的一项",
  ["ty__shushen_draw"] = "各摸一张牌",
  ["#ty__shenzhi-invoke"] = "神智：你可以弃置一张手牌，回复1点体力",

  ["$ty__shushen1"] = "妾身无恙，相公请安心征战。",
  ["$ty__shushen2"] = "船到桥头自然直。",
  ["$ty__shenzhi1"] = "子龙将军，一切都托付给你了。",
  ["$ty__shenzhi2"] = "阿斗，相信妈妈，没事的。",
  ["~ty__ganfuren"] = "请替我照顾好阿斗……",
}

local mifuren = General(extension, "ty__mifuren", "shu", 3, 3, General.Female)
local ty__guixiu = fk.CreateTriggerSkill{
  name = "ty__guixiu",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart, fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.TurnStart then
        return player:getMark(self.name) == 0
      else
        return data.name == "ty__cunsi" and player:isWounded()
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      player:drawCards(2, self.name)
      room:setPlayerMark(player, self.name, 1)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local ty__cunsi = fk.CreateActiveSkill{
  name = "ty__cunsi",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  prompt = "#ty__cunsi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:handleAddLoseSkills(target, "ty__yongjue", nil, true, false)
    if target ~= player then
      player:drawCards(2, self.name)
    end
  end,
}
local ty__yongjue = fk.CreateTriggerSkill{
  name = "ty__yongjue",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.card.trueName == "slash" and
      player:usedCardTimes("slash", Player.HistoryPhase) == 1 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__yongjue-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"ty__yongjue_time"}
    if room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, "ty__yongjue_obtain")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "ty__yongjue_time" then
      player:addCardUseHistory(data.card.trueName, -1)
    else
      room:obtainCard(player, data.card, true, fk.ReasonJustMove)
    end
  end,
}
mifuren:addSkill(ty__guixiu)
mifuren:addSkill(ty__cunsi)
mifuren:addRelatedSkill(ty__yongjue)
Fk:loadTranslationTable{
  ["ty__mifuren"] = "糜夫人",
  ["ty__guixiu"] = "闺秀",
  [":ty__guixiu"] = "锁定技，你获得此技能后的第一个回合开始时，你摸两张牌；当你发动〖存嗣〗后，你回复1点体力。",
  ["ty__cunsi"] = "存嗣",
  [":ty__cunsi"] = "限定技，出牌阶段，你可以令一名角色获得〖勇决〗；若不为你，你摸两张牌。",
  ["ty__yongjue"] = "勇决",
  [":ty__yongjue"] = "当你于出牌阶段内使用第一张【杀】时，你可以令其不计入使用次数或获得之。",
  ["#ty__cunsi"] = "存嗣：你可以令一名角色获得〖勇决〗，若不为你，你摸两张牌",
  ["#ty__yongjue-invoke"] = "勇决：你可以令此%arg不计入使用次数，或获得之",
  ["ty__yongjue_time"] = "不计入次数",
  ["ty__yongjue_obtain"] = "获得之",

  ["$ty__guixiu1"] = "闺楼独看花月，倚窗顾影自怜。",
  ["$ty__guixiu2"] = "闺中女子，亦可秀气英拔。",
  ["$ty__cunsi1"] = "存汉室之嗣，留汉室之本。",
  ["$ty__cunsi2"] = "一切，便托付将军了！",
  ["$ty__yongjue1"] = "能救一个是一个！",
  ["$ty__yongjue2"] = "扶幼主，成霸业！",
  ["~ty__mifuren"] = "阿斗被救，妾身……再无牵挂……",
}

--章台春望：郭照 樊玉凤 阮瑀 杨婉 潘淑
local guozhao = General(extension, "guozhao", "wei", 3, 3, General.Female)
local pianchong = fk.CreateTriggerSkill{
  name = "pianchong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    table.insertTable(cards, room:getCardsFromPileByRule(".|.|heart,diamond"))
    table.insertTable(cards, room:getCardsFromPileByRule(".|.|spade,club"))
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
    local choice = room:askForChoice(player, {"red", "black"}, self.name)
    room:setPlayerMark(player, "@pianchong", choice)
    return true
  end,

  refresh_events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) and not player.dead and player:getMark("@pianchong") ~= 0 then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start
      else
        local times = 0
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                local color = player:getMark("@pianchong")
                if Fk:getCardById(info.cardId):getColorString() == color then
                  times = times + 1
                end
              end
            end
          end
        end
        if times > 0 then
          player.room:setPlayerMark(player, self.name, times)
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(player, "@pianchong", 0)
    else
      local pattern
      local color = player:getMark("@pianchong")
      if color == "red" then
        pattern = ".|.|spade,club"
      else
        pattern = ".|.|heart,diamond"
      end
      local n = player:getMark(self.name)
      room:setPlayerMark(player, self.name, 0)
      local cards = room:getCardsFromPileByRule(pattern, n)
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
    end
  end,
}
local zunwei = fk.CreateActiveSkill{
  name = "zunwei",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name) == 0 then
      for i = 1, 3, 1 do
        if player:getMark(self.name .. tostring(i)) == 0 then
          return true
        end
      end
    end
    return false
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      local player = Fk:currentRoom():getPlayerById(Self.id)
      return (player:getMark("zunwei1") == 0 and #player.player_cards[Player.Hand] < #target.player_cards[Player.Hand]) or
       (player:getMark("zunwei2") == 0 and #player.player_cards[Player.Equip] < #target.player_cards[Player.Equip]) or
       (player:getMark("zunwei3") == 0 and player:isWounded() and player.hp < target.hp)
    end
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choices = {}
    if player:getMark("zunwei1") == 0 and #player.player_cards[Player.Hand] < #target.player_cards[Player.Hand] then
      table.insert(choices, "zunwei1")
    end
    if player:getMark("zunwei2") == 0 and #player.player_cards[Player.Equip] < #target.player_cards[Player.Equip] then
      table.insert(choices, "zunwei2")
    end
    if player:getMark("zunwei3") == 0 and player:isWounded() and player.hp < target.hp then
      table.insert(choices, "zunwei3")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "zunwei1" then
      player:drawCards(math.min(#target.player_cards[Player.Hand] - #player.player_cards[Player.Hand], 5), self.name)
    elseif choice == "zunwei2" then
      local n = #target.player_cards[Player.Equip] - #player.player_cards[Player.Equip]
      for i = 1, n, 1 do
        local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
        local cards = {}
        for i = 1, #room.draw_pile, 1 do
          local card = Fk:getCardById(room.draw_pile[i])
          for _, type in ipairs(types) do
            if card.sub_type == type and player:getEquipment(type) == nil then
              table.insertIfNeed(cards, room.draw_pile[i])
            end
          end
        end
        if #cards > 0 then
          room:useCard({
            from = player.id,
            tos = {{player.id}},
            card = Fk:getCardById(table.random(cards)),
          })
        end
      end
    elseif choice == "zunwei3" then
      room:recover{
        who = player,
        num = math.min(player:getLostHp(), target.hp - player.hp),
        recoverBy = player,
        skillName = self.name}
    end
    room:setPlayerMark(player, choice, 1)
  end,
}
guozhao:addSkill(pianchong)
guozhao:addSkill(zunwei)
Fk:loadTranslationTable{
  ["guozhao"] = "郭照",
  ["pianchong"] = "偏宠",
  [":pianchong"] = "摸牌阶段，你可以改为从牌堆获得红牌和黑牌各一张，然后选择一项直到你的下回合开始：1.你每失去一张红色牌时摸一张黑色牌，"..
  "2.你每失去一张黑色牌时摸一张红色牌。",
  ["zunwei"] = "尊位",
  [":zunwei"] = "出牌阶段限一次，你可以选择一名其他角色，并选择执行以下一项，然后移除该选项：1.将手牌数摸至与该角色相同（最多摸五张）；"..
  "2.随机使用牌堆中的装备牌至与该角色相同；3.将体力回复至与该角色相同。",
  ["@pianchong"] = "偏宠",
  ["zunwei1"] = "将手牌摸至与其相同（最多摸五张）",
  ["zunwei2"] = "使用装备至与其相同",
  ["zunwei3"] = "回复体力至与其相同",

  ["$pianchong1"] = "得陛下怜爱，恩宠不衰。",
  ["$pianchong2"] = "谬蒙圣恩，光授殊宠。",
  ["$zunwei1"] = "处尊居显，位极椒房。",
  ["$zunwei2"] = "自在东宫，及即尊位。",
  ["~guozhao"] = "我的出身，不配为后？",
}

local fanyufeng = General(extension, "fanyufeng", "qun", 3, 3, General.Female)
local bazhan = fk.CreateActiveSkill{
  name = "bazhan",
  anim_type = "switch",
  switch_skill_name = "bazhan",
  prompt = function ()
    return Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang and "#bazhan-Yang" or "#bazhan-Yin"
  end,
  target_num = 1,
  max_card_num = function ()
    return (Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang) and 2 or 0
  end,
  min_card_num = function ()
    return (Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang) and 1 or 0
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function(self, to_select, selected)
    return #selected < self:getMaxCardNum() and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected_cards >= self:getMinCardNum() and #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local isYang = player:getSwitchSkillState(self.name, true) == fk.SwitchYang

    local to_cheak = {}
    if isYang and #effect.cards > 0 then
      table.insertTable(to_cheak, effect.cards) 
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(to_cheak)
      room:obtainCard(target.id, dummy, false, fk.ReasonGive)
    elseif not isYang and not target:isKongcheng() then
      to_cheak = room:askForCardsChosen(player, target, 1, 2, "h", self.name)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(to_cheak)
      room:obtainCard(player, dummy, false, fk.ReasonPrey)
      target = player
    end
    if not player.dead and not target.dead and table.find(to_cheak, function (id)
    return Fk:getCardById(id).name == "analeptic" or Fk:getCardById(id).suit == Card.Heart end) then
      local choices = {"cancel"}
      if not target.faceup or target.chained then
        table.insert(choices, 1, "bazhan_reset")
      end
      if target:isWounded() then
        table.insert(choices, 1, "recover")
      end
      if #choices > 1 then
        local choice = room:askForChoice(player, choices, self.name, "#bazhan-support::" .. target.id)
        if choice == "recover" then
          room:recover{ who = target, num = 1, recoverBy = player, skillName = self.name }
        elseif choice == "bazhan_reset" then
          if not target.faceup then
            target:turnOver()
          end
          if target.chained then
            target:setChainState(false)
          end
        end
      end
    end
  end,
}
local jiaoying = fk.CreateTriggerSkill{
  name = "jiaoying",
  events = {fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
        local to = room:getPlayerById(move.to)
        local jiaoying_colors = type(to:getMark("jiaoying_colors-turn")) == "table" and to:getMark("jiaoying_colors-turn") or {}
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            local color = Fk:getCardById(info.cardId).color
            if color ~= Card.NoColor then
              table.insertIfNeed(jiaoying_colors, color)
              table.insertIfNeed(jiaoying_targets, to.id)
              if to:getMark("@jiaoying-turn") == 0 then
                room:setPlayerMark(to, "@jiaoying-turn", {})
              end
            end
          end
        end
        room:setPlayerMark(to, "jiaoying_colors-turn", jiaoying_colors)
      end
    end
    room:setPlayerMark(player, "jiaoying_targets-turn", jiaoying_targets)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
    local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
    return table.contains(jiaoying_targets, target.id) and not table.contains(jiaoying_ignores, target.id)
  end,
  on_refresh = function(self, event, target, player, data)
    local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
    table.insert(jiaoying_ignores, target.id)
    player.room:setPlayerMark(player, "jiaoying_ignores-turn", jiaoying_ignores)
    player.room:setPlayerMark(target, "@jiaoying-turn", {"jiaoying_usedcard"})
  end,
}
local jiaoying_delay = fk.CreateTriggerSkill{
  name = "#jiaoying_delay",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target.phase == Player.Finish then
      local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
      local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
      self.cost_data = #jiaoying_targets - #jiaoying_ignores
      if self.cost_data > 0 then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    local targets = player.room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function (p)
      return p:getHandcardNum() < 5 end), function (p)
      return p.id end), 1, x, "#jiaoying-choose:::" .. x, self.name, true)
    if #targets > 0 then
      room:sortPlayersByAction(targets)
      for _, pid in ipairs(targets) do
        local to = room:getPlayerById(pid)
        if not to.dead and to:getHandcardNum() < 5 then
          to:drawCards(5-to:getHandcardNum(), self.name)
        end
      end
    end
  end,
}
local jiaoying_prohibit = fk.CreateProhibitSkill{
  name = "#jiaoying_prohibit",
  prohibit_use = function(self, player, card)
    local jiaoying_colors = player:getMark("jiaoying_colors-turn")
    return type(jiaoying_colors) == "table" and table.contains(jiaoying_colors, card.color)
  end,
  prohibit_response = function(self, player, card)
    local jiaoying_colors = player:getMark("jiaoying_colors-turn")
    return type(jiaoying_colors) == "table" and table.contains(jiaoying_colors, card.color)
  end,
}
jiaoying:addRelatedSkill(jiaoying_delay)
jiaoying:addRelatedSkill(jiaoying_prohibit)
fanyufeng:addSkill(bazhan)
fanyufeng:addSkill(jiaoying)
Fk:loadTranslationTable{
  ["fanyufeng"] = "樊玉凤",
  ["bazhan"] = "把盏",
  [":bazhan"] = "转换技，出牌阶段限一次，阳：你可以交给一名其他角色至多两张手牌；阴：你可以获得一名其他角色至多两张手牌。"..
  "然后若这些牌里包括【酒】或<font color='red'>♥</font>牌，你可令获得此牌的角色回复1点体力或复原武将牌。",
  ["jiaoying"] = "醮影",
  ["#jiaoying_delay"] = "醮影",
  [":jiaoying"] = "锁定技，其他角色获得你的手牌后，该角色本回合不能使用或打出与此牌颜色相同的牌。然后此回合结束阶段，"..
  "若其本回合没有再使用牌，你令一名角色将手牌摸至五张。",
  ["#bazhan-Yang"] = "把盏（阳）：选择一至两张手牌，交给一名其他角色",
  ["#bazhan-Yin"] = "把盏（阴）：选择一名有手牌的其他角色，获得其一至两张手牌",
  ["#bazhan-support"] = "把盏：可以选择令 %dest 回复1点体力或复原武将牌",
  ["#jiaoying-choose"] = "醮影：可选择至多%arg名角色将手牌补至5张",
  ["@jiaoying-turn"] = "醮影",
  ["jiaoying_usedcard"] = "使用过牌",

  ["$bazhan1"] = "此酒，当配将军。",
  ["$bazhan2"] = "这杯酒，敬于将军。",
  ["$jiaoying1"] = "独酌清醮，霓裳自舞。",
  ["$jiaoying2"] = "醮影倩丽，何人爱怜。",
  ["~fanyufeng"] = "醮妇再遇良人难……",
}

local ruanyu = General(extension, "ruanyu", "wei", 3)
local xingzuo = fk.CreateTriggerSkill{
  name = "xingzuo",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (player.phase == Player.Play or
    (player.phase == Player.Finish and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Play then
      return room:askForSkillInvoke(player, self.name, nil, "#xingzuo-invoke")
    else
      local targets = table.map(table.filter(room.alive_players, function(p)
        return not p:isKongcheng() end), function (p) return p.id end)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#xingzuo-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Play then
      local piles = room:askForExchange(player, {room:getNCards(3, "bottom"), player.player_cards[Player.Hand]}, {"Bottom", "$Hand"}, self.name)
      local cards1, cards2 = {}, {}
      for _, id in ipairs(piles[1]) do
        if room:getCardArea(id) == Player.Hand then
          table.insert(cards1, id)
        end
      end
      for _, id in ipairs(piles[2]) do
        if room:getCardArea(id) ~= Player.Hand then
          table.insert(cards2, id)
        end
      end
      local move1 = {
        ids = cards1,
        from = player.id,
        fromArea = Player.Hand,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        drawPilePosition = -1,
      }
      local move2 = {
        ids = cards2,
        to = player.id,
        toArea = Player.Hand,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      room:moveCards(move1, move2)
    else
      local to = room:getPlayerById(self.cost_data)
      local n = to:getHandcardNum()
      local move1 = {
        ids = to.player_cards[Player.Hand],
        from = to.id,
        fromArea = Player.Hand,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        drawPilePosition = -1,
      }
      local move2 = {
        ids = room:getNCards(3, "bottom"),
        to = to.id,
        toArea = Player.Hand,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      room:moveCards(move1, move2)
      if n > 3 and not player.dead then
        room:loseHp(player, 1, self.name)
      end
    end
  end,
}
local miaoxian = fk.CreateViewAsSkill{
  name = "miaoxian",
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#miaoxian",
  interaction = function()
    local names = {}
    local blackcards = table.filter(Self.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end)
    if #blackcards ~= 1 then return false end
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived then
        local to_use = Fk:cloneCard(card.name)
        to_use:addSubcard(blackcards[1])
        if ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, to_use) and not Self:prohibitUse(to_use)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names }
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    if not self.interaction.data then return nil end
    local blackcards = table.filter(Self.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end)
    if #blackcards ~= 1 then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(blackcards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      #table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end) == 1
  end,
  enabled_at_response = function(self, player, response)
    return not response and Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) and
      not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      #table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end) == 1
  end,
}
local miaoxian_trigger = fk.CreateTriggerSkill{
  name = "#miaoxian_trigger",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and table.every(player.player_cards[Player.Hand], function(id)
      return Fk:getCardById(id).color ~= Card.Red end) and data.card.color == Card.Red and
      not (data.card:isVirtual() and #data.card.subcards ~= 1)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, miaoxian.name, self.anim_type)
    player:broadcastSkillInvoke(miaoxian.name)
    player:drawCards(1, "miaoxian")
  end,
}
miaoxian:addRelatedSkill(miaoxian_trigger)
ruanyu:addSkill(xingzuo)
ruanyu:addSkill(miaoxian)
Fk:loadTranslationTable{
  ["ruanyu"] = "阮瑀",
  ["xingzuo"] = "兴作",
  [":xingzuo"] = "出牌阶段开始时，你可观看牌堆底的三张牌并用任意张手牌替换其中等量的牌。若如此做，结束阶段，"..
  "你可以令一名有手牌的角色用所有手牌替换牌堆底的三张牌，然后若交换前该角色的手牌数大于3，你失去1点体力。",
  ["miaoxian"] = "妙弦",
  [":miaoxian"] = "每回合限一次，你可以将手牌中的唯一黑色牌当任意一张普通锦囊牌使用；当你使用手牌中的唯一红色牌时，你摸一张牌。",
  ["#xingzuo-invoke"] = "兴作：你可观看牌堆底的三张牌，并用任意张手牌替换其中等量的牌",
  ["#xingzuo-choose"] = "兴作：你可以令一名角色用所有手牌替换牌堆底的三张牌，若交换前其手牌数大于3，你失去1点体力",
  ["#miaoxian_trigger"] = "妙弦",
  ["#miaoxian"] = "妙弦：将手牌中的黑色牌当任意锦囊牌使用",

  ["$xingzuo1"] = "顺人之情，时之势，兴作可成。",
  ["$xingzuo2"] = "兴作从心，相继不绝。",
  ["$miaoxian1"] = "女为悦者容，士为知己死。",
  ["$miaoxian2"] = "与君高歌，请君侧耳。",
  ["~ruanyu"] = "良时忽过，身为土灰。",
}

local yangwan = General(extension, "ty__yangwan", "shu", 3, 3, General.Female)
local youyan = fk.CreateTriggerSkill{
  name = "youyan",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and (player.phase == Player.Play or player.phase == Player.Discard) and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      local suits = {"spade", "club", "heart", "diamond"}
      local can_invoked = false
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                can_invoked = true
              end
            end
          else
            local room = player.room
            local parentPindianEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.Pindian, true)
            if parentPindianEvent then
              local pindianData = parentPindianEvent.data[1]
              if pindianData.from == player then
                local leftFromCardIds = room:getSubcardsByRule(pindianData.fromCard)
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea == Card.Processing and table.contains(leftFromCardIds, info.cardId) then
                    table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                    can_invoked = true
                  end
                end
              end
              for toId, result in pairs(pindianData.results) do
                if player.id == toId then
                  local leftToCardIds = room:getSubcardsByRule(result.toCard)
                  for _, info in ipairs(move.moveInfo) do
                    if info.fromArea == Card.Processing and table.contains(leftToCardIds, info.cardId) then
                      table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                      can_invoked = true
                    end
                  end
                end
              end
            end
          end
        end
      end
      return can_invoked and #suits > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
            end
          end
        else
          local parentPindianEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.Pindian, true)
          if parentPindianEvent then
            local pindianData = parentPindianEvent.data[1]
            if pindianData.from == player then
              local leftFromCardIds = room:getSubcardsByRule(pindianData.fromCard)
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.Processing and table.contains(leftFromCardIds, info.cardId) then
                  table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                end
              end
            end
            for toId, result in pairs(pindianData.results) do
              if player.id == toId then
                local leftToCardIds = room:getSubcardsByRule(result.toCard)
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea == Card.Processing and table.contains(leftToCardIds, info.cardId) then
                    table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                  end
                end
              end
            end
          end
        end
      end
    end
    local cards = {}
    while #suits > 0 do
      local pattern = table.random(suits)
      table.removeOne(suits, pattern)
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
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
}
local zhuihuan = fk.CreateTriggerSkill{
  name = "zhuihuan",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id end), 1, 1, "#zhuihuan-choose", self.name, true, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), self.name, 1)
  end,

  refresh_events = {fk.Damaged, fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:getMark(self.name) > 0 then
      if event == fk.Damaged then
        return data.from and not data.from.dead
      else
        return player.phase == Player.Start
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      player.tag["zhuihuan"] = player.tag["zhuihuan"] or {}
      table.insertIfNeed(player.tag["zhuihuan"], data.from.id)
    else
      room:setPlayerMark(player, self.name, 0)
      player.tag["zhuihuan"] = player.tag["zhuihuan"] or {}
      local tos = player.tag["zhuihuan"]
      if #tos > 0 then
        for _, id in ipairs(tos) do
          local to = room:getPlayerById(id)
          if not to.dead then
            if to.hp > player.hp then
              room:damage{
                from = player,
                to = to,
                damage = 2,
                skillName = self.name,
              }
            elseif to.hp < player.hp then
              if #to.player_cards[Player.Hand] < 2 then
                to:throwAllCards("h")
              else
                room:throwCard(table.random(to.player_cards[Player.Hand], 2), self.name, to, to)
              end
            end
          end
        end
      end
    end
  end,
}
yangwan:addSkill(youyan)
yangwan:addSkill(zhuihuan)
Fk:loadTranslationTable{
  ["ty__yangwan"] = "杨婉",
  ["youyan"] = "诱言",
  [":youyan"] = "你的回合内，当你的牌因使用或打出之外的方式进入弃牌堆后，你可以从牌堆中获得本次弃牌中没有的花色的牌各一张（出牌阶段、弃牌阶段各限一次）。",
  ["zhuihuan"] = "追还",
  [":zhuihuan"] = "结束阶段，你可以秘密选择一名角色。直到该角色的下个准备阶段，此期间内对其造成过伤害的角色："..
  "若体力值大于该角色，则受到其造成的2点伤害；若体力值小于等于该角色，则随机弃置两张手牌。",
  ["#zhuihuan-choose"] = "追还：选择一名角色，直到其准备阶段，对此期间对其造成过伤害的角色造成伤害或弃牌",
  
  ["$youyan1"] = "诱言者，为人所不齿。",
  ["$youyan2"] = "诱言之弊，不可不慎。",
  ["$zhuihuan1"] = "伤人者，追而还之！",
  ["$zhuihuan2"] = "追而还击，皆为因果。",
  ["~ty__yangwan"] = "遇人不淑……",
}

local panshu = General(extension, "ty__panshu", "wu", 3, 3, General.Female)
local zhiren = fk.CreateTriggerSkill{
  name = "zhiren",
  anim_type = "control",
  events = {fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and not data.card:isVirtual() and
      (player.phase ~= Player.NotActive or player:getMark("@@yaner") > 0) then
      if player:getMark("zhiren-turn") == 0 then
        player.room:setPlayerMark(player, "zhiren-turn", 1)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #Fk:translate(data.card.trueName) / 3
    room:askForGuanxing(player, room:getNCards(n), nil, nil, "", false)
    if n > 1 then
      local targets = table.map(table.filter(room.alive_players, function(p)
        return #p.player_cards[Player.Equip] > 0 end), function(p) return p.id end)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiren1-choose", self.name, true)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askForCardChosen(player, to, "e", self.name)
          room:throwCard({id}, self.name, to, player)
        end
      end
      targets = table.map(table.filter(room.alive_players, function(p)
        return #p.player_cards[Player.Judge] > 0 end), function(p) return p.id end)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiren2-choose", self.name, true)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askForCardChosen(player, to, "j", self.name)
          room:throwCard({id}, self.name, to, player)
        end
      end
    end
    if n > 2 then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    end
    if n > 3 then
      player:drawCards(3, self.name)
    end
  end,
}
local yaner = fk.CreateTriggerSkill{
  name = "yaner",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              local to = player.room:getPlayerById(move.from)
              if to:isKongcheng() and to.phase == Player.Play and not to.dead then
                self.cost_data = move.from
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yaner-invoke::"..self.cost_data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards1 = player:drawCards(2, self.name)
    local cards2 = to:drawCards(2, self.name)
    if Fk:getCardById(cards1[1]).type == Fk:getCardById(cards1[2]).type then
      room:setPlayerMark(player, "@@yaner", 1)
    end
    if to:isWounded() and Fk:getCardById(cards2[1]).type == Fk:getCardById(cards2[2]).type then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yaner") > 0 and data.from == Player.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yaner", 0)
  end,
}
panshu:addSkill(zhiren)
panshu:addSkill(yaner)
Fk:loadTranslationTable{
  ["ty__panshu"] = "潘淑",
  ["zhiren"] = "织纴",
  [":zhiren"] = "你的回合内，当你使用本回合的第一张非转化牌时，若X：不小于1，你观看牌堆顶X张牌并以任意顺序放回牌堆顶或牌堆底；"..
  "不小于2，你可以弃置场上一张装备牌和一张延时锦囊牌；不小于3，你回复1点体力；不小于4，你摸三张牌（X为此牌名称字数）。",
  ["yaner"] = "燕尔",
  [":yaner"] = "每回合限一次，当其他角色于其出牌阶段内失去最后的手牌时，你可以与其各摸两张牌，然后若因此摸到相同类型的两张牌的角色为："..
  "你，〖织纴〗改为回合外也可以发动直到你的下个回合开始；其，其回复1点体力。",
  ["#zhiren1-choose"] = "织纴：你可以弃置场上一张装备牌",
  ["#zhiren2-choose"] = "织纴：你可以弃置场上一张延时锦囊牌",
  ["#yaner-invoke"] = "燕尔：你可以与 %dest 各摸两张牌，若摸到的牌类型形同则获得额外效果",
  ["@@yaner"] = "燕尔",
  
  ["$zhiren1"] = "穿针引线，栩栩如生。",
  ["$zhiren2"] = "纺绩织纴，布帛可成。",
  ["$yaner1"] = "如胶似漆，白首相随。",
  ["$yaner2"] = "新婚燕尔，亲睦和美。",
  ["~ty__panshu"] = "有喜必忧，以为深戒！",
}

--锦瑟良缘：曹金玉 孙翊 冯妤 来莺儿 曹华 张奋
local caojinyu = General(extension, "caojinyu", "wei", 3, 3, General.Female)
local yuqi = fk.CreateTriggerSkill{
  name = "yuqi",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not target.dead and player:usedSkillTimes(self.name) < 2 and
    (target == player or player:distanceTo(target) <= player:getMark("yuqi1"))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n1, n2, n3 = player:getMark("yuqi2"), player:getMark("yuqi3"), player:getMark("yuqi4")
    if n1 < 2 and n2 < 1 and n3 < 1 then
      return false
    end
    local cards = room:getNCards(n1)
    local result = room:askForCustomDialog(player, self.name,
    "packages/tenyear/qml/YuqiBox.qml", {
      cards,
      target.general, n2,
      player.general, n3,
    })
    local top, bottom
    if result ~= "" then
      local d = json.decode(result)
      top = d[2]
      bottom = d[3]
    else
      top = {cards[1]}
      bottom = {cards[2]}
    end
    local moveInfos = {}
    if #top > 0 then
      table.insert(moveInfos, {
        ids = top,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = player.id,
        skillName = self.name,
      })
      for _, id in ipairs(top) do
        table.removeOne(cards, id)
      end
    end
    if #bottom > 0 then
      table.insert(moveInfos, {
        ids = bottom,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
      for _, id in ipairs(bottom) do
        table.removeOne(cards, id)
      end
    end
    if #cards > 0 then
      for i = #cards, 1, -1 do
        table.insert(room.draw_pile, 1, cards[i])
      end
    end
    room:moveCards(table.unpack(moveInfos))
  end,

  refresh_events = {fk.EventLoseSkill, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventAcquireSkill then
      room:setPlayerMark(player, "yuqi1", 0)
      room:setPlayerMark(player, "yuqi2", 3)
      room:setPlayerMark(player, "yuqi3", 1)
      room:setPlayerMark(player, "yuqi4", 1)
      room:setPlayerMark(player, "@" .. self.name, string.format("%d-%d-%d-%d", 0, 3, 1, 1))
    else
      room:setPlayerMark(player, "yuqi1", 0)
      room:setPlayerMark(player, "yuqi2", 0)
      room:setPlayerMark(player, "yuqi3", 0)
      room:setPlayerMark(player, "yuqi4", 0)
      room:setPlayerMark(player, "@" .. self.name, 0)
    end
  end,
}
local function AddYuqi(player, skillName, num)
  local room = player.room
  local choices = {}
  for i = 1, 4, 1 do
    if player:getMark("yuqi" .. tostring(i)) < 5 then
      table.insert(choices, "yuqi" .. tostring(i))
    end
  end
  if #choices > 0 then
    local choice = room:askForChoice(player, choices, skillName)
    local x = player:getMark(choice)
    if x + num < 6 then
      x = x + num
    else
      x = 5
    end
    room:setPlayerMark(player, choice, x)
    room:setPlayerMark(player, "@yuqi", string.format("%d-%d-%d-%d",
    player:getMark("yuqi1"),
    player:getMark("yuqi2"),
    player:getMark("yuqi3"),
    player:getMark("yuqi4")))
  end
end
local shanshen = fk.CreateTriggerSkill{
  name = "shanshen",
  anim_type = "control",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    AddYuqi(player, self.name, 2)
    if target:getMark(self.name) == 0 and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skillName = self.name,
      }
    end
  end,
  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    return target == player and target:hasSkill(self.name) and data.to:getMark(self.name) == 0
  end,
  on_refresh = function(self, event, target, player, data)
      player.room:setPlayerMark(data.to, self.name, 1)
  end,
}
local xianjing = fk.CreateTriggerSkill{
  name = "xianjing",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Start then
      for i = 1, 4, 1 do
        if player:getMark("yuqi" .. tostring(i)) < 5 then
          return true
        end
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    AddYuqi(player, self.name, 1)
    if not player:isWounded() then
      AddYuqi(player, self.name, 1)
    end
  end,
}
caojinyu:addSkill(yuqi)
caojinyu:addSkill(shanshen)
caojinyu:addSkill(xianjing)
Fk:loadTranslationTable{
  ["caojinyu"] = "曹金玉",
  ["yuqi"] = "隅泣",
  [":yuqi"] = "每回合限两次，当一名角色受到伤害后，若你与其距离0或者更少，你可以观看牌堆顶的3张牌，将其中至多1张交给受伤角色，"..
  "至多1张自己获得，剩余的牌放回牌堆顶。",
  ["shanshen"] = "善身",
  [":shanshen"] = "当有角色死亡时，你可令〖隅泣〗中的一个数字+2（单项不能超过5）。然后若你没有对死亡角色造成过伤害，你回复1点体力。",
  ["xianjing"] = "娴静",
  [":xianjing"] = "准备阶段，你可令〖隅泣〗中的一个数字+1（单项不能超过5）。若你满体力值，则再令〖隅泣〗中的一个数字+1。",
  ["@yuqi"] = "隅泣",
  ["yuqi1"] = "距离",
  ["yuqi2"] = "观看牌数",
  ["yuqi3"] = "交给受伤角色牌数",
  ["yuqi4"] = "自己获得牌数",
  ["#yuqi"] = "隅泣：请分配卡牌，余下的牌以原顺序置于牌堆顶",

  ["$yuqi1"] = "孤影独泣，困于隅角。",
  ["$yuqi2"] = "向隅而泣，黯然伤感。",
  ["$shanshen1"] = "好善为德，坚守本心。",
  ["$shanshen2"] = "洁身自爱，独善其身。",
  ["$xianjing1"] = "文静娴丽，举止柔美。",
  ["$xianjing2"] = "娴静淡雅，温婉穆穆。",
  ["~caojinyu"] = "平叔之情，吾岂不明。",
}

local sunyi = General(extension, "ty__sunyi", "wu", 5)
local jiqiaos = fk.CreateTriggerSkill{
  name = "jiqiaos",
  anim_type = "drawcard",
  expand_pile = "jiqiaos",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile(self.name, player.room:getNCards(player.maxHp), true, self.name)
  end,
}
local jiqiaos_trigger = fk.CreateTriggerSkill{
  name = "#jiqiaos_trigger",
  anim_type = "drawcard",
  expand_pile = "jiqiaos",
  events = {fk.EventPhaseEnd, fk.CardUseFinished, fk.EventLoseSkill},
  can_trigger = function(self, event, target, player, data)
    if target == player and #player:getPile("jiqiaos") > 0 then
      if event == fk.EventPhaseEnd then
        return player.phase == Player.Play
      elseif event == fk.CardUseFinished then
        return true
      elseif event == fk.EventLoseSkill then
        return data.name == "jiqiaos"
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd or event == fk.EventLoseSkill then
      room:moveCards({
        from = player.id,
        ids = player:getPile("jiqiaos"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = "jiqiaos",
        specialName = "jiqiaos",
      })
    else
      local card = room:askForCard(player, 1, 1, false, "jiqiaos", false, ".|.|.|jiqiaos|.|.", "#jiqiaos-card", "jiqiaos")
      if #card == 0 then card = {table.random(player:getPile("jiqiaos"))} end
      room:obtainCard(player, card[1], true, fk.ReasonJustMove)
      local red = #table.filter(player:getPile("jiqiaos"), function (id) return Fk:getCardById(id, true).color == Card.Red end)
      local black = #player:getPile("jiqiaos") - red  --除了不该出现的衍生牌，都有颜色
      if red == black then
        if player:isWounded() then
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = "jiqiaos",
          }
        end
      else
        room:loseHp(player, 1, "jiqiaos")
      end
    end
  end,
}
local xiongyis = fk.CreateTriggerSkill{
  name = "xiongyis",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#xiongyis1-invoke:::"..tostring(math.min(3, player.maxHp))
    if table.find(player.room.alive_players, function(p) return string.find(p.general, "xushi") end) then
      prompt = "#xiongyis2-invoke"
    end
    if player.room:askForSkillInvoke(player, self.name, nil, prompt) then
      self.cost_data = prompt
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = tonumber(string.sub(self.cost_data, 10, 10))
    if n == 1 then
      local maxHp = player.maxHp
      room:recover({
        who = player,
        num = math.min(3, maxHp) - player.hp,
        recoverBy = player,
        skillName = self.name
      })
      room:changeHero(player, "xushi", false, false, true)
      player.maxHp = maxHp
      room:broadcastProperty(player, "maxHp")
    else
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = self.name
      })
      room:handleAddLoseSkills(player, "hunzi", nil, true, false)
    end
  end,
}
jiqiaos:addRelatedSkill(jiqiaos_trigger)
sunyi:addSkill(jiqiaos)
sunyi:addSkill(xiongyis)
sunyi:addRelatedSkill("hunzi")
sunyi:addRelatedSkill("ex__yingzi")
sunyi:addRelatedSkill("yinghun")
Fk:loadTranslationTable{
  ["ty__sunyi"] = "孙翊",
  ["jiqiaos"] = "激峭",
  [":jiqiaos"] = "出牌阶段开始时，你可以将牌堆顶的X张牌至于武将牌上（X为你的体力上限）；当你使用一张牌结算结束后，若你的武将牌上有“激峭”牌，"..
  "你获得其中一张，然后若剩余其中两种颜色牌的数量相等，你回复1点体力，否则你失去1点体力；出牌阶段结束时，移去所有“激峭”牌。",
  ["xiongyis"] = "凶疑",
  [":xiongyis"] = "限定技，当你处于濒死状态时，若徐氏：不在场，你可以将体力值回复至3点并将武将牌替换为徐氏；"..
  "在场，你可以将体力值回复至1点并获得技能〖魂姿〗。",
  ["#jiqiaos_trigger"] = "激峭",
  ["#jiqiaos-card"] = "激峭：获得一张“激峭”牌",
  ["#xiongyis1-invoke"] = "凶疑：你可以将回复体力至%arg点并变身为徐氏！",
  ["#xiongyis2-invoke"] = "凶疑：你可以将回复体力至1点并获得〖魂姿〗！",

  ["$jiqiaos1"] = "为将者，当躬冒矢石！",
  ["$jiqiaos2"] = "吾承父兄之志，危又何惧？",
  ["$xiongyis1"] = "此仇不报，吾恨难消！",
  ["$xiongyis2"] = "功业未立，汝可继之！",
  ["$hunzi_ty__sunyi1"] = "身临绝境，亦当心怀壮志！",
  ["$hunzi_ty__sunyi2"] = "危难之时，自当振奋以对！",
  ["$ex__yingzi_ty__sunyi"] = "骁悍果烈，威震江东！",
  ["$yinghun_ty__sunyi"] = "兄弟齐心，以保父兄基业！",
  ["~ty__sunyi"] = "功业未成而身先死，惜哉，惜哉！",
}

local fengyu = General(extension, "ty__fengfangnv", "qun", 3, 3, General.Female)
local tiqi = fk.CreateTriggerSkill{
  name = "tiqi",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player ~= target and target and not target.dead and target:getMark("tiqi-turn") ~= 2 and
        player:usedSkillTimes(self.name) < 1 then
      return data.to == Player.Play or data.to == Player.Discard or data.to == Player.Finish
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.abs(target:getMark("tiqi-turn") - 2)
    player:drawCards(n, self.name)
    local choice = room:askForChoice(player, {"tiqi_add", "tiqi_minus", "Cancel"}, self.name,
      "#tiqi-choice::" .. target.id .. ":" .. tostring(n))
    if choice == "tiqi_add" then
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, n)
    elseif choice == "tiqi_minus" then
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, n)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.phase == Player.Draw
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.to == player.id and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
        player.room:addPlayerMark(player, "tiqi-turn", #move.moveInfo)
      end
    end
  end,
}
local baoshu = fk.CreateTriggerSkill{
  name = "baoshu",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), function(p)
      return p.id
    end), 1, player.maxHp, "#baoshu-choose", self.name, true)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player.maxHp - #self.cost_data + 1
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:addPlayerMark(p, "@fengyu_shu", x)
        if p.chained then
          p:setChainState(false)
        end
      end
    end
  end,
}
local baoshu_delay = fk.CreateTriggerSkill{
  name = "#baoshu_delay",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@fengyu_shu") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@fengyu_shu")
    player.room:setPlayerMark(player, "@fengyu_shu", 0)
  end,
}
baoshu:addRelatedSkill(baoshu_delay)
fengyu:addSkill(tiqi)
fengyu:addSkill(baoshu)
Fk:loadTranslationTable{
  ["ty__fengfangnv"] = "冯妤",
  ["tiqi"] = "涕泣",
  [":tiqi"] = "其他角色出牌阶段、弃牌阶段、结束开始前，若其于此回合的摸牌阶段内因摸牌而得到的牌数之和不等于2且你于此回合内未发动过此技能，"..
  "则你摸超出或少于2的牌，然后可以令该角色本回合手牌上限增加或减少同样的数值。",
  ["baoshu"] = "宝梳",
  ["#baoshu_delay"] = "宝梳",
  [":baoshu"] = "准备阶段，你可以选择至多X名角色（X为你的体力上限），这些角色各获得一个“梳”标记并重置武将牌，"..
  "你每少选一名角色，每名目标角色便多获得一个“梳”。有“梳”标记的角色摸牌阶段多摸其“梳”数量的牌，然后移去其所有“梳”。",
  ["#tiqi-choice"] = "涕泣：你可以令%dest本回合的手牌上限增加或减少 %arg",
  ["tiqi_add"] = "增加手牌上限",
  ["tiqi_minus"] = "减少手牌上限",
  ["#baoshu-choose"] = "宝梳：你可以令若干名角色获得“梳”标记，重置其武将牌且其摸牌阶段多摸牌",
  ["@fengyu_shu"] = "梳",

  ["$tiqi1"] = "远望中原，涕泪交流。",
  ["$tiqi2"] = "瞻望家乡，泣涕如雨。",
  ["$baoshu1"] = "明镜映梳台，黛眉衬粉面。",
  ["$baoshu2"] = "头作扶摇髻，首枕千金梳。",
  ["~ty__fengfangnv"] = "诸位，为何如此对我？",
}

local laiyinger = General(extension, "laiyinger", "qun", 3, 3, General.Female)
local xiaowu = fk.CreateActiveSkill{
  name = "xiaowu",
  anim_type = "offensive",
  prompt = "#xiaowu",
  max_card_num = 0,
  target_num = 1,
  interaction = function(self)
    return UI.ComboBox { choices = {"xiaowu_clockwise", "xiaowu_anticlockwise"} }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local players = room:getOtherPlayers(player)
    local targets = {}
    local choice = self.interaction.data
    for i = 1, #players, 1 do
      local real_i = i
      if choice == "xiaowu_anticlockwise" then
        real_i = #players + 1 - real_i
      end
      local temp = players[real_i]
      table.insert(targets, temp)
      if temp == target then break end
    end
    room:doIndicate(player.id, table.map(targets, function (p) return p.id end))
    local x = 0
    local to_damage = {}
    for _, p in ipairs(targets) do
      if not p.dead and not player.dead then
        choice = room:askForChoice(p, {"xiaowu_draw1", "draw1"}, self.name, "#xiawu_draw:" .. player.id)
        if choice == "xiaowu_draw1" then
          player:drawCards(1, self.name)
          x = x+1
        elseif choice == "draw1" then
          p:drawCards(1, self.name)
          table.insert(to_damage, p.id)
        end
      end
    end
    if not player.dead then
      if x > #to_damage then
        room:addPlayerMark(player, "@xiaowu_sand")
      elseif x < #to_damage then
        room:sortPlayersByAction(to_damage)
        for _, pid in ipairs(to_damage) do
          local p = room:getPlayerById(pid)
          if not p.dead then
            room:damage{ from = player, to = p, damage = 1, skillName = self.name }
          end
        end
      end
    end
  end,
}
local huaping = fk.CreateTriggerSkill{
  name = "huaping",
  events = {fk.Death},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name, false, player == target) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player == target then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
        return p.id end), 1, 1, "#huaping-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#huaping-invoke::"..target.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player == target then
      local to = room:getPlayerById(self.cost_data)
      room:handleAddLoseSkills(to, "shawu", nil, true, false)
      room:setPlayerMark(to, "@xiaowu_sand", player:getMark("@xiaowu_sand"))
    else
      local skills = {}
      for _, s in ipairs(target.player_skills) do
        if not (s.attached_equip or s.name[#s.name] == "&") then
          table.insertIfNeed(skills, s.name)
        end
      end
      if #skills > 0 then
        room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
      end
      local x = player:getMark("@xiaowu_sand")
      room:handleAddLoseSkills(player, "-xiaowu", nil, true, false)
      room:setPlayerMark(player, "@xiaowu_sand", 0)
      if x > 0 then
        player:drawCards(x, self.name)
      end
    end
  end,
}
local shawu_select = fk.CreateActiveSkill{
  name = "shawu_select",
  can_use = function() return false end,
  target_num = 0,
  max_card_num = 2,
  min_card_num = function ()
    if Self:getMark("@xiaowu_sand") > 0 then
      return 0
    end
    return 2
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 2 and not Self:prohibitDiscard(Fk:getCardById(to_select)) and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
}
local shawu = fk.CreateTriggerSkill{
  name = "shawu",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and
      (player:getMark("@xiaowu_sand") > 0 or player:getHandcardNum() > 1) and not player.room:getPlayerById(data.to).dead
  end,
  on_cost = function(self, event, target, player, data)
    local _, ret = player.room:askForUseActiveSkill(player, "shawu_select", "#shawu-invoke::" .. data.to, true)
    if ret then
      self.cost_data = ret.cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:getPlayerById(data.to)
    local draw2 = false
    if #self.cost_data > 1 then
      room:throwCard(self.cost_data, self.name, player, player)
    else
      room:removePlayerMark(player, "@xiaowu_sand")
      draw2 = true
    end
    if not to.dead then
      room:damage{ from = player, to = to, damage = 1, skillName = self.name }
    end
    if draw2 and not player.dead then
      player:drawCards(2, self.name)
    end
  end,
}
Fk:addSkill(shawu_select)
laiyinger:addSkill(xiaowu)
laiyinger:addSkill(huaping)
laiyinger:addRelatedSkill(shawu)
Fk:loadTranslationTable{
  ["laiyinger"] = "来莺儿",
  ["xiaowu"] = "绡舞",
  [":xiaowu"] = "出牌阶段限一次，你可以从你的上家或下家起选择任意名座位连续的其他角色，每名角色依次选择一项：1.令你摸一张牌；2.自己摸一张牌。"..
  "选择完成后，若令你摸牌的选择人数较多，你获得一个“沙”标记；若自己摸牌的选择人数较多，你对这些角色各造成1点伤害。",
  ["huaping"] = "化萍",
  [":huaping"] = "限定技，一名其他角色死亡时，你可以获得其所有武将技能，然后你失去〖绡舞〗和所有“沙”标记并摸等量的牌。"..
  "你死亡时，若此技能未发动过，你可令一名其他角色获得技能〖沙舞〗和所有“沙”标记。",
  ["shawu"] = "沙舞",
  ["shawu_select"] = "沙舞",
  [":shawu"] = "当你使用【杀】指定目标后，你可以弃置两张手牌或1枚“沙”标记对目标角色造成1点伤害。若你弃置的是“沙”标记，你摸两张牌。",

  ["#xiaowu"] = "发动绡舞，选择按顺时针或逆时针顺序结算，并选择作为终点的目标角色",
  ["xiaowu_clockwise"] = "顺时针顺序",
  ["xiaowu_anticlockwise"] = "逆时针顺序",
  ["#xiawu_draw"] = "绡舞：选择令%src摸一张牌或自己摸一张牌",
  ["xiaowu_draw1"] = "令其摸一张牌",
  ["@xiaowu_sand"] = "沙",
  ["#huaping-choose"] = "化萍：选择一名角色，令其获得沙舞",
  ["#huaping-invoke"] = "化萍：你可以获得%dest的所有武将技能，然后失去绡舞",
  ["#shawu-invoke"] = "沙舞：你可选择两张手牌弃置，或直接点确定弃置沙标记。来对%dest造成1点伤害",

  ["$xiaowu1"] = "繁星临云袖，明月耀舞衣。",
  ["$xiaowu2"] = "逐舞飘轻袖，传歌共绕梁。",
  ["$huaping1"] = "风絮飘残，化萍而终。",
  ["$huaping2"] = "莲泥刚倩，藕丝萦绕。",
  ["~laiyinger"] = "谷底幽兰艳，芳魂永留香……",
}

local caohua = General(extension, "caohua", "wei", 3, 3, General.Female)
local function doCaiyi(player, target, choice, n)
  local room = player.room
  local state = string.sub(choice, 6, 9)
  local i = tonumber(string.sub(choice, 10))
  if i == 4 then
    local num = {}
    for i = 1, 3, 1 do
      if player:getMark("caiyi"..state..tostring(i)) == 0 then
        table.insert(num, i)
      end
    end
    doCaiyi(player, target, "caiyi"..state..tostring(table.random(num)), n)
  else
    if state == "yang" then
      if i == 1 then
        if target:isWounded() then
          room:recover({
            who = target,
            num = math.min(n, target:getLostHp()),
            recoverBy = player,
            skillName = "caiyi",
          })
        end
      elseif i == 2 then
        target:drawCards(n, "caiyi")
      else
        if not target.faceup then
          target:turnOver()
        end
        if target.chained then
          target:setChainState(false)
        end
      end
    else
      if i == 1 then
        room:damage{
          to = target,
          damage = n,
          skillName = "caiyi",
        }
      elseif i == 2 then
        if #target:getCardIds{Player.Hand, Player.Equip} <= n then
          target:throwAllCards("he")
        else
          room:askForDiscard(target, n, n, true, "caiyi", false)
        end
      else
        target:turnOver()
        if not target.chained then
          target:setChainState(true)
        end
      end
    end
  end
end
local caiyi = fk.CreateTriggerSkill{
  name = "caiyi",
  anim_type = "switch",
  switch_skill_name = "caiyi",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Finish then
      local state = "yang"
      if player:getSwitchSkillState(self.name, false) == fk.SwitchYin then
        state = "yinn"
      end
      for i = 1, 4, 1 do
        local mark = "caiyi"..state..tostring(i)
        if player:getMark(mark) == 0 then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#caiyi1-invoke"
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYin then
      prompt = "#caiyi2-invoke"
    end
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id end), 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    local state = "yang"
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYin then
      state = "yinn"
    end
    for i = 1, 4, 1 do
      local mark = "caiyi"..state..tostring(i)
      if player:getMark(mark) == 0 then
        table.insert(choices, mark)
      end
    end
    local num = #choices
    if num == 4 then
      table.remove(choices, 4)
    end
    local to = room:getPlayerById(self.cost_data)
    local choice = room:askForChoice(to, choices, self.name, "#caiyi-choice:::"..tostring(num))
    room:setPlayerMark(player, choice, 1)
    doCaiyi(player, to, choice, num)
  end,
}
local guili = fk.CreateTriggerSkill{
  name = "guili",
  anim_type = "control",
  events = {fk.TurnStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
        local room = player.room
      if target == player and event == fk.TurnStart then
        local turn_event = room.logic:getCurrentEvent()
        if not turn_event then return false end
        local x = player:getMark("guili_record")
        if x == 0 then
          local events = room.logic.event_recorder[GameEvent.Turn] or Util.DummyTable
          for _, e in ipairs(events) do
            local current_player = e.data[1]
            if current_player == player then
              x = e.id
              room:setPlayerMark(player, "guili_record", x)
              break
            end
          end
        end
        return turn_event.id == x
      elseif event == fk.TurnEnd and not target.dead and player:getMark(self.name) == target.id then
        local turn_event = room.logic:getCurrentEvent()
        if not turn_event then return false end
        local x = target:getMark("guili_record-round")
        if x == 0 then
          room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
            local current_player = e.data[1]
            if current_player == target then
              x = e.id
              room:setPlayerMark(target, "guili_record", x)
              return true
            end
          end, Player.HistoryRound)
        end
        return turn_event.id == x and #room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          local damage = e.data[5]
          if damage and target == damage.from then
            return true
          end
        end, Player.HistoryTurn) == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#guili-choose", self.name, false, true)
      local to
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
      room:setPlayerMark(player, self.name, to)
      room:setPlayerMark(room:getPlayerById(to), "@@guili", 1)
    elseif event == fk.TurnEnd then
      player:gainAnExtraTurn(true)
    end
  end,
}
caohua:addSkill(caiyi)
caohua:addSkill(guili)
Fk:loadTranslationTable{
  ["caohua"] = "曹华",
  ["caiyi"] = "彩翼",
  [":caiyi"] = "转换技，结束阶段，你可以令一名角色选择一项并移除该选项：阳：1.回复X点体力；2.摸X张牌；3.复原武将牌；4.随机执行一个已移除的阳选项；"..
  "阴：1.受到X点伤害；2.弃置X张牌；3.翻面并横置；4.随机执行一个已移除的阴选项（X为当前状态剩余选项数）。",
  ["guili"] = "归离",
  [":guili"] = "你的第一个回合开始时，你选择一名其他角色。该角色每轮的第一个回合结束时，若其本回合未造成过伤害，你执行一个额外的回合。",
  ["#caiyi1-invoke"] = "彩翼：你可以令一名角色执行一个正面选项",
  ["#caiyi2-invoke"] = "彩翼：你可以令一名角色执行一个负面选项",
  ["#caiyi-choice"] = "彩翼：选择执行的一项（其中X为%arg）",
  ["caiyiyang1"] = "回复X点体力",
  ["caiyiyang2"] = "摸X张牌",
  ["caiyiyang3"] = "复原武将牌",
  ["caiyiyang4"] = "随机一个已移除的阳选项",
  ["caiyiyinn1"] = "受到X点伤害",
  ["caiyiyinn2"] = "弃置X张牌",
  ["caiyiyinn3"] = "翻面并横置",
  ["caiyiyinn4"] = "随机一个已移除的阴选项",
  ["@@guili"] = "归离",
  ["#guili-choose"] = "归离：选择一名角色，其回合结束时，若其本回合未造成过伤害，你执行一个额外回合",

  ["$caiyi1"] = "凰凤化越，彩翼犹存。",
  ["$caiyi2"] = "身披彩翼，心有灵犀。",
  ["$guili1"] = "既离厄海，当归泸沽。",
  ["$guili2"] = "山野如春，不如归去。",
  ["~caohua"] = "自古忠孝难两全……",
}

local zhangfen = General(extension, "zhangfen", "wu", 4)
local wanglu = fk.CreateTriggerSkill{
  name = "wanglu",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getEquipment(Card.SubtypeTreasure) then
      if Fk:getCardById(player:getEquipment(Card.SubtypeTreasure)).name == "siege_engine" then
        player:gainAnExtraPhase(Player.Play)
        return
      end
    else
      for i = 1, 3, 1 do
        room:setPlayerMark(player, "xianzhu"..tostring(i), 0)
      end
    end
    for _, id in ipairs(Fk:getAllCardIds()) do
      if Fk:getCardById(id).name == "siege_engine" and room:getCardArea(id) == Card.Void then
        room:moveCards({
          ids = {id},
          fromArea = Card.Void,
          to = player.id,
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
        break
      end
    end
  end,
}
local xianzhu = fk.CreateTriggerSkill{
  name = "xianzhu",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and
      player:getEquipment(Card.SubtypeTreasure) and Fk:getCardById(player:getEquipment(Card.SubtypeTreasure)).name == "siege_engine" and
      (player:getMark("xianzhu1") + player:getMark("xianzhu2") + player:getMark("xianzhu3")) < 5
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"xianzhu2", "xianzhu3"}
    if player:getMark("xianzhu1") == 0 then
      table.insert(choices, 1, "xianzhu1")
    end
    local choice = room:askForChoice(player, choices, self.name, "#xianzhu-choice")
    room:addPlayerMark(player, choice, 1)
  end,
}
local chaixie = fk.CreateTriggerSkill{
  name = "chaixie",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.toArea == Card.Void then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId, true).name == "siege_engine" then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for i = 1, 3, 1 do
      n = n + player:getMark("xianzhu"..tostring(i))
      room:setPlayerMark(player, "xianzhu"..tostring(i), 0)
    end
    player:drawCards(n, self.name)
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local id = 0
    for i = #data, 1, -1 do
      local move = data[i]
      if move.toArea ~= Card.Void then
        for j = #move.moveInfo, 1, -1 do
          local info = move.moveInfo[j]
          if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId, true).name == "siege_engine" then
            id = info.cardId
            table.removeOne(move.moveInfo, info)
            break
          end
        end
      end
    end
    if id ~= 0 then
      local room = player.room
      room:sendLog{
        type = "#destructDerivedCard",
        arg = Fk:getCardById(id, true):toLogString(),
      }
      room:moveCardTo(Fk:getCardById(id, true), Card.Void, nil, fk.ReasonJustMove, "", "", true)
    end
  end,
}
zhangfen:addSkill(wanglu)
zhangfen:addSkill(xianzhu)
zhangfen:addSkill(chaixie)
Fk:loadTranslationTable{
  ["zhangfen"] = "张奋",
  ["wanglu"] = "望橹",
  [":wanglu"] = "锁定技，准备阶段，你将【大攻车】置入你的装备区，若你的装备区内已有【大攻车】，则你执行一个额外的出牌阶段。<br>"..
  "<font color='grey'>【大攻车】<br>♠9 装备牌·宝物<br /><b>装备技能</b>：出牌阶段开始时，你可以视为使用一张【杀】，"..
  "当此【杀】对目标角色造成伤害后，你弃置其一张牌。若此牌未升级，则不能被弃置。离开装备区时销毁。",
  ["xianzhu"] = "陷筑",
  [":xianzhu"] = "当你使用【杀】造成伤害后，你可以升级【大攻车】（每个【大攻车】最多升级5次）。升级选项：<br>"..
  "【大攻车】的【杀】无视距离和防具；<br>【大攻车】的【杀】可指定目标+1；<br>【大攻车】的【杀】造成伤害后弃牌数+1。",
  ["chaixie"] = "拆械",
  [":chaixie"] = "锁定技，当【大攻车】销毁后，你摸X张牌（X为该【大攻车】的升级次数）。",
  ["#xianzhu-choice"] = "陷筑：选择【大攻车】使用【杀】的增益效果",
  ["xianzhu1"] = "无视距离和防具",
  ["xianzhu2"] = "可指定目标+1",
  ["xianzhu3"] = "造成伤害后弃牌数+1",
  
  ["$wanglu1"] = "大攻车前，坚城弗当。",
  ["$wanglu2"] = "大攻既作，天下可望！",
  ["$xianzhu1"] = "敌垒已陷，当长驱直入！",
  ["$xianzhu2"] = "舍命陷登，击蛟蟒于狂澜！",
  ["$chaixie1"] = "利器经久，拆合自用。",
  ["$chaixie2"] = "损一得十，如鲸落宇。",
  ["~zhangfen"] = "身陨外，愿魂归江东……",
}

--高山仰止：王朗 刘徽
local wanglang = General(extension, "ty__wanglang", "wei", 3)
local ty__gushe = fk.CreateActiveSkill{
  name = "ty__gushe",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  can_use = function(self, player)
    return not player:isKongcheng() and player:getMark("ty__gushe-turn") < 7 - player:getMark("@ty__raoshe")
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected < 3 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.map(effect.tos, function(p) return room:getPlayerById(p) end)
    local pindian = player:pindian(targets, self.name)
    for _, target in ipairs(targets) do
      local losers = {}
      if pindian.results[target.id].winner then
        if pindian.results[target.id].winner == player then
          table.insert(losers, target)
        else
          table.insert(losers, player)
        end
      else
        table.insert(losers, player)
        table.insert(losers, target)
      end
      for _, p in ipairs(losers) do
        if p == player then
          room:addPlayerMark(player, "@ty__raoshe", 1)
          if player:getMark("@ty__raoshe") >= 7 then
            room:killPlayer({who = player.id,})
          end
        end
        local cancelable = true
        local prompt = "#ty__gushe-discard:"..player.id
        if player.dead then
          cancelable = false
          prompt = "#ty__gushe2-discard"
        end
        if #room:askForDiscard(p, 1, 1, true, self.name, cancelable, ".", prompt) == 0 and not player.dead then
          player:drawCards(1, self.name)
        end
      end
    end
  end,
}
local ty__gushe_record = fk.CreateTriggerSkill{
  name = "#ty__gushe_record",

  refresh_events = {fk.PindianResultConfirmed},
  can_refresh = function(self, event, target, player, data)
    return data.winner and data.winner == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "ty__gushe-turn", 1)
    if player:getMark("ty__gushe-turn") >= (7 - player:getMark("@ty__raoshe")) and player:hasSkill("ty__gushe", true) then
      room:setPlayerMark(player, "@@ty__gushe-turn", 1)
    end
  end,
}
local ty__jici = fk.CreateTriggerSkill{
  name = "ty__jici",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.PindianCardsDisplayed, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if event == fk.PindianCardsDisplayed then
      if player:hasSkill(self.name) then
        if data.from == player then
          return data.fromCard.number <= player:getMark("@ty__raoshe")
        elseif table.contains(data.tos, player) then
          return data.results[player.id].toCard.number <= player:getMark("@ty__raoshe")
        end
      end
    elseif event == fk.Death then
      return target == player and player:hasSkill(self.name, false, true) and data.damage and data.damage.from and not data.damage.from.dead
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PindianCardsDisplayed then
      local card
      if data.from == player then
        card = data.fromCard
      elseif table.contains(data.tos, player) then
        card = data.results[player.id].toCard
      end
      card.number = card.number + player:getMark("@ty__raoshe")
      if player.dead then return end
      local n = card.number
      if data.fromCard.number > n then
        n = data.fromCard.number
      end
      for _, result in pairs(data.results) do
        if result.toCard.number > n then
          n = result.toCard.number
        end
      end
      local cards = {}
      if data.fromCard.number == n and room:getCardArea(data.fromCard) == Card.Processing then
        table.insertIfNeed(cards, data.fromCard)
      end
      for _, result in pairs(data.results) do
        if result.toCard.number == n and room:getCardArea(data.fromCard) == Card.Processing then
          table.insertIfNeed(cards, result.toCard)
        end
      end
      if #cards > 0 then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(cards)
        room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
      end
    elseif event == fk.Death then
      local n = 7 - player:getMark("@ty__raoshe")
      if n > 0 and not data.damage.from:isNude() then
        if #data.damage.from:getCardIds{Player.Hand, Player.Equip} <= n then
          data.damage.from:throwAllCards("he")
        else
          room:askForDiscard(data.damage.from, n, n, true, self.name, false)
        end
      end
      if not data.damage.from.dead then
        room:loseHp(data.damage.from, 1, self.name)
      end
    end
  end,
}
ty__gushe:addRelatedSkill(ty__gushe_record)
wanglang:addSkill(ty__gushe)
wanglang:addSkill(ty__jici)
Fk:loadTranslationTable{
  ["ty__wanglang"] = "王朗",
  ["ty__gushe"] = "鼓舌",
  [":ty__gushe"] = "出牌阶段，你可以用一张手牌与至多三名角色同时拼点，没赢的角色选择一项: 1.弃置一张牌；2.令你摸一张牌。"..
  "若你没赢，获得一个“饶舌”标记；若你有7个“饶舌”标记，你死亡。当你一回合内累计七次拼点赢时（每有一个“饶舌”标记，此累计次数减1），本回合此技能失效。",
  ["ty__jici"] = "激词",
  [":ty__jici"] = "锁定技，当你的拼点牌亮出后，若此牌点数小于等于X，则点数+X（X为“饶舌”标记的数量）且你获得本次拼点中点数最大的牌。"..
  "你死亡时，杀死你的角色弃置7-X张牌并失去1点体力。",
  ["#ty__gushe-discard"] = "鼓舌：你需弃置一张牌，否则 %src 摸一张牌",
  ["#ty__gushe2-discard"] = "鼓舌：你需弃置一张牌",
  ["@@ty__gushe-turn"] = "鼓舌失效",
  ["@ty__raoshe"] = "饶舌",

  ["$ty__gushe1"] = "承寇贼之要，相时而后动，择地而后行，一举更无余事。",
  ["$ty__gushe2"] = "春秋之义，求诸侯莫如勤王。今天王在魏都，宜遣使奉承王命。",
  ["$ty__jici1"] = "天数有变，神器更易，而归于有德之人，此自然之理也。",
  ["$ty__jici2"] = "王命之师，囊括五湖，席卷三江，威取中国，定霸华夏。",
  ["~ty__wanglang"] = "我本东海弄墨客，如何枉做沙场魂……",
}

--钟灵毓秀：董贵人 滕芳兰 张瑾云 周不疑
local dongguiren = General(extension, "dongguiren", "qun", 3, 3, General.Female)
local lianzhi = fk.CreateTriggerSkill{
  name = "lianzhi",
  anim_type = "special",
  events = {fk.GameStart, fk.BeforeGameOverJudge},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        return player:getMark(self.name) == target.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
    if event == fk.GameStart then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#lianzhi-choose", self.name, false)
      if #to > 0 then
        to = room:getPlayerById(to[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:setPlayerMark(player, self.name, to.id)
      room:setPlayerMark(to, "@@lianzhi", 1)
    else
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#lianzhi2-choose", self.name, true)
      if #to > 0 then
        to = room:getPlayerById(to[1])
        room:handleAddLoseSkills(player, "shouze", nil, true, false)
        room:handleAddLoseSkills(to, "shouze", nil, true, false)
        room:addPlayerMark(to, "@dongguiren_jiao", math.max(player:getMark("@dongguiren_jiao"), 1))
      end
    end
  end,
}
local lianzhi_trigger = fk.CreateTriggerSkill{
  name = "#lianzhi_trigger",
  mute = true,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("lianzhi") and player:getMark("lianzhi") ~= 0 and
      not player.room:getPlayerById(player:getMark("lianzhi")).dead and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("lianzhi")
    room:notifySkillInvoked(player, "lianzhi", "support")
    local to = player:getMark("lianzhi")
    room:doIndicate(player.id, {to})
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = "lianzhi"
    })
    if not player.dead then
      player:drawCards(1, "lianzhi")
      room:getPlayerById(to):drawCards(1, "lianzhi")
    end
  end,
}
local lingfang = fk.CreateTriggerSkill{
  name = "lingfang",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.EventPhaseStart then
      return player == target and player.phase == Player.Start
    elseif event == fk.CardUseFinished then
      if data.card.color == Card.Black and data.tos then
        if target == player then
          return table.find(TargetGroup:getRealTargets(data.tos), function(id) return id ~= player.id end)
        else
          return table.contains(TargetGroup:getRealTargets(data.tos), player.id)
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@dongguiren_jiao", 1)
  end,
}
local fengying = fk.CreateViewAsSkill{
  name = "fengying",
  anim_type = "special",
  pattern = ".",
  prompt = "#fengying",
  interaction = function()
    local all_names, names = Self:getMark("fengying"), {}
    for _, name in ipairs(all_names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = "fengying"
      if ((Fk.currentResponsePattern == nil and to_use.skill:canUse(Self, to_use) and not Self:prohibitUse(to_use)) or
         (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
        table.insertIfNeed(names, name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).number <= Self:getMark("@dongguiren_jiao") and
      Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    local names = player:getMark("fengying")
    if player:getMark("@dongguiren_jiao") == 0 or type(names) ~= "table" then return false end
    for _, name in ipairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = self.name
      if to_use.skill:canUse(player, to_use) and not player:prohibitUse(to_use) then
        return true
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return false end
    local names = player:getMark("fengying")
    if player:getMark("@dongguiren_jiao") == 0 or type(names) ~= "table" then return false end
    for _, name in ipairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = self.name
      if (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use)) then
        return true
      end
    end
  end,
  before_use = function(self, player, useData)
    local names = player:getMark("fengying")
    if type(names) == "table" then
      table.removeOne(names, useData.card.name)
      player.room:setPlayerMark(player, "fengying", names)
      player.room:setPlayerMark(player, "@$fengying", names)
    end
  end,
}
local fengying_trigger = fk.CreateTriggerSkill{
  name = "#fengying_trigger",
  events = {fk.TurnStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fengying.name)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local names = {}
    for _, id in ipairs(player.room.discard_pile) do
      local card = Fk:getCardById(id)
      if card.color == Card.Black and (card.type == Card.TypeBasic or card:isCommonTrick()) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    player.room:setPlayerMark(player, "fengying", names)
    if player:hasSkill("fengying", true) then
      player.room:setPlayerMark(player, "@$fengying", names)
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data.name == "fengying"
  end,
  on_refresh = function(self, event, target, player, data)
      player.room:setPlayerMark(player, "fengying", 0)
      player.room:setPlayerMark(player, "@$fengying", 0)
  end,
}
local fengying_targetmod = fk.CreateTargetModSkill{
  name = "#fengying_targetmod",
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, "fengying")
  end,
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "fengying")
  end,
}
local shouze = fk.CreateTriggerSkill{
  name = "shouze",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and player:getMark("@dongguiren_jiao") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@dongguiren_jiao", 1)
    local card = room:getCardsFromPileByRule(".|.|spade,club", 1, "discardPile")
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
    room:loseHp(player, 1, self.name)
  end,
}
lianzhi:addRelatedSkill(lianzhi_trigger)
fengying:addRelatedSkill(fengying_trigger)
fengying:addRelatedSkill(fengying_targetmod)
dongguiren:addSkill(lianzhi)
dongguiren:addSkill(lingfang)
dongguiren:addSkill(fengying)
dongguiren:addRelatedSkill(shouze)
Fk:loadTranslationTable{
  ["dongguiren"] = "董贵人",
  ["lianzhi"] = "连枝",
  [":lianzhi"] = "游戏开始时，你选择一名其他角色。每回合限一次，当你进入濒死状态时，若该角色没有死亡，你回复1点体力且与其各摸一张牌。"..
  "该角色死亡时，你可以选择一名其他角色，你与其获得〖受责〗，其获得与你等量的“绞”标记（至少1个）。",
  ["lingfang"] = "凌芳",
  [":lingfang"] = "锁定技，准备阶段或当其他角色对你使用或你对其他角色使用的黑色牌结算后，你获得一枚“绞”标记。",
  ["fengying"] = "风影",
  ["#fengying_trigger"] = "风影",
  [":fengying"] = "每个回合开始时，记录此时弃牌堆中的黑色基本牌和黑色普通锦囊牌牌名。"..
  "每回合每种牌名限一次，你可以将一张点数不大于“绞”标记数的手牌当一张记录的牌使用，且无距离和次数限制。",
  ["shouze"] = "受责",
  [":shouze"] = "锁定技，结束阶段，你弃置一枚“绞”，然后随机获得弃牌堆一张黑色牌并失去1点体力。",
  ["@@lianzhi"] = "连枝",
  ["#lianzhi-choose"] = "连枝：选择一名角色成为“连枝”角色",
  ["#lianzhi2-choose"] = "连枝：你可以选择一名角色，你与其获得技能〖受责〗",
  ["@dongguiren_jiao"] = "绞",
  ["@$fengying"] = "风影",
  ["#fengying"] = "发动风影，将一张点数不大于绞标记数的手牌当一张记录的牌使用",

  ["$lianzhi1"] = "刘董同气连枝，一损则俱损。",
  ["$lianzhi2"] = "妾虽女流，然亦有忠侍陛下之心。",
  ["$lingfang1"] = "曹贼欲加之罪，何患无据可言。",
  ["$lingfang2"] = "花落水自流，何须怨东风。",
  ["$fengying1"] = "可怜东篱寒累树，孤影落秋风。",
  ["$fengying2"] = "西风落，西风落，宫墙不堪破。",
  ["~dongguiren"] = "陛下乃大汉皇帝，不可言乞。",
}

local tengfanglan = General(extension, "ty__tengfanglan", "wu", 3, 3, General.Female)
local ty__luochong = fk.CreateTriggerSkill{
  name = "ty__luochong",
  anim_type = "control",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:getMark(self.name) < 4 and
      not table.every(player.room.alive_players, function (p) return p:isAllNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p) return not p:isAllNude() end), function(p) return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1,
      "#ty__luochong-choose:::"..tostring(4 - player:getMark(self.name))..":"..tostring(4 - player:getMark(self.name)), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local total = 4 - player:getMark(self.name)
    local n = total
    local to = room:getPlayerById(self.cost_data)
    repeat
      local cards = room:askForCardsChosen(player, to, 1, n, "hej", self.name)
      if #cards > 0 then
        room:throwCard(cards, self.name, to, player)
        room:addPlayerMark(to, "ty__luochong_target", #cards)
        n = n - #cards
        if n <= 0 then break end
      end
      local targets = table.map(table.filter(room.alive_players, function(p)
        return not p:isAllNude() end), function(p) return p.id end)
      if #targets == 0 then break end
      local tos = room:askForChoosePlayers(player, targets, 1, 1,
        "#ty__luochong-choose:::"..tostring(total)..":"..tostring(n), self.name, true)
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        break
      end
    until total == 0 or player.dead
    if table.find(room.players, function(p) return p:getMark("ty__luochong_target") > 2 end) then
      room:addPlayerMark(player, self.name, 1)
    end
    for _, p in ipairs(room.players) do
      room:setPlayerMark(p, "ty__luochong_target", 0)
    end
  end,
}
local ty__aichen = fk.CreateTriggerSkill{
  name = "ty__aichen",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.EventPhaseChanging, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AfterCardsMove and #player.room.draw_pile > 80 and player:usedSkillTimes(self.name, Player.HistoryRound) == 0 then
        for _, move in ipairs(data) do
          if move.skillName == "ty__luochong" and move.from == player.id then
            return true
          end
        end
      elseif event == fk.EventPhaseChanging and #player.room.draw_pile > 40 then
        return target == player and data.to == Player.Discard
      elseif event == fk.TargetConfirmed and #player.room.draw_pile < 40 then
        return target == player and data.card.type ~= Card.TypeEquip and data.card.suit == Card.Spade
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      player:drawCards(2, self.name)
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "drawcard")
    elseif event == fk.EventPhaseChanging then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "defensive")
      return true
    elseif event == fk.TargetConfirmed then
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
      data.disresponsiveList = data.disresponsiveList or {}
      table.insertIfNeed(data.disresponsiveList, player.id)
    end
  end,
}
tengfanglan:addSkill(ty__luochong)
tengfanglan:addSkill(ty__aichen)
Fk:loadTranslationTable{
  ["ty__tengfanglan"] = "滕芳兰",
  ["ty__luochong"] = "落宠",
  [":ty__luochong"] = "每轮开始时，你可以弃置任意名角色区域内共计至多4张牌，若你一次性弃置了一名角色区域内至少3张牌，〖落宠〗弃置牌数-1。",
  ["ty__aichen"] = "哀尘",
  [":ty__aichen"] = "锁定技，若剩余牌堆数大于80，当你发动〖落宠〗弃置自己区域内的牌后，你摸两张牌；"..
  "若剩余牌堆数大于40，你跳过弃牌阶段；若剩余牌堆数小于40，当你成为♠牌的目标后，你不能响应此牌。",
  ["#ty__luochong-choose"] = "落宠：你可以依次选择角色，弃置其区域内的牌（共计至多%arg张，还剩%arg2张）",

  ["$ty__luochong1"] = "陛下独宠她人，奈何雨露不均？",
  ["$ty__luochong2"] = "妾贵于佳丽，然宠不及三千。",
  ["$ty__aichen1"] = "君可负妾，然妾不负君。",
  ["$ty__aichen2"] = "所思所想，皆系陛下。",
  ["~ty__tengfanglan"] = "今生缘尽，来世两宽……",
}

local zhangjinyun = General(extension, "zhangjinyun", "shu", 3, 3, General.Female)
local huizhi = fk.CreateTriggerSkill{
  name = "huizhi",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local discard_data = {
      num = 999,
      min_num = 0,
      include_equip = false,
      skillName = self.name,
      pattern = ".",
    }
    local success, ret = player.room:askForUseActiveSkill(player, "discard_skill", "#huizhi-invoke", true, discard_data)
    if success then
      self.cost_data = ret.cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #self.cost_data > 0 then
      room:throwCard(self.cost_data, self.name, player, player)
    end
    local n = player:getHandcardNum()
    for _, p in ipairs(room:getAlivePlayers()) do
      if #p.player_cards[Player.Hand] > n then
        n = #p.player_cards[Player.Hand]
      end
    end
    if n > player:getHandcardNum() then
      player:drawCards(math.min(n - player:getHandcardNum()), 5)
    else
      player:drawCards(1, self.name)
    end
  end,
}
local jijiao = fk.CreateActiveSkill{
  name = "jijiao",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and #Fk:currentRoom().discard_pile > 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local ids = {}
    local discard_pile = table.simpleClone(room.discard_pile)
    local logic = room.logic
    local events = logic.event_recorder[GameEvent.MoveCards] or Util.DummyTable
    for i = #events, 1, -1 do
      local e = events[i]
      local move_by_use = false
      local parentUseEvent = e:findParent(GameEvent.UseCard)
      if parentUseEvent then
        local use = parentUseEvent.data[1]
        if use.from == effect.from then
          move_by_use = true
        end
      end
      for _, move in ipairs(e.data) do
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.removeOne(discard_pile, id) and Fk:getCardById(id):isCommonTrick() then
            if move.toArea == Card.DiscardPile then
              if move.moveReason == fk.ReasonUse and move_by_use then
                table.insert(ids, id)
              elseif move.moveReason == fk.ReasonDiscard and move.from == player.id then
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  table.insert(ids, id)
                end
              end
            end
          end
        end
      end
      if #discard_pile == 0 then break end
    end

    if #ids > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(ids)
      room:setPlayerMark(player, "jijiao_cards", dummy.subcards)
      room:obtainCard(target.id, dummy, true, fk.ReasonJustMove)
    end
  end,
}
local jijiao_record = fk.CreateTriggerSkill{
  name = "#jijiao_record",
  anim_type = "special",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:getMark(self.name) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
    player:setSkillUseHistory("jijiao", 0, Player.HistoryGame)
  end,

  refresh_events = {fk.AfterDrawPileShuffle, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return player:usedSkillTimes("jijiao", Player.HistoryGame) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 1)
  end,
}
local jijiao_trigger = fk.CreateTriggerSkill{
  name = "#jijiao_trigger",
  mute = true,
  events = {fk.CardUsing, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:getMark("jijiao_cards") ~= 0 and #player:getMark("jijiao_cards") > 0 then
      if event == fk.CardUsing then
        return target == player and data.card:isCommonTrick() and not data.card:isVirtual()
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then  --TODO: 这也弄个全局记录！
      local mark = player:getMark("jijiao_cards")
      if table.contains(mark, data.card.id) then
        data.prohibitedCardNames = {"nullification"}
        table.removeOne(mark, data.card.id)
        room:setPlayerMark(player, "jijiao_cards", mark)
      end
    else
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              local mark = player:getMark("jijiao_cards")
              if table.contains(mark, info.cardId) then
                table.removeOne(mark, info.cardId)
                room:setPlayerMark(player, "jijiao_cards", mark)
              end
            end
          end
        end
      end
    end
  end,
}
jijiao:addRelatedSkill(jijiao_record)
jijiao:addRelatedSkill(jijiao_trigger)
zhangjinyun:addSkill(huizhi)
zhangjinyun:addSkill(jijiao)
Fk:loadTranslationTable{
  ["zhangjinyun"] = "张瑾云",
  ["huizhi"] = "蕙质",
  [":huizhi"] = "摸牌阶段结束时，你可以弃置任意张手牌（可不弃），然后将手牌摸至与全场手牌最多的角色相同（至少摸一张，最多摸五张）。",
  ["jijiao"] = "继椒",
  [":jijiao"] = "限定技，出牌阶段，你可以令一名角色获得弃牌堆中本局游戏你使用和弃置的所有普通锦囊牌，这些牌不能被【无懈可击】响应。"..
  "每回合结束后，若此回合内牌堆洗过牌或有角色死亡，复原此技能。",
  ["#huizhi-invoke"] = "蕙质：你可以弃置任意张手牌，然后将手牌摸至与全场手牌最多的角色相同（最多摸五张）",
  ["#jijiao_record"] = "继椒",

  ["$huizhi1"] = "妾有一席幽梦，予君三千暗香。",
  ["$huizhi2"] = "我有玲珑之心，其情唯衷陛下。",
  ["$jijiao1"] = "哀吾姊早逝，幸陛下垂怜。",
  ["$jijiao2"] = "居椒之殊荣，妾得之惶恐。",
  ["~zhangjinyun"] = "陛下，妾身来陪你了……",
}

local zhoubuyi = General(extension, "zhoubuyi", "wei", 3)
local shijiz = fk.CreateTriggerSkill{
  name = "shijiz",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target.phase == Player.Finish and not target:isNude() then
      local events = player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
        local damage = e.data[5]
        return damage and target == damage.from
      end, Player.HistoryTurn)
      return #events == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("shijiz_names")
    if type(mark) ~= "table" then
      mark = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id)
        if card:isCommonTrick() and not card.is_derived then
          table.insertIfNeed(mark, card.name)
        end
      end
      room:setPlayerMark(player, "shijiz_names", mark)
    end
    local mark2 = player:getMark("@$shijiz-round")
    if mark2 == 0 then mark2 = {} end
    local names, choices = {}, {}
    for _, name in ipairs(mark) do
      local card = Fk:cloneCard(name)
      card.skillName = self.name
      if target:canUse(card) and not target:prohibitUse(card) then
        table.insert(names, name)
        if not table.contains(mark2, name) then
          table.insert(choices, name)
        end
      end
    end
    table.insert(names, "Cancel")
    table.insert(choices, "Cancel")
    local choice = room:askForChoice(player, choices, self.name, "#shijiz-invoke::"..target.id, false, names)
    if choice ~= "Cancel" then
      room:doIndicate(player.id, {target.id})
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@$shijiz-round")
    if mark == 0 then mark = {} end
    table.insert(mark, self.cost_data)
    room:setPlayerMark(player, "@$shijiz-round", mark)
    room:doIndicate(player.id, {target.id})
    room:setPlayerMark(target, "shijiz-tmp", self.cost_data)
    local success, dat = room:askForUseViewAsSkill(target, "shijiz_viewas", "#shijiz-use:::"..self.cost_data, true)
    room:setPlayerMark(target, "shijiz-tmp", 0)
    if success then
      local card = Fk:cloneCard(self.cost_data)
      card:addSubcards(dat.cards)
      card.skillName = self.name
      room:useCard{
        from = target.id,
        tos = table.map(dat.targets, function(p) return {p} end),
        card = card,
      }
    end
  end,
}
local shijiz_viewas = fk.CreateViewAsSkill{
  name = "shijiz_viewas",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getMark("shijiz-tmp") ~= 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(Self:getMark("shijiz-tmp"))
    card:addSubcard(cards[1])
    card.skillName = "shijiz"
    return card
  end,
}
local shijiz_prohibit = fk.CreateProhibitSkill{
  name = "#shijiz_prohibit",
  is_prohibited = function(self, from, to, card)
    return card and from == to and table.contains(card.skillNames, "shijiz")
  end,
}
local silun = fk.CreateTriggerSkill{
  name = "silun",
  anim_type = "masochism",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start
      else
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(4, self.name)
    for i = 1, 4, 1 do
      if player.dead or player:isNude() then return end
      local success, _ = room:askForUseActiveSkill(player, "silun_active", "#silun-card:::" .. tostring(i), false)
      if not success then
        room:moveCards({
          ids = {player:getCardIds("he")[1]},
          from = player.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = self.name,
        })
      end
    end
  end,
}
local silun_active = fk.CreateActiveSkill{
  name = "silun_active",
  mute = true,
  card_num = 1,
  max_target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"Field", "Top", "Bottom"}}
  end,
  card_filter = function(self, to_select, selected, targets)
    if #selected == 0 then
      if self.interaction.data == "Field" then
        local card = Fk:getCardById(to_select)
        return card.type == Card.TypeEquip or card.sub_type == Card.SubtypeDelayedTrick
      end
      return true
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and self.interaction.data == "Field" and #selected_cards == 1 then
      local card = Fk:getCardById(selected_cards[1])
      local target = Fk:currentRoom():getPlayerById(to_select)
      if card.type == Card.TypeEquip then
        return target:hasEmptyEquipSlot(card.sub_type)
      elseif card.sub_type == Card.SubtypeDelayedTrick then
        return not target:isProhibited(target, card)
      end
      return false
    end
  end,
  feasible = function(self, selected, selected_cards)
    if #selected_cards == 1 then
      if self.interaction.data == "Field" then
        return #selected == 1
      else
        return true
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card_id = effect.cards[1]
    local reset_self = room:getCardArea(card_id) == Card.PlayerEquip
    if self.interaction.data == "Field" then
      local target = room:getPlayerById(effect.tos[1])
      local card = Fk:getCardById(card_id)
      if card.type == Card.TypeEquip then
        room:moveCardTo(card, Card.PlayerEquip, target, fk.ReasonPut, "silun", "", true, player.id)
        if reset_self and not player.dead then
          if player.chained then
            player:setChainState(false)
          end
          if not player.dead and not player.faceup then
            player:turnOver()
          end
        end
        if not target.dead then
          if target.chained then
            target:setChainState(false)
          end
          if not target.dead and not target.faceup then
            target:turnOver()
          end
        end
      elseif card.sub_type == Card.SubtypeDelayedTrick then
        room:moveCardTo(card, Card.PlayerJudge, target, fk.ReasonPut, "silun", "", true, player.id)
        if reset_self and not player.dead then
          if player.chained then
            player:setChainState(false)
          end
          if not player.dead and not player.faceup then
            player:turnOver()
          end
        end
      end
    else
      local drawPilePosition = 1
      if self.interaction.data == "Bottom" then
        drawPilePosition = -1
      end
      room:moveCards({
        ids = effect.cards,
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = "silun",
        drawPilePosition = drawPilePosition,
      })
      if reset_self and not player.dead then
        if player.chained then
          player:setChainState(false)
        end
        if not player.dead and not player.faceup then
          player:turnOver()
        end
      end
    end
  end,
}
Fk:addSkill(shijiz_viewas)
shijiz:addRelatedSkill(shijiz_prohibit)
Fk:addSkill(silun_active)
zhoubuyi:addSkill(shijiz)
zhoubuyi:addSkill(silun)
Fk:loadTranslationTable{
  ["zhoubuyi"] = "周不疑",
  ["shijiz"] = "十计",
  [":shijiz"] = "一名角色的结束阶段，若其本回合未造成伤害，你可以声明一种普通锦囊牌（每轮每种牌名限一次），其可以将一张牌当你声明的牌使用"..
  "（不能指定其为目标）。",
  ["silun"] = "四论",
  [":silun"] = "准备阶段或当你受到伤害后，你可以摸四张牌，然后将四张牌依次置于场上、牌堆顶或牌堆底，若此牌为你装备区里的牌，你复原武将牌，"..
  "若你将装备牌置于一名角色装备区，其复原武将牌。",
  ["@$shijiz-round"] = "十计",
  ["#shijiz-invoke"] = "十计：你可以选择一种锦囊，令 %dest 可以将一张牌当此牌使用（不能指定其自己为目标）",
  ["shijiz_viewas"] = "十计",
  ["#shijiz-use"] = "十计：你可以将一张牌当【%arg】使用",
  ["silun_active"] = "四论",
  ["#silun-card"] = "四论：将一张牌置于场上、牌堆顶或牌堆底（第%arg张/共4张）",
  ["Field"] = "场上",

  ["$shijiz1"] = "区区十丈之城，何须丞相图画。",
  ["$shijiz2"] = "顽垒在前，可依不疑之计施为。",
  ["$silun1"] = "习守静之术，行务时之风。",
  ["$silun2"] = "纵笔瑞白雀，满座尽高朋。",
  ["~zhoubuyi"] = "人心者，叵测也。",
}

--武庙：诸葛亮
local zhugeliang = General(extension, "wm__zhugeliang", "shu", 4, 7)
local jincui = fk.CreateTriggerSkill{
  name = "jincui",
  anim_type = "control",
  frequency = Skill.Compulsory,
  mute = true,
  events = {fk.EventPhaseStart, fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self.name) and player:getHandcardNum() < 7
    elseif event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self.name) and player.phase == Player.Start
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)
      local n = 7 - player:getHandcardNum()
      if n > 0 then
        player:drawCards(n, self.name)
      end
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name)
      player:broadcastSkillInvoke(self.name)
      local n = 0
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).number == 7 then
          n = n + 1
        end
      end
      n = math.max(n, 1)
      if player.hp > n then
        room:loseHp(player, player.hp - n, self.name)
      elseif player.hp < n then
        room:recover({
          who = player,
          num = math.min(n - player.hp, player:getLostHp()),
          recoverBy = player,
          skillName = self.name
        })
      end
      room:askForGuanxing(player, room:getNCards(player.hp))
    end
  end,
}
local qingshi = fk.CreateTriggerSkill{
  name = "qingshi",
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getMark("@@qingshi-turn") == 0 and
      table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == data.card.trueName end) and
      (player:getMark("@$qingshi-turn") == 0 or not table.contains(player:getMark("@$qingshi-turn"), data.card.trueName))
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"qingshi2", "qingshi3", "Cancel"}
    if data.card.is_damage_card and data.tos then
      table.insert(choices, 1, "qingshi1")
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#qingshi-invoke:::"..data.card:toLogString())
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@$qingshi-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, data.card.trueName)
    room:setPlayerMark(player, "@$qingshi-turn", mark)
    if self.cost_data == "qingshi1" then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name)
      local to = room:askForChoosePlayers(player, TargetGroup:getRealTargets(data.tos), 1, 1,
        "#qingshi1-choose:::"..data.card:toLogString(), self.name, false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(TargetGroup:getRealTargets(data.tos))
      end
      data.extra_data = data.extra_data or {}
      data.extra_data.qingshi = to
    elseif self.cost_data == "qingshi2" then
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(self.name)
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 10, "#qingshi2-choose", self.name, false)
      if #tos == 0 then
        tos = table.random(targets, 1)
      end
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    elseif self.cost_data == "qingshi3" then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)
      player:drawCards(3, self.name)
      room:setPlayerMark(player, "@@qingshi-turn", 1)
    end
  end,

  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        return use.extra_data and use.extra_data.qingshi and data.to.id == use.extra_data.qingshi
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local zhizhe = fk.CreateActiveSkill{
  name = "zhizhe",
  prompt = "#zhizhe-active",
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and not Fk:getCardById(to_select).is_derived
  end,
  on_use = function(self, room, effect)
    local c = Fk:getCardById(effect.cards[1], true)
    local toGain = room:printCard(c.name, c.suit, c.number)
    room:moveCards({
      ids = {toGain.id},
      to = effect.from,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      proposer = effect.from,
      skillName = self.name,
      moveVisible = false,
    })
  end
}
local zhizhe_trigger = fk.CreateTriggerSkill{
  name = "#zhizhe_trigger",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    local mark = player:getMark("zhizhe")
    if type(mark) ~= "table" then return false end
    local room = player.room
    local move_event = room.logic:getCurrentEvent()
    local parent_event = move_event.parent
    if parent_event and (parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard) then
      local parent_data = parent_event.data[1]
      if parent_data.from == player.id then
        local card_ids = room:getSubcardsByRule(parent_data.card)
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              local id = info.cardId
              if info.fromArea == Card.Processing and room:getCardArea(id) == Card.DiscardPile and
              table.contains(card_ids, id) and table.contains(mark, id) then
                return true
              end
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
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(zhizhe.name)
    local mark = player:getMark("zhizhe")
    local to_get = {}
    if type(mark) ~= "table" then return false end
    local move_event = room.logic:getCurrentEvent():findParent(GameEvent.MoveCards, true)
    local parent_event = move_event.parent
    if parent_event and (parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard) then
      local parent_data = parent_event.data[1]
      if parent_data.from == player.id then
        local card_ids = room:getSubcardsByRule(parent_data.card)
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              local id = info.cardId
              if info.fromArea == Card.Processing and room:getCardArea(id) == Card.DiscardPile and
              table.contains(card_ids, id) and table.contains(mark, id) then
                table.insertIfNeed(to_get, id)
              end
            end
          end
        end
      end
    end
    if #to_get > 0 then
      room:moveCards({
        ids = to_get,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = zhizhe.name,
        moveVisible = false,
      })
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local marked = type(player:getMark("zhizhe")) == "table" and player:getMark("zhizhe") or {}
    local marked2 = type(player:getMark("zhizhe-turn")) == "table" and player:getMark("zhizhe-turn") or {}
    marked2 = table.filter(marked2, function (id)
      return room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player
    end)
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == zhizhe.name then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            if info.fromArea == Card.Void then
              table.insertIfNeed(marked, id)
            else
              table.insert(marked2, id)
            end
            room:setCardMark(Fk:getCardById(id), "@@zhizhe-inhand", 1)
          end
        end
      elseif move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          table.removeOne(marked, id)
        end
      end
    end
    room:setPlayerMark(player, "zhizhe", marked)
    room:setPlayerMark(player, "zhizhe-turn", marked2)
  end,
}
local zhizhe_prohibit = fk.CreateProhibitSkill{
  name = "#zhizhe_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getMark("zhizhe-turn")
    if type(mark) ~= "table" then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return table.contains(mark, id) end)
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getMark("zhizhe-turn")
    if type(mark) ~= "table" then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return table.contains(mark, id) end)
  end,
}
zhizhe:addRelatedSkill(zhizhe_trigger)
zhizhe:addRelatedSkill(zhizhe_prohibit)
zhugeliang:addSkill(jincui)
zhugeliang:addSkill(qingshi)
zhugeliang:addSkill(zhizhe)
Fk:loadTranslationTable{
  ["wm__zhugeliang"] = "诸葛亮",
  ["jincui"] = "尽瘁",
  [":jincui"] = "锁定技，游戏开始时，你将手牌补至7张。准备阶段，你的体力值调整为与牌堆中点数为7的游戏牌数量相等（至少为1）。"..
  "然后你观看牌堆顶X张牌（X为你的体力值），将这些牌以任意顺序放回牌堆顶或牌堆底。",
  ["qingshi"] = "情势",
  [":qingshi"] = "当你于出牌阶段内使用一张牌时（每种牌名每回合限一次），若手牌中有同名牌，你可以选择一项：1.令此牌对其中一个目标造成的伤害值+1："..
  "2.令任意名其他角色各摸一张牌；3.摸三张牌，然后此技能本回合失效。",
  ["zhizhe"] = "智哲",
  [":zhizhe"] = "限定技，出牌阶段，你可以复制一张手牌（衍生牌除外）。此牌因你使用或打出而进入弃牌堆，你从弃牌堆获得且本回合不能再使用或打出之。",
  ["@$qingshi-turn"] = "情势",
  ["@@qingshi-turn"] = "情势失效",
  ["#qingshi-invoke"] = "情势：请选择一项（当前使用牌为%arg）",
  ["qingshi1"] = "令此牌对其中一个目标伤害+1",
  ["qingshi2"] = "令任意名其他角色各摸一张牌",
  ["qingshi3"] = "摸三张牌，然后此技能本回合失效",
  ["#qingshi1-choose"] = "情势：令%arg对其中一名目标造成伤害+1",
  ["#qingshi2-choose"] = "情势：令任意名其他角色各摸一张牌",
  ["#zhizhe_trigger"] = "智哲",
  ["#zhizhe-active"] = "发动 智哲，选择一张手牌（衍生牌除外），获得一张此牌的复制",
  ["@@zhizhe-inhand"] = "智哲",

  ["$jincui1"] = "情记三顾之恩，亮必继之以死。",
  ["$jincui2"] = "身负六尺之孤，臣当鞠躬尽瘁。",
  ["$qingshi1"] = "兵者，行霸道之势，彰王道之实。",
  ["$qingshi2"] = "将为军魂，可因势而袭，其有战无类。",
  ["$zhizhe1"] = "轻舟载浊酒，此去，我欲借箭十万。",
  ["$zhizhe2"] = "主公有多大胆略，亮便有多少谋略。",
  ["~wm__zhugeliang"] = "天下事，了犹未了，终以不了了之……",
}

return extension
