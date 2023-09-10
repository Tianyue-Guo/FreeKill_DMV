-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("espionage_cards", Package.CardPack)
extension.extensionName = "game_mode"
extension.game_modes_blacklist = {"m_1v1_mode", "m_1v2_mode", "m_2v2_mode", "zombie_mode", "heg_mode"}
Fk:loadTranslationTable{
  ["espionage_cards"] = "用间",
}

extension:addCards{
  Fk:cloneCard("slash", Card.Heart, 5),--赠
  Fk:cloneCard("slash", Card.Heart, 10),--赠
  Fk:cloneCard("slash", Card.Heart, 11),--赠
  Fk:cloneCard("slash", Card.Heart, 12),--赠
}

local slash = Fk:cloneCard("slash")
local stabSlashSkill = fk.CreateActiveSkill{
  name = "stab__slash_skill",
  max_phase_use_time = 1,
  target_num = 1,
  can_use = slash.skill.canUse,
  mod_target_filter = slash.skill.modTargetFilter,
  target_filter = slash.skill.targetFilter,
  on_effect = slash.skill.onEffect,
}
local stab__slash_trigger = fk.CreateTriggerSkill{
  name = "stab__slash_trigger",
  global = true,
  mute = true,
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return data.card.name == "stab__slash" and data.to == player.id and not player.dead and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#stab__slash-discard:::"..data.card:toLogString(), true)
    if #card == 0 then
      return true
    else
      room:throwCard(card, self.name, player, player)
      local e = room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if e then
        e:shutdown()
      end
    end
  end,
}
Fk:addSkill(stab__slash_trigger)
local stabSlash = fk.CreateBasicCard{
  name = "stab__slash",
  skill = stabSlashSkill,
  is_damage_card = true,
}
extension:addCards{
  stabSlash:clone(Card.Spade, 6),
  stabSlash:clone(Card.Spade, 7),
  stabSlash:clone(Card.Spade, 8),
  stabSlash:clone(Card.Club, 2),
  stabSlash:clone(Card.Club, 6),
  stabSlash:clone(Card.Club, 7),
  stabSlash:clone(Card.Club, 8),
  stabSlash:clone(Card.Club, 9),
  stabSlash:clone(Card.Club, 10),
  stabSlash:clone(Card.Diamond, 13),
}
Fk:loadTranslationTable{
  ["stab__slash"] = "刺杀",
  ["stab__slash_trigger"] = "刺杀",
	[":stab__slash"] = "基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：攻击范围内的一名角色<br/><b>效果</b>：对目标角色造成1点伤害。"..
  "当目标角色使用【闪】抵消刺【杀】时，若其有手牌，其需弃置一张手牌，否则此刺【杀】依然造成伤害。",
  ["#stab__slash-discard"] = "请弃置一张手牌，否则%arg依然对你生效",
}

extension:addCards{
  Fk:cloneCard("jink", Card.Heart, 2),--赠
  Fk:cloneCard("jink", Card.Diamond, 2),--赠
  Fk:cloneCard("jink", Card.Diamond, 5),
  Fk:cloneCard("jink", Card.Diamond, 6),
  Fk:cloneCard("jink", Card.Diamond, 7),
  Fk:cloneCard("jink", Card.Diamond, 8),
  Fk:cloneCard("jink", Card.Diamond, 12),

  Fk:cloneCard("peach", Card.Heart, 7),
  Fk:cloneCard("peach", Card.Heart, 8),
  Fk:cloneCard("peach", Card.Diamond, 11),--赠

  --[[Fk:cloneCard("poison", Card.Spade, 4),--赠
  Fk:cloneCard("poison", Card.Spade, 5),--赠
  Fk:cloneCard("poison", Card.Spade, 9),--赠
  Fk:cloneCard("poison", Card.Spade, 10),--赠
  Fk:cloneCard("poison", Card.Club, 4),]]--

  Fk:cloneCard("snatch", Card.Spade, 3),--赠

  Fk:cloneCard("duel", Card.Diamond, 1),--赠

  Fk:cloneCard("nullification", Card.Spade, 11),
  Fk:cloneCard("nullification", Card.Club, 11),
  Fk:cloneCard("nullification", Card.Club, 12),

  Fk:cloneCard("amazing_grace", Card.Heart, 3),--赠
}

local snatch = Fk:cloneCard("snatch")
local sincereTreatSkill = fk.CreateActiveSkill{
  name = "sincere_treat_skill",
  distance_limit = 1,
  target_num = 1,
  mod_target_filter = snatch.skill.modTargetFilter,
  target_filter = snatch.skill.targetFilter,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.to)
    if player.dead or target.dead or target:isAllNude() then return end
    local cards = room:askForCardsChosen(player, target, 1, 2, "hej", self.name)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(cards)
    room:obtainCard(player, dummy, false, fk.ReasonPrey)
    if not player.dead and not target.dead or player:isKongcheng() then
      local n = math.min(#cards, player:getHandcardNum())
      local cards2 = room:askForCard(player, n, n, false, self.name, false, ".|.|.|hand", "#sincere_treat-give::"..target.id..":"..n)
      local dummy2 = Fk:cloneCard("dilu")
      dummy2:addSubcards(cards2)
      room:obtainCard(target, dummy2, false, fk.ReasonGive)
    end
  end
}
local sincere_treat = fk.CreateTrickCard{
  name = "sincere_treat",
  skill = sincereTreatSkill,
}
extension:addCards({
  sincere_treat:clone(Card.Diamond, 9),
  sincere_treat:clone(Card.Diamond, 10),
})
Fk:loadTranslationTable{
  ["sincere_treat"] = "推心置腹",
  ["sincere_treat_skill"] = "推心置腹",
  [":sincere_treat"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：距离为1的一名区域内有牌的其他角色<br/><b>效果</b>：你获得目标角色"..
  "区域里至多两张牌，然后交给其等量的手牌。",
  ["#sincere_treat-give"] = "推心置腹：请交给 %dest %arg张手牌",
}

local lootingSkill = fk.CreateActiveSkill{
  name = "looting_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return to_select ~= user and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  target_filter = function(self, to_select)
    return to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.to)
    if player.dead or target.dead or target:isKongcheng() then return end
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards(id)
    if player.dead or target.dead then return end
    if room:getCardOwner(id) == target and room:getCardArea(id) == Card.PlayerHand then
      if room:askForSkillInvoke(target, self.name, nil, "#looting-give:"..player.id.."::"..effect.card:toLogString()) then
        room:obtainCard(player, id, true, fk.ReasonGive)
      else
        room:damage({
          from = player,
          to = target,
          card = effect.card,
          damage = 1,
          skillName = self.name
        })
      end
    else
      room:damage({
        from = player,
        to = target,
        card = effect.card,
        damage = 1,
        skillName = self.name
      })
    end
  end
}
local looting = fk.CreateTrickCard{
  name = "looting",
  skill = lootingSkill,
  is_damage_card = true,
}
extension:addCards({
  looting:clone(Card.Spade, 12),
  looting:clone(Card.Spade, 13),
  looting:clone(Card.Heart, 6),
})
Fk:loadTranslationTable{
  ["looting"] = "趁火打劫",
  ["looting_skill"] = "趁火打劫",
  [":looting"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名有手牌的其他角色<br/><b>效果</b>：你展示目标角色一张手牌，"..
  "然后令其选择一项：将此牌交给你，或受到你造成的1点伤害。",
  ["#looting-give"] = "趁火打劫：点“确定”将此牌交给 %src ，或点“取消”其对你造成1点伤害",
}

Fk:loadTranslationTable{
  ["bogus_flower"] = "树上开花",
  ["bogus_flower_skill"] = "树上开花",
  [":bogus_flower"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：你<br/><b>效果</b>：目标角色弃置至多两张牌，然后摸等量的牌；"..
  "若弃置了装备牌，则多摸一张牌。",
}

return extension
