local extension = Package("sp_re")
extension.extensionName = "sp"

Fk:loadTranslationTable{
  ["sp_re"] = "RE.SP",
  ["re"] = "RE",
}

local masu = General(extension, "re__masu", "shu", 3)
local sanyao = fk.CreateActiveSkill{
  name = "sanyao",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.hp > n then
          n = p.hp
        end
      end
      return Fk:currentRoom():getPlayerById(to_select).hp == n
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
    }
  end
}
local zhiman = fk.CreateTriggerSkill{
  name = "zhiman",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to ~= player
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhiman-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #data.to:getCardIds{Player.Equip, Player.Judge} > 0 then
      local card = room:askForCardChosen(player, data.to, "ej", self.name)
      room:obtainCard(player.id, card, true, fk.ReasonPrey)
    end
    return true
  end
}
masu:addSkill(sanyao)
masu:addSkill(zhiman)
Fk:loadTranslationTable{
  ["re__masu"] = "马谡",
  ["sanyao"] = "散谣",
  [":sanyao"] = "出牌阶段限一次，你可以弃置一张牌并选择一名体力值最大的角色，你对其造成1点伤害。",
  ["zhiman"] = "制蛮",
  [":zhiman"] = "当你对其他角色造成伤害时，你可以防止此伤害，然后获得其装备区或判定区的一张牌。",
  ["#zhiman-invoke"] = "制蛮：你可以防止对 %dest 造成的伤害，然后获得其场上的一张牌",

  ["$sanyao1"] = "三人成虎，事多有。",
  ["$sanyao2"] = "散谣惑敌，不攻自破！",
}

local yujin = General(extension, "re__yujin", "wei", 4)
local jieyue = fk.CreateViewAsSkill{
  name = "jieyue",
  pattern = "jink,nullification",
  card_filter = function(self, to_select, selected)
    if #Self:getPile(self.name) == 0 then return end
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card
    if Fk:getCardById(cards[1]).color == Card.Red then
      card = Fk:cloneCard("jink")
    elseif Fk:getCardById(cards[1]).color == Card.Black then
      card = Fk:cloneCard("nullification")
    end
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function(self, player)
    return #player:getPile(self.name) > 0
  end,
}
local jieyue_trigger = fk.CreateTriggerSkill{
  name = "#jieyue_trigger",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if player.phase == Player.Finish then
        return player:hasSkill("jieyue") and not player:isKongcheng()
      elseif player.phase == Player.Start then
        return #player:getPile("jieyue") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.phase == Player.Finish then
      local room = player.room
      local targets = {}
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not p:isNude() then
          table.insert(targets, p.id)
        end
      end
      if #targets == 0 then return end
      local tos, id = player.room:askForChooseCardAndPlayers(player, targets, 1, 1, ".|.|.|hand|.|.", "#jieyue-cost", "jieyue")
      if #tos > 0 then
        self.cost_data = {tos[1], id}
        return true
      end
    elseif player.phase == Player.Start then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Finish then
      room:throwCard(self.cost_data[2], "jieyue", player, player)
      if player.dead then return end
      local to = room:getPlayerById(self.cost_data[1])
      local card = room:askForCard(to, 1, 1, true, "jieyue", true, ".", "#jieyue-give:"..player.id)
      if #card > 0 then
        player:addToPile("jieyue", card, false, "jieyue")
      else
        local id = room:askForCardChosen(player, to, "he", "jieyue")
        room:throwCard({id}, "jieyue", to, player)
      end
    elseif player.phase == Player.Start then
      if player.dead then return end
      room:moveCards({
        from = player.id,
        ids = player:getPile("jieyue"),
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        skillName = "jieyue",
      })
    end
  end,
}
jieyue:addRelatedSkill(jieyue_trigger)
yujin:addSkill(jieyue)
Fk:loadTranslationTable{
  ["re__yujin"] = "于禁",
  ["jieyue"] = "节钺",
  [":jieyue"] = "结束阶段开始时，你可以弃置一张手牌并选择一名其他角色，若如此做，除非该角色将一张牌置于你的武将牌上，否则你弃置其一张牌。"..
  "若你的武将牌上有牌，则你可以将红色手牌当【闪】、黑色手牌当【无懈可击】使用或打出，准备阶段开始时，你获得你武将牌上的牌。",
  ["#jieyue_trigger"] = "节钺",
  ["#jieyue-cost"] = "节钺：你可以弃置一张手牌，令一名其他角色执行后续效果",
  ["#jieyue-give"] = "节钺：将一张牌置为 %src 的“节钺”牌，或其弃置你一张牌",
}

local liubiao = General(extension, "re__liubiao", "qun", 3)
local re__zishou = fk.CreateTriggerSkill{
  name = "re__zishou",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    data.n = data.n + #kingdoms
  end,
}
local zishou_prohibit = fk.CreateProhibitSkill{
  name = "#zishou_prohibit",
  is_prohibited = function(self, from, to, card)
    if from:hasSkill(self.name) then
      return from:usedSkillTimes("re__zishou") > 0 and from ~= to
    end
  end,
}
re__zishou:addRelatedSkill(zishou_prohibit)
liubiao:addSkill(re__zishou)
liubiao:addSkill("zongshi")
Fk:loadTranslationTable{
  ["re__liubiao"] = "刘表",
  ["re__zishou"] = "自守",
  [":re__zishou"] = "摸牌阶段，你可以额外摸X张牌（X为全场势力数）。若如此做，直到回合结束，其他角色不能被选择为你使用牌的目标。",
}

local madai = General(extension, "re__madai", "shu", 4)
local re__qianxi = fk.CreateTriggerSkill{
  name = "re__qianxi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    local card = room:askForDiscard(player, 1, 1, true, self.name, false, ".", "#qianxi-discard")
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player:distanceTo(p) == 1 then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#qianxi-choose", self.name, false)
    local to
    if #tos > 0 then
      to = tos[1]
    else
      to = targets[math.random(1, #targets)]
    end
    room:setPlayerMark(room:getPlayerById(to), "@qianxi-turn", Fk:getCardById(card[1]):getColorString())
  end,
}
local re__qianxi_prohibit = fk.CreateProhibitSkill{  --actually the same as YJ2012 new MaDai
  name = "#re__qianxi_prohibit",
  is_prohibited = function()
  end,
  prohibit_use = function(self, player, card)
    return player:getMark("@qianxi-turn") ~= 0 and card:getColorString() == player:getMark("@qianxi-turn")
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@qianxi-turn") ~= 0 and card:getColorString() == player:getMark("@qianxi-turn")
  end,
}
re__qianxi:addRelatedSkill(re__qianxi_prohibit)
madai:addSkill("mashu")
madai:addSkill(re__qianxi)
Fk:loadTranslationTable{
  ["re__madai"] = "马岱",
  ["re__qianxi"] = "潜袭",
  [":re__qianxi"] = "准备阶段开始时，你可以摸一张牌然后弃置一张牌。若如此做，你选择距离为1的一名角色，然后直到回合结束，"..
  "该角色不能使用或打出与你以此法弃置的牌颜色相同的手牌。",
  ["#qianxi-discard"] = "潜袭：弃置一张牌，令一名角色本回合不能使用或打出此颜色的手牌",
}

local bulianshi = General(extension, "re__bulianshi", "wu", 3, 3, General.Female)
local anxu = fk.CreateActiveSkill{
  name = "re__anxu",
  anim_type = "control",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    if #selected > 1 or to_select == Self.id then return false end
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      local target1 = Fk:currentRoom():getPlayerById(to_select)
      local target2 = Fk:currentRoom():getPlayerById(selected[1])
      return #target1.player_cards[Player.Hand] ~= #target2.player_cards[Player.Hand]
    else
      return false
    end
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target1 = room:getPlayerById(use.tos[1])
    local target2 = room:getPlayerById(use.tos[2])
    local from, to
    if #target1.player_cards[Player.Hand] < #target2.player_cards[Player.Hand] then
      from = target1
      to = target2
    else
      from = target2
      to = target1
    end
    local card = room:askForCard(to, 1, 1, false, self.name, false, ".", "#anxu-give::"..from.id)
    if #card == 0 then
      card = {table.random(to.player_cards[Player.Hand])}
    end
    if #card > 0 then
      room:obtainCard(from.id, Fk:getCardById(card[1]), false, fk.ReasonGive)
    end
    if #target1.player_cards[Player.Hand] == #target2.player_cards[Player.Hand] then
      local choices = {"draw1"}
      if player:isWounded() then
        table.insert(choices, "recover")
      end
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "draw1" then
        player:drawCards(1)
      else
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    end
  end,
}
bulianshi:addSkill(anxu)
bulianshi:addSkill("zhuiyi")
Fk:loadTranslationTable{
  ["re__bulianshi"] = "步练师",
  ["re__anxu"] = "安恤",
  [":re__anxu"] = "出牌阶段限一次，你可以选择两名手牌数不同的其他角色，令其中手牌多的角色将一张手牌交给手牌少的角色，然后若这两名角色手牌数相等，"..
  "你摸一张牌或回复1点体力。",
  ["#anxu-give"] = "安恤：你需将一张手牌交给 %dest",
}

local xusheng = General(extension, "re__xusheng", "wu", 4)
local pojun = fk.CreateTriggerSkill{
  name = "re__pojun",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.card.trueName == "slash" and
      not player.room:getPlayerById(data.to):isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local cards = room:askForCardsChosen(player, to, 0, to.hp, "he", self.name)
    if #cards > 0 then
      to:addToPile(self.name, cards, false, self.name)
    end
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target.phase == Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if #p:getPile(self.name) > 0 then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(p:getPile(self.name))
        room:obtainCard(p.id, dummy, false, fk.ReasonJustMove)
      end
    end
  end,
}
xusheng:addSkill(pojun)
Fk:loadTranslationTable{
  ["re__xusheng"] = "徐盛",
  ["re__pojun"] = "破军",
  [":re__pojun"] = "当你于出牌阶段内使用【杀】指定一个目标后，你可以将其至多X张牌扣置于该角色的武将牌旁（X为其体力值）。"..
  "若如此做，当前回合结束后，该角色获得其武将牌旁的所有牌。",
}

return extension
