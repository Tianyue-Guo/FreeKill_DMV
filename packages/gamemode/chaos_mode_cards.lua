local extension = Package:new("chaos_mode_cards", Package.CardPack)
extension.extensionName = "game_mode"
--extension.game_modes_whitelist = {"chaos_mode"}
extension.game_modes_blacklist = {"aaa_role_mode", "m_1v1_mode", "m_1v2_mode", "m_2v2_mode", "zombie_mode", "heg_mode"}

Fk:loadTranslationTable{
  ["chaos_mode_cards"] = "文和乱武特殊牌",
}

local poisonSkill = fk.CreateActiveSkill{
  name = "poison_skill",
  can_use = function(self, player)
    return player.hp > 0
  end,
  on_use = function(self, room, use)
    if not use.tos or #TargetGroup:getRealTargets(use.tos) == 0 then
      use.tos = { { use.from } }
    end
  end,
  on_effect = function(self, room, effect)
    local target = room:getPlayerById(effect.to)
    room:loseHp(target, 1, self.name)
  end
}
Fk:addSkill(poisonSkill)
local poisonAction = fk.CreateTriggerSkill{
  name = "poison_action",
  global = true,
  priority = 0.1,
  events = { fk.AfterCardsMove },
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@chaos_mode_event") == 0 then return false end
    local poison_losehp = (data.extra_data or {}).poison_losehp or {}
    return table.contains(poison_losehp, player.id) and not player.dead
  end,
  on_trigger = function(self, event, target, player, data)
    local poison_losehp = (data.extra_data or {}).poison_losehp or {}
    player.room:notifySkillInvoked(player, self.name, "negative")
    player.room:loseHp(player, #table.filter(poison_losehp, function(pid) return pid == player.id end), "poison")
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@chaos_mode_event") ~= 0 --先这样
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason ~= fk.ReasonUse then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and (info.moveVisible or move.toArea == Card.PlayerEquip or move.toArea == Card.PlayerJudge or move.toArea == Card.DiscardPile or move.toArea == Card.Processing) then --寄 
            local id = info.cardId
            if Fk:getCardById(id).name == "poison" or (player:getMark("@chaos_mode_event") == "poisoned_banquet" and Fk:getCardById(id).name == "peach") then --耦
              data.extra_data = data.extra_data or {}
              local poison_losehp = data.extra_data.poison_losehp or {}
              table.insert(poison_losehp, player.id)
              data.extra_data.poison_losehp = poison_losehp
            end
          end
        end
      end
    end
  end,
}
Fk:addSkill(poisonAction)
local poison = fk.CreateBasicCard{
  name = "&poison",
  skill = poisonSkill,
}
extension:addCards{
  poison,
}

Fk:loadTranslationTable{
  ["poison"] = "毒",
  [":poison"] = "基本牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：体力值大于0的你<br /><b>效果</b>：目标角色失去1点体力。<br />锁定技，当此牌正面朝上离开你的手牌区后，你失去1点体力。",

  ["poison_action"] = "毒",
}

local timeFlyingSkill = fk.CreateActiveSkill{
  name = "time_flying_skill",
  target_num = 1,
  target_filter = function(self, to_select, selected)
    if #selected < self:getMaxTargetNum(Self) then
      local player = Fk:currentRoom():getPlayerById(to_select)
      return Self ~= player 
    end
  end,
  on_effect = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    if to.dead or from.dead then return end
    local num, num2 = from.hp, to.hp
    local min = math.max(1 - num, num2 - to.maxHp)
    local max = math.min(from.maxHp - num, num2 - 1)
    num = min == max and min or math.random(min, max)
    if num > 0 then
      room:recover({
        who = from,
        num = num,
        recoverBy = from,
        skillName = self.name,
      })
      room:loseHp(to, num, self.name)
    elseif num < 0 then
      num = -num
      room:loseHp(from, num, self.name)
      room:recover({
        who = to,
        num = num,
        recoverBy = from,
        skillName = self.name,
      })
    end
  end
}
local timeFlying = fk.CreateTrickCard{
  name = "&time_flying",
  skill = timeFlyingSkill,
  suit = Card.Heart,
  number = 1,
}
extension:addCards{
  timeFlying,
  timeFlying:clone(Card.Diamond, 5),
}
Fk:loadTranslationTable{
  ["time_flying"] = "斗转星移",
  [":time_flying"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名其他角色<br /><b>效果</b>：随机分配你和目标角色的体力（至少为1且无法超出上限）。",
}
local substitutingSkill = fk.CreateActiveSkill{
  name = "substituting_skill",
  target_num = 1,
  target_filter = function(self, to_select, selected)
    if #selected < self:getMaxTargetNum(Self) then
      local player = Fk:currentRoom():getPlayerById(to_select)
      return Self ~= player 
    end
  end,
  on_effect = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    if to.dead or from.dead or (to:isKongcheng() and from:isKongcheng()) then return end
    local cards = {}
    local moveInfos = {}
    for _, p in ipairs({from, to}) do
      if #p:getCardIds(Player.Hand) > 0 then
        table.insert(moveInfos, {
          ids = table.clone(p:getCardIds(Player.Hand)),
          fromArea = Card.PlayerHand,
          from = p.id,
          toArea = Card.Processing,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
          moveVisible = false
        })
        table.insertTable(cards, p:getCardIds(Player.Hand))
      end
    end
    room:moveCards(table.unpack(moveInfos))
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    room:delay(1000)
    if #cards == 0 then return false end
    local num = math.random(0, #cards)
    if to.dead and from.dead then
      return false
    elseif from.dead then
      num = 0 --乐
    elseif to.dead then
      num = #cards
    end
    if num == 0 then
      room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonJustMove, self.name, nil, false)
    elseif num == #cards then
      room:moveCardTo(cards, Card.PlayerHand, from, fk.ReasonJustMove, self.name, nil, false)
    else
      local cids = table.random(cards, num)
      local cards_id = table.filter(cards, function(c) return not table.contains(cids, c) end)
      room:moveCards({
        ids = cids,
        fromArea = Card.Processing,
        to = from.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        moveVisible = false
      }, {
        ids = cards_id,
        fromArea = Card.Processing,
        to = to.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        moveVisible = false
      })
    end
  end
}
local substituting = fk.CreateTrickCard{
  name = "&substituting",
  skill = substitutingSkill,
  suit = Card.Diamond,
  number = 12,
}
extension:addCards{
  substituting,
  substituting:clone(Card.Heart, 1),
  substituting:clone(Card.Heart, 13),
}
Fk:loadTranslationTable{
  ["substituting"] = "李代桃僵",
  [":substituting"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名其他角色<br /><b>效果</b>：随机分配你和目标角色的手牌。",
}
local replaceWithAFakeSkill = fk.CreateActiveSkill{
  name = "replace_with_a_fake_skill",
  on_use = function(self, room, use)
    if not use.tos or #TargetGroup:getRealTargets(use.tos) == 0 then
      use.tos = { { use.from } }
    end
  end,
  on_effect = function(self, room, effect)
    local cards = {}
    local moveInfos = {}
    for _, p in ipairs(room.alive_players) do
      if #p:getCardIds(Player.Equip) > 0 then
        table.insert(moveInfos, {
          ids = table.clone(p:getCardIds(Player.Equip)),
          fromArea = Card.PlayerEquip,
          from = p.id,
          toArea = Card.Processing,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
        })
        table.insertTable(cards, p:getCardIds(Player.Equip))
      end
    end
    if #cards == 0 then return false end
    room:moveCards(table.unpack(moveInfos))
    local IdMapper = {}
    local players = table.map(room.alive_players, function(p) return p.id end)
    for _, cid in ipairs(cards) do
      if room:getCardArea(cid) == Card.Processing then
        table.shuffle(players)
        local card = Fk:getCardById(cid)
        local target
        for _, pid in ipairs(players) do
          if room:getPlayerById(pid):getEquipment(card.sub_type) == nil then
            target = pid
            break
          end
        end
        if target then
          IdMapper[target] = IdMapper[target] or {}
          table.insertIfNeed(IdMapper[target], cid)
        end
      end
    end
    room:delay(1000)
    if IdMapper ~= {} then
      moveInfos = {}
      for _, p in ipairs(room.alive_players) do
        if IdMapper[p.id] then
          table.insert(moveInfos, {
            ids = IdMapper[p.id],
            fromArea = Card.Processing,
            to = p.id,
            toArea = Player.Equip,
            moveReason = fk.ReasonJustMove,
            skillName = self.name,
          })
        end
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end
    end
    local dis_cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #dis_cards > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(dis_cards)
      room:moveCardTo(dummy, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name)
    end
  end
}
local replaceWithAFake = fk.CreateTrickCard{
  name = "&replace_with_a_fake",
  skill = replaceWithAFakeSkill,
  suit = Card.Spade,
  number = 11,
}
extension:addCards{
  replaceWithAFake,
  replaceWithAFake:clone(Card.Club, 12),
  replaceWithAFake:clone(Card.Club, 13),
  replaceWithAFake:clone(Card.Spade, 13),
}
Fk:loadTranslationTable{
  ["replace_with_a_fake"] = "偷梁换柱",
  [":replace_with_a_fake"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：你<br /><b>效果</b>：随机分配所有角色装备区里的牌。",
}
local wenheChaosSkill = fk.CreateActiveSkill{
  name = "wenhe_chaos_skill",
  can_use = function(self, player, card)
    local room = Fk:currentRoom()
    for _, p in ipairs(room.alive_players) do
      if p ~= player and not (card and player:isProhibited(p, card)) then
        return true
      end
    end
  end,
  on_use = function(self, room, cardUseEvent)
    if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
      cardUseEvent.tos = {}
      for _, player in ipairs(room:getOtherPlayers(room:getPlayerById(cardUseEvent.from))) do
        if not room:getPlayerById(cardUseEvent.from):isProhibited(player, cardUseEvent.card) then
          TargetGroup:pushTargets(cardUseEvent.tos, player.id)
        end
      end
    end
  end,
  on_effect = function(self, room, effect)
    local target = room:getPlayerById(effect.to)
    local other_players = room:getOtherPlayers(target)
    local luanwu_targets = table.map(table.filter(other_players, function(p2)
      return table.every(other_players, function(p1)
        return target:distanceTo(p1) >= target:distanceTo(p2)
      end)
    end), function (p)
      return p.id
    end)
    local use = room:askForUseCard(target, "slash", "slash", "#luanwu-use", true, {exclusive_targets = luanwu_targets})
    if use then
      room:useCard(use)
    else
      room:loseHp(target, 1, self.name)
    end
  end
}
local wenheChaos = fk.CreateTrickCard{
  name = "&wenhe_chaos",
  skill = wenheChaosSkill,
  suit = Card.Spade,
  number = 10,
  multiple_targets = true,
}
extension:addCards{
  wenheChaos,
  wenheChaos:clone(Card.Club, 4),
}
Fk:loadTranslationTable{
  ["wenhe_chaos"] = "文和乱武",
  [":wenhe_chaos"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：所有其他角色<br /><b>效果</b>：目标角色选择一项：1. 对距离最近的一名角色使用【杀】；2. 失去1点体力。",

  ["wenhe_chaos_skill"] = "文和乱武",
}

return extension
