local extension = Package:new("god")
extension.extensionName = "shzl"

Fk:loadTranslationTable{
  ["god"] = "神话再临·神",
  ["nos"] = "旧",
  --["gundam"] = "高达",
}

local godguanyu = General(extension, "godguanyu", "god", 5)
local wushen = fk.CreateFilterSkill{
  name = "wushen",
  card_filter = function(self, to_select, player)
    return player:hasSkill(self.name) and to_select.suit == Card.Heart and
    not table.contains(player.player_cards[Player.Equip], to_select.id) and
    not table.contains(player.player_cards[Player.Judge], to_select.id)
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("slash", Card.Heart, to_select.number)
    card.skillName = self.name
    return card
  end,
}
local wushen_targetmod = fk.CreateTargetModSkill{
  name = "#wushen_targetmod",
  distance_limit_func =  function(self, player, skill, card)
    if player:hasSkill("wushen") and skill.trueName == "slash_skill" and card.suit == Card.Heart then
      return 999
    end
    return 0
  end,
}
local wushenAudio = fk.CreateTriggerSkill{
  name = "#wushenAudio",
  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill("wushen") and
      data.card.trueName == "slash" and
      data.card.suit == Card.Heart
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke("wushen")
    player.room:notifySkillInvoked(player, "wushen", "offensive")
  end,
}
wushen:addRelatedSkill(wushen_targetmod)
wushen:addRelatedSkill(wushenAudio)
local wuhun = fk.CreateTriggerSkill{
  name = "wuhun",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name, false, true) then
      if event == fk.Damaged then
        return data.from and not data.from.dead and not player.dead
      else
        local availableTargets = {}
        local n = 0
        for _, p in ipairs(player.room:getOtherPlayers(player)) do
          if p:getMark("@nightmare") > n then
            availableTargets = {}
            table.insert(availableTargets,p.id)
            n = p:getMark("@nightmare")
          elseif p:getMark("@nightmare") == n and n ~= 0 then
            table.insert(availableTargets,p.id)
          end
        end
        if #availableTargets > 0 then
          self.availableTargets = availableTargets
          return true
        end
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      room:addPlayerMark(data.from, "@nightmare", data.damage)
    else
      local p_id
      if #self.availableTargets > 1 then
        p_id = room:askForChoosePlayers(player, self.availableTargets, 1, 1, "#wuhun-choose", self.name, false)[1]
      else
        p_id = self.availableTargets[1]
      end
      local judge = {
        who = room:getPlayerById(p_id),
        reason = self.name,
        pattern = "peach,god_salvation|.",
      }
      room:judge(judge)
      if judge.card.name == "peach" or judge.card.name == "god_salvation" then return false end
      room:killPlayer({who = p_id})
    end
  end,
}
godguanyu:addSkill(wushen)
godguanyu:addSkill(wuhun)
Fk:loadTranslationTable {
  ["godguanyu"] = "神关羽",
  ["wushen"] = "武神",
  [":wushen"] = "锁定技，你的<font color='red'>♥</font>手牌视为【杀】；你使用<font color='red'>♥</font>【杀】无距离限制。",
  ["wuhun"] = "武魂",
  [":wuhun"] = "锁定技，当你受到1点伤害后，伤害来源获得1枚“梦魇”；你死亡时，令“梦魇”最多的一名其他角色判定，若不为【桃】或【桃园结义】，其死亡。",
  ["@nightmare"] = "梦魇",
  ["#wuhun-choose"] = "武魂：选择一名“梦魇”最多的其他角色",

  ["$wushen1"] = "取汝狗头，犹如探囊取物！",
  ["$wushen2"] = "还不速速领死！",
  ["$wuhun1"] = "拿命来！",
  ["$wuhun2"] = "谁来与我同去？",
  ["~godguanyu"] = "",
}

local godlvmeng = General(extension, "godlvmeng", "god", 3)
local shelie = fk.CreateTriggerSkill{
  name = "shelie",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card_ids = room:getNCards(5)
    local get, throw = {}, {}
    room:moveCards({
      ids = card_ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonPut,
    })
    table.forEach(room.players, function(p)
      room:fillAG(p, card_ids)
    end)
    while true do
      local card_suits = {}
      table.forEach(get, function(id)
        table.insert(card_suits, Fk:getCardById(id).suit)
      end)
      for i = #card_ids, 1, -1 do
        local id = card_ids[i]
        if table.contains(card_suits, Fk:getCardById(id).suit) then
          room:takeAG(player, id)
          table.insert(throw, id)
          table.removeOne(card_ids, id)
        end
      end
      if #card_ids == 0 then break end
      local card_id = room:askForAG(player, card_ids, false, self.name)
      room:takeAG(player, card_id)
      table.insert(get, card_id)
      table.removeOne(card_ids, card_id)
      if #card_ids == 0 then break end
    end
    room:closeAG()
    if #get > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonPrey)
    end
    if #throw > 0 then
      room:moveCards({
        ids = throw,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
    end
    return true
  end,
}
local gongxin = fk.CreateActiveSkill{
  name = "gongxin",
  anim_type = "control",
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = target.player_cards[Player.Hand]
    local hearts = table.filter(cards, function (id) return Fk:getCardById(id).suit == Card.Heart end)
    room:fillAG(player, cards)
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).suit ~= Card.Heart then
          room:takeAG(player, cards[i], room.players)
      end
    end
    if #hearts == 0 then
      room:delay(3000)
      room:closeAG(player)
      return
    end
    local id = room:askForAG(player, hearts, true, self.name)
    room:closeAG(player)
    if id then
      local choice = room:askForChoice(player, {"gongxin_discard", "gongxin_put", "Cancel"}, self.name)
      if choice == "gongxin_discard" then
        room:throwCard({id}, self.name, target, player)
      elseif choice == "gongxin_put" then
        room:moveCardTo({id}, Card.DrawPile, nil, fk.ReasonPut, self.name, nil, false)
      end
    end
  end,
}
godlvmeng:addSkill(gongxin)
godlvmeng:addSkill(shelie)
Fk:loadTranslationTable{
  ["godlvmeng"] = "神吕蒙",
  ["shelie"] = "涉猎",
  [":shelie"] = "摸牌阶段，你可以改为亮出牌堆顶五张牌，获得不同花色的牌各一张。",
  ["gongxin"] = "攻心",
  [":gongxin"] = "出牌阶段限一次，你可以观看一名其他角色的手牌并可以展示其中的一张♥牌，选择：1. 弃置此牌；2. 将此牌置于牌堆顶。",
  ["gongxin_discard"] = "弃置此牌",
  ["gongxin_put"] = "将此牌置于牌堆顶",

  ["$shelie1"] = "什么都略懂一点，生活更多彩一些。",
  ["$shelie2"] = "略懂，略懂。",
  ["$gongxin1"] = "攻城为下，攻心为上。",
  ["$gongxin2"] = "我替施主把把脉。",
  ["~godlvmeng"] = "劫数难逃，我们别无选择……",
}

local godzhouyu = General(extension, "godzhouyu", "god", 4)
local qinyin = fk.CreateTriggerSkill{
  name = "qinyin",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Discard and player:getMark("qinyin-phase") > 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"loseHp"}
    if not table.every(room.alive_players, function (p) return not p:isWounded() end) then
      table.insert(choices, 1, "recover")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "recover" then
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:isWounded() then
          room:recover{
            who = p,
            num = 1,
            recoverBy = player,
            skillName = self.name
          }
        end
      end
    else
      for _, p in ipairs(room:getAlivePlayers()) do
        if not p.dead then room:loseHp(p, 1, self.name) end
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            player.room:addPlayerMark(player, "qinyin-phase", 1)
          end
        end
      end
    end
  end,
}
local yeyan = fk.CreateActiveSkill{
  name = "yeyan",
  anim_type = "offensive",
  min_target_num = 1,
  max_target_num = 3,
  min_card_num = 0,
  max_card_num = 4,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Player.Equip then return end
    if #selected == 0 then
      return true
    else
      return table.every(selected, function (id) return Fk:getCardById(to_select).suit ~= Fk:getCardById(id).suit end)
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected_cards == 4 then
      return #selected < 2
    elseif #selected_cards == 0 then
      return #selected < 3
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if #effect.cards == 0 then
      for _, id in ipairs(effect.tos) do
        room:damage{
          from = player,
          to = room:getPlayerById(id),
          damage = 1,
          damageType = fk.FireDamage,
          skillName = self.name,
        }
      end
    else
      room:throwCard(effect.cards, self.name, player, player)
      if #effect.tos == 1 then
        local choice = room:askForChoice(player, {"3", "2"}, self.name)
        room:loseHp(player, 3, self.name)
        room:damage{
          from = player,
          to = room:getPlayerById(effect.tos[1]),
          damage = tonumber(choice),
          damageType = fk.FireDamage,
          skillName = self.name,
        }
      else
        local target1 = room:getPlayerById(effect.tos[1])
        local target2 = room:getPlayerById(effect.tos[2])
        local to = room:askForChoosePlayers(player, effect.tos, 1, 1, "#yeyan-choose:::".."1", self.name, false)
        room:addPlayerMark(room:getPlayerById(to[1]), self.name, 1)
        to = room:askForChoosePlayers(player, effect.tos, 1, 1, "#yeyan-choose:::".."2", self.name, false)
        room:addPlayerMark(room:getPlayerById(to[1]), self.name, 1)
        if target1:getMark(self.name) > 0 and target2:getMark(self.name) > 0 then
          to = room:askForChoosePlayers(player, effect.tos, 1, 1, "#yeyan-choose:::".."3", self.name, false)
          room:addPlayerMark(room:getPlayerById(to[1]), self.name, 1)
        end
        for _, p in ipairs({target1, target2}) do
          if p:getMark(self.name) == 0 then
            room:addPlayerMark(p, self.name, 1)
          end
        end
        room:loseHp(player, 3, self.name)
        for _, p in ipairs({target1, target2}) do
          room:damage{
            from = player,
            to = p,
            damage = p:getMark(self.name),
            damageType = fk.FireDamage,
            skillName = self.name,
          }
          room:setPlayerMark(p, self.name, 0)
        end
      end
    end
  end,
}
godzhouyu:addSkill(qinyin)
godzhouyu:addSkill(yeyan)
Fk:loadTranslationTable{
  ["godzhouyu"] = "神周瑜",
  ["qinyin"] = "琴音",
  [":qinyin"] = "弃牌阶段结束时，若你此阶段弃置过至少两张手牌，你可以选择：1. 令所有角色各回复1点体力；2. 令所有角色各失去1点体力。",
  ["yeyan"] = "业炎",
  [":yeyan"] = "限定技，出牌阶段，你可以指定一至三名角色，你分别对这些角色造成至多共计3点火焰伤害；若你对一名角色分配2点或更多的火焰伤害，你须先弃置四张不同花色的手牌并失去3点体力。",
  ["#yeyan-choose"] = "业炎：选择第%arg点伤害的目标",

  ["$qinyin1"] = "（急促的琴声、燃烧声）",
  ["$qinyin2"] = "（舒缓的琴声）",
  ["$yeyan1"] = "（燃烧声）聆听吧，这献给你的镇魂曲！",
  ["$yeyan2"] = "（燃烧声）让这熊熊业火，焚尽你的罪恶！",
  ["~godzhouyu"] = "逝者不死，浴火重生。",
}

local godzhugeliang = General(extension, "godzhugeliang", "god", 3)
local qixing = fk.CreateTriggerSkill{
  name = "qixing",
  events = {fk.GameStart, fk.EventPhaseEnd},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    return event == fk.GameStart or (target == player and player.phase == Player.Draw and #player:getPile("star") > 0)
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then return true 
    else return player.room:askForSkillInvoke(player, self.name, data) end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(room:getNCards(7))
      player:addToPile("star", dummy, false, self.name)
    end
    local cids = room:askForExchange(player, {player:getPile("star"), player:getCardIds(Player.Hand)}, {"star", "$Hand"}, self.name)
    local cards1, cards2 = {}, {}
    for _, id in ipairs(cids[1]) do
      if room:getCardArea(id) == Player.Hand then
        table.insert(cards1, id)
      end
    end
    for _, id in ipairs(cids[2]) do
      if room:getCardArea(id) ~= Player.Hand then
        table.insert(cards2, id)
      end
    end
    room:moveCards( 
      {
      ids = cards2,
        from = player.id,
        to = player.id,
        fromArea = Card.PlayerSpecial,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        proposer = player.id,
        skillName = self.name,
      },
      {
      ids = cards1,
        from = player.id,
        to = player.id,
        fromArea = Card.PlayerHand,
        toArea = Card.PlayerSpecial,
        moveReason = fk.ReasonExchange,
        proposer = player.id,
        specialName = "star",
        skillName = self.name,
      }
    )
  end,
}
local kuangfeng = fk.CreateTriggerSkill{
  name = "kuangfeng",
  events = {fk.EventPhaseStart, fk.DamageInflicted},
  anim_type = "offensive",
  expand_pile = "star",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.EventPhaseStart then
      return target == player and player.phase == Player.Finish and #player:getPile("star") > 0
    else
      return target:getMark("@@kuangfeng") > 0 and data.damageType == fk.FireDamage and player:getMark("_kuangfeng") ~= 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      local cids = room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|star", "#kuangfeng-card", "star")
      if #cids > 0 then
        local targets = room:askForChoosePlayers(player, table.map(room.alive_players, function(p) return p.id end), 1, 1, "#kuangfeng-target", self.name, false)
        self.cost_data = {targets[1], cids}
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      room:moveCardTo(self.cost_data[2], Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, "star")
      room:addPlayerMark(room:getPlayerById(self.cost_data[1]), "@@kuangfeng")
      room:setPlayerMark(player, "_kuangfeng", self.cost_data[1])
    else
      data.damage = data.damage + 1
    end
  end,

  refresh_events = {fk.EventPhaseChanging, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if target ~= player or player:getMark("_kuangfeng") == 0 then return false end
    return event == fk.Death or data.from == Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(room:getPlayerById(player:getMark("_kuangfeng")), "@@kuangfeng")
    room:setPlayerMark(player, "_kuangfeng", 0)
  end,
}
local dawu = fk.CreateTriggerSkill{
  name = "dawu",
  anim_type = "defensive",
  events = {fk.EventPhaseStart, fk.DamageInflicted},
  expand_pile = "star",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.EventPhaseStart then
      return target == player and player.phase == Player.Finish and #player:getPile("star") > 0
    else
      return target:getMark("@@dawu") > 0 and data.damageType ~= fk.ThunderDamage and player:getMark("_dawu") ~= 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      local cids = room:askForCard(player, 1, #room.alive_players, false, self.name, true, ".|.|.|star", "#dawu-card", "star")
      if #cids > 0 then
        local targets = room:askForChoosePlayers(player, table.map(room.alive_players, function(p) return p.id end), #cids, #cids, "#dawu-target:::" .. #cids, self.name, false)
        self.cost_data = {targets, cids}
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      room:moveCardTo(self.cost_data[2], Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, "star")
      table.forEach(self.cost_data[1], function(pid) 
        room:addPlayerMark(room:getPlayerById(pid), "@@dawu")
      end)
      room:setPlayerMark(player, "_dawu", self.cost_data[1])
    else
      return true
    end
  end,

  refresh_events = {fk.EventPhaseChanging, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if target ~= player or player:getMark("_dawu") == 0 then return false end
    return event == fk.Death or data.from == Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    table.forEach(player:getMark("_dawu"), function(pid)
      room:removePlayerMark(room:getPlayerById(pid), "@@dawu")
    end)
    room:setPlayerMark(player, "_dawu", 0)
  end,
}
godzhugeliang:addSkill(qixing)
godzhugeliang:addSkill(kuangfeng)
godzhugeliang:addSkill(dawu)
Fk:loadTranslationTable{
  ["godzhugeliang"] = "神诸葛亮",
  ["qixing"] = "七星",
  [":qixing"] = "游戏开始时，你将牌堆顶的七张牌扣置于武将牌上，称为“星”，然后你可以用任意张手牌替换等量的“星”；摸牌阶段结束时，你可以用任意张手牌替换等量的“星”。",
  ["kuangfeng"] = "狂风",
  [":kuangfeng"] = "结束阶段开始时，你可以将一张“星”置入弃牌堆并选择一名角色，当其于你的下回合开始之前受到火焰伤害时，你令伤害值+1。",
  ["dawu"] = "大雾",
  [":dawu"] = "结束阶段开始时，你可以将至少一张“星”置入弃牌堆并选择等量的角色，当其于你的下回合开始之前受到不为雷电伤害的伤害时，防止此伤害。",

  ["star"] = "星",
  ["@@kuangfeng"] = "狂风",
  ["#kuangfeng-card"] = "狂风：你可以将一张“星”置入弃牌堆，点击“确认”后选择一名角色",
  ["#kuangfeng-target"] = "狂风：请选择一名角色，当其于你的下回合开始之前受到火焰伤害时，你令伤害值+1",
  ["@@dawu"] = "大雾",
  ["#dawu-card"] = "大雾：你可以将至少一张“星”置入弃牌堆，点击“确认”后选择等量的角色",
  ["#dawu-target"] = "大雾：请选择%arg名角色，当其于你的下回合开始之前受到不为雷电伤害的伤害时，防止此伤害",

  ["$qixing1"] = "祈星辰之力，佑我蜀汉！	",
  ["$qixing2"] = "伏望天恩，誓讨汉贼！",
  ["$kuangfeng1"] = "风~~起~~",
  ["$kuangfeng2"] = "万事俱备，只欠业火。",
  ["$dawu1"] = "此计可保你一时平安。",
  ["$dawu2"] = "此非万全之策，唯惧天雷。",
  ["~godzhugeliang"] = "今当远离，临表涕零，不知所言……",
}

local godlvbu = General(extension, "godlvbu", "god", 5)
local kuangbao = fk.CreateTriggerSkill{
  name = "kuangbao",
  events = {fk.GameStart, fk.Damage, fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return (event == fk.GameStart or target == player) and player:hasSkill(self.name) and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@baonu", event == fk.GameStart and 2 or data.damage)
  end,
}
local wumou = fk.CreateTriggerSkill{
  name = "wumou",
  anim_type = "negative",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card:isCommonTrick()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"loseHp"}
    if player:getMark("@baonu") > 0 then table.insert(choices, "wumouBaonu") end
    if room:askForChoice(player, choices, self.name) == "loseHp" then
      room:loseHp(player, 1, self.name)
    else
      room:removePlayerMark(player, "@baonu", 1)
    end
  end,
}
local wuqian = fk.CreateActiveSkill{
  name = "wuqian",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:getMark("@baonu") > 1
  end,
  card_num = 0,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected < 1 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("@@wuqian-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:removePlayerMark(player, "@baonu", 2)
    room:addPlayerMark(target, "@@wuqian-turn")
    room:handleAddLoseSkills(player, "wushuang", nil, true, false)
    room:addPlayerMark(target, fk.MarkArmorNullified)
  end
}
local wuqianCleaner = fk.CreateTriggerSkill{
  name = "#wuqianCleaner",
  mute = true,
  refresh_events = {fk.TurnEnd},
  can_refresh = function(_, _, target, player)
    return target == player and target:usedSkillTimes("wuqian") > 0
  end,
  on_refresh = function(_, _, target)
    local room = target.room
    room:handleAddLoseSkills(target, "-wushuang", nil, true, false)
    table.forEach(room.alive_players, function(p)
      if p:getMark("@@wuqian-turn") > 0 then room:removePlayerMark(p, fk.MarkArmorNullified) end
    end)
  end,
}
wuqian:addRelatedSkill(wuqianCleaner)
local shenfen = fk.CreateActiveSkill{
  name = "shenfen",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player:getMark("@baonu") > 5
  end,
  card_num = 0,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:removePlayerMark(player, "@baonu", 6)
    local targets = room:getOtherPlayers(player, true)
    table.forEach(targets, function(p)
      if not p.dead then room:damage{ from = player, to = p, damage = 1, skillName = self.name } end
    end)
    table.forEach(targets, function(p)
      if not p.dead then p:throwAllCards("e") end
    end)
    table.forEach(targets, function(p)
      if not p.dead then
        room:askForDiscard(p, 4, 4, false, self.name, false)
      end
    end)
    if not player.dead then player:turnOver() end
  end
}
godlvbu:addSkill(kuangbao)
godlvbu:addSkill(wumou)
godlvbu:addSkill(wuqian)
godlvbu:addSkill(shenfen)
godlvbu:addRelatedSkill("wushuang")
Fk:loadTranslationTable{
  ["godlvbu"] = "神吕布",
  ["kuangbao"] = "狂暴",
  [":kuangbao"] = "锁定技，游戏开始时，你获得2枚“暴怒”；当你造成或受到1点伤害后，你获得1枚“暴怒”。",
  ["wumou"] = "无谋",
  [":wumou"] = "锁定技，当你使用普通锦囊牌时，你选择：1.弃1枚“暴怒”；2.失去1点体力。",
  ["wuqian"] = "无前",
  [":wuqian"] = "出牌阶段，你可以弃2枚“暴怒”并选择一名此回合内未以此法选择过的其他角色，你于此回合内拥有〖无双〗且其防具技能于此回合内无效。",
  ["shenfen"] = "神愤",
  [":shenfen"] = "出牌阶段限一次，你可以弃6枚“暴怒”并选择所有其他角色，对这些角色各造成1点伤害，然后这些角色各弃置其装备区里的所有牌，各弃置四张手牌，最后你翻面。",

  ["@baonu"] = "暴怒",
  ["wumouBaonu"] = "弃1枚“暴怒”",
  ["@@wuqian-turn"] = "无前",
  ["#wuqianCleaner"] = "无前",

  ["$kuangbao1"] = "嗯→↗↑↑↑↓……",
  ["$kuangbao2"] = "哼！",
  ["$wumou1"] = "哪个说我有勇无谋？!",
  ["$wumou2"] = "不管这些了！",
  ["$wuqian1"] = "看我神威，无坚不摧！",
  ["$wuqian2"] = "天王老子也保不住你！",
  ["$shenfen1"] = "凡人们，颤抖吧！这是神之怒火！",
  ["$shenfen2"] = "这，才是活生生的地狱！",
  ["$wushuang_godlvbu1"] = "燎原千里，凶名远扬！",
  ["$wushuang_godlvbu2"] = "铁蹄奋进，所向披靡！",
  ["~godlvbu"] = "我在修罗炼狱，等着你们，呃哈哈哈哈哈~",
}

local godcaocao = General(extension, "godcaocao", "god", 3)
local guixin = fk.CreateTriggerSkill{
  name = "guixin",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost or table.every(player.room:getOtherPlayers(player), function (p) return p:isAllNude() end) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player, true)) do
      if not p:isAllNude() then
        local id = room:askForCardChosen(player, p, "hej", self.name)
        room:obtainCard(player, id, false, fk.ReasonPrey)
      end
    end
    player:turnOver()
  end,
}
local feiying = fk.CreateDistanceSkill{
  name = "feiying",
  correct_func = function(self, from, to)
    if to:hasSkill(self.name) then
      return 1
    end
    return 0
  end,
}
godcaocao:addSkill(guixin)
godcaocao:addSkill(feiying)
Fk:loadTranslationTable{
  ["godcaocao"] = "神曹操",
  ["guixin"] = "归心",
  [":guixin"] = "当你受到1点伤害后，你可获得所有其他角色区域中的一张牌，然后你翻面。",
  ["feiying"] = "飞影",
  [":feiying"] = "锁定技，其他角色至你距离+1。",

  ["$guixin1"] = "周公吐哺，天下归心！",
  ["$guixin2"] = "山不厌高，海不厌深！",
  ["~godcaocao"] = "腾蛇乘雾，终为土灰。",
}

local nos__godzhaoyun = General(extension, "nos__godzhaoyun", "god", 2)
local nos__juejing = fk.CreateTriggerSkill{
  name = "nos__juejing",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getLostHp()
  end,
}
local nos__juejing_maxcards = fk.CreateMaxCardsSkill{
  name = "#nos__juejing_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(nos__juejing.name) then
      return 2
    end
  end
}
nos__juejing:addRelatedSkill(nos__juejing_maxcards)

local nos__longhun = fk.CreateViewAsSkill{
  name = "nos__longhun",
  pattern = "peach,slash,jink,nullification",
  card_filter = function(self, to_select, selected)
    if #selected == 2 then
      return false
    elseif #selected == 1 then
      if math.max(Self.hp, 1) == 1 then return false end
      return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(selected[1]))
    else
      local suit = Fk:getCardById(to_select).suit
      local c
      if suit == Card.Heart then
        c = Fk:cloneCard("peach")
      elseif suit == Card.Diamond then
        c = Fk:cloneCard("fire__slash")
      elseif suit == Card.Club then
        c = Fk:cloneCard("jink")
      elseif suit == Card.Spade then
        c = Fk:cloneCard("nullification")
      else
        return false
      end
      return (Fk.currentResponsePattern == nil and c.skill:canUse(Self, c)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
    end
  end,
  view_as = function(self, cards)
    if #cards ~= math.max(Self.hp, 1) then
      return nil
    end
    local suit = Fk:getCardById(cards[1]).suit
    local c
    if suit == Card.Heart then
      c = Fk:cloneCard("peach")
    elseif suit == Card.Diamond then
      c = Fk:cloneCard("fire__slash")
    elseif suit == Card.Club then
      c = Fk:cloneCard("jink")
    elseif suit == Card.Spade then
      c = Fk:cloneCard("nullification")
    else
      return nil
    end
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
}

nos__godzhaoyun:addSkill(nos__juejing)
nos__godzhaoyun:addSkill(nos__longhun)

Fk:loadTranslationTable{
  ["nos__godzhaoyun"] = "神赵云",
  ["nos__juejing"] = "绝境",
  [":nos__juejing"] = "锁定技，摸牌阶段，你令额定摸牌数+X（X为你已损失的体力值）；你的手牌上限+2。",
  ["nos__longhun"] = "龙魂",
  [":nos__longhun"] = "你可以将X张你的同花色的牌按以下规则使用或打出：红桃当【桃】，方块当火【杀】，梅花当【闪】，黑桃当【无懈可击】（X为你的体力值且至少为1）。",

  ["$nos__juejing1"] = "背水一战，不胜便死！",
  ["$nos__juejing2"] = "置于死地，方能后生！",
  ["$nos__longhun1"] = "常山赵子龙在此！",
  ["$nos__longhun2"] = "能屈能伸，才是大丈夫！",
  ["~nos__godzhaoyun"] = "龙身虽死，魂魄不灭！",
}

local godzhaoyun = General(extension, "godzhaoyun", "god", 2)
local juejing = fk.CreateTriggerSkill{
  name = "juejing",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying, fk.AfterDying},
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local juejing_maxcards = fk.CreateMaxCardsSkill{
  name = "#juejing_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(juejing.name) then
      return 2
    end
  end
}
juejing:addRelatedSkill(juejing_maxcards)
local longhun = fk.CreateViewAsSkill{
  name = "longhun",
  pattern = "peach,slash,jink,nullification",
  card_filter = function(self, to_select, selected)
    if #selected == 2 then
      return false
    elseif #selected == 1 then
      return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(selected[1]))
    else
      local suit = Fk:getCardById(to_select).suit
      local c
      if suit == Card.Heart then
        c = Fk:cloneCard("peach")
      elseif suit == Card.Diamond then
        c = Fk:cloneCard("fire__slash")
      elseif suit == Card.Club then
        c = Fk:cloneCard("jink")
      elseif suit == Card.Spade then
        c = Fk:cloneCard("nullification")
      else
        return false
      end
      return (Fk.currentResponsePattern == nil and c.skill:canUse(Self, c)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
    end
  end,
  view_as = function(self, cards)
    if #cards == 0 or #cards > 2 then
      return nil
    end
    local suit = Fk:getCardById(cards[1]).suit
    local c
    if suit == Card.Heart then
      c = Fk:cloneCard("peach")
    elseif suit == Card.Diamond then
      c = Fk:cloneCard("fire__slash")
    elseif suit == Card.Club then
      c = Fk:cloneCard("jink")
    elseif suit == Card.Spade then
      c = Fk:cloneCard("nullification")
    else
      return nil
    end
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    local num = #use.card.subcards
    if num == 2 then
      local suit = Fk:getCardById(use.card.subcards[1]).suit
      if suit == Card.Diamond then
        use.additionalDamage = (use.additionalDamage or 0) + 1
      elseif suit == Card.Heart then
        use.additionalRecover = (use.additionalRecover or 0) + 1
      end
    end
  end,
}
local longhun_discard = fk.CreateTriggerSkill{
  name = "#longhun_discard",
  events = {fk.CardUseFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "longhun") and #data.card.subcards == 2 and Fk:getCardById(data.card.subcards[1]).color == Card.Black
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not room.current:isNude() then
      local cid = room:askForCardChosen(player, room.current, "he", self.name)
      room:throwCard({cid}, self.name, room.current, player)
    end
  end,
}
longhun:addRelatedSkill(longhun_discard)
godzhaoyun:addSkill(juejing)
godzhaoyun:addSkill(longhun)
Fk:loadTranslationTable{
  ["godzhaoyun"] = "神赵云",
  ["juejing"] = "绝境",
  [":juejing"] = "锁定技，你的手牌上限+2；当你进入濒死状态时或你的濒死结算结束后，你摸一张牌。",
  ["longhun"] = "龙魂",
  [":longhun"] = "你可以将至多两张你的同花色的牌按以下规则使用或打出：红桃当【桃】，方块当火【杀】，梅花当【闪】，黑桃当【无懈可击】。若你以此法使用或打出了两张：红桃牌，此牌回复基数+1；方块牌，此牌伤害基数+1；黑色牌，你弃置当前回合角色一张牌。",
  
  ["#longhun_discard"] = "龙魂",

  ["$juejing1"] = "绝望中，仍存有一线生机！",
  ["$juejing2"] = "还不可以认输！",
  ["$longhun1"] = "龙战于野，其血玄黄。",
  ["$longhun2"] = "潜龙勿用，藏锋守拙。",
  ["~godzhaoyun"] = "龙鳞崩损，坠于九天……",
}

local gundam = General(extension, "gundam", "god", 1)
gundam.hidden = true
local gundam__juejing = fk.CreateTriggerSkill{
  name = "gundam__juejing",
  events = {fk.AfterCardsMove, fk.EventPhaseChanging},
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.EventPhaseChanging then
      return target == player and data.to == Player.Draw
    elseif player:getHandcardNum() ~= 4 then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand then
          return true
        elseif move.from == player.id then
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
    player:broadcastSkillInvoke(self.name)
    if event == fk.EventPhaseChanging then
      room:notifySkillInvoked(player, self.name, "negative")
      return true
    else
      local num = 4 - player:getHandcardNum()
      if num > 0 then
        room:notifySkillInvoked(player, self.name, "drawcard")
        player:drawCards(num, self.name)
      elseif num < 0 then
        room:notifySkillInvoked(player, self.name, "negative")
        room:askForDiscard(player, -num, -num, false, self.name, false)
      end
    end
  end,
}
local gundam__longhun = fk.CreateViewAsSkill{
  name = "gundam__longhun",
  mute = true,
  pattern = "peach,slash,jink,nullification",
  card_filter = function(self, to_select, selected)
    if #selected == 1 then
      return false
    else
      local suit = Fk:getCardById(to_select).suit
      local c
      if suit == Card.Heart then
        c = Fk:cloneCard("peach")
      elseif suit == Card.Diamond then
        c = Fk:cloneCard("fire__slash")
      elseif suit == Card.Club then
        c = Fk:cloneCard("jink")
      elseif suit == Card.Spade then
        c = Fk:cloneCard("nullification")
      else
        return false
      end
      return (Fk.currentResponsePattern == nil and c.skill:canUse(Self, c)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local suit = Fk:getCardById(cards[1]).suit
    local c
    if suit == Card.Heart then
      c = Fk:cloneCard("peach")
    elseif suit == Card.Diamond then
      c = Fk:cloneCard("fire__slash")
    elseif suit == Card.Club then
      c = Fk:cloneCard("jink")
    elseif suit == Card.Spade then
      c = Fk:cloneCard("nullification")
    else
      return nil
    end
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
}
local gundam__longhun_qinggang = fk.CreateTriggerSkill{
  name = "#gundam__longhun_qinggang",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(gundam__longhun.name) or player.phase ~= Player.Start then return false end
    for _, id in ipairs(Fk:getAllCardIds()) do
      if Fk:getCardById(id).name == "qinggang_sword" and table.contains({Card.PlayerEquip, Card.PlayerJudge}, player.room:getCardArea(id)) then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cids, target = {}, nil
    for _, id in ipairs(Fk:getAllCardIds()) do
      if Fk:getCardById(id).name == "qinggang_sword" and table.contains({Card.PlayerEquip, Card.PlayerJudge}, room:getCardArea(id)) then
        table.insert(cids, id)
        target = target or room:getCardOwner(id).id
      end
    end
    if #cids == 0 then
      return false
    else
      local prompt = #cids == 1 and "#gundam__longhun_qinggang-target:" .. target or "#gundam__longhun_qinggang-targets:" .. target
      if room:askForSkillInvoke(player, self.name, data, prompt) then
        self.cost_data = cids
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, gundam__longhun.name, "control")
    player:broadcastSkillInvoke(gundam__longhun.name)
    table.forEach(self.cost_data, function(id)
      room:obtainCard(player, id, true, fk.ReasonPrey)
    end)
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.PreCardRespond},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "gundam__longhun")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card.trueName == "nullification" then
      player:broadcastSkillInvoke("gundam__longhun", 1)
      room:notifySkillInvoked(player, "gundam__longhun", "control")
    elseif data.card.trueName == "jink" then
      player:broadcastSkillInvoke("gundam__longhun", 2)
      room:notifySkillInvoked(player, "gundam__longhun", "defensive")
    elseif data.card.trueName == "peach" then
      player:broadcastSkillInvoke("gundam__longhun", 3)
      room:notifySkillInvoked(player, "gundam__longhun", "support")
    elseif data.card.trueName == "slash" then
      player:broadcastSkillInvoke("gundam__longhun", 4)
      room:notifySkillInvoked(player, "gundam__longhun", "offensive")
    end
  end,
}
gundam__longhun:addRelatedSkill(gundam__longhun_qinggang)
gundam:addSkill(gundam__juejing)
gundam:addSkill(gundam__longhun)
Fk:loadTranslationTable{
  --["gundam__godzhaoyun"] = "高达一号",
  ["gundam"] = "高达一号",
  ["gundam__juejing"] = "绝境",
  [":gundam__juejing"] = "锁定技，你跳过摸牌阶段；当你的手牌数大于4/小于4时，你将手牌弃置至4/摸至4张。",
  ["gundam__longhun"] = "龙魂",
  [":gundam__longhun"] = "你可以将你的牌按以下规则使用或打出：红桃当【桃】，方块当火【杀】，梅花当【闪】，黑桃当【无懈可击】。准备阶段开始时，如果场上有【青釭剑】，你可以获得之。",

  ["#gundam__longhun_qinggang"] = "龙魂",
  ["#gundam__longhun_qinggang-target"] = "龙魂：你可夺走 %src 的【青釭剑】！",
  ["#gundam__longhun_qinggang-targets"] = "龙魂：你可夺走 %src 等的【青釭剑】！",

  ["$gundam__juejing1"] = "龙战于野，其血玄黄。",
  ["$gundam__longhun1"] = "金甲映日，驱邪祛秽。", --无懈
  ["$gundam__longhun2"] = "腾龙行云，首尾不见。", --闪
  ["$gundam__longhun3"] = "潜龙于渊，涉灵愈伤。", --桃
  ["$gundam__longhun4"] = "千里一怒，红莲灿世。", --火杀
  ["~gundam"] = "血染鳞甲，龙坠九天。",
}

local godsimayi = General(extension, "godsimayi", "god", 4)
local renjie = fk.CreateTriggerSkill{
  name = "renjie",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.Damaged then
        return target == player
      else
        if player.phase == Player.Discard then
          for _, move in ipairs(data) do
            if move.from == player.id and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand then
                  return true
                end
              end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      room:addPlayerMark(player, "@godsimayi_bear", data.damage)
    else
      local n = 0
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              n = n + 1
            end
          end
        end
      end
      room:addPlayerMark(player, "@godsimayi_bear", n)
    end
  end,
}
local baiyin = fk.CreateTriggerSkill{
  name = "baiyin",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@godsimayi_bear") > 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "jilve", nil, true, false)
  end,
}
local lianpo = fk.CreateTriggerSkill{
  name = "lianpo",
  anim_type = "offensive",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      local room = player.room
      local events = room.logic:getEventsOfScope(GameEvent.Death, 999, function(e)
        local deathStruct = e.data[1]
        return deathStruct.damage and deathStruct.damage.from and deathStruct.damage.from == player
      end, Player.HistoryTurn)
      return #events > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#lianpo-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn(true)
  end,
}
local jilve = fk.CreateActiveSkill{
  name = "jilve",
  mute = true,
  min_card_num = function(self)
    if self.interaction.data == "ex__zhiheng" then
      return 1
    end
    if self.interaction.data == "ol_ex__wansha" then
      return 0
    end
  end,
  max_card_num = function(self)
    if self.interaction.data == "ex__zhiheng" then
      return 999
    end
    if self.interaction.data == "ol_ex__wansha" then
      return 0
    end
  end,
  target_num = 0,
  prompt = function(self, selected, selected_cards)
    if self.interaction.data == "ex__zhiheng" then
      return "#jilve-zhiheng"
    elseif self.interaction.data == "ol_ex__wansha" then
      return "#jilve-wansha"
    end
  end,
  interaction = function(self)
    local choices = {}
    if Self:usedSkillTimes("ex__zhiheng", Player.HistoryPhase) == 0 then
      table.insert(choices, "ex__zhiheng")
    end
    if not Self:hasSkill("ol_ex__wansha", true) then
      table.insert(choices, "ol_ex__wansha")
    end
    if #choices == 0 then return false end
    return UI.ComboBox { choices = choices , all_choices = {"ex__zhiheng", "ol_ex__wansha"}}
  end,
  can_use = function(self, player)
    return player:getMark("@godsimayi_bear") > 0 and
      (player:usedSkillTimes("ex__zhiheng", Player.HistoryPhase) == 0 or not player:hasSkill("ol_ex__wansha", true))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:removePlayerMark(player, "@godsimayi_bear", 1)
    if self.interaction.data == "ex__zhiheng" then
      player:broadcastSkillInvoke("ex__zhiheng")
      room:notifySkillInvoked(player, "jilve", "drawcard")
      player:setSkillUseHistory("ex__zhiheng", player:usedSkillTimes("ex__zhiheng", Player.HistoryPhase) + 1, Player.HistoryPhase)
      local hand = player:getCardIds(Player.Hand)
      local more = #hand > 0
      for _, id in ipairs(hand) do
        if not table.contains(effect.cards, id) then
          more = false
          break
        end
      end
      room:throwCard(effect.cards, "ex__zhiheng", player, player)
      room:drawCards(player, #effect.cards + (more and 1 or 0), "ex__zhiheng")
    elseif self.interaction.data == "ol_ex__wansha" then
      player:broadcastSkillInvoke("ol_ex__wansha")
      room:notifySkillInvoked(player, "jilve", "offensive")
      room:setPlayerMark(player, "jilve-turn", 1)
      room:handleAddLoseSkills(player, "ol_ex__wansha", nil, true, false)
    end
  end
}
local jilve_trigger = fk.CreateTriggerSkill{
  name = "#jilve_trigger",
  mute = true,
  events = {fk.AskForRetrial, fk.Damaged, fk.CardUsing, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill("jilve") and player:getMark("@godsimayi_bear") > 0 then
      if event == fk.AskForRetrial then
        return not player:isNude()
      elseif event == fk.Damaged then
        return target == player
      elseif event == fk.CardUsing then
        return target == player and data.card.type == Card.TypeTrick and not data.card:isVirtual()
      end
    end
    if player:getMark("jilve-turn") > 0 and event == fk.TurnEnd then
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AskForRetrial then
      local card = room:askForResponse(player, "ex__guicai", ".|.|.|hand,equip|.|", "#guicai-ask::" .. target.id, true)
      if card ~= nil then
        self.cost_data = card
        return true
      end
    elseif event == fk.Damaged then
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
        return p.id end), 1, 1, "#fangzhu-choose:::"..player:getLostHp(), "fangzhu", true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    elseif event == fk.CardUsing then
      return room:askForSkillInvoke(player, "ex__jizhi")
    elseif event == fk.TurnEnd then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      room:handleAddLoseSkills(player, "-ol_ex__wansha", nil, true, false)
    else
      room:removePlayerMark(player, "@godsimayi_bear", 1)
      local type
      if event == fk.AskForRetrial then
        type = "control"
      elseif event == fk.Damaged then
        type = "control"
      elseif event == fk.CardUsing then
        type = "drawcard"
      end
      room:notifySkillInvoked(player, "jilve", type)
      if event == fk.AskForRetrial then
        player:broadcastSkillInvoke("ex__guicai")
        room:retrial(self.cost_data, player, data, "ex__guicai")
      elseif event == fk.Damaged then
        player:broadcastSkillInvoke("fangzhu")
        local to = player.room:getPlayerById(self.cost_data)
        to:drawCards(player:getLostHp(), "fangzhu")
        to:turnOver()
      elseif event == fk.CardUsing then
        player:broadcastSkillInvoke("ex__jizhi")
        local id = player:drawCards(1, "ex__jizhi")[1]
        if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player and
          Fk:getCardById(id).type == Card.TypeBasic and player.phase ~= Player.NotActive and
          room:askForSkillInvoke(player, "ex__jizhi", nil, "#jizhi-invoke:::"..Fk:getCardById(id):toLogString()) then
            room:throwCard({id}, "ex__jizhi", player, player)
            room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 1)
        end
      end
    end
  end,
}
jilve:addRelatedSkill(jilve_trigger)
godsimayi:addSkill(renjie)
godsimayi:addSkill(baiyin)
godsimayi:addSkill(lianpo)
godsimayi:addRelatedSkill(jilve)
godsimayi:addRelatedSkill("ex__guicai")
godsimayi:addRelatedSkill("fangzhu")
godsimayi:addRelatedSkill("ex__jizhi")
godsimayi:addRelatedSkill("ex__zhiheng")
godsimayi:addRelatedSkill("ol_ex__wansha")
Fk:loadTranslationTable{
  ["godsimayi"] = "神司马懿",
  ["renjie"] = "忍戒",
  [":renjie"] = "锁定技，当你受到伤害后/于弃牌阶段弃置手牌后，你获得X枚“忍”（X为伤害值/你弃置的手牌数）。",
  ["baiyin"] = "拜印",
  [":baiyin"] = "觉醒技，准备阶段开始时，若你的“忍”数大于3，你减1点体力上限，获得〖极略〗。",
  ["lianpo"] = "连破",
  [":lianpo"] = "当你杀死一名角色后，你可于此回合结束后获得一个额外回合。",
  ["jilve"] = "极略",
  [":jilve"] = "你可以弃置1枚“忍”，发动下列一项技能：〖鬼才〗、〖放逐〗、〖集智〗、〖制衡〗、〖完杀〗。",
  ["@godsimayi_bear"] = "忍",
  ["#jilve-zhiheng"] = "极略：你可以弃置1枚“忍”标记，发动〖制衡〗",
  ["#jilve-wansha"] = "极略：你可以弃置1枚“忍”标记，获得〖完杀〗直到回合结束",
  ["#jilve_trigger"] = "极略",
  ["#lianpo-invoke"] = "连破：你可以额外执行一个回合！",

  ["$renjie1"] = "忍一时，风平浪静。",
  ["$renjie2"] = "退一步，海阔天空。",
  ["$baiyin1"] = "老骥伏枥，志在千里！",
  ["$baiyin2"] = "烈士暮年，壮心不已！",
  ["$lianpo1"] = "受命于天，既寿永昌！",
  ["$lianpo2"] = "一鼓作气，破敌致胜！",
  ["$ex__guicai_godsimayi"] = "老夫，即是天命！",
  ["$fangzhu_godsimayi"] = "赦你死罪，你去吧！",
  ["$ex__jizhi_godsimayi"] = "顺应天意，得道多助。",
  ["$ex__zhiheng_godsimayi"] = "天之道，轮回也。",
  ["$ol_ex__wansha_godsimayi"] = "天要亡你，谁人能救？",
  ["~godsimayi"] = "鼎足三分已成梦，一切都结束了……",
}

local godliubei = General(extension, "godliubei", "god", 6)
local longnu = fk.CreateTriggerSkill{
  name = "longnu",
  events = {fk.EventPhaseStart},
  anim_type = "switch",
  frequency = Skill.Compulsory,
  switch_skill_name = "longnu",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:loseHp(player, 1, self.name)
      player:drawCards(1, self.name)
      room:setPlayerMark(player, "_longnu-phase", "yang")
    else
      room:changeMaxHp(player, -1)
      player:drawCards(1, self.name)
      room:setPlayerMark(player, "_longnu-phase", "yin")
    end
  end,
}
local longnu_filter = fk.CreateFilterSkill{
  name = "#longnu_filter",
  card_filter = function(self, to_select, player)
    if player:hasSkill("longnu") and player.phase == Player.Play then
      if player:getSwitchSkillState("longnu", true) == fk.SwitchYang then
        return to_select.color == Card.Red
      else
        return to_select.type == Card.TypeTrick
      end
    end
  end,
  view_as = function(self, to_select, player)
    local card
    if player:getSwitchSkillState("longnu", true) == fk.SwitchYang then
      card = Fk:cloneCard("fire__slash", to_select.suit, to_select.number)
    else
      card = Fk:cloneCard("thunder__slash", to_select.suit, to_select.number)
    end
    card.skillName = "longnu"
    return card
  end,
}
local longnu_targetmod = fk.CreateTargetModSkill{
  name = "#longnu_targetmod",
  distance_limit_func =  function(self, player, skill, card)
    return (player:getMark("_longnu-phase") == "yang" and skill.trueName == "slash_skill" and card.name == "fire__slash") and 999 or 0
  end,
  residue_func = function(self, player, skill, scope, card)
    return (player:getMark("_longnu-phase") == "yin" and skill.trueName == "slash_skill" and scope == Player.HistoryPhase and card.name == "thunder__slash") and 999 or 0
  end,
}
longnu:addRelatedSkill(longnu_filter)
longnu:addRelatedSkill(longnu_targetmod)
local jieying = fk.CreateTriggerSkill{
  name = "jieying",
  events = {fk.BeforeChainStateChange, fk.EventPhaseStart, fk.EventAcquireSkill, fk.EventLoseSkill},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self and target == player
    end
    if not player:hasSkill(self.name) then return false end
    if event == fk.BeforeChainStateChange then
      return target == player and player.chained
    elseif target == player and player.phase == Player.Finish then 
      return table.find(player.room.alive_players, function(p) 
        return p ~= player and not p.chained
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill then
      player:setChainState(true)
    elseif event == fk.EventLoseSkill then
      player:setChainState(false)
    elseif event == fk.BeforeChainStateChange then
      return true
    else
      local availableTargets = table.map(table.filter(player.room.alive_players, function(p) 
        return p ~= player and not p.chained
      end), function(p)
        return p.id
      end)
      if #availableTargets == 0 then return false end
      local room = player.room
      local targets = room:askForChoosePlayers(player, availableTargets, 1, 1, "#jieying-target", self.name, false)
      room:getPlayerById(targets[1]):setChainState(true)
    end
  end,
}
local jieying_maxcards = fk.CreateMaxCardsSkill{
  name = "#jieying_maxcards",
  correct_func = function(self, player)
    if not player.chained then return false end
    local num = #table.filter(Fk:currentRoom().alive_players, function(p)
      return p:hasSkill(jieying.name) 
    end)
    return 2 * num
  end,
}
jieying:addRelatedSkill(jieying_maxcards)
godliubei:addSkill(longnu)
godliubei:addSkill(jieying)
Fk:loadTranslationTable{
  ["godliubei"] = "神刘备",
  ["longnu"] = "龙怒",
  [":longnu"] = "转换技，锁定技，出牌阶段开始时，阳：你失去1点体力，摸一张牌，你的红色手牌于此阶段内均视为火【杀】，你于此阶段内使用火【杀】无距离限制；"..
  "阴：你减1点体力上限，摸一张牌，你的锦囊牌于此阶段内均视为雷【杀】，你于此阶段内使用雷【杀】无次数限制。",
  ["jieying"] = "结营",
  [":jieying"] = "锁定技，你始终处于横置状态；处于连环状态的角色手牌上限+2；结束阶段开始时，你横置一名其他角色。",

  ["#longnu_filter"] = "龙怒",
  ["#jieying-target"] = "结营：选择一名其他角色，令其横置",

  ["$longnu1"] = "损身熬心，誓报此仇！",
  ["$longnu2"] = "兄弟疾难，血债血偿！",
  ["$jieying1"] = "桃园结义，营一世之交。",
  ["$jieying2"] = "结草衔环，报兄弟大恩。",
  ["~godliubei"] = "桃园依旧，来世再结……",
}

local godluxun = General(extension, "godluxun", "god", 4)
local junlue = fk.CreateTriggerSkill{
  name = "junlue",
  events = {fk.Damage, fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@junlue", data.damage)
  end,
}
godluxun:addSkill(junlue)
local cuike = fk.CreateTriggerSkill{
  name = "cuike",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local is_dmg = player:getMark("@junlue") % 2 == 1
    local room = player.room
    local targets
    if is_dmg then
      targets = table.map(room.alive_players, Util.IdMapper)
    else
      targets = table.map(table.filter(room.alive_players, function(p)
        return not p:isAllNude()
      end), Util.IdMapper)
    end

    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1,
      is_dmg and "#cuike-damage" or "#cuike-discard", self.name, true)

    if tos[1] then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local is_dmg = player:getMark("@junlue") % 2 == 1
    local room = player.room
    local to = room:getPlayerById(self.cost_data)

    if is_dmg then
      room:damage {
        from = player, to = to,
        damage = 1, skillName = self.name
      }
    else
      local cid = room:askForCardChosen(player, to, "hej", self.name)
      room:throwCard(cid, self.name, to, player)
      if not to.chained then
        to:setChainState(true)
      end
    end

    if player:getMark("@junlue") > 7 then
      if room:askForSkillInvoke(player, self.name, nil, "#cuike-shenfen") then
        room:setPlayerMark(player, "@junlue", 0)
        for _, p in ipairs(room:getOtherPlayers(player)) do
          room:damage {
            from = player, to = p,
            damage = 1, skillName = self.name
          }
        end
      end
    end
  end,
}
godluxun:addSkill(cuike)
local zhanhuo = fk.CreateActiveSkill{
  name = "zhanhuo",
  anim_type = "offensive",
  min_target_num = 1,
  max_target_num = function()
    return math.max(Self:getMark("@junlue"), 1)
  end,
  card_num = 0,
  frequency = Skill.Limited,
  card_filter = function() return false end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player:getMark("@junlue") > 0
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected < Self:getMark("@junlue") and Fk:currentRoom():getPlayerById(to_select).chained
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "@junlue", 0)

    for _, pid in ipairs(effect.tos) do
      local to = room:getPlayerById(pid)
      room:throwCard(to:getCardIds(Player.Equip), self.name, to, to)
    end

    local tos = room:askForChoosePlayers(player, effect.tos, 1, 1, "#zhanhuo-damage", self.name, false)
    room:damage {
      from = player, to = room:getPlayerById(tos[1]),
      damage = 1, damageType = fk.FireDamage, skillName = self.name
    }
  end,

  prompt = "#zhanhuo-prompt",
}
godluxun:addSkill(zhanhuo)
Fk:loadTranslationTable{
  ["godluxun"] = "神陆逊",
  ["junlue"] = "军略",
  [":junlue"] = "锁定技，当你造成或受到1点伤害后，你获得一枚“军略”。",
  ["@junlue"] = "军略",
  ["cuike"] = "摧克",
  [":cuike"] = "出牌阶段开始时，若你的“军略”数为：奇数，你可以对一名角色造成1点伤害；偶数，你可以弃置一名角色区域里的一张牌，令其横置。然后若“军略”数大于7，你可弃全部“军略”，对所有其他角色各造成1点伤害。",
  ["#cuike-damage"] = "摧克：你可以对一名角色造成1点伤害",
  ["#cuike-discard"] = "摧克：你可以弃置一名角色区域里的一张牌并横置之",
  ["#cuike-shenfen"] = "摧克：你可以弃置所有“军略”对所有其他角色各造成1点伤害",
  ["zhanhuo"] = "绽火",
  [":zhanhuo"] = "限定技，出牌阶段，你可以弃全部“军略”，令至多等量的处于连环状态的角色弃置所有装备区里的牌，然后对其中一名角色造成1点火焰伤害。",
  ["#zhanhuo-damage"] = "绽火：对其中一名角色造成一点火焰伤害",
  ["#zhanhuo-prompt"] = "绽火：弃置全部“军略”并选择至多等量处于连环状态中的角色",

  ["$junlue1"] = "军略绵腹，制敌千里。",
  ["$junlue2"] = "文韬武略兼备，方可破敌如破竹。",
  ["$cuike1"] = "克险摧难，军略当先。",
  ["$cuike2"] = "摧敌心神，克敌计谋。",
  ["$zhanhuo1"] = "业火映东水，吴志绽敌营！",
  ["$zhanhuo2"] = "绽东吴业火，烧敌军数千！",
  ["~godluxun"] = "东吴业火，终究熄灭…",
}

local godzhangliao = General(extension, "godzhangliao", "god", 4)

local duorui = fk.CreateTriggerSkill{
  name = "duorui",
  anim_type = "control",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getMark("duorui_source") == 0 and
    #player:getAvailableEquipSlots() > 0 and data.to ~= player and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"WeaponSlot", "ArmorSlot", "DefensiveRideSlot", "OffensiveRideSlot", "TreasureSlot"}
    local subtypes = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
    local choices = {}
    for i = 1, 5, 1 do
      if #player:getAvailableEquipSlots(subtypes[i]) > 0 then
        table.insert(choices, all_choices[i])
      end
    end
    table.insert(all_choices, "Cancel")
    table.insert(choices, "Cancel")
    local choice = player.room:askForChoice(player, choices, self.name, "#duorui-choice::" .. data.to.id, false, all_choices)
    if choice ~= "Cancel" then
      player.room:doIndicate(player.id, {data.to.id})
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, _, player, data)
    local room = player.room
    room:abortPlayerArea(player, {self.cost_data})
    local target = data.to
    if player.dead or target.dead then return false end
    local skills = {}
    local ban_types = {Skill.Limited, Skill.Wake, Skill.Quest}
    for _, skill_name in ipairs(Fk.generals[target.general]:getSkillNameList()) do
      local skill = Fk.skills[skill_name]
      if not (skill.lordSkill or table.contains(ban_types, skill.frequency)) then
        table.insertIfNeed(skills, skill_name)
      end
    end
    if target.deputyGeneral and target.deputyGeneral ~= "" then
      for _, skill_name in ipairs(Fk.generals[target.deputyGeneral]:getSkillNameList()) do
        local skill = Fk.skills[skill_name]
        if not (skill.lordSkill or table.contains(ban_types, skill.frequency)) then
          table.insertIfNeed(skills, skill_name)
        end
      end
    end
    if #skills == 0 then return false end
    local choice = room:askForChoice(player, skills, self.name, "#duorui-skill::" .. data.to.id, true)
    local mark = type(target:getMark("duorui_target")) == "table" and target:getMark("duorui_target") or {}
    table.insert(mark, choice)
    room:setPlayerMark(target, "duorui_target", mark)
    room:setPlayerMark(target, "@duorui_target", choice)
    if player:hasSkill(choice, true) then return false end
    local mark2 = type(player:getMark("duorui_source")) == "table" and player:getMark("duorui_source") or {}
    table.insert(mark2, {target.id, choice})
    room:setPlayerMark(player, "duorui_source", mark2)
    room:setPlayerMark(player, "@duorui_source", choice)
    room:handleAddLoseSkills(player, choice, nil, true, true)
  end,

  refresh_events = {fk.AfterTurnEnd, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player == target then
      room:setPlayerMark(player, "duorui_target", 0)
      room:setPlayerMark(player, "@duorui_target", 0)
    end
    local mark = player:getMark("duorui_source")
    if type(mark) ~= "table" then return false end
    local clear_skills = {}
    local mark2 = {}
    for _, duorui_info in ipairs(mark) do
      if duorui_info[1] == target.id then
        table.insertIfNeed(clear_skills, duorui_info[2])
      else
        table.insertIfNeed(mark2, duorui_info)
      end
    end
    if #clear_skills > 0 then
      if #mark2 > 0 then
        room:setPlayerMark(player, "duorui_source", mark2)
        room:setPlayerMark(player, "@duorui_source", mark2[#mark2][2])
      else
        room:setPlayerMark(player, "duorui_source", 0)
        room:setPlayerMark(player, "@duorui_source", 0)
      end
      room:handleAddLoseSkills(player, "-"..table.concat(clear_skills, "|-"), nil, true, false)
    end
  end,
}
local duorui_invalidity = fk.CreateInvaliditySkill {
  name = "#duorui_invalidity",
  invalidity_func = function(self, from, skill)
    local mark = from:getMark("duorui_target")
    return type(mark) == "table" and table.contains(mark, skill.name)
  end
}
local zhiti = fk.CreateTriggerSkill{
  name = "zhiti",
  events = {fk.Damage, fk.Damaged, fk.PindianResultConfirmed},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) or table.every(player.sealedSlots, function(slot_name)
      return slot_name == Player.JudgeSlot
    end) then return false end
    if event == fk.Damage then
      return player == target and data.card and data.card.trueName == "duel" and data.to:isWounded() and player:inMyAttackRange(data.to)
    elseif event == fk.Damaged then
      return player == target and data.from and data.from:isWounded() and player:inMyAttackRange(data.from)
    elseif event == fk.PindianResultConfirmed then
      if data.winner == player then
        if player == data.from then
          return data.to:isWounded() and player:inMyAttackRange(data.to)
        else
          return data.from:isWounded() and player:inMyAttackRange(data.from)
        end
      end
    end
  end,
  on_use = function(self, event, _, player, data)
    local all_slots = {"WeaponSlot", "ArmorSlot", "DefensiveRideSlot", "OffensiveRideSlot", "TreasureSlot"}
    local choices = {}
    for _, equip_slot in ipairs(all_slots) do
      if table.contains(player.sealedSlots, equip_slot) then
        table.insert(choices, equip_slot)
      end
    end
    if #choices > 0 then
      local choice = player.room:askForChoice(player, choices, self.name, "#zhiti-choice", false)
      player.room:resumePlayerArea(player, {choice})
    end
  end,
}
local zhiti_maxcards = fk.CreateMaxCardsSkill{
  name = "#zhiti_maxcards",
  correct_func = function(self, player)
    if not player:isWounded() then return 0 end
    return - #table.filter(Fk:currentRoom().alive_players, function(p)
      return p:hasSkill(zhiti.name) and p:inMyAttackRange(player) end
    )
  end,
}
duorui:addRelatedSkill(duorui_invalidity)
zhiti:addRelatedSkill(zhiti_maxcards)
godzhangliao:addSkill(duorui)
godzhangliao:addSkill(zhiti)

Fk:loadTranslationTable{
  ["godzhangliao"] = "神张辽",
  ["duorui"] = "夺锐",
  [":duorui"] = "当你于出牌阶段内对一名其他角色造成伤害后，你可以废除你的一个装备栏，然后选择该角色的武将牌上的一个技能"..
  "（限定技、觉醒技、使命技、主公技除外），令其于其下回合结束之前此技能无效，然后你于其下回合结束或其死亡之前拥有此技能且不能发动〖夺锐〗。",
  ["zhiti"] = "止啼",
  [":zhiti"] = "锁定技，你攻击范围内已受伤的角色手牌上限-1；当你和这些角色拼点或【决斗】你赢时，你恢复一个装备栏。"..
  "当你受到伤害后，若来源在你的攻击范围内且已受伤，你恢复一个装备栏。",

  ["#duorui-choice"] = "是否发动 夺锐，废除一个装备栏，夺取%dest一个技能",
  ["#duorui-skill"] = "夺锐：选择%dest的一个技能令其无效，且你获得此技能",
  ["@duorui_source"] = "夺锐",
  ["@duorui_target"] = "被夺锐",
  ["#zhiti-choice"] = "止啼：选择要恢复的装备栏",

  ["$duorui1"] = "夺敌军锐气，杀敌方士气。",
  ["$duorui2"] = "尖锐之势，吾亦可一人夺之！",
  ["$zhiti1"] = "江东小儿，安敢啼哭？",
  ["$zhiti2"] = "娃闻名止啼，孙损十万休。",
  ["~godzhangliao"] = "我也有……被孙仲谋所伤之时？",
}

local godganning = General(extension, "godganning", "god", 3, 6)

local poxi = fk.CreateActiveSkill{
  name = "poxi",
  anim_type = "control",
  prompt = "#poxi-prompt",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local player_hands = player:getCardIds(Player.Hand)
    local target_hands = target:getCardIds(Player.Hand)

    local result = room:askForCustomDialog(player, self.name,
      "packages/shzl/qml/PoxiBox.qml", {
        player.general, player_hands,
        target.general, target_hands,
      })

    if result == "" then return end
    local cards = json.decode(result)

    local cards1 = table.filter(cards, function(id)
      return table.contains(player_hands, id)
    end)
    local cards2 = table.filter(cards, function(id)
      return table.contains(target_hands, id)
    end)
    if #cards1 == 0 and #cards2 == 0 then return false end

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
    if player.dead then return false end

    if #cards1 == 0 then
      room:changeMaxHp(player, -1)
    elseif #cards1 == 3 and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    elseif #cards1 == 1 then
      room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn)
      room.logic:getCurrentEvent():findParent(GameEvent.Phase):shutdown()
    elseif #cards1 == 4 then
      room:drawCards(player, 4, self.name)
    end
    return false
  end,
}
local gn_jieying = fk.CreateTriggerSkill{
  name = "gn_jieying",
  anim_type = "drawcard",
  events = {fk.DrawNCards, fk.EventPhaseStart, fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.EventPhaseChanging then
      return player == target and data.from == Player.RoundStart and table.every(player.room.alive_players, function (p)
        return p:getMark("@@jieying_camp") == 0 end)
    elseif event == fk.EventPhaseStart and target.phase ~= Player.Finish then
      return false
    end
    return target:getMark("@@jieying_camp") > 0
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart and player == target then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
        return p.id end), 1, 1, "#gn_jieying-choose", self.name, true)
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
    if event == fk.EventPhaseChanging then
      room:addPlayerMark(player, "@@jieying_camp")
    elseif event == fk.DrawNCards then
      data.n = data.n + 1
    elseif event == fk.EventPhaseStart then
      if player == target then
        local tar = room:getPlayerById(self.cost_data)
        room:setPlayerMark(player, "@@jieying_camp", 0)
        room:addPlayerMark(tar, "@@jieying_camp")
      else
        room:setPlayerMark(target, "@@jieying_camp", 0)
        room:addPlayerMark(player, "@@jieying_camp")
        if not target:isKongcheng() then
          local dummy = Fk:cloneCard("dilu")
          dummy:addSubcards(target.player_cards[Player.Hand])
          room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
        end
      end
    end
    return false
  end,

  refresh_events = {fk.BuryVictim, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return (event == fk.BuryVictim or data == self) and player:getMark("@@jieying_camp") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if table.every(room.alive_players, function (p) return not p:hasSkill(self.name, true) end) then
      room:setPlayerMark(player, "@@jieying_camp", 0)
    end
  end,
}
local gn_jieying_targetmod = fk.CreateTargetModSkill{
  name = "#gn_jieying_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@jieying_camp") > 0 and scope == Player.HistoryPhase then
      return #table.filter(Fk:currentRoom().alive_players, function (p) return p:hasSkill(gn_jieying.name) end)
    end
  end,
}
local gn_jieying_maxcards = fk.CreateMaxCardsSkill{
  name = "#gn_jieying_maxcards",
  correct_func = function(self, player)
    if player:getMark("@@jieying_camp") > 0 then
      return #table.filter(Fk:currentRoom().alive_players, function (p) return p:hasSkill(gn_jieying.name) end)
    else
      return 0
    end
  end,
}
gn_jieying:addRelatedSkill(gn_jieying_targetmod)
gn_jieying:addRelatedSkill(gn_jieying_maxcards)
godganning:addSkill(poxi)
godganning:addSkill(gn_jieying)
Fk:loadTranslationTable{
  ["godganning"] = "神甘宁",
  ["poxi"] = "魄袭",
  [":poxi"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后你可以弃置你与其手里共计四张不同花色的牌。若如此做，根据此次弃置你的牌数量执行以下效果：没有，体力上限减1；一张，结束出牌阶段且本回合手牌上限-1；三张，回复1点体力；四张，摸四张牌。",
  ["gn_jieying"] = "劫营",
  [":gn_jieying"] = "回合开始时，若没有角色有“营”标记，你获得一个“营”标记；结束阶段你可以将“营”标记交给一名其他角色；有“营”的角色摸牌阶段多摸一张牌、使用【杀】的次数上限+1、手牌上限+1。有“营”的其他角色的结束阶段，你获得其“营”标记及所有手牌。",

  ["#poxi-prompt"] = "魄袭：选择一名有手牌的其他角色，并可弃置你与其手牌中共计四张花色各不相同的牌",
  ["@@jieying_camp"] = "营",
  ["#poxi-choose"] = "魄袭：从双方的手牌中选出四张不同花色的牌弃置，或者点取消",
  ["#gn_jieying-choose"] = "劫营：你可将营标记交给其他角色",
  
  ["$poxi1"] = "夜袭敌军，挫其锐气。",
  ["$poxi2"] = "受主知遇，袭敌不惧。",
  ["$gn_jieying1"] = "裹甲衔枚，劫营如入无人之境。",
  ["$gn_jieying2"] = "劫营速战，措手不及。",
  ["~godganning"] = "吾不能奉主，谁辅主基业？",
}

local goddiaochan = General(extension, "goddiaochan", "god", 3, 3, General.Female)
local meihun = fk.CreateTriggerSkill{
  name = "meihun",
  anim_type = "control",
  mute = true,
  events = {fk.EventPhaseStart, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self.name)) then return end
    if event == fk.EventPhaseStart then
      return player.phase == Player.Finish
    elseif event == fk.TargetConfirmed then
      return data.card.trueName == "slash"
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isNude() then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end

    local p = room:askForChoosePlayers(player, targets, 1, 1,
      "#meihun-choose", self.name, true)

    if p[1] then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    if event == fk.TargetConfirmed then
      player:broadcastSkillInvoke(self.name, math.random(1, 2))
    else
      player:broadcastSkillInvoke(self.name, math.random(3, 4))
    end

    local choice = room:askForChoice(player,
      {"spade", "heart", "club", "diamond"}, self.name)

    local to = room:getPlayerById(self.cost_data)
    local c = table.find(to:getCardIds{ Player.Hand, Player.Equip }, function(id)
      return Fk:getCardById(id):getSuitString() == choice
    end)

    if c then
      local card = room:askForCard(to, 1, 1, true, self.name, false,
        ".|.|" .. choice, "#meihun-give:" .. player.id .. "::" .. choice)

      room:obtainCard(player, card[1], false, fk.ReasonGive)
    else
      local cids = to:getCardIds(Player.Hand)
      if #cids == 0 then return end
      room:fillAG(player, cids)

      local id = room:askForAG(player, cids, false, self.name)
      room:closeAG(player)

      if not id then return false end
      room:throwCard(id, self.name, to, player)
    end
  end,
}
local huoxinTrig = fk.CreateTriggerSkill{
  name = "#huoxin_trig",
  mute = true,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and
      target:getMark("@huoxin-meihuo") >= 2 and target.faceup
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("huoxin")
    room:notifySkillInvoked(player, "huoxin")

    room:setPlayerMark(target, "@huoxin-meihuo", 0)
    room:addPlayerMark(target, "huoxincontrolled", 1)

    player:control(target)
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(_, _, target, player)
    return target == player and target:getMark("huoxincontrolled") > 0
  end,
  on_refresh = function(_, _, target)
    local room = target.room
    room:setPlayerMark(target, "huoxincontrolled", 0)
    target:control(target)
  end,
}
local huoxin = fk.CreateActiveSkill{
  name = "huoxin",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 2,
  target_num = 2,
  target_filter = function(self, to_select, selected)
    return #selected < 2 and to_select ~= Self.id
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 1 then 
      return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and
        Fk:getCardById(to_select).suit == Fk:getCardById(selected[1]).suit

    elseif #selected == 2 then
      return false
    end

    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local tos = effect.tos
    local target1 = room:getPlayerById(tos[1])
    local target2 = room:getPlayerById(tos[2])
    local cards = effect.cards
    local cpattern = ".|.|.|.|.|.|" .. table.concat(cards, ",")

    from:showCards(cards)

    local p, cid = room:askForChooseCardAndPlayers(from, tos, 1, 1, cpattern,
      "#huoxin-choose", self.name, false)

    table.removeOne(cards, cid)

    if p[1] == target1.id then
      room:obtainCard(target1, cid, true, fk.ReasonGive)
      room:obtainCard(target2, cards[1], true, fk.ReasonGive)
    else
      room:obtainCard(target2, cid, true, fk.ReasonGive)
      room:obtainCard(target1, cards[1], true, fk.ReasonGive)
    end

    local pindianData = target1:pindian({ target2 }, self.name)
    local winner = pindianData.results[target2.id].winner
    local fix = math.abs(pindianData.results[target2.id].toCard.number - pindianData.fromCard.number) >= 5 and 1 or 0
    if winner ~= target1 then
      room:addPlayerMark(target1, "@huoxin-meihuo", 1 + fix)
    end
    if winner ~= target2 then
      room:addPlayerMark(target2, "@huoxin-meihuo", 1 + fix)
    end
  end
}
huoxin:addRelatedSkill(huoxinTrig)
goddiaochan:addSkill(meihun)
goddiaochan:addSkill(huoxin)
Fk:loadTranslationTable{
  ["goddiaochan"] = "神貂蝉",
  ["meihun"] = "魅魂",
  [":meihun"] = "结束阶段或当你成为【杀】目标后，你可以令一名其他角色" ..
    "交给你一张你声明的花色的牌，若其没有则你观看其手牌然后弃置其中一张。",
  ["#meihun-choose"] = "魅魂：你可以对一名其他角色发动“魅魂”",
  ["#meihun-give"] = "魅魂：请交给 %src 一张 %arg 牌",

  ["huoxin"] = "惑心",
  [":huoxin"] = "出牌阶段限一次，你可以展示两张花色相同的手牌并分别交给两名" ..
    "其他角色，然后令这两名角色拼点，没赢的角色获得1个“魅惑”标记；若双方拼点点数" ..
    "相差5或更多，改为获得2个“魅惑”标记。拥有2个或" ..
    "更多“魅惑”的角色回合即将开始时，该角色移去其所有“魅惑”，" ..
    "此回合改为由你操控。",
  ["@huoxin-meihuo"] = "魅惑",
  ["#huoxin-choose"] = "惑心：请将一张牌交给其中一名角色，另一张牌自动交给另一名",
  ["#huoxin-pindian"] = "惑心：请选择拼点牌，拼点没赢会获得1枚魅惑标记",
  ["#huoxin_trig"] = "惑心",

  -- CV: 桃妮儿
  ["cv:goddiaochan"] = "桃妮儿",
  ["~goddiaochan"] = "也许，你们日后的所闻所望，都是我某天的所叹所想…",
  ["$meihun1"] = "将军还记得那晚的话么？弄疼人家，要赔不是哦~",
  ["$meihun2"] = "让我看看，将军这次会为我心软，还是耳根子软~",
  ["$meihun3"] = "眼前皆是身外物，将军所在，即吾心归处…",
  ["$meihun4"] = "既然你说我是魔鬼中的天使，那我就再任性一次~",
  ["$huoxin1"] = "今天下大乱，就不能摒弃儿女私情，挺身而出吗！",
  ["$huoxin2"] = "谁怜九州难救天下人，我有一心只付将军身…",
}

return extension
