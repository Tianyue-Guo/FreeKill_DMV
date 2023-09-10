-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("variation_cards", Package.CardPack)
extension.extensionName = "game_mode"
extension.game_modes_blacklist = {"m_1v1_mode", "m_1v2_mode", "m_2v2_mode", "zombie_mode"}
Fk:loadTranslationTable{
  ["variation_cards"] = "应变",
}

extension:addCards{
  Fk:cloneCard("slash", Card.Diamond, 6),
  Fk:cloneCard("slash", Card.Diamond, 7),
  Fk:cloneCard("slash", Card.Diamond, 9),
  Fk:cloneCard("slash", Card.Diamond, 13),
  Fk:cloneCard("slash", Card.Heart, 10),
  Fk:cloneCard("slash", Card.Heart, 10),
  Fk:cloneCard("slash", Card.Heart, 11),
  Fk:cloneCard("slash", Card.Club, 6),
  Fk:cloneCard("slash", Card.Club, 7),
  Fk:cloneCard("slash", Card.Club, 8),
  Fk:cloneCard("slash", Card.Club, 11),
  Fk:cloneCard("slash", Card.Club, 8),
  Fk:cloneCard("slash", Card.Spade, 9),
  Fk:cloneCard("slash", Card.Spade, 9),
  Fk:cloneCard("slash", Card.Spade, 10),
  Fk:cloneCard("slash", Card.Spade, 10),
  Fk:cloneCard("slash", Card.Club, 2),
  Fk:cloneCard("slash", Card.Club, 3),
  Fk:cloneCard("slash", Card.Club, 4),
  Fk:cloneCard("slash", Card.Club, 5),
  Fk:cloneCard("slash", Card.Club, 11),
  Fk:cloneCard("slash", Card.Diamond, 8),
}

local slash = Fk:cloneCard("slash")
local iceSlashSkill = fk.CreateActiveSkill{
  name = "ice__slash_skill",
  max_phase_use_time = 1,
  target_num = 1,
  can_use = slash.skill.canUse,
  mod_target_filter = slash.skill.modTargetFilter,
  target_filter = slash.skill.targetFilter,
  on_effect = function(self, room, effect)
    local to = effect.to
    local from = effect.from
    room:damage({
      from = room:getPlayerById(from),
      to = room:getPlayerById(to),
      card = effect.card,
      damage = 1,
      damageType = fk.IceDamage,
      skillName = self.name
    })
  end
}
local IceDamageSkill = fk.CreateTriggerSkill{
  name = "ice_damage_skill",
  global = true,
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.damageType == fk.IceDamage and not data.chain and not data.to:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    for i = 1, 2 do
      if to:isNude() then break end
      local card = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard({card}, self.name, to, player)
    end
    return true
  end
}
Fk:addSkill(IceDamageSkill)
local iceSlash = fk.CreateBasicCard{
  name = "ice__slash",
  skill = iceSlashSkill,
  is_damage_card = true,
}
extension:addCards{
  iceSlash:clone(Card.Spade, 7),
  iceSlash:clone(Card.Spade, 7),
  iceSlash:clone(Card.Spade, 8),
  iceSlash:clone(Card.Spade, 8),
  iceSlash:clone(Card.Spade, 8),
}
Fk:loadTranslationTable{
  ["ice__slash"] = "冰杀",
  ["ice_damage_skill"] = "冰杀",
	[":ice__slash"] = "基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：攻击范围内的一名角色<br /><b>效果</b>：对目标角色造成1点冰冻伤害。"..
  "（一名角色造成不为连环伤害的冰冻伤害时，若受到此伤害的角色有牌，来源可防止此伤害，然后依次弃置其两张牌）。",
}

extension:addCards{
  Fk:cloneCard("thunder__slash", Card.Spade, 4),
  Fk:cloneCard("thunder__slash", Card.Spade, 5),
  Fk:cloneCard("thunder__slash", Card.Spade, 6),
  Fk:cloneCard("thunder__slash", Card.Club, 5),
  Fk:cloneCard("thunder__slash", Card.Club, 6),
  Fk:cloneCard("thunder__slash", Card.Club, 7),
  Fk:cloneCard("thunder__slash", Card.Club, 8),
  Fk:cloneCard("thunder__slash", Card.Club, 9),
  Fk:cloneCard("thunder__slash", Card.Club, 9),
  Fk:cloneCard("thunder__slash", Card.Club, 10),
  Fk:cloneCard("thunder__slash", Card.Club, 10),

  Fk:cloneCard("fire__slash", Card.Heart, 4),
  Fk:cloneCard("fire__slash", Card.Heart, 7),
  Fk:cloneCard("fire__slash", Card.Diamond, 5),
  Fk:cloneCard("fire__slash", Card.Heart, 10),
  Fk:cloneCard("fire__slash", Card.Diamond, 4),
  Fk:cloneCard("fire__slash", Card.Diamond, 10),

  Fk:cloneCard("jink", Card.Diamond, 11),
  Fk:cloneCard("jink", Card.Diamond, 3),
  Fk:cloneCard("jink", Card.Diamond, 5),
  Fk:cloneCard("jink", Card.Diamond, 6),
  Fk:cloneCard("jink", Card.Diamond, 7),
  Fk:cloneCard("jink", Card.Diamond, 8),
  Fk:cloneCard("jink", Card.Diamond, 9),
  Fk:cloneCard("jink", Card.Diamond, 10),
  Fk:cloneCard("jink", Card.Diamond, 11),
  Fk:cloneCard("jink", Card.Heart, 13),
  Fk:cloneCard("jink", Card.Heart, 8),
  Fk:cloneCard("jink", Card.Heart, 9),
  Fk:cloneCard("jink", Card.Heart, 11),
  Fk:cloneCard("jink", Card.Heart, 12),
  Fk:cloneCard("jink", Card.Diamond, 6),
  Fk:cloneCard("jink", Card.Diamond, 7),
  Fk:cloneCard("jink", Card.Diamond, 8),
  Fk:cloneCard("jink", Card.Diamond, 10),
  Fk:cloneCard("jink", Card.Diamond, 11),
  Fk:cloneCard("jink", Card.Heart, 2),
  Fk:cloneCard("jink", Card.Heart, 2),
  Fk:cloneCard("jink", Card.Diamond, 2),
  Fk:cloneCard("jink", Card.Diamond, 2),
  Fk:cloneCard("jink", Card.Diamond, 4),

  Fk:cloneCard("peach", Card.Diamond, 12),
  Fk:cloneCard("peach", Card.Heart, 3),
  Fk:cloneCard("peach", Card.Heart, 4),
  Fk:cloneCard("peach", Card.Heart, 6),
  Fk:cloneCard("peach", Card.Heart, 7),
  Fk:cloneCard("peach", Card.Heart, 8),
  Fk:cloneCard("peach", Card.Heart, 9),
  Fk:cloneCard("peach", Card.Heart, 12),
  Fk:cloneCard("peach", Card.Heart, 5),
  Fk:cloneCard("peach", Card.Heart, 6),
  Fk:cloneCard("peach", Card.Diamond, 2),
  Fk:cloneCard("peach", Card.Diamond, 3),

  Fk:cloneCard("analeptic", Card.Diamond, 9),
  Fk:cloneCard("analeptic", Card.Spade, 3),
  Fk:cloneCard("analeptic", Card.Spade, 9),
  Fk:cloneCard("analeptic", Card.Club, 3),
  Fk:cloneCard("analeptic", Card.Club, 9),
}

extension:addCards{
  Fk:cloneCard("crossbow", Card.Diamond, 1),
  Fk:cloneCard("crossbow", Card.Club, 1),
  Fk:cloneCard("double_swords", Card.Spade, 2),
  Fk:cloneCard("qinggang_sword", Card.Spade, 6),
  Fk:cloneCard("blade", Card.Spade, 5),
  Fk:cloneCard("spear", Card.Spade, 12),
  Fk:cloneCard("axe", Card.Diamond, 5),
  Fk:cloneCard("kylin_bow", Card.Heart, 5),
  Fk:cloneCard("guding_blade", Card.Spade, 1),
}

local blackChainSkill = fk.CreateTriggerSkill{
  name = "#black_chain_skill",
  attached_equip = "black_chain",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and
      not player.room:getPlayerById(data.to).chained
  end,
  on_use = function(self, event, target, player, data)
    player.room:getPlayerById(data.to):setChainState(true)
  end,
}
Fk:addSkill(blackChainSkill)
local blackChain = fk.CreateWeapon{
  name = "black_chain",
  suit = Card.Diamond,
  number = 12,
  attack_range = 3,
  equip_skill = blackChainSkill,
}
extension:addCard(blackChain)
Fk:loadTranslationTable{
  ["black_chain"] = "乌铁锁链",
  ["#black_chain_skill"] = "乌铁锁链",
  [":black_chain"] = "装备牌·武器<br/><b>攻击范围</b>：3<br/><b>武器技能</b>：当你使用【杀】指定目标后，你可以横置目标角色武将牌。",
}

local fiveElementsFanSkill = fk.CreateViewAsSkill{
  name = "five_elements_fan_skill",
  attached_equip = "five_elements_fan",
  interaction = function(self)
    local choices = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.trueName == "slash" and card.name ~= "slash" then
        table.insertIfNeed(choices, card.name)
      end
    end
    return UI.ComboBox{choices = choices}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash" and Fk:getCardById(to_select).name ~= "slash" and
      Fk:getCardById(to_select).name ~= self.interaction.data
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = "five_elements_fan"
    return card
  end,
}
Fk:addSkill(fiveElementsFanSkill)
local fiveElementsFan = fk.CreateWeapon{
  name = "five_elements_fan",
  suit = Card.Diamond,
  number = 1,
  attack_range = 4,
  equip_skill = fiveElementsFanSkill,
}
extension:addCard(fiveElementsFan)
Fk:loadTranslationTable{
  ["five_elements_fan"] = "五行鹤翎扇",
  ["five_elements_fan_skill"] = "五行扇",
  [":five_elements_fan"] = "装备牌·武器<br/><b>攻击范围</b>：4<br/><b>武器技能</b>：你可以将属性【杀】当任意其他属性【杀】使用。",
}

extension:addCards{
  Fk:cloneCard("eight_diagram", Card.Spade, 2),
  Fk:cloneCard("nioh_shield", Card.Club, 2),
  Fk:cloneCard("vine", Card.Spade, 2),
  Fk:cloneCard("vine", Card.Club, 2),
}

local breastplateSkill = fk.CreateTriggerSkill{
  name = "#breastplate_skill",
  attached_equip = "breastplate",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (data.damage > 1 or data.damage >= player.hp)
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCards({
      ids = {player:getEquipment(Card.SubtypeArmor)},
      from = player.id,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
    })
    return true
  end,
}
Fk:addSkill(breastplateSkill)
local putEquip = fk.CreateActiveSkill{
  name = "putEquip",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip and not Fk:currentRoom():getCardArea(to_select) == Player.Equip
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and #cards == 1 and to_select ~= Self.id and
      Fk:currentRoom():getPlayerById(to_select):getEquipment(Fk:getCardById(cards[1]).sub_type) == nil
  end,
  on_use = function(self, room, effect)
    room:moveCards({
      ids = effect.cards,
      from = effect.from,
      to = effect.tos[1],
      toArea = Card.PlayerEquip,
      moveReason = fk.ReasonPut,
    })
  end
}
Fk:addSkill(putEquip)
local breastplate = fk.CreateArmor{
  name = "breastplate",
  suit = Card.Club,
  number = 1,
  equip_skill = breastplateSkill,
  special_skills = {"putEquip"},
}
extension:addCard(breastplate)
Fk:loadTranslationTable{
  ["breastplate"] = "护心镜",
  ["#breastplate_skill"] = "护心镜",
  [":breastplate"] = "装备牌·防具<br/><b>防具技能</b>：当你受到大于1点的伤害或致命伤害时，你可将装备区里的【护心镜】置入弃牌堆，若如此做，防止此伤害。"..
  "出牌阶段，你可将手牌中的【护心镜】置入其他角色的装备区。",
  ["putEquip"] = "置入",
  [":putEquip"] = "你可以将此牌置入其他角色的装备区",
}

local darkArmorSkill = fk.CreateTriggerSkill{
  name = "#dark_armor_skill",
  attached_equip = "dark_armor",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and #AimGroup:getAllTargets(data.tos) > 1 and
      (data.card.is_damage_card or data.card.color == Card.Black)
  end,
  on_use = function(self, event, target, player, data)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
}
Fk:addSkill(darkArmorSkill)
local darkArmor = fk.CreateArmor{
  name = "dark_armor",
  suit = Card.Club,
  number = 2,
  equip_skill = darkArmorSkill,
}
extension:addCard(darkArmor)
Fk:loadTranslationTable{
  ["dark_armor"] = "黑光铠",
  ["#dark_armor_skill"] = "黑光铠",
  [":dark_armor"] = "装备牌·防具<br/><b>防具技能</b>：当你成为【杀】、伤害锦囊或黑色锦囊牌的目标后，若你不是唯一目标，此牌对你无效。",
}

local wonderMapSkill = fk.CreateTriggerSkill{  --需要一个空技能以判断equip_skill是否无效
  name = "#wonder_map_skill",
  attached_equip = "wonder_map",
}
Fk:addSkill(wonderMapSkill)
local wonderMap = fk.CreateTreasure{
  name = "wonder_map",
  suit = Card.Club,
  number = 12,
  equip_skill = wonderMapSkill,
  on_install = function(self, room, player)
    if player:isAlive() and self.equip_skill:isEffectable(player) then
      --room:broadcastPlaySound("./packages/ol/audio/card/wonder_map")
      --room:setEmotion(player, "./packages/ol/image/anim/wonder_map")
      room:askForDiscard(player, 1, 1, true, self.name, false, "^wonder_map", "#wonder_map-discard")
    end
  end,
  on_uninstall = function(self, room, player)
    if player:isAlive() and self.equip_skill:isEffectable(player) then
      --room:broadcastPlaySound("./packages/ol/audio/card/wonder_map")
      --room:setEmotion(player, "./packages/ol/image/anim/wonder_map")
      local n = 5 - #player.player_cards[Player.Hand]
      if n > 0 then
        player:drawCards(n, self.name)
      end
    end
  end,
}
extension:addCard(wonderMap)
Fk:loadTranslationTable{
  ["wonder_map"] = "天机图",
  [":wonder_map"] = "装备牌·宝物<br/><b>宝物技能</b>：锁定技，此牌进入你的装备区时，弃置一张其他牌；此牌离开你的装备区时，你将手牌摸至五张。",
  ["#wonder_map-discard"] = "天机图：你须弃置一张【天机图】以外的牌",
}

local taigongTacticsSkill = fk.CreateTriggerSkill{
  name = "#taigong_tactics_skill",
  mute = true,
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return true
      else
        return not player:isKongcheng()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local to = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), function (p)
        return p.id end), 1, 1, "#taigong_tactics-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      local card = room:askForCard(player, 1, 1, false, self.name, true, ".", "#taigong_tactics-invoke")
      if #card > 0 then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local to = room:getPlayerById(self.cost_data)
      if to.chained then
        to:setChainState(false)
      else
        to:setChainState(true)
      end
    else
      room:recastCard(self.cost_data, player, self.name)
    end
  end,
}
Fk:addSkill(taigongTacticsSkill)
local taigongTactics = fk.CreateTreasure{
  name = "taigong_tactics",
  suit = Card.Spade,
  number = 1,
  equip_skill = taigongTacticsSkill,
}
extension:addCard(taigongTactics)
Fk:loadTranslationTable{
  ["taigong_tactics"] = "太公阴符",
  ["#taigong_tactics_skill"] = "太公阴符",
  [":taigong_tactics"] = "装备牌·宝物<br/><b>宝物技能</b>：出牌阶段开始时，你可以横置或重置一名角色；出牌阶段结束时，你可以重铸一张手牌。",
  ["#taigong_tactics-choose"] = "太公阴符：你可以横置或重置一名角色",
  ["#taigong_tactics-invoke"] = "太公阴符：你可以重铸一张手牌",
}
--♣K 铜雀
--你每回合使用的第一张带有强化效果的牌无使用条件。

extension:addCards{
  Fk:cloneCard("chitu", Card.Heart, 5),
  Fk:cloneCard("zixing", Card.Diamond, 13),
  Fk:cloneCard("dayuan", Card.Spade, 13),
  Fk:cloneCard("jueying", Card.Spade, 5),
  Fk:cloneCard("dilu", Card.Club, 5),
  Fk:cloneCard("zhuahuangfeidian", Card.Heart, 13),
  Fk:cloneCard("hualiu", Card.Diamond, 13),
}

extension:addCards{
  Fk:cloneCard("snatch", Card.Diamond, 3),
  Fk:cloneCard("snatch", Card.Diamond, 4),
  Fk:cloneCard("snatch", Card.Spade, 11),
  Fk:cloneCard("dismantlement", Card.Heart, 12),
  Fk:cloneCard("dismantlement", Card.Spade, 4),
  Fk:cloneCard("dismantlement", Card.Heart, 2),
  Fk:cloneCard("amazing_grace", Card.Heart, 3),
  Fk:cloneCard("amazing_grace", Card.Heart, 4),
  Fk:cloneCard("duel", Card.Diamond, 1),
  Fk:cloneCard("duel", Card.Spade, 1),
  Fk:cloneCard("duel", Card.Club, 1),
  Fk:cloneCard("savage_assault", Card.Spade, 13),
  Fk:cloneCard("savage_assault", Card.Spade, 7),
  Fk:cloneCard("savage_assault", Card.Club, 7),
  Fk:cloneCard("archery_attack", Card.Heart, 1),
  Fk:cloneCard("lightning", Card.Heart, 12),
  Fk:cloneCard("god_salvation", Card.Heart, 1),
  Fk:cloneCard("nullification", Card.Club, 12),
  Fk:cloneCard("nullification", Card.Club, 13),
  Fk:cloneCard("nullification", Card.Spade, 11),
  Fk:cloneCard("nullification", Card.Diamond, 12),
  Fk:cloneCard("nullification", Card.Heart, 1),
  Fk:cloneCard("nullification", Card.Spade, 13),
  Fk:cloneCard("nullification", Card.Heart, 13),
  Fk:cloneCard("indulgence", Card.Heart, 6),
  Fk:cloneCard("indulgence", Card.Club, 6),
  Fk:cloneCard("indulgence", Card.Spade, 6),
  Fk:cloneCard("iron_chain", Card.Spade, 11),
  Fk:cloneCard("iron_chain", Card.Spade, 12),
  Fk:cloneCard("iron_chain", Card.Club, 10),
  Fk:cloneCard("iron_chain", Card.Club, 11),
  Fk:cloneCard("iron_chain", Card.Club, 12),
  Fk:cloneCard("iron_chain", Card.Club, 13),
  Fk:cloneCard("supply_shortage", Card.Spade, 10),
  Fk:cloneCard("supply_shortage", Card.Club, 4),
}

local drowningSkill = fk.CreateActiveSkill{
  name = "drowning_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return to_select ~= user
  end,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id
  end,
  on_effect = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    if #to.player_cards[Player.Equip] == 0 then
      room:damage({
        from = from,
        to = to,
        card = effect.card,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = self.name
      })
    else
      if room:askForSkillInvoke(to, self.name, nil, "#drowning-discard::"..from.id) then
        to:throwAllCards("e")
      else
        room:damage({
          from = from,
          to = to,
          card = effect.card,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = self.name
        })

      end
    end
  end
}
local drowning = fk.CreateTrickCard{
  name = "drowning",
  skill = drowningSkill,
  is_damage_card = true,
}
extension:addCards({
  drowning:clone(Card.Spade, 3),
  drowning:clone(Card.Spade, 4),
})
Fk:loadTranslationTable{
  ["drowning"] = "水淹七军",
  ["drowning_skill"] = "水淹七军",
  [":drowning"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br /><b>效果</b>：目标角色选择一项："..
  "1.弃置装备区所有牌（至少一张）；2.你对其造成1点雷电伤害。",
  ["#drowning-discard"] = "水淹七军：“确定”弃置装备区所有牌，或点“取消” %dest 对你造成1点雷电伤害",
}

local unexpectationSkill = fk.CreateActiveSkill{
  name = "unexpectation_skill",
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
    if target:isKongcheng() then return end
    local card = room:askForCardChosen(player, target, "h", self.name)
    target:showCards(card)
    card = Fk:getCardById(card)
    if target.dead or card.suit == Card.NoSuit or effect.card.suit == Card.NoSuit then return end
    if card.suit ~= effect.card.suit then
      room:damage({
        from = player,
        to = target,
        card = effect.card,
        damage = 1,
        skillName = self.name
      })
    end
  end,
}
local unexpectation = fk.CreateTrickCard{
  name = "unexpectation",
  skill = unexpectationSkill,
  is_damage_card = true,
}
extension:addCards{
  unexpectation:clone(Card.Heart, 3),
  unexpectation:clone(Card.Diamond, 11),
}
Fk:loadTranslationTable{
  ["unexpectation"] = "出其不意",
  ["unexpectation_skill"] = "出其不意",
  [":unexpectation"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名有手牌的其他角色<br/><b>效果</b>：你展示目标角色的一张手牌，"..
  "若该牌与此【出其不意】花色不同，你对其造成1点伤害。",
}

local adaptationSkill = fk.CreateActiveSkill{
  name = "adaptation_skill",
  can_use = function()
    return false
  end,
}
local adaptationTriggerSkill = fk.CreateTriggerSkill{
  name = "adaptation_trigger_skill",
  global = true,

  refresh_events = {fk.AfterCardsMove, fk.CardUsing, fk.CardResponding, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.toArea == Card.PlayerHand and move.to == player.id then
          return true
        end
      end
    else
      if target == player then
        if event == fk.CardUsing or event == fk.CardResponding then
          return (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and player.room.current and
          table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id, true).trueName == "adaptation" end)
        else
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.toArea == Card.PlayerHand and move.to == player.id then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId, true).trueName == "adaptation" then
              local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
                local use = e.data[1]
                return use.from == player.id
              end, Player.HistoryTurn)
            end
          end
        end
      end
    elseif event == fk.CardUsing or event == fk.CardResponding then
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        if Fk:getCardById(id, true).trueName == "adaptation" then
          player.room:setCardMark(Fk:getCardById(id, true), "adaptation", data.card.name)
        end
      end
    else
      for _, id in ipairs(Fk:getAllCardIds()) do
        if Fk:getCardById(id, true).trueName == "adaptation" then
          player.room:setCardMark(Fk:getCardById(id, true), "adaptation", 0)
        end
      end
    end
  end,
}
local adaptationFilterSkill = fk.CreateFilterSkill{
  name = "adaptation_filter_skill",
  mute = true,
  global = true,
  card_filter = function(self, card, player)
    return card:getMark("adaptation") ~= 0
  end,
  view_as = function(self, card)
    return Fk:cloneCard(card:getMark("adaptation"), card.suit, card.number)
  end,
}
local adaptation = fk.CreateTrickCard{
  name = "adaptation",
  skill = adaptationSkill,
}
--Fk:addSkill(adaptationTriggerSkill)
--Fk:addSkill(adaptationFilterSkill)
extension:addCards{
  --adaptation:clone(Card.Spade, 2),
}
Fk:loadTranslationTable{
  ["adaptation"] = "随机应变",
  ["adaptation_filter_skill"] = "随机应变",
  [":adaptation"] = "锦囊牌<br/><b>效果</b>：此牌视为你本回合使用或打出的上一张基本牌或普通锦囊牌。",
}

local foresightSkill = fk.CreateActiveSkill{
  name = "foresight_skill",
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return true
  end,
  on_use = function(self, room, cardUseEvent)
    if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
      cardUseEvent.tos = {{cardUseEvent.from}}
    end
  end,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    room:askForGuanxing(to, room:getNCards(2), nil, nil)
    room:drawCards(to, 2, self.name)
  end
}
local foresight = fk.CreateTrickCard{
  name = "foresight",
  skill = foresightSkill,
}
extension:addCards({
  foresight:clone(Card.Heart, 7),
  foresight:clone(Card.Heart, 8),
  foresight:clone(Card.Heart, 9),
  foresight:clone(Card.Heart, 11),
})
Fk:loadTranslationTable{
  ["foresight"] = "洞烛先机",
  ["foresight_skill"] = "洞烛先机",
  [":foresight"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：你<br/><b>效果</b>：目标角色卜算2（观看牌堆顶的两张牌，"..
  "将其中任意张以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底），然后摸两张牌。",
}

local chasingNearSkill = fk.CreateActiveSkill{
  name = "chasing_near_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return to_select ~= user and not Fk:currentRoom():getPlayerById(to_select):isAllNude()
  end,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isAllNude()
  end,
  on_effect = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    if to:isAllNude() then return end
    local id = room:askForCardChosen(from, to, "hej", self.name)
    if from:distanceTo(to) > 1 then
      room:throwCard({id}, self.name, to, from)
    elseif from:distanceTo(to) == 1 then
      room:obtainCard(from, id, false, fk.ReasonPrey)
    end
  end
}
local chasing_near = fk.CreateTrickCard{
  name = "chasing_near",
  skill = chasingNearSkill,
}
extension:addCards({
  chasing_near:clone(Card.Spade, 3),
  chasing_near:clone(Card.Spade, 12),
  chasing_near:clone(Card.Club, 3),
  chasing_near:clone(Card.Club, 4),
})
Fk:loadTranslationTable{
  ["chasing_near"] = "逐近弃远",
  ["chasing_near_skill"] = "逐近弃远",
  [":chasing_near"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名区域里有牌的其他角色<br/><b>效果</b>：若你与目标角色距离为1，"..
  "你获得其区域里一张牌；若你与目标角色距离大于1，你弃置其区域里一张牌。",
}

return extension
