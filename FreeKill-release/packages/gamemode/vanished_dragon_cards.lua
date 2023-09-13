local extension = Package:new("vanished_dragon_cards", Package.CardPack)
extension.extensionName = "game_mode"
--extension.game_modes_whitelist = {"chaos_mode"}
extension.game_modes_blacklist = {"aaa_role_mode", "m_1v1_mode", "m_1v2_mode", "m_2v2_mode", "zombie_mode", "heg_mode"}

Fk:loadTranslationTable{
  ["vanished_dragon_cards"] = "忠胆英杰特殊牌",
}
--[[
  【**声东击西**】（替换【顺手牵羊】）普通锦囊：出牌阶段，对距离为1的一名角色使用。你交给目标角色一张手牌，然后其将两张牌交给一名由你选择的除其以外的角色。

  【**草木皆兵**】（替换【兵粮寸断】），延时锦囊：出牌阶段，对一名其他角色使用。将【草木皆兵】置于目标角色判定区里。若判定结果不为♣：摸牌阶段，少摸一张牌；摸牌阶段结束时，与其距离为1的角色各摸一张牌。

  【**增兵减灶**】（替换【无中生有】和【五谷丰登】），普通锦囊：出牌阶段，对一名角色使用。目标角色摸三张牌，然后选择一项：1. 弃置一张非基本牌；2. 弃置两张牌。

  【**弃甲曳兵**】（替换【借刀杀人】），普通锦囊：出牌阶段，对一名装备区里有牌的其他角色使用。目标角色选择一项：1.弃置手牌区和装备区里所有的武器和-1坐骑；2.弃置手牌区和装备区里所有的防具和+1坐骑。

  【**金蝉脱壳**】（替换【无懈可击】），普通锦囊：当你成为其他角色使用牌的目标时，若你的手牌里只有【金蝉脱壳】，使该牌对你无效，你摸两张牌。当你因弃置而失去【金蝉脱壳】时，你摸一张牌。

  【**浮雷**】（替换【闪电】），延时锦囊：出牌阶段，对你使用。将【浮雷】放置于你的判定区里，若判定结果为♠，则目标角色受到X点雷电伤害（X为此锦囊判定结果为♠的次数）。判定完成后，将此牌移动到下家的判定区里。

  【**烂银甲**】（替换【八卦阵】），防具：你可以将一张手牌当做【闪】使用或打出。【烂银甲】不会被无效或无视。当你受到【杀】造成的伤害时，你弃置装备区里的【烂银甲】。

  【**七宝刀**】（替换【青釭剑】），武器，攻击范围２：锁定技，你使用【杀】无视目标防具，若目标角色未损失体力值，此【杀】伤害+1。

  【**衠钢槊**】（替换【青龙偃月刀】），武器，攻击范围３：当你使用【杀】指定一名角色为目标后，你可令该角色弃置你的一张手牌，然后你弃置其一张手牌。
]]

local diversionSkill = fk.CreateActiveSkill{
  name = "diversion_skill",
  distance_limit = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    local player = Fk:currentRoom():getPlayerById(to_select)
    local from = Fk:currentRoom():getPlayerById(user)
    return from ~= player and not (distance_limited and not self:withinDistanceLimit(from, false, card, player))
  end,
  target_filter = function(self, to_select, selected, _, card)
    if #selected == 0 then
      return self:modTargetFilter(to_select, selected, Self.id, card, true)
    end
  end,
  target_num = 1,
  on_effect = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    if to.dead or from:isKongcheng() then return end
    local plist, cid = room:askForChooseCardAndPlayers(from, table.map(room:getOtherPlayers(to), Util.IdMapper), 1, 1, ".|.|.|hand", "#diversion-give::" .. to.id, self.name, false)
    room:moveCardTo(cid, Player.Hand, to, fk.ReasonGive, self.name, nil, false, from.id)
    local target = plist[1]
    local card
    if #to:getCardIds{Player.Hand, Player.Equip} <= 2 then
      card = to:getCardIds{Player.Hand, Player.Equip}
    else
      card = room:askForCard(to, 2, 2, true, self.name, false, nil, "#diversion-give2::" .. target)
    end
    room:moveCardTo(card, Player.Hand, room:getPlayerById(target), fk.ReasonGive, self.name, nil, false, from.id)
  end
}
local diversion = fk.CreateTrickCard{
  name = "&diversion",
  skill = diversionSkill,
  suit = Card.Spade,
  number = 3,
}
extension:addCards{
  diversion,
  diversion:clone(Card.Spade, 4),
  diversion:clone(Card.Spade, 11),
  diversion:clone(Card.Diamond, 3),
  diversion:clone(Card.Diamond, 4),
}
Fk:loadTranslationTable{
  ["diversion"] = "声东击西",
  [":diversion"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：距离为1的一名角色<br /><b>效果</b>：你交给目标角色一张手牌并选择一名除其以外的角色，目标角色将两张牌交给该角色。",

  ["diversion_skill"] = "声东击西",
  ["#diversion-give"] = "声东击西：交给 %dest 一张手牌，并选择其要将两张牌交给的目标",
  ["#diversion-give2"] = "声东击西：交给 %dest 两张牌",
}

local paranoidSkill = fk.CreateActiveSkill{
  name = "paranoid_skill",
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return user ~= to_select
  end,
  target_filter = function(self, to_select, selected, _, card)
    return #selected == 0 and self:modTargetFilter(to_select, selected, Self.id, card, true)
  end,
  target_num = 1,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    local judge = {
      who = to,
      reason = "paranoid",
      pattern = ".|.|spade,heart,diamond",
    }
    room:judge(judge)
    local result = judge.card
    if result.suit ~= Card.Club then
      --to:skip(Player.Draw)
      room:addPlayerMark(to, "@@paranoid-turn")
    end
    self:onNullified(room, effect)
  end,
  on_nullified = function(self, room, effect)
    room:moveCards{
      ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonUse
    }
  end,
}
local paranoid_result = fk.CreateTriggerSkill{
  name = "#paranoidResult",
  global = true,
  anim_type = "negative",
  events = {fk.DrawNCards, fk.EventPhaseEnd},
  frequency = Skill.Compulsory,
  priority = 0.1,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("@@paranoid-turn") > 0 and (event == fk.DrawNCards or player.phase == Player.Draw)
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n - 1
    else
      local room = player.room
      local targets = table.map(table.filter(room.alive_players, function(p)
        return p:distanceTo(target) == 1 end), function (p) return p.id end)
      room:sortPlayersByAction(targets)
      for _, pid in ipairs(targets) do
        local p = room:getPlayerById(pid)
        if not p.dead then p:drawCards(1, "paranoid") end
      end
    end
  end,
}
Fk:addSkill(paranoid_result)
local paranoid = fk.CreateDelayedTrickCard{
  name = "&paranoid",
  skill = paranoidSkill,
  suit = Card.Spade,
  number = 10,
}
extension:addCards{
  paranoid,
  paranoid:clone(Card.Club, 4),
}

Fk:loadTranslationTable{
  ["paranoid"] = "草木皆兵",
  [":paranoid"] = "延时锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名其他角色<br /><b>效果</b>：将【草木皆兵】置于目标角色判定区里。若判定结果不为♣：摸牌阶段，少摸一张牌；摸牌阶段结束时，与其距离为1的角色各摸一张牌。",

  ["@@paranoid-turn"] = "草木皆兵",
  ["#paranoidResult"] = "草木皆兵",
}

local reinforcementSkill = fk.CreateActiveSkill{
  name = "reinforcement_skill",
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return true
  end,
  target_filter = function(self, to_select, selected, _, card)
    if #selected == 0 then
      return self:modTargetFilter(to_select, selected, Self.id, card, true)
    end
  end,
  target_num = 1,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    if to.dead then return end
    to:drawCards(3, self.name)
    if to.dead then return end
    local all_choices = {"reinforcement-nonbasic", "reinforcement-2cards"}
    local choices = table.clone(all_choices)
    local cards = to:getCardIds{Player.Hand, Player.Equip}
    if #cards < 2 then
      table.remove(choices)
    end
    if table.every(cards, function(cid) return Fk:getCardById(cid).type ~= Card.TypeTrick end) then
      table.remove(choices, 1)
    end
    if #choices == 0 then return end
    local choice = room:askForChoice(to, choices, self.name, nil, false, all_choices)
    if choice == "reinforcement-nonbasic" then
      room:askForDiscard(to, 1, 1, true, self.name, false, ".|.|.|.|.|^basic")
    else
      room:askForDiscard(to, 2, 2, true, self.name, false, nil)
    end
  end
}
local reinforcement = fk.CreateTrickCard{
  name = "&reinforcement",
  skill = reinforcementSkill,
  suit = Card.Heart,
  number = 7,
}
extension:addCards{
  reinforcement,
  reinforcement:clone(Card.Heart, 8),
  reinforcement:clone(Card.Heart, 9),
  reinforcement:clone(Card.Heart, 11),
  reinforcement:clone(Card.Heart, 3),
  reinforcement:clone(Card.Heart, 4),
}

Fk:loadTranslationTable{
  ["reinforcement"] = "增兵减灶",
  [":reinforcement"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名角色<br /><b>效果</b>：目标角色摸三张牌，然后选择一项：1. 弃置一张非基本牌；2. 弃置两张牌。",

  ["reinforcement-nonbasic"] = "弃置一张非基本牌",
  ["reinforcement-2cards"] = "弃置两张牌",
  ["reinforcement_skill"] = "增兵减灶",
}

local abandoningArmorSkill = fk.CreateActiveSkill{
  name = "abandoning_armor_skill",
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return user ~= to_select and #Fk:currentRoom():getPlayerById(to_select):getCardIds{Player.Equip} > 0
  end,
  target_filter = function(self, to_select, selected, _, card)
    return #selected == 0 and self:modTargetFilter(to_select, selected, Self.id, card, true)
  end,
  target_num = 1,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    if to.dead then return end
    local all_choices = {"abandoning_armor-offensive", "abandoning_armor-defensive"}
    local choices = {}
    local x, y = {}, {}
    local cards = to:getCardIds{Player.Hand, Player.Equip}
    for _, cid in ipairs(cards) do
      local subtype = Fk:getCardById(cid).sub_type
      if subtype == Card.SubtypeWeapon or subtype == Card.SubtypeOffensiveRide then
        table.insert(x, cid)
      elseif subtype == Card.SubtypeArmor or subtype == Card.SubtypeDefensiveRide then
        table.insert(y, cid)
      end
    end
    if #x > 0 then table.insert(choices, "abandoning_armor-offensive") end
    if #y > 0 then table.insert(choices, "abandoning_armor-defensive") end
    if #choices == 0 then return end
    local choice = room:askForChoice(to, choices, self.name, nil, false, all_choices)
    room:throwCard(choice == "abandoning_armor-offensive" and x or y, self.name, to, to)
  end
}
local abandoningArmor = fk.CreateTrickCard{
  name = "&abandoning_armor",
  skill = abandoningArmorSkill,
  suit = Card.Club,
  number = 12,
}
extension:addCards{
  abandoningArmor,
  abandoningArmor:clone(Card.Club, 13),
}

Fk:loadTranslationTable{
  ["abandoning_armor"] = "弃甲曳兵",
  [":abandoning_armor"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名装备区里有牌的其他角色<br /><b>效果</b>：目标角色选择一项：1. 弃置手牌区和装备区里所有的武器和进攻坐骑；2. 弃置手牌区和装备区里所有的防具和防御坐骑。",

  ["abandoning_armor-offensive"] = "弃置手牌区和装备区里所有的武器和进攻坐骑",
  ["abandoning_armor-defensive"] = "弃置手牌区和装备区里所有的防具和防御坐骑",
  ["abandoning_armor_skill"] = "弃甲曳兵",
}

local craftyEscapeTrigger = fk.CreateTriggerSkill{
  name = "crafty_escape_trigger",
  anim_type = "defensive",
  mute = true,
  global = true,
  priority = 0.1,
  events = {fk.TargetConfirming, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TargetConfirming then
      if target ~= player or data.card.type == Card.TypeEquip then return end
      local ret = false
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        local card = Fk:getCardById(id)
        if card and card.name == "crafty_escape" then
          if not player:prohibitUse(card) and not player:isProhibited(player, card) then
            ret = true
          end
        else
          return false
        end
      end
      return ret
    else
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard and not player.dead then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).name == "crafty_escape" then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.TargetConfirming then
      self:doCost(event, target, player, data)
    else
      local i = 0
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard and not player.dead then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).name == "crafty_escape" then
              i = i + 1
            end
          end
        end
      end
      for i = 1, i do
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetConfirming then
      local use = player.room:askForUseCard(player, "crafty_escape", nil, "#crafty_escape-ask:::" .. data.card:toLogString() , true, nil, data)
      if use then
        self.cost_data = use
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirming then
      local use = self.cost_data
      use.toCard = data.card
      use.responseToEvent = data
      room:useCard(use)
    else
      player:drawCards(1, self.name)
    end
  end,
}
Fk:addSkill(craftyEscapeTrigger)
local craftyEscapeSkill = fk.CreateActiveSkill{
  name = "crafty_escape_skill",
  can_use = function()
    return false
  end,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if effect.responseToEvent then
      table.insertIfNeed(effect.responseToEvent.nullifiedTargets, player.id)
    end
    player:drawCards(2, self.name)
  end,
}
local craftyEscape = fk.CreateTrickCard{
  name = "&crafty_escape",
  skill = craftyEscapeSkill,
  suit = Card.Spade,
  number = 11,
}
extension:addCards{
  craftyEscape,
  craftyEscape:clone(Card.Club, 12),
  craftyEscape:clone(Card.Club, 13),
  craftyEscape:clone(Card.Diamond, 12),
  craftyEscape:clone(Card.Heart, 1),
  craftyEscape:clone(Card.Heart, 13),
  craftyEscape:clone(Card.Spade, 13),
}

Fk:loadTranslationTable{
  ["crafty_escape"] = "金蝉脱壳",
  [":crafty_escape"] = "锦囊牌<br /><b>时机</b>：当你成为其他角色使用牌的目标时，若你的手牌里只有【金蝉脱壳】<br /><b>目标</b>：该牌<br /><b>效果</b>：令目标牌对你无效，你摸两张牌。当你因弃置而失去【金蝉脱壳】时，你摸一张牌。",

  ["crafty_escape_skill"] = "金蝉脱壳",
  ["#crafty_escape-ask"] = "是否使用【金蝉脱壳】，令%arg对你无效，你摸两张牌？",
  ["crafty_escape_trigger"] = "金蝉脱壳",
}

local floatingThunderSkill = fk.CreateActiveSkill{
  name = "floating_thunder_skill",
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return true
  end,
  can_use = function(self, player, card)
    return not player:isProhibited(player, card)
  end,
  on_use = function(self, room, use)
    if not use.tos or #TargetGroup:getRealTargets(use.tos) == 0 then
      use.tos = { { use.from } }
    end
  end,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    local judge = {
      who = to,
      reason = "floating_thunder",
      pattern = ".|.|spade",
    }
    room:judge(judge)
    local result = judge.card
    if result.suit == Card.Spade then
      local card = Fk:getCardById(effect.card:getEffectiveId())
      room:addCardMark(card, "_floating_thunder")
      room:damage{
        to = to,
        damage = card:getMark("_floating_thunder"),
        card = effect.card,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    end
    self:onNullified(room, effect)
  end,
  on_nullified = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    local nextp = to
    repeat
      nextp = nextp:getNextAlive()
      if nextp == to then break end
    until not nextp:hasDelayedTrick("floating_thunder") and not nextp:isProhibited(nextp, effect.card)
    if nextp ~= to then
      if effect.card:isVirtual() then
        nextp:addVirtualEquip(effect.card)
      end
      room:moveCards{
        ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
        to = nextp.id,
        toArea = Card.PlayerJudge,
        moveReason = fk.ReasonPut
      }
    else
      room:moveCards{
        ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile
      }
    end
  end,
}
local floatingThunder = fk.CreateDelayedTrickCard{
  name = "&floating_thunder",
  suit = Card.Spade,
  number = 1,
  skill = floatingThunderSkill,
}

extension:addCards{
  floatingThunder,
  floatingThunder:clone(Card.Heart, 12),
}

Fk:loadTranslationTable{
  ["floating_thunder"] = "浮雷",
  [":floating_thunder"] = "延时锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：你<br /><b>效果</b>：将【浮雷】放置于目标角色的判定区里。若判定结果为♠，则目标角色受到X点雷电伤害（X为此牌判定结果为♠的次数）。判定完成后，将此牌移动到下家的判定区里。",
}

local glitteryArmorSkill = fk.CreateViewAsSkill{
  name = "glittery_armor_skill&", --假装
  --attached_equip = "glittery_armor", --为了不吃无效
  anim_type = "defensive",
  pattern = "jink",
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    return Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("jink")
    c.skillName = "glittery_armor"
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:notifySkillInvoked(player, "glittery_armor", "defensive")
  end
}
Fk:addSkill(glitteryArmorSkill)
local glitteryArmorTrigger = fk.CreateTriggerSkill{
  name = "#glittery_armor_trigger",
  global = true,
  events = {fk.DamageInflicted},
  anim_type = "negative",
  priority = 0.1,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getEquipment(Card.SubtypeArmor) and table.find(player:getEquipments(Card.SubtypeArmor), function(cid) return Fk:getCardById(cid).name == "glittery_armor" end)
    and data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local cards = player:getEquipments(Card.SubtypeArmor)
    cards = table.filter(cards, function(cid) return Fk:getCardById(cid).name == "glittery_armor" end)
    player.room:throwCard(cards, self.name, player, player)
  end,
}
Fk:addSkill(glitteryArmorTrigger)
local glitteryArmor = fk.CreateArmor{
  name = "&glittery_armor",
  suit = Card.Spade,
  number = 2,
  equip_skill = glitteryArmorSkill,
}

extension:addCards{
  glitteryArmor,
  glitteryArmor:clone(Card.Club, 2),
}

Fk:loadTranslationTable{
  ["glittery_armor"] = "烂银甲",
  [":glittery_armor"] = "装备牌·防具<br /><b>防具技能</b>：你可以将一张手牌当【闪】使用或打出。【烂银甲】不会被无效或无视。当你受到【杀】造成的伤害时，你弃置装备区里的【烂银甲】。",

  ["glittery_armor_skill&"] = "烂银甲",
  [":glittery_armor_skill&"] = "烂银甲：你可以将一张手牌当【闪】使用或打出。",
  ["#glittery_armor_trigger"] = "烂银甲[弃置]",
}

local sevenStarsSwordSkill = fk.CreateTriggerSkill{
  name = "#seven_stars_sword_skill",
  attached_equip = "seven_stars_sword",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
    if not room:getPlayerById(data.to):isWounded() then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.qinggangNullified = data.extra_data.qinggangNullified or {}
    data.extra_data.qinggangNullified[tostring(data.to)] = (data.extra_data.qinggangNullified[tostring(data.to)] or 0) + 1
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.qinggangNullified
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.qinggangNullified) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
    end
    data.qinggangNullified = nil
  end,
}
--Fk:addSkill(sevenStarsSwordSkill)
local sevenStarsSword = fk.CreateWeapon{
  name = "&seven_stars_sword",
  suit = Card.Spade,
  number = 6,
  attack_range = 2,
  equip_skill = sevenStarsSwordSkill,
}
extension:addCard(sevenStarsSword)

Fk:loadTranslationTable{
  ["seven_stars_sword"] = "七宝刀",
  ["#seven_stars_sword_skill"] = "七宝刀",
  [":seven_stars_sword"] = "装备牌·武器<br /><b>攻击范围</b>：２ <br /><b>武器技能</b>：锁定技，你使用【杀】无视目标防具，若目标角色未损失体力值，此【杀】伤害+1。",
}

local steelLanceSkill = fk.CreateTriggerSkill{
  name = "#steel_lance_skill",
  attached_equip = "steel_lance",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and not player:isKongcheng() and not player.dead--not player.room:getPlayerById(data.to):isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(data.to)
    if target.dead or player:isKongcheng() then return end
    local cid = room:askForCardChosen(target, player, "h", self.name)
    room:throwCard({cid}, self.name, player, target)
    if player.dead or target:isKongcheng() then return end
    cid = room:askForCardChosen(player, target, "h", self.name)
    room:throwCard({cid}, self.name, target, player)
  end,
}
Fk:addSkill(steelLanceSkill)
local steelLance = fk.CreateWeapon{
  name = "&steel_lance",
  suit = Card.Spade,
  number = 5,
  attack_range = 3,
  equip_skill = steelLanceSkill,
}
extension:addCard(steelLance)

Fk:loadTranslationTable{
  ["steel_lance"] = "衠钢槊",
  ["#steel_lance_skill"] = "衠钢槊",
  [":steel_lance"] = "装备牌·武器<br /><b>攻击范围</b>：３ <br /><b>武器技能</b>：当你使用【杀】指定一名角色为目标后，你可令其弃置你的一张手牌，然后你弃置其一张手牌。",
}

return extension
