local extension = Package("yczh2017")
extension.extensionName = "yj"

Fk:loadTranslationTable{
  ["yczh2017"] = "原创之魂2017",
}

local xushi = General(extension, "xushi", "wu", 3, 3, General.Female)
local wengua = fk.CreateActiveSkill{
  name = "wengua",
  anim_type = "support",
  card_num = 1,
  target_num = 0,
  prompt = "#wengua",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local choices = {"Cancel", "Top", "Bottom"}
    local choice = room:askForChoice(player, choices, self.name,
      "#wengua-choice::"..player.id..":"..Fk:getCardById(effect.cards[1]):toLogString())
    if choice == "Cancel" then return end
    local index = 1
    if choice == "Bottom" then
      index = -1
    end
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      drawPilePosition = index,
    })
    if choice == "Top" then
      player:drawCards(1, self.name, "bottom")
      player:drawCards(1, self.name, "bottom")
    else
      player:drawCards(1, self.name)
      player:drawCards(1, self.name)
    end
  end,
}
local wengua_trigger = fk.CreateTriggerSkill{
  name = "#wengua_trigger",

  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self.name, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self and not table.find(player.room:getOtherPlayers(player), function(p) return p:hasSkill("wengua", true) end)
    else
      return target == player and player:hasSkill(self.name, true, true) and
        not table.find(player.room:getOtherPlayers(player), function(p) return p:hasSkill("wengua", true) end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self.name, true) then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          room:handleAddLoseSkills(p, "wengua&", nil, false, true)
        end
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        room:handleAddLoseSkills(p, "-wengua&", nil, false, true)
      end
    end
  end,
}
local wengua_active = fk.CreateActiveSkill{
  name = "wengua&",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#wengua&",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):hasSkill("wengua")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = effect.cards[1]
    room:obtainCard(target.id, id, false, fk.ReasonGive)
    if room:getCardOwner(id) ~= target or room:getCardArea(id) ~= Card.PlayerHand then return end
    local choices = {"Cancel", "Top", "Bottom"}
    local choice = room:askForChoice(target, choices, "wengua",
      "#wengua-choice::"..player.id..":"..Fk:getCardById(id):toLogString())
    if choice == "Cancel" then return end
    local index = 1
    if choice == "Bottom" then
      index = -1
    end
    room:moveCards({
      ids = effect.cards,
      from = target.id,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = "wengua",
      drawPilePosition = index,
    })
    if choice == "Top" then
      player:drawCards(1, "wengua", "bottom")
      target:drawCards(1, "wengua", "bottom")
    else
      player:drawCards(1, "wengua")
      target:drawCards(1, "wengua")
    end
  end,
}
local fuzhu = fk.CreateTriggerSkill{
  name = "fuzhu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Finish and
      target.gender == General.Male and #player.room.draw_pile <= 10 * player.hp
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#fuzhu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local n = 0
    local cards = table.simpleClone(room.draw_pile)
    for _, id in ipairs(cards) do
      local card = Fk:getCardById(id, true)
      if card.trueName == "slash" then
        room:useCard({
          from = player.id,
          tos = {{target.id}},
          card = card,
        })
        n = n + 1
      end
      if n >= #room.players or player.dead or target.dead then
        break
      end
    end
    room:shuffleDrawPile()
  end,
}
Fk:addSkill(wengua_active)
wengua:addRelatedSkill(wengua_trigger)
xushi:addSkill(wengua)
xushi:addSkill(fuzhu)
Fk:loadTranslationTable{
  ["xushi"] = "徐氏",
  ["wengua"] = "问卦",
  [":wengua"] = "每名角色出牌阶段限一次，其可以交给你一张牌，然后你可以将此牌置于牌堆顶或牌堆底，你与其从另一端摸一张牌。",
  ["fuzhu"] = "伏诛",
  [":fuzhu"] = "一名男性角色结束阶段，若牌堆剩余牌数不大于你体力值的十倍，你可以依次对其使用牌堆中所有的【杀】（不能超过游戏人数），然后洗牌。",
  ["#wengua"] = "问卦：你可以将一张牌置于牌堆顶或牌堆底，从另一端摸两张牌",
  ["#wengua-choice"] = "问卦：你可以将 %arg 置于牌堆顶或牌堆底，然后你与 %dest 从另一端摸一张牌",
  ["wengua&"] = "问卦",
  [":wengua&"] = "出牌阶段限一次，你可以交给徐氏一张牌，然后其可以将此牌置于牌堆顶或牌堆底，其与你从另一端摸一张牌。",
  ["#wengua&"] = "问卦：你可以交给徐氏一张牌，然后其可以将此牌置于牌堆顶或牌堆底，从另一端各摸一张牌",
  ["#fuzhu-invoke"] = "伏诛：你可以对 %dest 使用牌堆中所有【杀】！",

  ["$wengua1"] = "阴阳相生相克，万事周而复始。",
  ["$wengua2"] = "卦不能佳，可须异日。",
  ["$zongzuo1"] = "我连做梦都在等这一天呢。",
  ["$zongzuo2"] = "既然来了，就别想走了。",
  ["~xushi"] = "莫问前程凶吉，但求落幕无悔。",
}

return extension
