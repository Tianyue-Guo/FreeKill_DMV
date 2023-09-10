local extension = Package("tenyear_yj22")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_yj22"] = "十周年-一将2022",
}

--李婉 诸葛尚 陆凯 轲比能 韩龙 谯周 苏飞 武安国
local liwan = General(extension, "liwan", "wei", 3, 3, General.Female)
local liandui = fk.CreateTriggerSkill{
  name = "liandui",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) or target.dead then return false end
    local liandui_target = (data.extra_data or {}).liandui_lastplayer
    return liandui_target ~= nil and ((liandui_target == player.id) ~= (player == target))
      and not player.room:getPlayerById(liandui_target).dead
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.id
    if player == target then
      to = (data.extra_data or {}).liandui_lastplayer
    end
    if player.room:askForSkillInvoke(target, self.name, nil, "#liandui-invoke:"..player.id .. ":" .. to) then
      self.cost_data = to
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local tar = player.room:getPlayerById(self.cost_data)
    tar:drawCards(2, self.name)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local liandui_target = {}
    for _, p in ipairs(room.alive_players) do
      if p:getMark("liandui_lastplayer") > 0 then
        table.insert(liandui_target, p.id)
        room:setPlayerMark(p, "liandui_lastplayer", 0)
      end
    end
    if #liandui_target > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.liandui_lastplayer = liandui_target[1]
    end
    if not player.dead then
      room:setPlayerMark(player, "liandui_lastplayer", 1)
    end
  end,
}
local biejun = fk.CreateTriggerSkill{
  name = "biejun",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player and
      table.every(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@biejun-inhand") == 0 end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#biejun-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    return true
  end,

  refresh_events = {fk.TurnEnd, fk.EventAcquireSkill, fk.EventLoseSkill, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if event == fk.TurnEnd then
      return true
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    elseif event == fk.BuryVictim then
      return player:hasSkill(self.name, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        room:setCardMark(Fk:getCardById(id), "@@biejun-inhand", 0)
      end
    else
      if table.every(room.alive_players, function(p) return not p:hasSkill(self.name, true) or p == player end) then
        if player:hasSkill("biejun&", true, true) then
          room:handleAddLoseSkills(player, "-biejun&", nil, false, true)
        end
      else
        if not player:hasSkill("biejun&", true, true) then
          room:handleAddLoseSkills(player, "biejun&", nil, false, true)
        end
      end
    end
  end,
}
local biejun_active = fk.CreateActiveSkill{
  name = "biejun&",
  anim_type = "support",
  prompt = "#biejun-active",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local targetRecorded = player:getMark("biejun_targets-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill(biejun.name) and (type(targetRecorded) ~= "table" or not table.contains(targetRecorded, p.id))
    end)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):hasSkill(biejun.name) then
      local targetRecorded = Self:getMark("biejun_targets-phase")
      return type(targetRecorded) ~= "table" or not table.contains(targetRecorded, to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    player:broadcastSkillInvoke(biejun.name)
    local targetRecorded = type(player:getMark("biejun_targets-phase")) == "table" and player:getMark("biejun_targets-phase") or {}
    table.insertIfNeed(targetRecorded, target.id)
    room:setPlayerMark(player, "biejun_targets-phase", targetRecorded)
    local id = effect.cards[1]
    room:obtainCard(target, id, false, fk.ReasonGive)
    if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == target then
      room:setCardMark(Fk:getCardById(id), "@@biejun-inhand", 1)
    end
  end,
}
Fk:addSkill(biejun_active)
liwan:addSkill(liandui)
liwan:addSkill(biejun)
Fk:loadTranslationTable{
  ["liwan"] = "李婉",
  ["liandui"] = "联对",
  [":liandui"] = "当你使用一张牌时，若上一张牌的使用者不为你，你可以令其摸两张牌；其他角色使用一张牌时，若上一张牌的使用者为你，其可以令你摸两张牌。",
  ["biejun"] = "别君",
  [":biejun"] = "其他角色出牌阶段限一次，其可以交给你一张手牌。当你受到伤害时，若你手牌中没有本回合以此法获得的牌，你可以翻面并防止此伤害。",
  ["biejun&"] = "别君",
  [":biejun&"] = "出牌阶段限一次，你可以将一张手牌交给李婉。",
  ["#liandui-invoke"] = "联对：你可以发动 %src 的“联对”，令 %dest 摸两张牌",
  ["#biejun-invoke"] = "别君：你可以翻面，防止你受到的伤害",
  ["@@biejun-inhand"] = "别君",
  ["#biejun-active"] = "别君：选择一张手牌交给一名拥有“别君”的角色",

  ["$liandui1"] = "以句相联，抒离散之苦。",
  ["$liandui2"] = "以诗相对，颂哀怨之情。",
  ["$biejun1"] = "彼岸荼蘼远，落寞北风凉。",
  ["$biejun2"] = "此去经年，不知何时能归？",
  ["~liwan"] = "生不能同寝，死亦难同穴……",
}

local zhugeshang = General(extension, "zhugeshang", "shu", 3)
local sangu = fk.CreateTriggerSkill{
  name = "sangu",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Play and target:getHandcardNum() >= target.maxHp
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#sangu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3)
    local fakemove = {
      toArea = Card.PlayerHand,
      to = player.id,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.Void} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({player}, {fakemove})
    local availableCards = {}
    for _, id in ipairs(ids) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic or card:isCommonTrick() then
        table.insertIfNeed(availableCards, id)
      end
    end
    room:setPlayerMark(player, "sangu_cards", availableCards)
    local success, dat = room:askForUseActiveSkill(player, "sangu_show", "#sangu-show::"..target.id, true)
    room:setPlayerMark(player, "sangu_cards", 0)
    fakemove = {
      from = player.id,
      toArea = Card.Void,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({player}, {fakemove})
    for i = #ids, 1, -1 do
      table.insert(room.draw_pile, 1, ids[i])
    end
    if success then
      room:doIndicate(player.id, {target.id})
      room:moveCards({
        fromArea = Card.DrawPile,
        ids = dat.cards,
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
      room:sendFootnote(dat.cards, {
        type = "##ShowCard",
        from = player.id,
      })
      room:delay(2000)
      room:moveCards({
        ids = dat.cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
      if not target.dead then
        local mark = table.map(dat.cards, function(id) return Fk:getCardById(id).name end)
        room:setPlayerMark(target, "@$sangu-phase", mark)
        room:handleAddLoseSkills(target, "sangu&", nil, false, true)
      end
    end
  end,

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill("sangu&", true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(target, "-sangu&", nil, false, true)
  end,
}
local sangu_show = fk.CreateActiveSkill{
  name = "sangu_show",
  mute = true,
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    local ids = Self:getMark("sangu_cards")
    return ids ~= 0 and table.contains(ids, to_select) and
      table.every(selected, function(id) return Fk:getCardById(to_select).trueName ~= Fk:getCardById(id).trueName end)
  end,
}
local sangu_active = fk.CreateViewAsSkill{
  name = "sangu&",
  pattern = ".",
  prompt = "#sangu",
  interaction = function()
    return UI.ComboBox {choices = Self:getMark("@$sangu-phase")}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getMark("@$sangu-phase")
    if mark ~= 0 then
      table.removeOne(mark, use.card.name)
      if #mark == 0 then mark = 0 end
    end
    player.room:setPlayerMark(player, "@$sangu-phase", mark)
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and player:getMark("@$sangu-phase") ~= 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isKongcheng() and player:getMark("@$sangu-phase") ~= 0
  end,
}
local yizu = fk.CreateTriggerSkill{
  name = "yizu",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.firstTarget and table.contains({"slash", "duel"}, data.card.trueName) and
      player.room:getPlayerById(data.from).hp >= player.hp and player:isWounded() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
  end,
}
Fk:addSkill(sangu_show)
Fk:addSkill(sangu_active)
zhugeshang:addSkill(sangu)
zhugeshang:addSkill(yizu)
Fk:loadTranslationTable{
  ["zhugeshang"] = "诸葛尚",
  ["sangu"] = "三顾",
  [":sangu"] = "一名角色出牌阶段开始时，若其手牌数不小于其体力上限，你可以观看牌堆顶三张牌并亮出其中任意张牌名不同的基本牌或普通锦囊牌。若如此做，"..
  "此阶段每种牌名限一次，该角色可以将一张手牌当你亮出的一张牌使用。",
  ["yizu"] = "轶祖",
  [":yizu"] = "锁定技，每回合限一次，当你成为【杀】或【决斗】的目标后，若你的体力值不大于使用者的体力值，你回复1点体力。",
  ["#sangu-invoke"] = "三顾：你可以观看牌堆顶三张牌，令 %dest 本阶段可以将手牌当其中的牌使用",
  ["sangu_show"] = "三顾",
  ["#sangu-show"] = "三顾：你可以亮出其中的基本牌或普通锦囊牌，%dest 本阶段可以将手牌当亮出的牌使用",
  ["@$sangu-phase"] = "三顾",
  ["sangu&"] = "三顾",
  [":sangu&"] = "出牌阶段每种牌名限一次，你可以将一张手牌当一张“三顾”牌使用。",
  ["#sangu"] = "三顾：你可以将一张手牌当一张“三顾”牌使用",
}

local lukai = General(extension, "lukai", "wu", 4)
local bushil = fk.CreateTriggerSkill{
  name = "bushil",
  mute = true,
  events = {fk.CardUseFinished, fk.CardRespondFinished, fk.TargetConfirmed, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.CardUseFinished or event == fk.CardRespondFinished then
        return player:getMark("bushil2") == "log_"..data.card:getSuitString()
      elseif event == fk.TargetConfirmed then
        return data.card.type ~= Card.TypeEquip and player:getMark("bushil3") == "log_"..data.card:getSuitString() and not player:isKongcheng()
      elseif event == fk.EventPhaseStart then
        return player.phase == Player.Start or player.phase == Player.Finish
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart and player.phase == Player.Start then
      return player.room:askForSkillInvoke(player, self.name, nil, "#bushil-invoke")
    elseif event == fk.TargetConfirmed then
      local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#bushil-discard:::"..data.card:toLogString(), true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.EventPhaseStart and player.phase == Player.Start then
      room:notifySkillInvoked(player, self.name, "special")
      local suits = {"log_spade", "log_heart", "log_club", "log_diamond"}
      for i = 1, 4, 1 do
        local choices = table.map(suits, function(s) return Fk:translate(s) end)
        local choice = room:askForChoice(player, choices, self.name, "#bushil"..i.."-choice")
        local str = suits[table.indexOf(choices, choice)]
        table.removeOne(suits, str)
        room:setPlayerMark(player, "bushil"..i, str)
        room:setPlayerMark(player, "@bushil", string.format("%s-%s-%s-%s",
        Fk:translate(player:getMark("bushil1")),
        Fk:translate(player:getMark("bushil2")),
        Fk:translate(player:getMark("bushil3")),
        Fk:translate(player:getMark("bushil4"))))
      end
    elseif event == fk.CardUseFinished or event == fk.CardRespondFinished then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    elseif event == fk.TargetConfirmed then
      room:notifySkillInvoked(player, self.name, "defensive")
      room:throwCard(self.cost_data, self.name, player, player)
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        AimGroup:cancelTarget(data, player.id)
      else
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    elseif event == fk.EventPhaseStart and player.phase == Player.Finish then
      room:notifySkillInvoked(player, self.name, "drawcard")
      local card = room:getCardsFromPileByRule(".|.|"..string.sub(player:getMark("bushil4"), 5))
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
    end
  end,

  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name, true) then
      if event == fk.GameStart then
        return true
      else
        return target == player and data == self
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      room:setPlayerMark(player, "bushil1", "log_spade")
      room:setPlayerMark(player, "bushil2", "log_heart")
      room:setPlayerMark(player, "bushil3", "log_club")
      room:setPlayerMark(player, "bushil4", "log_diamond")
      room:setPlayerMark(player, "@bushil", string.format("%s-%s-%s-%s",
      Fk:translate(player:getMark("bushil1")),
      Fk:translate(player:getMark("bushil2")),
      Fk:translate(player:getMark("bushil3")),
      Fk:translate(player:getMark("bushil4"))))
    else
      for _, mark in ipairs({"bushil1", "bushil2", "bushil3", "bushil4", "@bushil"}) do
        room:setPlayerMark(player, mark, 0)
      end
    end
  end,
}
local bushil_targetmod = fk.CreateTargetModSkill{
  name = "#bushil_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if player:hasSkill("bushil") and player:getMark("bushil1") == "log_"..card:getSuitString() and scope == Player.HistoryPhase then
      return 999
    end
  end,
}
local zhongzhuang = fk.CreateTriggerSkill{
  name = "zhongzhuang",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and not data.chain and
      (player:getAttackRange() > 3 or (player:getAttackRange() < 3 and data.damage > 1))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getAttackRange() > 3 then
      data.damage = data.damage + 1
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "offensive")
    elseif player:getAttackRange() < 3 then
      data.damage = 1
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
    end
  end,
}
bushil:addRelatedSkill(bushil_targetmod)
lukai:addSkill(bushil)
lukai:addSkill(zhongzhuang)
Fk:loadTranslationTable{
  ["lukai"] = "陆凯",
  ["bushil"] = "卜筮",
  [":bushil"] = "你使用♠牌无次数限制；<br>你使用或打出<font color='red'>♥</font>牌后，摸一张牌；<br>当你成为♣牌的目标后，"..
  "你可以弃置一张手牌令此牌对你无效；<br>结束阶段，你获得一张<font color='red'>♦</font>牌。<br>准备阶段，你可以将以上四种花色重新分配。",
  ["zhongzhuang"] = "忠壮",
  [":zhongzhuang"] = "锁定技，你使用【杀】造成伤害时，若你的攻击范围大于3，则此伤害+1；若你的攻击范围小于3，则此伤害改为1。",
  ["@bushil"] = "卜筮",
  ["#bushil-invoke"] = "卜筮：是否重新分配“卜筮”的花色？",
  ["#bushil-discard"] = "卜筮：你可以弃置一张手牌令%arg对你无效",
  ["#bushil1-choice"] = "卜筮：使用此花色牌无次数限制",
  ["#bushil2-choice"] = "卜筮：使用或打出此花色牌后摸一张牌",
  ["#bushil3-choice"] = "卜筮：成为此花色牌目标后可弃置一张手牌对你无效",
}

local kebineng = General(extension, "kebineng", "qun", 4)
local koujing = fk.CreateTriggerSkill{
  name = "koujing",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForCard(player, 1, player:getHandcardNum(), false, self.name, true, ".", "#koujing-invoke")
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, id in ipairs(self.cost_data) do
      player.room:setCardMark(Fk:getCardById(id), "@@koujing-turn", 1)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.toArea ~= Card.Processing then
        for _, info in ipairs(move.moveInfo) do
          room:setCardMark(Fk:getCardById(info.cardId), "@@koujing-turn", 0)
        end
      end
    end
  end,
}
local koujing_filter = fk.CreateFilterSkill{
  name = "#koujing_filter",
  anim_type = "offensive",
  card_filter = function(self, card, player)
    return card:getMark("@@koujing-turn") > 0
  end,
  view_as = function(self, card)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = "koujing"
    return c
  end,
}
local koujing_targetmod = fk.CreateTargetModSkill{
  name = "#koujing_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, "koujing")
  end,
}
local koujing_trigger = fk.CreateTriggerSkill{
  name = "#koujing_trigger",
  mute = true,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if data.from and data.from == player and target ~= player and not player.dead and
      data.card and table.contains(data.card.skillNames, "koujing") then
      return table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@koujing-turn") > 0 end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@koujing-turn") > 0 end)
    player:showCards(ids)
    if player.dead or target.dead or target:isKongcheng() then return end
    room:doIndicate(player.id, {target.id})
    if room:askForSkillInvoke(target, "koujing", nil, "#koujing-card:"..player.id) then
      local cards1 = table.simpleClone(target:getCardIds("h"))
      local cards2 = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@koujing-turn") > 0 end)
      local move1 = {
        from = target.id,
        ids = cards1,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = player.id,
        skillName = self.name,
      }
      local move2 = {
        from = player.id,
        ids = cards2,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = player.id,
        skillName = self.name,
      }
      room:moveCards(move1, move2)
      local move3 = {ids = table.filter(cards1, function(id) return room:getCardArea(id) == Card.Processing end),
        fromArea = Card.Processing,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        proposer = player.id,
        skillName = self.name,
      }
      local move4 = {
        ids = table.filter(cards2, function(id) return room:getCardArea(id) == Card.Processing end),
        fromArea = Card.Processing,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        proposer = player.id,
        skillName = self.name,
      }
      room:moveCards(move3, move4)
    end
  end,
}
koujing:addRelatedSkill(koujing_filter)
koujing:addRelatedSkill(koujing_targetmod)
koujing:addRelatedSkill(koujing_trigger)
kebineng:addSkill(koujing)
Fk:loadTranslationTable{
  ["kebineng"] = "轲比能",
  ["koujing"] = "寇旌",
  [":koujing"] = "出牌阶段开始时，你可以选择任意张手牌，这些牌本回合视为不计入次数的【杀】。其他角色受到以此法使用的【杀】的伤害后展示这些牌，"..
  "其可用所有手牌交换这些牌。",
  ["#koujing-invoke"] = "寇旌：你可以将任意张手牌作为“寇旌”牌，本回合视为不计入次数的【杀】",
  ["@@koujing-turn"] = "寇旌",
  ["#koujing_filter"] = "寇旌",
  ["#koujing-card"] = "寇旌：你可以用所有手牌交换 %src 这些“寇旌”牌",
}

local wuanguo = General(extension, "wuanguo", "qun", 4)
local diezhang = fk.CreateTriggerSkill{
  name = "diezhang",
  anim_type = "switch",
  switch_skill_name = "diezhang",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.responseToEvent then
      if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
        if data.responseToEvent.from == player.id and not player:isNude() then
          return target ~= player and not target.dead and not player:isProhibited(target, Fk:cloneCard("slash"))
        end
      else
        if target == player then
          local from = player.room:getPlayerById(data.responseToEvent.from)
          return from ~= player and not from.dead and not player:isProhibited(from, Fk:cloneCard("slash"))
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      local card = room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#diezhang1-invoke::"..target.id, true)
      if #card > 0 then
        self.cost_data = {target.id, card}
        return true
      end
    else
      if room:askForSkillInvoke(player, self.name, nil, "#diezhang2-invoke::"..data.responseToEvent.from) then
        self.cost_data = {data.responseToEvent.from}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:throwCard(self.cost_data[2], self.name, player, player)
    else
      player:drawCards(1, self.name)
    end
    local to = room:getPlayerById(self.cost_data[1])
    if not player.dead and not to.dead then
      room:useVirtualCard("slash", nil, player, to, self.name, true)
    end
  end,
}
local diezhang_targetmod = fk.CreateTargetModSkill{
  name = "#diezhang_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if card and player:hasSkill("diezhang") and card.trueName == "slash" and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
local duanwan = fk.CreateTriggerSkill{
  name = "duanwan",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#duanwan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = math.min(2, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    if not player:hasSkill("diezhang", true) then return end
    local skill = "diezhangYang"
    if player:getSwitchSkillState("diezhang", false) == fk.SwitchYang then
      skill = "diezhangYin"
    end
    room:handleAddLoseSkills(player, "-diezhang|"..skill, nil, false, true)
  end,
}
local diezhangYang = fk.CreateTriggerSkill{
  name = "diezhangYang",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
      return player:hasSkill(self.name) and data.responseToEvent and data.responseToEvent.from == player.id and not player:isNude() and
        target ~= player and not target.dead and not player:isProhibited(target, Fk:cloneCard("slash"))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#diezhangYang-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    for i = 1, 2, 1 do
      if not player.dead and not target.dead then
        room:useVirtualCard("slash", nil, player, target, self.name, true)
      end
    end
  end,
}
local diezhangYin = fk.CreateTriggerSkill{
  name = "diezhangYin",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.responseToEvent then
      local from = player.room:getPlayerById(data.responseToEvent.from)
      return from ~= player and not from.dead and not player:isProhibited(from, Fk:cloneCard("slash"))
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#diezhangYin-invoke::"..data.responseToEvent.from)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.responseToEvent.from)
    player:drawCards(2, self.name)
    if not player.dead and not to.dead then
      room:useVirtualCard("slash", nil, player, to, self.name, true)
    end
  end,
}
diezhang:addRelatedSkill(diezhang_targetmod)
wuanguo:addSkill(diezhang)
wuanguo:addSkill(duanwan)
Fk:addSkill(diezhangYang)
Fk:addSkill(diezhangYin)
Fk:loadTranslationTable{
  ["wuanguo"] = "武安国",
  ["diezhang"] = "叠嶂",
  [":diezhang"] = "转换技，你出牌阶段使用【杀】次数上限+1。阳：当你使用牌被其他角色抵消后，你可以弃置一张牌视为对其使用(一)张【杀】；"..
  "阴：当你使用牌抵消其他角色使用的牌后，你可以摸(一)张牌视为对其使用一张【杀】。",
  ["duanwan"] = "断腕",
  [":duanwan"] = "限定技，当你处于濒死状态时，你可以将体力回复至2点，然后修改〖叠嶂〗：失去当前状态的效果，括号内的数字+1。",
  ["diezhangYang"] = "叠嶂",
  [":diezhangYang"] = "每回合限一次，当你使用牌被其他角色抵消后，你可以弃置一张牌视为对其使用两张【杀】。",
  ["diezhangYin"] = "叠嶂",
  [":diezhangYin"] = "每回合限一次，当你使用牌抵消其他角色使用的牌后，你可以摸两张牌视为对其使用一张【杀】。",
  ["#diezhang1-invoke"] = "叠嶂：你可以弃置一张牌，视为对 %dest 使用【杀】",
  ["#diezhang2-invoke"] = "叠嶂：你可以摸一张牌，视为对 %dest 使用【杀】",
  ["#duanwan-invoke"] = "断腕：你可以回复体力至2点，删除现在的“叠嶂”状态！",
  ["#diezhangYang-invoke"] = "叠嶂：你可以弃置一张牌，视为对 %dest 使用两张【杀】",
  ["#diezhangYin-invoke"] = "叠嶂：你可以摸两张牌，视为对 %dest 使用【杀】",
}

return extension
