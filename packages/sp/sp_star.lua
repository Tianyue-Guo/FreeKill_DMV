local extension = Package("sp_star")
extension.extensionName = "sp"

Fk:loadTranslationTable{
  ["sp_star"] = "☆SP",
  ["starsp"] = "☆SP",
}

local zhaoyun = General(extension, "starsp__zhaoyun", "qun", 3)
local chongzhen = fk.CreateTriggerSkill{
  name = "chongzhen",
  anim_type = "offensive",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and
      table.find(data.card.skillNames, function(name) return string.find(name, "longdan") end) then
      local id
      if event == fk.CardUsing then
        if data.card.trueName == "slash" then
          id = data.tos[1][1]
        elseif data.card.name == "jink" then
          if data.responseToEvent then
            id = data.responseToEvent.from  --jink
          end
        end
      elseif event == fk.CardResponding then
        if data.responseToEvent then
          if data.responseToEvent.from == player.id then
            id = data.responseToEvent.to  --duel used by zhaoyun
          else
            id = data.responseToEvent.from  --savsavage_assault, archery_attack, passive duel

            --TODO: Lenovo shu zhaoyun may chongzhen liubei when responding to jijiang
          end
        end
      end
      if id ~= nil then
        self.cost_data = id
        return not player.room:getPlayerById(id):isKongcheng()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#chongzhen-invoke::"..self.cost_data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCardChosen(player, to, "h", self.name)
    room:obtainCard(player.id, card, false, fk.ReasonPrey)
  end,
}
zhaoyun:addSkill("longdan")
zhaoyun:addSkill(chongzhen)
Fk:loadTranslationTable{
  ["starsp__zhaoyun"] = "赵云",
  ["chongzhen"] = "冲阵",
  [":chongzhen"] = "每当你发动〖龙胆〗使用或打出一张手牌时，你可以立即获得对方的一张手牌。",
  ["#chongzhen-invoke"] = "冲阵：你可以获得 %dest 的一张手牌",
}

local diaochan = General(extension, "starsp__diaochan", "qun", 3, 3, General.Female)
local lihun = fk.CreateActiveSkill{
  name = "lihun",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target.gender == General.Male and not target:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(target:getCardIds(Player.Hand))
    room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
    player:turnOver()
    local mark = player:getMark("lihun-phase")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, target.id)
    room:setPlayerMark(player, "lihun-phase", mark)
  end,
}
local lihun_record = fk.CreateTriggerSkill{
  name = "#lihun_record",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:usedSkillTimes("lihun", Player.HistoryPhase) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("lihun-phase")
    for _, id in ipairs(mark) do
      local to = room:getPlayerById(id)
      if to.dead or player:isNude() then return end
      local n = math.min(to.hp, #player:getCardIds{Player.Hand, Player.Equip})
      local dummy = Fk:cloneCard("dilu")
      if n == #player:getCardIds{Player.Hand, Player.Equip} then
        dummy:addSubcards(player:getCardIds{Player.Hand, Player.Equip})
      else
        local cards = room:askForCard(player, n, n, true, "lihun", false, ".", "#lihun-give::"..to.id..":"..n)
        dummy:addSubcards(cards)
      end
      room:obtainCard(to.id, dummy, false, fk.ReasonGive)
    end
  end,
}
lihun:addRelatedSkill(lihun_record)
diaochan:addSkill(lihun)
diaochan:addSkill("biyue")
Fk:loadTranslationTable{
  ["starsp__diaochan"] = "貂蝉",
  ["lihun"] = "离魂",
  [":lihun"] = "出牌阶段，你可以弃置一张牌并将你的武将牌翻面，若如此做，指定一名男性角色，获得其所有手牌。"..
  "出牌阶段结束时，你须为该角色的每一点体力分配给其一张牌，每回合限一次。",
  ["#lihun-give"] = "离魂：你需交还 %dest %arg张牌",
}

local caoren = General(extension, "starsp__caoren", "wei", 4)
local kuiwei = fk.CreateTriggerSkill{
  name = "kuiwei",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:getEquipment(Card.SubtypeWeapon) ~= nil then
        n = n + 1
      end
    end
    player:drawCards(2 + n, self.name)
    player:turnOver()
    room:addPlayerMark(player, self.name, 1)
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Draw and player:getMark(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, 0)
    local n = 0
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:getEquipment(Card.SubtypeWeapon) ~= nil then
        n = n + 1
      end
    end
    if n == 0 then return end
    if #player:getCardIds{Player.Hand, Player.Equip} <= n then
      player:throwAllCards("he")
    else
      room:askForDiscard(player, n, n, true, self.name, false, ".", "#kuiwei-discard:::"..n)
    end
  end,
}
local yanzheng = fk.CreateViewAsSkill{
  name = "yanzheng",
  anim_type = "defensive",
  pattern = "nullification",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("nullification")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function (self, player)
    return false
  end,
  enabled_at_response = function (self, player)
    return player:getHandcardNum() > player.hp and #player.player_cards[Player.Equip] > 0
  end,
}
caoren:addSkill(kuiwei)
caoren:addSkill(yanzheng)
Fk:loadTranslationTable{
  ["starsp__caoren"] = "曹仁",
  ["kuiwei"] = "溃围",
  [":kuiwei"] = "回合结束阶段开始时，你可以摸2+X张牌，然后将你的武将牌翻面。若如此做，在你的下个摸牌阶段开始时，你须弃置X张牌。"..
  "X等于当时场上装备区内的武器牌的数量。",
  ["yanzheng"] = "严整",
  [":yanzheng"] = "若你的手牌数大于你的体力值，你可以将你装备区内的牌当【无懈可击】使用。",
  ["#kuiwei-discard"] = "溃围：你需弃置%arg张牌",
}

local pangtong = General(extension, "starsp__pangtong", "qun", 3)
local manjuan = fk.CreateTriggerSkill{
  name = "manjuan",
  mute = true,
  events = {fk.BeforeCardsMove, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if event == fk.BeforeCardsMove and move.to and move.to == player.id and move.toArea == Card.PlayerHand then
          return move.skillName ~= self.name and move.skillName ~= "zuixiang"
        end
        if event == fk.AfterCardsMove and move.toArea == Card.DiscardPile then
          return move.extra_data and move.extra_data.manjuan and move.extra_data.manjuan == player.id
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.BeforeCardsMove then
      return true
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#manjuan-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if event == fk.BeforeCardsMove and move.to and move.to == player.id and move.toArea == Card.PlayerHand and
        move.skillName ~= self.name and move.skillName ~= "zuixiang" then
        move.to = nil
        move.toArea = Card.DiscardPile
        move.moveReason = fk.ReasonPutIntoDiscardPile
        if player.phase ~= Player.NotActive then
          player:broadcastSkillInvoke(self.name)
          room:notifySkillInvoked(player, self.name, "special")
          move.extra_data = move.extra_data or {}
          move.extra_data.manjuan = player.id
        else
          player:broadcastSkillInvoke(self.name)
          room:notifySkillInvoked(player, self.name, "negative")
        end
      end
      if event == fk.AfterCardsMove and move.toArea == Card.DiscardPile and
        move.extra_data and move.extra_data.manjuan and move.extra_data.manjuan == player.id then
        player:broadcastSkillInvoke(self.name)
        room:notifySkillInvoked(player, self.name, "drawcard")
        for _, info in ipairs(move.moveInfo) do
          local cards = table.filter(room.discard_pile, function(id)
            return Fk:getCardById(id, true).number == Fk:getCardById(info.cardId, true).number end)
          if #cards > 0 then
            local ids = room:askForCardsChosen(player, player, 0, 1, {card_data = {{"DiscardPile", cards}}}, self.name)
            if #ids > 0 then
              room:moveCards({
                ids = ids,
                fromArea = Card.DiscardPile,
                to = player.id,
                toArea = Card.PlayerHand,
                moveReason = fk.ReasonJustMove,
                skillName = self.name,
                moveVisible = true,
              })
            end
          end
        end
      end
    end
  end,
}
local zuixiang = fk.CreateTriggerSkill{
  name = "zuixiang",
  anim_type = "drawcard",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Start then
      return (player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0) or #player:getPile(self.name) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    if #player:getPile(self.name) == 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#zuixiang-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(cards)
    player:addToPile(self.name, dummy, true, self.name)
    local number = {}
    for i = 1, #player:getPile(self.name), 1 do
      table.insertIfNeed(number, Fk:getCardById(player:getPile(self.name)[i], true).number)
    end
    if #number < #player:getPile(self.name) then
      room:moveCards({
        ids = player:getPile(self.name),
        from = player.id,
        fromArea = Card.PlayerSpecial,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        specialName = self.name,
        moveVisible = true,
      })
    end
  end,
}
local zuixiang_trigger = fk.CreateTriggerSkill{
  name = "#zuixiang_trigger",
  anim_type = "defensive",
  events = {fk.PreCardEffect, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if #player:getPile("zuixiang") > 0 and
      table.find(player:getPile("zuixiang"), function(id) return Fk:getCardById(id, true).type == data.card.type end) then
      if event == fk.PreCardEffect then
        return player.id == data.to
      else
        return target == player and data.card.sub_type == Card.SubtypeDelayedTrick
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("zuixiang")
    if data.card.sub_type == Card.SubtypeDelayedTrick then  --取消延时锦囊
      AimGroup:cancelTarget(data, player.id)
    else
      return true
    end
  end,

  --[[refresh_events = {fk.TargetConfirmed, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return #player:getPile("zuixiang") > 0 and data.card.trueName == "slash" and
      table.find(player:getPile("zuixiang"), function(id) return Fk:getCardById(id, true).type == Card.TypeEquip end) and
      table.contains(TargetGroup:getRealTargets(data.tos), player.id)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirmed then
      room:addPlayerMark(room:getPlayerById(data.to), "zuixiangNullified")
      data.extra_data = data.extra_data or {}
      data.extra_data.zuixiangNullified = data.extra_data.zuixiangNullified or {}
      data.extra_data.zuixiangNullified[tostring(data.to)] = (data.extra_data.zuixiangNullified[tostring(data.to)] or 0) + 1
    else
      for key, num in pairs(data.extra_data.zuixiangNullified) do
        local p = room:getPlayerById(tonumber(key))
        if p:getMark("zuixiangNullified") > 0 then
          room:removePlayerMark(p, "zuixiangNullified", num)
        end
      end
      data.zuixiangNullified = nil
    end
  end,]]--
}
local zuixiang_prohibit = fk.CreateProhibitSkill{
  name = "#zuixiang_prohibit",
  prohibit_use = function(self, player, card)
    if #player:getPile("zuixiang") > 0 then
      return table.find(player:getPile("zuixiang"), function(id) return Fk:getCardById(id, true).type == card.type end)
    end
  end,
  prohibit_response = function(self, player, card)
    if #player:getPile("zuixiang") > 0 then
      return table.find(player:getPile("zuixiang"), function(id) return Fk:getCardById(id, true).type == card.type end)
    end
  end,
}
local zuixiang_invalidity = fk.CreateInvaliditySkill {
  name = "#zuixiang_invalidity",
  invalidity_func = function(self, player, skill)
    if skill.attached_equip then
      return (#player:getPile("zuixiang") > 0 and
        table.find(player:getPile("zuixiang"), function(id) return Fk:getCardById(id, true).type == Card.TypeEquip end))
        -- or player:getMark("zuixiangNullified") > 0
    end
  end,
}
zuixiang:addRelatedSkill(zuixiang_trigger)
zuixiang:addRelatedSkill(zuixiang_prohibit)
zuixiang:addRelatedSkill(zuixiang_invalidity)
pangtong:addSkill(manjuan)
pangtong:addSkill(zuixiang)
Fk:loadTranslationTable{
  ["starsp__pangtong"] = "庞统",
  ["manjuan"] = "漫卷",
  [":manjuan"] = "每当你将获得任何一张牌，将之置于弃牌堆。若此情况处于你的回合中，你可依次将与该牌点数相同的一张牌从弃牌堆置于你手上。",
  ["zuixiang"] = "醉乡",
  [":zuixiang"] = "限定技，回合开始阶段开始时，你可以展示牌库顶的3张牌置于你的武将牌上，你不可以使用或打出与该些牌同类的牌，所有同类牌对你无效。"..
  "之后每个你的回合开始阶段，你须重复展示一次，直至该些牌中任意两张点数相同时，将你武将牌上的全部牌置于你的手上。",
  --当“醉乡”牌中有装备牌时，你的装备技能无效；以你为目标的【杀】结算过程中使用者的装备技能无效。
  ["DiscardPile"] = "弃牌堆",
  ["#manjuan-invoke"] = "漫卷：你可以从弃牌堆中依次选择相同点数的牌置入手牌",
  ["#zuixiang-invoke"] = "醉乡：你可以发动“醉乡”",
  ["#zuixiang_trigger"] = "醉乡",

  -- CV: 樰默
  ["$manjuan1"] = "漫卷纵酒，白首狂歌。",
  ["$manjuan2"] = "吾有雄才，漫天卷地。",
  ["$zuixiang1"] = "懵懵醉乡中，天下心中藏。",
  ["$zuixiang2"] = "今朝有酒，管甚案牍俗事。",
  ["~starsp__pangtong"] = "纵有治世才，难遇治世主。",
}

local zhangfei = General(extension, "starsp__zhangfei", "shu", 4)
local jyie = fk.CreateTriggerSkill{
  name = "jyie",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and data.card.color == Card.Red
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
}
local dahe = fk.CreateActiveSkill{
  name = "dahe",
  anim_type = "offensive",
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
      room:addPlayerMark(target, "dahe-turn", 1)
      local card = pindian.results[target.id].toCard
      if room:getCardArea(card.id) == Card.DiscardPile then
        local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
          return player.hp >= p.hp end), function(p) return p.id end), 1, 1, "#dahe-choose:::"..card:toLogString(), self.name, true)
        if #to > 0 then
          room:obtainCard(to[1], card, true, fk.ReasonJustMove)
        end
      end
    else
      if not player:isKongcheng() then
        player:showCards(player.player_cards[Player.Hand])
        room:askForDiscard(player, 1, 1, false, self.name, false)
      end
    end
  end,
}
local dahe_trigger = fk.CreateTriggerSkill{
  name = "#dahe_trigger",
  mute = true,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("dahe-turn") > 0 and data.card.name == "jink" and data.card.suit ~= Card.Heart
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    return true
  end,
}
dahe:addRelatedSkill(dahe_trigger)
zhangfei:addSkill(jyie)
zhangfei:addSkill(dahe)
Fk:loadTranslationTable{
  ["starsp__zhangfei"] = "张飞",
  ["jyie"] = "嫉恶",
  [":jyie"] = "锁定技，你使用的红色【杀】造成的伤害+1。",
  ["dahe"] = "大喝",
  [":dahe"] = "出牌阶段，你可以与一名其他角色拼点；若你赢，该角色的非<font color='red'>♥</font>【闪】无效直到回合结束，"..
  "你可以将该角色拼点的牌交给场上一名体力不多于你的角色。若你没赢，你须展示手牌并选择一张弃置。每阶段限一次。",
  ["#dahe-choose"] = "大喝：你可以将%arg交给一名角色",
}

local lvmeng = General(extension, "starsp__lvmeng", "wu", 3)
local tanhu = fk.CreateActiveSkill{
  name = "tanhu",
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
      local mark = player:getMark("tanhu-turn")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, target.id)
      room:setPlayerMark(player, "tanhu-turn", mark)
    end
  end,
}
local tanhu_distance = fk.CreateDistanceSkill{
  name = "#tanhu_distance",
  correct_func = function(self, from, to)
    if from:getMark("tanhu-turn") ~= 0 then
      if table.contains(from:getMark("tanhu-turn"), to.id) then
        from:setFixedDistance(to, 1)
      else
        from:removeFixedDistance(to)
      end
    end
    return 0
  end,
}
local tanhu_trigger = fk.CreateTriggerSkill{
  name = "#tanhu_trigger",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("tanhu-turn") ~= 0 and data.card:isCommonTrick() and data.tos and
      table.find(TargetGroup:getRealTargets(data.tos), function(id) return table.contains(player:getMark("tanhu-turn"), id) end)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.prohibitedCardNames = {"nullification"}
  end,
}
local mouduan = fk.CreateTriggerSkill{
  name = "mouduan",
  anim_type = "switch",
  switch_skill_name = "mouduan",
  events = {fk.AfterCardsMove, fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
        if event ~= fk.AfterCardsMove then return end
        for _, move in ipairs(data) do
          if move.from == player.id then
            return player:getHandcardNum() < 3
          end
        end
      else
        return event == fk.EventPhaseChanging and data.from == Player.RoundStart
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      return true
    else
      local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#mouduan-invoke", true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:handleAddLoseSkills(player, "-jiang|-qianxun|yingzi|keji", nil, false, true)
    else
      room:handleAddLoseSkills(player, "jiang|qianxun|-yingzi|-keji", nil, false, true)
      room:throwCard(self.cost_data, self.name, player, player)
    end
  end,

  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self.name)
    else
      return target == player and data == self
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventLoseSkill then
      room:handleAddLoseSkills(player, "-jiang|-qianxun|-yingzi|-keji", nil, false, true)
    else
      room:handleAddLoseSkills(player, "jiang|qianxun", nil, false, true)
    end
  end,
}
tanhu:addRelatedSkill(tanhu_distance)
tanhu:addRelatedSkill(tanhu_trigger)
lvmeng:addSkill(tanhu)
lvmeng:addSkill(mouduan)
lvmeng:addRelatedSkill("jiang")
lvmeng:addRelatedSkill("qianxun")
lvmeng:addRelatedSkill("yingzi")
lvmeng:addRelatedSkill("keji")
Fk:loadTranslationTable{
  ["starsp__lvmeng"] = "吕蒙",
  ["tanhu"] = "探虎",
  [":tanhu"] = "出牌阶段，你可与一名其他角色拼点。若你赢，你获得以下技能直到回合结束：你与该角色的距离视为1，"..
  "你对该角色使用的非延时类锦囊牌不能被【无懈可击】抵消。每阶段限一次。",
  ["mouduan"] = "谋断",
  [":mouduan"] = "转化技，通常状态下，你拥有标记“武”并拥有技能〖激昂〗和〖谦逊〗。当你的手牌数为2张或以下时，你须将你的标记翻面为“文”，"..
  "将该两项技能转化为〖英姿〗和〖克己〗。任一角色的回合开始前，你可弃一张牌将标记翻回。<br>"..
  "<font color='grey'>转换技，阳：你拥有〖激昂〗和〖谦逊〗，当你失去手牌后，若你的手牌数小于等于2，你发动此技能；"..
  "阴，你拥有〖英姿〗和〖克己〗，一名角色回合开始前，你可以弃置一张牌。",
  ["#mouduan-invoke"] = "谋断：你可以弃置一张牌，转换状态",
}

local liubei = General(extension, "starsp__liubei", "shu", 4)
local zhaolie = fk.CreateTriggerSkill{
  name = "zhaolie",
  anim_type = "offensive",
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.n > 0
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room:getOtherPlayers(player),
      function(p) return player:inMyAttackRange(p) end), function(p) return p.id end)
    if #targets == 0 then return end
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#zhaolie-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.n = data.n - 1
    local to = room:getPlayerById(self.cost_data)
    local cards = room:getNCards(3)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
    })
    local get = {}
    local throw = {}
    for _, id in ipairs(cards) do
      local card = Fk:getCardById(id)
      if card.type ~= Card.TypeBasic or card.name == "peach" then
        table.insert(throw, id)
      else
        table.insert(get, id)
      end
    end
    if #throw > 0 then
      room:delay(1000)
      room:moveCards({
        ids = throw,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
    end
    if #get > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      if to:isNude() or #to:getCardIds{Player.Hand, Player.Equip} < #get then
        room:damage{
          from = player,
          to = to,
          damage = #get,
          skillName = self.name,
        }
        if not to.dead then
          room:obtainCard(to.id, dummy, true, fk.ReasonJustMove)
        end
      else
        if #room:askForDiscard(to, 1, 1, true, self.name, true, ".",
          "#zhaolie-discard:"..player.id.."::"..tostring(#get)..":"..tostring(#get), false) > 0 then
          for i = 1, #get - 1, 1 do
            room:askForDiscard(to, 1, 1, true, self.name, false)
          end
          room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
        else
          room:damage{
            from = player,
            to = to,
            damage = #get,
            skillName = self.name,
          }
          if not to.dead then
            room:obtainCard(to.id, dummy, true, fk.ReasonJustMove)
          end
        end
      end
    end
  end,
}
local shichoul = fk.CreateTriggerSkill{
  name = "shichoul$",
  anim_type = "control",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseStart then
        return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
          #player:getCardIds{Player.Hand, Player.Equip} > 1
      else
        return player:getMark("shichoul") ~= 0 and not player.room:getPlayerById(player:getMark("shichoul")).dead
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      local targets = table.map(table.filter(room:getOtherPlayers(player),
        function(p) return p.kingdom == "shu" end), function(p) return p.id end)
      if #targets == 0 then return end
      room:setPlayerMark(player, "shichoul-phase", targets)
      if room:askForUseActiveSkill(player, "shichoul_active", "#shichoul-invoke", true) then
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      local room = player.room
      local new_data = table.simpleClone(data)
      new_data.to = room:getPlayerById(player:getMark("shichoul"))
      room:damage(new_data)
      if not new_data.to.dead then
        new_data.to:drawCards(data.damage, self.name)
      end
      return true
    end
  end,

  refresh_events = {fk.EnterDying, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if player:getMark("shichoul") ~= 0 then
      return target:getMark("@@shichoul") ~= 0 or (target == player and event == fk.Death)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, "@@shichoul", 0)
    local to = player:getMark("shichoul")
    local mark = to:getMark("@@shichoul")
    table.removeOne(mark, player.id)
    if #mark == 0 then mark = 0 end
    room:setPlayerMark(to, "@@shichoul", mark)
    room:setPlayerMark(player, "shichoul", 0)
  end,
}
local shichoul_active = fk.CreateActiveSkill{
  name = "shichoul_active",
  mute = true,
  card_num = 2,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return #selected < 2
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and table.contains(Self:getMark("shichoul-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:obtainCard(target.id, dummy, false, fk.ReasonGive)
    room:setPlayerMark(player, "shichoul", target.id)
    local mark = target:getMark("@@shichoul")
    if mark == 0 then mark = {} end
    table.insert(mark, player.id)
    room:setPlayerMark(target, "@@shichoul", mark)  --小心伪帝！
  end,
}
Fk:addSkill(shichoul_active)
liubei:addSkill(zhaolie)
liubei:addSkill(shichoul)
Fk:loadTranslationTable{
  ["starsp__liubei"] = "刘备",
  ["zhaolie"] = "昭烈",
  [":zhaolie"] = "摸牌阶段摸牌时，你可以少摸一张，指定你攻击范围内的一名角色亮出牌堆顶上3张牌，将其中的非基本牌和【桃】置于弃牌堆，该角色进行二选一："..
  "你对其造成X点伤害，然后他获得这些基本牌；或他依次弃置X张牌，然后你获得这些基本牌。（X为其中非基本牌的数量）",
  ["shichoul"] = "誓仇",
  [":shichoul"] = "主公技，限定技，回合开始时，你可指定一名蜀国角色并交给其两张牌。本盘游戏中，每当你受到伤害时，改为该角色代替你受到等量的伤害，"..
  "然后摸等量的牌，直到该角色第一次进入濒死状态。",
  ["#zhaolie-choose"] = "昭烈：你可以少摸一张牌，亮出牌堆顶三张牌，令一名角色根据其中基本牌数受到伤害或弃牌",
  ["#zhaolie-discard"] = "昭烈：你需依次弃置%arg张牌，否则 %src 对你造成%arg2点伤害",
  ["#shichoul-choose"] = "誓仇：你可以将两张牌交给一名蜀势力角色，你受到的伤害均转移给其直到其进入濒死状态",
  ["@@shichoul"] = "誓仇",
}

local daqiao = General(extension, "starsp__daqiao", "wu", 3, 3, General.Female)
local yanxiao = fk.CreateActiveSkill{
  name = "yanxiao",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Diamond
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):hasDelayedTrick("yanxiao_trick")
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:cloneCard("yanxiao_trick")
    card:addSubcards(effect.cards)
    target:addVirtualEquip(card)
    room:moveCardTo(card, Card.PlayerJudge, target, fk.ReasonJustMove, self.name)
  end,
}
local yanxiao_trigger = fk.CreateTriggerSkill{
  name = "#yanxiao_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Judge and player:hasDelayedTrick("yanxiao_trick")
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player.player_cards[Player.Judge])
    player.room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
  end,
}
local anxian = fk.CreateTriggerSkill{
  name = "anxian",
  mute = true,
  events = {fk.DamageCaused, fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" then
      if event == fk.DamageCaused then
        return not data.chain
      else
        return not player:isKongcheng()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      return player.room:askForSkillInvoke(player, self.name, nil, "#anxian1-invoke::"..data.to.id)
    else
      local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".",
        "#anxian2-invoke::"..data.from..":"..data.card:toLogString(), true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "control")
      if not data.to:isKongcheng() then
        room:askForDiscard(data.to, 1, 1, false, self.name, false)
      end
      player:drawCards(1, self.name)
      return true
    else
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "defensive")
      table.insertIfNeed(data.nullifiedTargets, player.id)
      room:throwCard(self.cost_data, self.name, player, player)
      room:getPlayerById(data.from):drawCards(1, self.name)
    end
  end
}
yanxiao:addRelatedSkill(yanxiao_trigger)
daqiao:addSkill(yanxiao)
daqiao:addSkill(anxian)
Fk:loadTranslationTable{
  ["starsp__daqiao"] = "大乔",
  ["yanxiao"] = "言笑",
  [":yanxiao"] = "出牌阶段，你可以将一张<font color='red'>♦</font>牌置于一名角色的判定区内，判定区内有“言笑”牌的角色下个判定阶段开始时，"..
  "获得其判定区里的所有牌。",
  ["anxian"] = "安娴",
  [":anxian"] = "每当你使用【杀】对目标角色造成伤害时，你可以防止此次伤害，令其弃置一张手牌，然后你摸一张牌；当你成为【杀】的目标时，"..
  "你可以弃置一张手牌使之无效，然后该【杀】的使用者摸一张牌。",
  ["#anxian1-invoke"] = "安娴：你可以防止对 %dest 造成的伤害，其弃置一张手牌，你摸一张牌",
  ["#anxian2-invoke"] = "安娴：你可以弃置一张手牌令%arg对你无效，%dest 摸一张牌",
}

local ganning = General(extension, "starsp__ganning", "qun", 4)
local yinling = fk.CreateActiveSkill{
  name = "yinling",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isNude() and #player:getPile("ganning_jin") < 4
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    local id = room:askForCardChosen(player, target, "he", self.name)
    player:addToPile("ganning_jin", id, true, self.name)
  end,
}
local junwei = fk.CreateTriggerSkill{
  name = "junwei",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and #player:getPile("ganning_jin") > 2
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForCard(player, 3, 3, false, self.name, true, ".|.|.|ganning_jin|.|.", "#junwei-invoke", "ganning_jin")
    if #cards == 3 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCards({
      from = player.id,
      ids = self.cost_data,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = self.name,
      specialName = "ganning_jin",
    })
    local targets = table.map(room:getAlivePlayers(), function(p) return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#junwei-choose", self.name, false)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    to = room:getPlayerById(to)
    local card = {}
    if not to:isKongcheng() then
      card = room:askForCard(to, 1, 1, false, self.name, true, "jink", "#junwei-card:"..player.id)
    end
    if #card > 0 then
      to:showCards(card)
      local p = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), function(p) return p.id end), 1, 1,
        "#junwei-give:::"..Fk:getCardById(card[1]):toLogString(), self.name, false)
      if #p > 0 then
        p = p[1]
      else
        p = player.id
      end
      if p ~= to.id then
        room:obtainCard(p, card[1], true, fk.ReasonGive)
      end
    else
      room:loseHp(to, 1, self.name)
      if not to.dead and #to.player_cards[Player.Equip] > 0 then
        local id = room:askForCardChosen(player, to, "e", self.name)
        to:addToPile(self.name, id, true, self.name)
      end
    end
  end,
}
local junwei_trigger = fk.CreateTriggerSkill{
  name = "#junwei_trigger",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getPile("junwei") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for i = #player:getPile("junwei"), 1, -1 do
      local id = player:getPile("junwei")[i]
      if player:getEquipment(Fk:getCardById(id, true).sub_type) ~= nil then
        room:moveCards({
            ids = {player:getEquipment(Fk:getCardById(id, true).sub_type)},
            from = player.id,
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonPutIntoDiscardPile,
          },
          {
            ids = {id},
            from = player.id,
            to = player.id,
            toArea = Card.PlayerEquip,
            moveReason = fk.ReasonJustMove,
            specialName = "junwei",
          })
      else
        room:moveCards({
          ids = {id},
          from = player.id,
          to = player.id,
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonJustMove,
          specialName = "junwei",
        })
      end
    end
  end,
}
junwei:addRelatedSkill(junwei_trigger)
ganning:addSkill(yinling)
ganning:addSkill(junwei)
Fk:loadTranslationTable{
  ["starsp__ganning"] = "甘宁",
  ["yinling"] = "银铃",
  [":yinling"] = "出牌阶段，你可以弃置一张黑色牌并指定一名其他角色，若如此做，你获得其一张牌并置于你的武将牌上，称为“锦”。（数量最多为四）",
  ["junwei"] = "军威",
  [":junwei"] = "回合结束阶段开始时，你可以将三张“锦”置入弃牌堆。若如此做，你须指定一名角色并令其选择一项：1.亮出一张【闪】，然后由你交给任意一名角色。"..
  "2.该角色失去1点体力，然后由你选择将其装备区的一张牌移出游戏，在该角色的回合结束后，将以此法移出游戏的装备牌移回原处。",
  ["ganning_jin"] = "锦",
  ["#junwei-invoke"] = "军威：你可以将三张“锦”置入弃牌堆",
  ["#junwei-choose"] = "军威：选择一名角色，其展示【闪】并由你交给一名角色，或失去1点体力并移除一张装备直到其回合结束",
  ["#junwei-card"] = "军威：展示一张【闪】并由 %src 交给一名角色，否则失去1点体力并被移除一张装备直到你回合结束",
  ["#junwei-give"] = "军威：将%arg交给一名角色",
}

local xiahoudun = General(extension, "starsp__xiahoudun", "wei", 4)
local fenyong = fk.CreateTriggerSkill{
  name = "fenyong",
  anim_type = "defensive",
  events = {fk.Damaged, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.Damaged then
        return player:hasSkill(self.name)
      else
        return player:getMark("@@fenyong") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.Damaged then
      return player.room:askForSkillInvoke(player, self.name, nil, "#fenyong-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.Damaged then
      player.room:setPlayerMark(player, "@@fenyong", 1)
    else
      return true
    end
  end,
}
local xuehen = fk.CreateTriggerSkill{
  name = "xuehen",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Finish and player:getMark("@@fenyong") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@fenyong", 0)
    local current = room.current
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not player:isProhibited(p, Fk:cloneCard("slash")) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 and (current == nil or current.dead or current:isNude()) then return end
    if #targets == 0 then
      if #current:getCardIds{Player.Hand, Player.Equip} <= player:getLostHp() then
        current:throwAllCards("he")
      else
        local cards = room:askForCardsChosen(player, current, player:getLostHp(), player:getLostHp(), "he", self.name)
        room:throwCard(cards, self.name, current, player)
      end
    else
      if current == nil or current.dead or current:isNude() or player:getLostHp() == 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#xuehen-slash", self.name, false)
        if #to > 0 then
          to = room:getPlayerById(to[1])
        else
          to = room:getPlayerById(table.random(targets))
        end
        room:useVirtualCard("slash", nil, player, to, self.name, true)
      else
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#xuehen-choose::"..current.id..":"..player:getLostHp(), self.name, true)
        if #to > 0 then
          room:useVirtualCard("slash", nil, player, room:getPlayerById(to[1]), self.name, true)
        else
          if #current:getCardIds{Player.Hand, Player.Equip} <= player:getLostHp() then
            current:throwAllCards("he")
          else
            local cards = room:askForCardsChosen(player, current, player:getLostHp(), player:getLostHp(), "he", self.name)
            room:throwCard(cards, self.name, current, player)
          end
        end
      end
    end
  end,
}
xiahoudun:addSkill(fenyong)
xiahoudun:addSkill(xuehen)
Fk:loadTranslationTable{
  ["starsp__xiahoudun"] = "夏侯惇",
  ["fenyong"] = "奋勇",
  [":fenyong"] = "每当你受到一次伤害后，你可以竖置你的体力牌；当你的体力牌为竖置状态时，防止你受到的所有伤害。",
  ["xuehen"] = "雪恨",
  [":xuehen"] = "每个角色的回合结束阶段开始时，若你的体力牌为竖置状态，你须横置之，然后选择一项：1.弃置当前回合角色X张牌（X为你已损失的体力值）；"..
  "2.视为对一名任意角色使用一张【杀】。",
  ["#fenyong-invoke"] = "奋勇：你可以竖置你的体力牌！",
  ["@@fenyong"] = "体力牌竖置",
  ["#xuehen-slash"] = "雪恨：选择一名角色视为对其使用【杀】",
  ["#xuehen-choose"] = "雪恨：选择一名角色视为对其使用【杀】，或点“取消”弃置 %dest %arg张牌",
}

return extension
