local extension = Package("tenyear_activity")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_activity"] = "十周年-活动限定",
}

--文和乱武：李傕 郭汜 樊稠 张济 梁兴 唐姬 段煨 张横 牛辅

local lijue = General(extension, "lijue", "qun", 4, 6)
local langxi = fk.CreateTriggerSkill{
  name = "langxi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      not table.every(player.room:getOtherPlayers(player), function(p)
        return p.hp > player.hp
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.hp <= player.hp end), function(p) return p.id end), 1, 1, "#langxi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:damage({
      from = player,
      to = room:getPlayerById(self.cost_data),
      damage = math.random(0, 2),
      skillName = self.name,
    })
  end,
}
local yisuan = fk.CreateTriggerSkill{
  name = "yisuan",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.card:isCommonTrick() and
      player.room:getCardArea(data.card) == Card.Processing and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
  end,
}
lijue:addSkill(langxi)
lijue:addSkill(yisuan)
Fk:loadTranslationTable{
  ["lijue"] = "李傕",
  ["langxi"] = "狼袭",
  [":langxi"] = "准备阶段开始时，你可以对一名体力值不大于你的其他角色随机造成0~2点伤害。",
  ["#langxi-choose"] = "狼袭：请选择一名体力值不大于你的其他角色，对其随机造成0~2点伤害",
  ["yisuan"] = "亦算",
  [":yisuan"] = "出牌阶段限一次，当你使用普通锦囊牌结算后，你可以减1点体力上限，然后获得此牌。",

  ["$langxi1"] = "袭夺之势，如狼噬骨。",
  ["$langxi2"] = "引吾至此，怎能不袭掠之？",
  ["$yisuan1"] = "吾亦能善算谋划。",
  ["$yisuan2"] = "算计人心，我也可略施一二。",
  ["~lijue"] = "若无内讧，也不至如此。",
}

local guosi = General(extension, "guosi", "qun", 4)
local tanbei = fk.CreateActiveSkill{
  name = "tanbei",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    local choices = {"tanbei2"}
    if not target:isNude() then
      table.insert(choices, 1, "tanbei1")
    end
    local choice = room:askForChoice(target, choices, self.name)
    local targetRecorded = type(player:getMark(choice.."-turn")) == "table" and player:getMark(choice.."-turn") or {}
    table.insertIfNeed(targetRecorded, target.id)
    room:setPlayerMark(player, choice.."-turn", targetRecorded)
    if choice == "tanbei1" then
      local id = table.random(target:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
}
local tanbei_prohibit = fk.CreateProhibitSkill{
  name = "#tanbei_prohibit",
  is_prohibited = function(self, from, to, card)
    local targetRecorded = from:getMark("tanbei1-turn")
    return type(targetRecorded) == "table" and table.contains(targetRecorded, to.id)
  end,
}
local tanbei_targetmod = fk.CreateTargetModSkill{
  name = "#tanbei_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    local targetRecorded = player:getMark("tanbei2-turn")
    return type(targetRecorded) == "table" and to and table.contains(targetRecorded, to.id)
  end,
  bypass_distances =  function(self, player, skill, card, to)
    local targetRecorded = player:getMark("tanbei2-turn")
    return type(targetRecorded) == "table" and to and table.contains(targetRecorded, to.id)
  end,
}
local sidao = fk.CreateTriggerSkill{
  name = "sidao",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isKongcheng() and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      return self.sidao_tos and #self.sidao_tos > 0
    end
  end,
  on_cost = function(self, event, target, player, data)  --TODO: target filter
    local tos, id = player.room:askForChooseCardAndPlayers(player, self.sidao_tos, 1, 1, ".|.|.|hand|.|.", "#sidao-cost", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos[1], id}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("snatch", {self.cost_data[2]}, player, player.room:getPlayerById(self.cost_data[1]), self.name)
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.firstTarget
  end,
  on_refresh = function(self, event, target, player, data)
    self.sidao_tos = {}
    local mark = player:getMark("sidao-phase")
    if mark ~= 0 and #mark > 0 and #AimGroup:getAllTargets(data.tos) > 0 then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        if table.contains(mark, id) then
          table.insert(self.sidao_tos, id)
        end
      end
    end
    if #AimGroup:getAllTargets(data.tos) > 0 then
      mark = AimGroup:getAllTargets(data.tos)
      table.removeOne(mark, player.id)
    else
      mark = 0
    end
    player.room:setPlayerMark(player, "sidao-phase", mark)
  end,
}
tanbei:addRelatedSkill(tanbei_prohibit)
tanbei:addRelatedSkill(tanbei_targetmod)
guosi:addSkill(tanbei)
guosi:addSkill(sidao)
Fk:loadTranslationTable{
  ["guosi"] = "郭汜",
  ["tanbei"] = "贪狈",
  [":tanbei"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.令你随机获得其区域内的一张牌，此回合不能再对其使用牌；"..
  "2.令你此回合对其使用牌没有次数和距离限制。",
  ["sidao"] = "伺盗",
  [":sidao"] = "出牌阶段限一次，当你对一名其他角色连续使用两张牌后，你可将一张手牌当【顺手牵羊】对其使用（目标须合法）。",
  ["tanbei1"] = "其随机获得你区域内的一张牌，此回合不能再对你使用牌",
  ["tanbei2"] = "此回合对你使用牌无次数和距离限制",
  ["#sidao-cost"] = "伺盗：你可将一张手牌当【顺手牵羊】对相同的目标使用",

  ["$tanbei1"] = "此机，我怎么会错失。",
  ["$tanbei2"] = "你的东西，现在是我的了！",
  ["$sidao1"] = "连发伺动，顺手可得。	",
  ["$sidao2"] = "伺机而动，此地可窃。",
  ["~guosi"] = "伍习，你……",
}

local fanchou = General(extension, "fanchou", "qun", 4)
local xingluan = fk.CreateTriggerSkill{
  name = "xingluan",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
    data.tos and #data.tos == 1 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule(".|6")
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
  end,
}
fanchou:addSkill(xingluan)
Fk:loadTranslationTable{
  ["fanchou"] = "樊稠",
  ["xingluan"] = "兴乱",
  [":xingluan"] = "出牌阶段限一次，当你使用的仅指定一个目标的牌结算完成后，你可以从牌堆里获得一张点数为6的牌。",

  ["$xingluan1"] = "大兴兵争，长安当乱。",
  ["$xingluan2"] = "勇猛兴军，乱世当立。",
  ["~fanchou"] = "唉，稚然，疑心甚重。",
}

local zhangji = General(extension, "zhangji", "qun", 4)
local lveming = fk.CreateActiveSkill{
  name = "lveming",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and #target.player_cards[Player.Equip] < #Self.player_cards[Player.Equip]
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    local choices = {}
    for i = 1, 13, 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askForChoice(target, choices, self.name)
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if tostring(judge.card.number) == choice then
      room:damage{
        from = player,
        to = target,
        damage = 2,
        skillName = self.name,
      }
    elseif not target:isAllNude() then
      local id = table.random(target:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
}
local tunjun = fk.CreateActiveSkill{
  name = "tunjun",
  anim_type = "drawcard",
  target_num = 1,
  card_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:usedSkillTimes("lveming", Player.HistoryGame) > 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and #Fk:currentRoom():getPlayerById(to_select).player_cards[Player.Equip] < 4  --TODO: no treasure yet
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    local n = player:usedSkillTimes("lveming", Player.HistoryGame)
    for i = 1, n, 1 do
      local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
      local cards = {}
      for i = 1, #room.draw_pile, 1 do
        local card = Fk:getCardById(room.draw_pile[i])
        for _, type in ipairs(types) do
          if card.sub_type == type and target:getEquipment(type) == nil then
            table.insertIfNeed(cards, room.draw_pile[i])
          end
        end
      end
      if #cards > 0 then
        room:useCard({
          from = target.id,
          tos = {{target.id}},
          card = Fk:getCardById(table.random(cards)),
        })
      end
    end
  end,
}
zhangji:addSkill(lveming)
zhangji:addSkill(tunjun)
Fk:loadTranslationTable{
  ["zhangji"] = "张济",
  ["lveming"] = "掠命",
  [":lveming"] = "出牌阶段限一次，你选择一名装备区装备少于你的其他角色，令其选择一个点数，然后你进行判定：若点数相同，你对其造成2点伤害；"..
  "不同，你随机获得其区域内的一张牌。",
  ["tunjun"] = "屯军",
  [":tunjun"] = "限定技，出牌阶段，你可以选择一名角色，令其随机使用牌堆中的X张不同类型的装备牌。（不替换原有装备，X为你发动〖掠命〗的次数）",

  ["$lveming1"] = "劫命掠财，毫不费力。",
  ["$lveming2"] = "人财，皆掠之，哈哈！",
  ["$tunjun1"] = "得封侯爵，屯军弘农。",
  ["$tunjun2"] = "屯军弘农，养精蓄锐。",
  ["~zhangji"] = "哪，哪里来的乱箭？",
}

local liangxing = General(extension, "liangxing", "qun", 4)
local lulve = fk.CreateTriggerSkill{
  name = "lulve",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (p:getHandcardNum() < #player.player_cards[Player.Hand] and not p:isKongcheng()) end), function(p) return p.id end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#lulve-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choice = room:askForChoice(to, {"lulve_give", "lulve_slash"}, self.name, "#lulve-choice:"..player.id)
    if choice == "lulve_give" then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(to:getCardIds(Player.Hand))
      room:obtainCard(player.id, dummy, false, fk.ReasonGive)
      player:turnOver()
    else
      to:turnOver()
      room:useVirtualCard("slash", nil, to, player, self.name, true)
    end
  end,
}
local zhuixi = fk.CreateTriggerSkill{
  name = "zhuixi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from and data.to and
      ((data.from.faceup and not data.to.faceup) or (not data.from.faceup and data.to.faceup))
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
liangxing:addSkill(lulve)
liangxing:addSkill(zhuixi)
Fk:loadTranslationTable{
  ["liangxing"] = "梁兴",
  ["lulve"] = "掳掠",
  [":lulve"] = "出牌阶段开始时，你可以令一名有手牌且手牌数小于你的其他角色选择一项：1.将所有手牌交给你，然后你翻面；2.翻面，然后视为对你使用一张【杀】。",
  ["zhuixi"] = "追袭",
  [":zhuixi"] = "锁定技，当你对其他角色造成伤害时，或当你受到其他角色造成的伤害时，若你与其翻面状态不同，此伤害+1。",
  ["#lulve-choose"] = "掳掠：你可以令一名有手牌且手牌数小于你的其他角色选择一项",
  ["lulve_give"] = "将所有手牌交给其，其翻面",
  ["lulve_slash"] = "你翻面，视为对其使用【杀】",
  ["#lulve-choice"] = "掳掠：选择对 %src 执行的一项",

  ["$lulve1"] = "趁火打劫，乘危掳掠。",
  ["$lulve2"] = "天下大乱，掳掠以自保。",
  ["$zhuixi1"] = "得势追击，胜望在握！",
  ["$zhuixi2"] = "诸将得令，追而袭之！",
  ["~liangxing"] = "夏侯渊，你竟敢！",
}

local tangji = General(extension, "tangji", "qun", 3, 3, General.Female)
local kangge = fk.CreateTriggerSkill{
  name = "kangge",
  events = {fk.TurnStart, fk.AfterCardsMove, fk.Death},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.TurnStart then
        if player ~= target then return false end
        local room = player.room
        local turn_event = room.logic:getCurrentEvent()
        if not turn_event then return false end
        local x = player:getMark("kangge_record")
        if x == 0 then
          local events = room.logic.event_recorder[GameEvent.Turn] or Util.DummyTable
          for _, e in ipairs(events) do
            local current_player = e.data[1]
            if current_player == player then
              x = e.id
              room:setPlayerMark(player, "kangge_record", x)
              break
            end
          end
        end
        return turn_event.id == x
      elseif event == fk.AfterCardsMove then
        local kangge_id = player:getMark(self.name)
        if kangge_id ~= 0 and player:getMark("kangge-turn") < 3 then
          local kangge_player = player.room:getPlayerById(kangge_id)
          if kangge_player.dead or kangge_player.phase ~= Player.NotActive then return false end
          for _, move in ipairs(data) do
            if kangge_id == move.to and move.toArea == Card.PlayerHand then
              return true
            end
          end
        end
      elseif event == fk.Death then
        return player:getMark(self.name) == target.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.TurnStart then
      room:notifySkillInvoked(player, self.name, "special")
      local targets = table.map(room:getOtherPlayers(player, false), function(p) return p.id end)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#kangge-choose", self.name, false, true)
      if #to > 0 then
        room:setPlayerMark(player, self.name, to[1])
      end
    elseif event == fk.AfterCardsMove then
      local n = 0
      local kangge_id = player:getMark(self.name)
      for _, move in ipairs(data) do
        if move.to and kangge_id == move.to and move.toArea == Card.PlayerHand then
          n = n + #move.moveInfo
        end
      end
      if n > 0 then
        room:notifySkillInvoked(player, self.name, "drawcard")
        local x = math.min(n, 3 - player:getMark("kangge-turn"))
        room:addPlayerMark(player, "kangge-turn", x)
        if player:getMark("@kangge") == 0 then
          room:setPlayerMark(player, "@kangge", room:getPlayerById(kangge_id).general)
        end
        player:drawCards(x, self.name)
      end
    elseif event == fk.Death then
      room:notifySkillInvoked(player, self.name, "negative")
      if player:getMark("@kangge") == 0 then
        room:setPlayerMark(player, "@kangge", target.general)
      end
      player:throwAllCards("he")
      if not player.dead then
        room:loseHp(player, 1, self.name)
      end
    end
  end,

  refresh_events = {fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) == target.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, 0)
    room:setPlayerMark(player, "@kangge", 0)
  end,
}
local kangge_trigger = fk.CreateTriggerSkill{
  name = "#kangge_trigger",
  mute = true,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("kangge") and player:getMark("kangge") == target.id and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("kangge")
    room:notifySkillInvoked(player, "kangge", "support")
    room:doIndicate(player.id, {target.id})
    if player:getMark("@kangge") == 0 then
      room:setPlayerMark(player, "@kangge", target.general)
    end
    room:recover({
      who = target,
      num = 1 - target.hp,
      recoverBy = player,
      skillName = "kangge"
    })
  end,
}
local jielie = fk.CreateTriggerSkill{
  name = "jielie",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from and
      data.from ~= player.id and data.from ~= player:getMark("kangge")
  end,
  on_cost = function(self, event, target, player, data)
    local suits = {"spade", "heart", "club", "diamond"}
    local choices = table.map(suits, function(s) return Fk:translate("log_"..s) end)
    table.insert(choices, "Cancel")
    local choice = player.room:askForChoice(player, choices, self.name, "#jielie-choice")
    if choice ~= "Cancel" then
      self.cost_data = suits[table.indexOf(choices, choice)]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suit = self.cost_data
    room:loseHp(player, data.damage, self.name)
    local kangge_id = player:getMark(self.name)
    if kangge_id ~= 0 then
      local to = room:getPlayerById(kangge_id)
      if to and not to.dead then
        room:setPlayerMark(player, "@kangge", to.general)
        local cards = room:getCardsFromPileByRule(".|.|"..suit, data.damage, "discardPile")
        if #cards > 0 then
          room:moveCards({
            ids = cards,
            to = to.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = player.id,
            skillName = self.name,
            moveVisible = false
          })
        end
      end
    end
    return true
  end,
}
kangge:addRelatedSkill(kangge_trigger)
tangji:addSkill(kangge)
tangji:addSkill(jielie)
Fk:loadTranslationTable{
  ["tangji"] = "唐姬",
  ["kangge"] = "抗歌",
  [":kangge"] = "你的第一个回合开始时，你选择一名其他角色：<br>1.当该角色于其回合外获得手牌后，你摸等量的牌（每回合最多摸三张）；<br>"..
  "2.每轮限一次，当该角色进入濒死状态时，你可以令其将体力回复至1点；<br>3.当该角色死亡时，你弃置所有牌并失去1点体力。",
  ["jielie"] = "节烈",
  [":jielie"] = "当你受到你或〖抗歌〗角色以外的角色造成的伤害时，你可以防止此伤害并选择一种花色，失去X点体力，"..
  "令〖抗歌〗角色从弃牌堆中随机获得X张此花色的牌（X为伤害值）。",
  ["#kangge-choose"] = "抗歌：请选择“抗歌”角色",
  ["@kangge"] = "抗歌",
  ["#jielie-choice"] = "是否发动 节烈，选择一种花色",

  ["$kangge1"] = "慷慨悲歌，以抗凶逆。",
  ["$kangge2"] = "忧惶昼夜，抗之以歌。",
  ["$jielie1"] = "节烈之妇，从一而终也！",
  ["$jielie2"] = "清闲贞静，守节整齐。",
  ["~tangji"] = "皇天崩兮后土颓……",
}

--段煨

local zhangheng = General(extension, "zhangheng", "qun", 8)
local liangjue = fk.CreateTriggerSkill{
  name = "liangjue",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.hp > 1 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black and (info.fromArea == Card.PlayerJudge or info.fromArea == Card.PlayerEquip) then
              return true
            end
          end
        end
        if move.to == player.id and (move.toArea == Card.PlayerJudge or move.toArea == Card.PlayerEquip) then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
    player:drawCards(2, self.name)
  end,
}
local dangzai = fk.CreateTriggerSkill{
  name = "dangzai",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play then
      self.dangzai_tos = {}
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if #p.player_cards[Player.Judge] > 0 then
          for _, j in ipairs(p.player_cards[Player.Judge]) do
            if not player:hasDelayedTrick(Fk:getCardById(j).name) then
              table.insertIfNeed(self.dangzai_tos, p.id)
              break
            end
          end
        end
      end
      return #self.dangzai_tos > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, self.dangzai_tos, 1, 1, "#dangzai-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local ids = {}
    for _, j in ipairs(to.player_cards[Player.Judge]) do
      if not player:hasDelayedTrick(Fk:getCardById(j).name) then
        table.insert(ids, j)
      end
    end
    room:fillAG(player, ids)
    local id = room:askForAG(player, ids, true, self.name)
    room:closeAG(player)
    room:moveCards({
      from = to.id,
      ids = {id},
      to = player.id,
      toArea = Card.PlayerJudge,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    })
  end,
}
zhangheng:addSkill(liangjue)
zhangheng:addSkill(dangzai)
Fk:loadTranslationTable{
  ["zhangheng"] = "张横",
  ["liangjue"] = "粮绝",
  [":liangjue"] = "锁定技，当有黑色牌进入或者离开你的判定区或装备区时，若你的体力值大于1，你失去1点体力，然后摸两张牌。",
  ["dangzai"] = "挡灾",
  [":dangzai"] = "出牌阶段开始时，你可以将一名其他角色判定区里的一张牌移至你的判定区。",
  ["#dangzai-choose"] = "挡灾：你可以将一名其他角色判定区里的一张牌移至你的判定区",

  ["$liangjue1"] = "行军者，切不可无粮！",
  ["$liangjue2"] = "粮尽援绝，须另谋出路。",
  ["$dangzai1"] = "此处有我，休得放肆！",
  ["$dangzai2"] = "退后，让我来！",
  ["~zhangheng"] = "军粮匮乏。",
}

local niufu = General(extension, "niufu", "qun", 4, 7)
local xiaoxi = fk.CreateTriggerSkill{
  name = "xiaoxi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"1", "2"}
    if player.maxHp == 1 then
      choices = {"1"}
    end
    local n = tonumber(room:askForChoice(player, choices, self.name, "#xiaoxi1-choice"))
    room:changeMaxHp(player, -n)
    if player.dead then return end
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:inMyAttackRange(p) end), function (p) return p.id end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#xiaoxi-choose", self.name, false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    choices = {"xiaoxi_prey", "xiaoxi_slash"}
    if #to:getCardIds{Player.Hand, Player.Equip} < n then
      choices = {"xiaoxi_slash"}
    elseif player:isProhibited(to, Fk:cloneCard("slash")) then
      choices = {"xiaoxi_prey"}
    end
    local choice = room:askForChoice(player, choices, self.name, "#xiaoxi2-choice::"..to.id..":"..n)
    if choice == "xiaoxi_prey" then
      local cards = room:askForCardsChosen(player, to, 2, 2, "he", self.name)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      room:obtainCard(player, dummy, false, fk.ReasonPrey)
    else
      for i = 1, n, 1 do
        if player.dead or to.dead then return end
        room:useVirtualCard("slash", nil, player, to, self.name, true)
      end
    end
  end,
}
local xiongrao = fk.CreateTriggerSkill{
  name = "xiongrao",
  anim_type = "offensive",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xiongrao-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      room:setPlayerMark(p, "@@xiongrao-turn", 1)
    end
    local x = 7 - player.maxHp
    if x > 0 then
      room:changeMaxHp(player, x)
      player:drawCards(x, self.name)
    end
  end,
}
local xiongrao_invalidity = fk.CreateInvaliditySkill {
  name = "#xiongrao_invalidity",
  invalidity_func = function(self, from, skill)
    return from:getMark("@@xiongrao-turn") > 0 and
      skill.frequency ~= Skill.Compulsory and skill.frequency ~= Skill.Limited and skill.frequency ~= Skill.Wake and
      not (skill:isEquipmentSkill() or skill.name:endsWith("&"))
  end
}
xiongrao:addRelatedSkill(xiongrao_invalidity)
niufu:addSkill(xiaoxi)
niufu:addSkill(xiongrao)
Fk:loadTranslationTable{
  ["niufu"] = "牛辅",
  ["xiaoxi"] = "宵袭",
  [":xiaoxi"] = "锁定技，出牌阶段开始时，你需减少1或2点体力上限，然后选择一项：1.获得你攻击范围内一名其他角色等量的牌；"..
  "2.视为对你攻击范围内的一名其他角色使用等量张【杀】。",
  ["xiongrao"] = "熊扰",
  [":xiongrao"] = "限定技，准备阶段，你可以令所有其他角色本回合除锁定技、限定技、觉醒技以外的技能全部失效，"..
  "然后你将体力上限增加至7并摸等同于增加体力上限张数的牌。",
  ["#xiaoxi1-choice"] = "宵袭：你需减少1或2点体力上限",
  ["#xiaoxi-choose"] = "宵袭：选择攻击范围内一名角色，获得其等量牌或视为对其使用等量【杀】",
  ["#xiaoxi2-choice"] = "宵袭：选择对 %dest 执行的一项（X为%arg）",
  ["xiaoxi_prey"] = "获得其X张牌",
  ["xiaoxi_slash"] = "视为对其使用X张【杀】",
  ["#xiongrao-invoke"] = "熊扰：你可以令其他角色本回合非锁定技无效，你体力上限增加至7！",
  ["@@xiongrao-turn"] = "熊扰",

  ["$xiaoxi1"] = "夜深枭啼，亡命夺袭！",
  ["$xiaoxi2"] = "以夜为幕，纵兵逞凶！",
  ["$xiongrao1"] = "势如熊罴，威震四海！",
  ["$xiongrao2"] = "啸聚熊虎，免走狐惊！",
  ["~niufu"] = "胡儿安敢杀我！",
}

local dongxie = General(extension, "dongxie", "qun", 4, 4, General.Female)
local jiaoxia = fk.CreateTriggerSkill{
  name = "jiaoxia",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiaoxia-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@jiaoxia-phase", 1)
  end,

  refresh_events = {fk.AfterCardTargetDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local yes = false
    for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
      local p = room:getPlayerById(id)
      if p:getMark("jiaoxia-phase") == 0 then
        room:setPlayerMark(p, "jiaoxia-phase", 1)
        yes = true
      end
    end
    if yes then
      player:addCardUseHistory(data.card.trueName, -1)
    end
  end,
}
local jiaoxia_filter = fk.CreateFilterSkill{
  name = "#jiaoxia_filter",
  anim_type = "offensive",
  card_filter = function(self, card, player)
    return player:getMark("@@jiaoxia-phase") > 0 and not table.contains(player:getCardIds("ej"), card.id)
  end,
  view_as = function(self, card)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = "jiaoxia"
    return c
  end,
}
local jiaoxia_trigger = fk.CreateTriggerSkill{
  name = "#jiaoxia_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and table.contains(data.card.skillNames, "jiaoxia") and not player.dead then
      local c = Fk:getCardById(data.card:getEffectiveId())
      local card = Fk:cloneCard(c.name)
      return (card.type == Card.TypeBasic or card:isCommonTrick()) and not player:prohibitUse(card) and card.skill:canUse(player, card)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local name = Fk:getCardById(data.card:getEffectiveId()).name
    room:setPlayerMark(player, "jiaoxia-tmp", name)
    local success, dat = room:askForUseActiveSkill(player, "jiaoxia_viewas", "#jiaoxia-use:::"..name, true)
    room:setPlayerMark(player, "jiaoxia-tmp", 0)
    if success then
      local card = Fk:cloneCard(name)
      room:useCard{
        from = player.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
        skillName = "jiaoxia_viewas",
        extraUse = true,
      }
    end
  end,
}
local jiaoxia_viewas = fk.CreateViewAsSkill{
  name = "jiaoxia_viewas",
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    if Self:getMark("jiaoxia-tmp") == 0 then return end
    local card = Fk:cloneCard(Self:getMark("jiaoxia-tmp"))
    card.skillName = self.name
    return card
  end,
}
local jiaoxia_targetmod = fk.CreateTargetModSkill{
  name = "#jiaoxia_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, "jiaoxia_viewas")
  end,
}
local humei = fk.CreateActiveSkill{
  name = "humei",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = function(self)
    return "#humei:::"..Self:getMark("humei-phase")
  end,
  interaction = function(self)
    local choices = {}
    for i = 1, 3, 1 do
      if Self:getMark("humei"..i.."-phase") == 0 then
        table.insert(choices, "humei"..i.."-phase")
      end
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    for i = 1, 3, 1 do
      if player:getMark("humei"..i.."-phase") == 0 then
        return true
      end
    end
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 and target.hp <= Self:getMark("humei-phase") then
      if self.interaction.data == "humei1-phase" then
        return true
      elseif self.interaction.data == "humei2-phase" then
        return not target:isNude()
      elseif self.interaction.data == "humei3-phase" then
        return target:isWounded()
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, self.interaction.data, 1)
    if self.interaction.data == "humei1-phase" then
      target:drawCards(1, self.name)
    elseif self.interaction.data == "humei2-phase" then
      local card = room:askForCard(target, 1, 1, true, self.name, false, ".", "#humei-give:"..player.id)
      room:obtainCard(player, card[1], false, fk.ReasonGive)
    elseif self.interaction.data == "humei3-phase" then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,
}
local humei_record = fk.CreateTriggerSkill{
  name = "#humei_record",

  refresh_events = {fk.Damage, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play then
      if event == fk.Damage then
        return true
      else
        return data.name == "humei"
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:addPlayerMark(player, "humei-phase", 1)
    else
      local events = room.logic:getEventsOfScope(GameEvent.ChangeHp, 999, function(e)
        local damage = e.data[5]
        if damage and player == damage.from then
          room:addPlayerMark(player, "humei-phase", 1)
        end
      end, Player.HistoryPhase)
    end
  end,
}
Fk:addSkill(jiaoxia_viewas)
jiaoxia:addRelatedSkill(jiaoxia_filter)
jiaoxia:addRelatedSkill(jiaoxia_targetmod)
jiaoxia:addRelatedSkill(jiaoxia_trigger)
humei:addRelatedSkill(humei_record)
dongxie:addSkill(jiaoxia)
dongxie:addSkill(humei)
Fk:loadTranslationTable{
  ["dongxie"] = "董翓",
  ["jiaoxia"] = "狡黠",
  [":jiaoxia"] = "出牌阶段开始时，你可以令本阶段你的手牌均视为【杀】。若你以此法使用的【杀】造成了伤害，此【杀】结算后你视为使用原牌名的牌。"..
  "出牌阶段，你对每名角色使用第一张【杀】无次数限制。",
  ["humei"] = "狐魅",
  [":humei"] = "出牌阶段每项限一次，你可以选择一项，令一名体力值不大于X的角色执行：1.摸一张牌；2.交给你一张牌；3.回复1点体力"..
  "（X为你本阶段造成伤害次数）。",
  ["#jiaoxia-invoke"] = "狡黠：你可以令本阶段你的手牌均视为【杀】，且结算后你视为使用原本牌名的牌！",
  ["@@jiaoxia-phase"] = "狡黠",
  ["#jiaoxia_filter"] = "狡黠",
  ["jiaoxia_viewas"] = "狡黠",
  ["#jiaoxia-use"] = "狡黠：请视为使用【%arg】",
  ["#humei"] = "狐魅：令一名体力值不大于%arg的角色执行一项",
  ["humei1-phase"] = "摸一张牌",
  ["humei2-phase"] = "交给你一张牌",
  ["humei3-phase"] = "回复1点体力",
  ["#humei-give"] = "狐魅：请交给 %src 一张牌",
  
  ["$jiaoxia1"] = "暗剑匿踪，现时必捣黄龙！",
  ["$jiaoxia2"] = "袖中藏刃，欲取诸君之头！",
  ["$humei1"] = "尔为靴下之臣，当行顺我之事。",
  ["$humei2"] = "妾身一笑，可倾将军之城否？",
  ["~dongxie"] = "覆巢之下，断无完卵余生……",
}

--逐鹿天下：张恭 吕凯 卫温诸葛直

--自走棋：沙摩柯 忙牙长 许贡 张昌蒲
local shamoke = General(extension, "shamoke", "shu", 4)
local jilis = fk.CreateTriggerSkill{
  name = "jilis",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      local x, y = player:getAttackRange(), player:getMark("jilis_times-turn")
      if x >= y then
        local room = player.room
        local logic = room.logic
        local end_id = player:getMark("jilis_record-turn")
        local e = logic:getCurrentEvent()
        if end_id == 0 then
          local turn_event = e:findParent(GameEvent.Turn, false)
          end_id = turn_event.id
        end
        room:setPlayerMark(player, "jilis_record-turn", logic.current_event_id)
        local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
        for i = #events, 1, -1 do
          e = events[i]
          if e.id <= end_id then break end
          local use = e.data[1]
          if use.from == player.id then
            y = y + 1
          end
        end
        events = logic.event_recorder[GameEvent.RespondCard] or Util.DummyTable
        for i = #events, 1, -1 do
          e = events[i]
          if e.id <= end_id then break end
          local use = e.data[1]
          if use.from == player.id then
            y = y + 1
          end
        end
        room:setPlayerMark(player, "jilis_times-turn", y)
        return x == y
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getAttackRange())
  end,
}
shamoke:addSkill(jilis)
Fk:loadTranslationTable{
  ["shamoke"] = "沙摩柯",
  ["jilis"] = "蒺藜",
  [":jilis"] = "当你于一回合内使用或打出第X张牌时，你可以摸X张牌（X为你的攻击范围）。",

  ["$jilis1"] = "蒺藜骨朵，威震慑敌！",
  ["$jilis2"] = "看我一招，铁蒺藜骨朵！",
  ["~shamoke"] = "五溪蛮夷，不可能输！",
}

local mangyachang = General(extension, "mangyachang", "qun", 4)
local jiedao = fk.CreateTriggerSkill{
  name = "jiedao",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if player:getMark("jiedao-turn") == 0 then
        player.room:addPlayerMark(player, "jiedao-turn", 1)
        return player:isWounded()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiedao-invoke::"..data.to.id..":"..player:getLostHp())
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getLostHp()
    data.damage = data.damage + n
    data.extra_data = data.extra_data or {}
    data.extra_data.jiedao = n
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and not data.to.dead and data.extra_data and data.extra_data.jiedao and not player:isNude()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = data.extra_data.jiedao
    if #player:getCardIds{Player.Hand, Player.Equip} <= n then
      player:throwAllCards("he")
    else
      room:askForDiscard(player, n, n, true, self.name, false, ".", "#jiedao-discard:::"..n)
    end
  end,
}
mangyachang:addSkill(jiedao)
Fk:loadTranslationTable{
  ["mangyachang"] = "忙牙长",
  ["jiedao"] = "截刀",
  [":jiedao"] = "当你每回合第一次造成伤害时，你可令此伤害至多+X（X为你损失的体力值）。然后若受到此伤害的角色没有死亡，你弃置等同于此伤害加值的牌。",
  ["#jiedao-invoke"] = "截刀：你可以令你对 %dest 造成的伤害+%arg",
  ["#jiedao-discard"] = "截刀：你需弃置等同于此伤害加值的牌（%arg张）",

  ["$jiedao1"] = "截头大刀的威力，你来尝尝？",
  ["$jiedao2"] = "我这大刀，可是不看情面的。",
  ["~mangyachang"] = "黄骠马也跑不快了……",
}

local xugong = General(extension, "ty__xugong", "wu", 3)
local biaozhao = fk.CreateTriggerSkill{
  name = "biaozhao",
  mute = true,
  events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.EventPhaseStart then
      return (player.phase == Player.Finish and #player:getPile("biaozhao_message") == 0) or
      (player.phase == Player.Start and #player:getPile("biaozhao_message") > 0)
    elseif event == fk.AfterCardsMove and #player:getPile("biaozhao_message") > 0 then
      local pile = Fk:getCardById(player:getPile("biaozhao_message")[1])
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card:compareNumberWith(pile) and card:compareSuitWith(pile) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      local cards = room:askForCard(player, 1, 1, true, self.name, true, ".", "#biaozhao-cost")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
      return false
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(self.name)
      if player.phase == Player.Finish then
        player:addToPile("biaozhao_message", self.cost_data, true, self.name)
      else
        room:moveCards({
          from = player.id,
          ids = player:getPile("biaozhao_message"),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
        })
        local targets = room:askForChoosePlayers(player, table.map(room.alive_players, function (p)
          return p.id end), 1, 1, "#biaozhao-choose", self.name, false)
        if #targets > 0 then
          local to = room:getPlayerById(targets[1])
          if to:isWounded() then
            room:recover{
              who = to,
              num = 1,
              recoverBy = player,
              skillName = self.name,
            }
            if not to.dead then
              local x = 0
              for _, p in ipairs(room.alive_players) do
                x = math.max(x, p:getHandcardNum())
              end
              x = x - to:getHandcardNum()
              if x > 0 then
                room:drawCards(to, math.min(5, x), self.name)
              end
            end
          end
        end
      end
    elseif event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "negative")
      player:broadcastSkillInvoke(self.name)
      local pile = Fk:getCardById(player:getPile("biaozhao_message")[1])
      local targets = {}
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile and move.from ~= nil and
        move.from ~= player.id and not room:getPlayerById(move.from).dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              local card = Fk:getCardById(info.cardId)
              if card:compareNumberWith(pile) and card:compareSuitWith(pile) then
                table.insertIfNeed(targets, move.from)
              end
            end
          end
        end
      end
      if #targets > 1 then
        targets = room:askForChoosePlayers(player, targets, 1, 1, "#biaozhao-target:::" .. pile:toLogString(), self.name, false)
      end
      if #targets > 0 then
        room:obtainCard(targets[1], pile, false, fk.ReasonPrey)
      end
      if #targets == 0 then
        room:moveCards({
          from = player.id,
          ids = {pile.id},
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
        })
        if not player.dead then
          room:loseHp(player, 1, self.name)
        end
      end
    end
  end,
}
local yechou = fk.CreateTriggerSkill{
  name = "yechou",
  anim_type = "offensive",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, false, true) and table.find(player.room.alive_players, function (p)
      return p:getLostHp() > 1
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:getLostHp() > 1
    end)
    local p = room:askForChoosePlayers(player, table.map(targets, function (p)
      return p.id
    end), 1, 1, "#yechou-choose", self.name, true)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:addPlayerMark(to, "@@yechou", 1)
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yechou") > 0 and data.from == Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yechou", 0)
  end,
}
local yechou_delay = fk.CreateTriggerSkill{
  name = "#yechou_delay",
  anim_type = "negative",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and not player.dead and player:getMark("@@yechou") > 0
  end,
  on_cost = function () return true end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, yechou.name)
  end,
}
yechou:addRelatedSkill(yechou_delay)
xugong:addSkill(biaozhao)
xugong:addSkill(yechou)
Fk:loadTranslationTable{
  ["ty__xugong"] = "许贡",
  ["biaozhao"] = "表召",
  [":biaozhao"] = "结束阶段，你可将一张牌置于武将牌上，称为“表”。当一张与“表”花色点数均相同的牌进入弃牌堆时，若此牌是其他角色弃置的牌，"..
  "则其获得“表”，否则你移去“表”并失去1点体力。准备阶段，你移去“表”，令一名角色回复1点体力，其将手牌摸至与手牌最多的角色相同（至多摸五张）。",
  ["yechou"] = "业仇",
  ["#yechou_delay"] = "业仇",
  [":yechou"] = "你死亡时，你可以选择一名已损失的体力值大于1的角色。若如此做，每名角色的结束阶段，其失去1点体力，直到其下回合开始。",

  ["biaozhao_message"] = "表",
  ["#biaozhao-cost"] = "你可以发动表召，选择一张牌作为表置于武将牌上",
  ["#biaozhao-choose"] = "表召：选择一名角色，令其回复1点体力并补充手牌",
  ["#biaozhao-target"] = "表召：选择一名角色，令其获得你的“表”%arg",
  ["#yechou-choose"] = "你可以发动表召，选择一名角色，令其于下个回合开始之前的每名角色的结束阶段都会失去1点体力",
  ["@@yechou"] = "业仇",

  ["$biaozhao1"] = "此人有祸患之像，望丞相慎之。",
  ["$biaozhao2"] = "孙策宜加贵宠，须召还京邑！",
  ["$yechou1"] = "会有人替我报仇的！",
  ["$yechou2"] = "我的门客，是不会放过你的！",
  ["~ty__xugong"] = "终究……还是被其所害……",
}

Fk:loadTranslationTable{
  ["ty__zhangchangpu"] = "张昌蒲",
  ["yanjiao"] = "严教",
  [":yanjiao"] = "出牌阶段限一次，你可以选择一名其他角色并亮出牌堆顶的四张牌，然后令该角色将这些牌分成点数之和相等的两组，"..
    "将这两组牌分配给你与其，且将剩余未分组的牌置入弃牌堆。若未分组的牌超过一张，你本回合手牌上限-1。",
  ["xingshen"] = "省身",
  [":xingshen"] = "当你受到伤害后，你可以摸一张牌并令下一次发动〖严教〗亮出的牌数+1。若你的手牌数为全场最少，改为摸两张牌；"..
  "若你的体力值为全场最少，〖严教〗亮出的牌数改为+2（加值总数至多为4）。",

  ["$yanjiao1"] = "会虽童稚，勤见规诲。",
  ["$yanjiao2"] = "性矜严教，明于教训。",
  ["$xingshen1"] = "居上不骄，制节谨度。",
  ["$xingshen2"] = "君子之行，皆积小以致高大。",
  ["~ty__zhangchangpu"] = "我还是小看了，孙氏的伎俩……",
}
--上兵伐谋：辛毗 张温 李肃
--辛毗

local zhangwen = General(extension, "ty__zhangwen", "wu", 3)
local ty__songshu = fk.CreateActiveSkill{
  name = "ty__songshu",
  anim_type = "drawcard",
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
      player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
    else
      player:drawCards(2, self.name)
      target:drawCards(2, self.name)
    end
  end,
}
local sibian = fk.CreateTriggerSkill{
  name = "sibian",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    local min, max = 13, 1
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).number < min then
        min = Fk:getCardById(id).number
      end
      if Fk:getCardById(id).number > max then
        max = Fk:getCardById(id).number
      end
    end
    local get = {}
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).number == min or Fk:getCardById(cards[i]).number == max then
        table.insert(get, cards[i])
        table.removeOne(cards, cards[i])
      end
    end
    room:delay(1000)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(get)
    room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    if #cards > 0 then
      local n = #player.player_cards[Player.Hand]
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if #p.player_cards[Player.Hand] < n then
          n = #p.player_cards[Player.Hand]
        end
      end
      local targets = {}
      for _, p in ipairs(room:getAlivePlayers()) do
        if #p.player_cards[Player.Hand] == n then
          table.insert(targets, p.id)
        end
      end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#sibian-choose", self.name, true)
      if #to > 0 then
        local dummy2 = Fk:cloneCard("dilu")
        dummy2:addSubcards(cards)
        room:obtainCard(room:getPlayerById(to[1]), dummy2, false, fk.ReasonGive)
      else
        room:moveCards({
          ids = cards,
          fromArea = Card.Processing,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
        })
      end
    end
    return true
  end,
}
zhangwen:addSkill(ty__songshu)
zhangwen:addSkill(sibian)
Fk:loadTranslationTable{
  ["ty__zhangwen"] = "张温",
  ["ty__songshu"] = "颂蜀",
  [":ty__songshu"] = "出牌阶段限一次，你可以与一名其他角色拼点：若你没赢，你和该角色各摸两张牌；若你赢，视为本阶段此技能未发动过。",
  ["sibian"] = "思辩",
  [":sibian"] = "摸牌阶段，你可以放弃摸牌，改为亮出牌堆顶的4张牌，你获得其中所有点数最大和最小的牌，然后你可以将剩余的牌交给一名手牌数最少的角色。",
  ["#sibian-choose"] = "思辩：你可以将剩余的牌交给一名手牌数最少的角色",

  ["$ty__songshu1"] = "称颂蜀汉，以表诚心。",
  ["$ty__songshu2"] = "吴蜀两和，方可安稳。",
  ["$sibian1"] = "才藻俊茂，辨思如涌。",
  ["$sibian2"] = "弘雅之素，英秀之德。",
  ["~ty__zhangwen"] = "暨艳过错，强牵吾罪。",
}

--李肃

--戚宦之争：何进 冯方 赵忠 穆顺
local hejin = General(extension, "ty__hejin", "qun", 4)
local ty__mouzhu = fk.CreateActiveSkill{
  name = "ty__mouzhu",
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return to_select ~= Self.id and (target:distanceTo(Self) == 1 or target.hp == Self.hp) and not target:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, p in ipairs(effect.tos) do
      local target = room:getPlayerById(p)
      if player.dead or target.dead then return end
      if not target:isKongcheng() then
        local card = room:askForCard(target, 1, 1, false, self.name, false, ".", "#mouzhu-give::"..player.id)
        room:obtainCard(player, card[1], false, fk.ReasonGive)
        if #player.player_cards[Player.Hand] > #target.player_cards[Player.Hand] then
          local choice = room:askForChoice(target, {"slash", "duel"}, self.name)
          room:useVirtualCard(choice, nil, target, player, self.name, true)
        end
      end
    end
  end,
}
local ty__yanhuo = fk.CreateTriggerSkill{
  name = "ty__yanhuo",
  anim_type = "offensive",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#yanhuo-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player.room:setTag("yanhuo", true)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.room:getTag("yanhuo") and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
}
hejin:addSkill(ty__mouzhu)
hejin:addSkill(ty__yanhuo)
Fk:loadTranslationTable{
  ["ty__hejin"] = "何进",
  ["ty__mouzhu"] = "谋诛",
  [":ty__mouzhu"] = "出牌阶段限一次，你可以选择任意名与你距离为1或体力值与你相同的其他角色，依次将一张手牌交给你，然后若其手牌数小于你，"..
  "其视为对你使用一张【杀】或【决斗】。",
  ["ty__yanhuo"] = "延祸",
  [":ty__yanhuo"] = "当你死亡时，你可以令本局接下来所有【杀】的伤害基数值+1。",
  ["#mouzhu-give"] = "谋诛：交给%dest一张手牌，然后若你手牌数小于其，视为你对其使用【杀】或【决斗】",
  ["#yanhuo-invoke"] = "延祸：你可以令本局接下来所有【杀】的伤害基数值+1！",
}

--冯方

local zhaozhong = General(extension, "zhaozhong", "qun", 6)
local yangzhong = fk.CreateTriggerSkill{
  name = "yangzhong",
  anim_type = "offensive",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not data.from.dead and not data.to.dead and
      #data.from:getCardIds{Player.Hand, Player.Equip} > 1
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(data.from, 2, 2, true, self.name, true, ".", "#yangzhong-invoke::"..data.to.id) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(data.to, 1, self.name)
  end
}
local huangkong = fk.CreateTriggerSkill{
  name = "huangkong",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:isKongcheng() and player.phase == Player.NotActive and
      (data.card:isCommonTrick() or data.card.trueName == "slash")
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
zhaozhong:addSkill(yangzhong)
zhaozhong:addSkill(huangkong)
Fk:loadTranslationTable{
  ["zhaozhong"] = "赵忠",
  ["yangzhong"] = "殃众",
  [":yangzhong"] = "当你造成或受到伤害后，伤害来源可以弃置两张牌，令受到伤害的角色失去1点体力。",
  ["huangkong"] = "惶恐",
  [":huangkong"] = "锁定技，你的回合外，当你成为【杀】或普通锦囊牌的目标后，若你没有手牌，你摸两张牌。",
  ["#yangzhong-invoke"] = "殃众：你可以弃置两张牌，令 %dest 失去1点体力",
}

local mushun = General(extension, "mushun", "qun", 4)
local jinjianm = fk.CreateTriggerSkill{
  name = "jinjianm",
  anim_type = "defensive",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@mushun_jin", 1)
    if event == fk.Damaged then
      local to = data.from
      if to and not to.dead and to ~= player and not player:isKongcheng() and not to:isKongcheng() and
        room:askForSkillInvoke(player, self.name, nil, "#jinjianm-invoke::"..to.id) then
        local pindian = player:pindian({to}, self.name)
        if pindian.results[to.id].winner == player and player:isWounded() then
          room:recover({
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
      end
    end
  end
}
local jinjianm_attackrange = fk.CreateAttackRangeSkill{
  name = "#jinjianm_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@mushun_jin")
  end,
}
local shizhao = fk.CreateTriggerSkill{
  name = "shizhao",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:isKongcheng() and player.phase == Player.NotActive and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from == player.id then
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
    if player:getMark("@mushun_jin") > 0 then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:removePlayerMark(player, "@mushun_jin", 1)
      player:drawCards(2, self.name)
    else
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
      room:addPlayerMark(player, "@shizhao-turn", 1)
    end
  end,

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@shizhao-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("@shizhao-turn")
    player.room:setPlayerMark(player, "@shizhao-turn", 0)
  end,
}
jinjianm:addRelatedSkill(jinjianm_attackrange)
mushun:addSkill(jinjianm)
mushun:addSkill(shizhao)
Fk:loadTranslationTable{
  ["mushun"] = "穆顺",
  ["jinjianm"] = "劲坚",
  [":jinjianm"] = "当你造成或受到伤害后，你获得一个“劲”标记，然后你可以与伤害来源拼点：若你赢，你回复1点体力。每有一个“劲”你的攻击范围+1。",
  ["shizhao"] = "失诏",
  [":shizhao"] = "锁定技，你的回合外，当你每回合第一次失去最后一张手牌时：若你有“劲”，你移去一个“劲”并摸两张牌；没有“劲”，你本回合下一次受到的伤害值+1。",
  ["@mushun_jin"] = "劲",
  ["#jinjianm-invoke"] = "劲坚：你可以与 %dest 拼点，若赢，你回复1点体力",
  ["@shizhao-turn"] = "失诏",
}

--兵临城下：牛金 李采薇 赵俨 王威 李异谢旌 孟达 是仪 孙狼
local niujin = General(extension, "ty__niujin", "wei", 4)
local cuirui = fk.CreateActiveSkill{
  name = "cuirui",
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_num = 0,
  min_target_num = 1,
  max_target_num = function()
    return Self.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected < Self.hp and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      local card = room:askForCardChosen(player, p, "h", self.name)
      room:obtainCard(player, card, false, fk.ReasonPrey)
    end
  end,
}
local ty__liewei = fk.CreateTriggerSkill{
  name = "ty__liewei",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase ~= Player.NotActive
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
niujin:addSkill(cuirui)
niujin:addSkill(ty__liewei)
Fk:loadTranslationTable{
  ["ty__niujin"] = "牛金",
  ["cuirui"] = "摧锐",
  [":cuirui"] = "限定技，出牌阶段，你可以选择至多X名其他角色（X为你的体力值），你获得这些角色各一张手牌。",
  ["ty__liewei"] = "裂围",
  [":ty__liewei"] = "你的回合内，有角色进入濒死状态时，你可以摸一张牌。",
}

local licaiwei = General(extension, "licaiwei", "qun", 3, 3, General.Female)
local yijiao = fk.CreateActiveSkill{
  name = "yijiao",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = 4,
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("yijiao1") == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    if not self.interaction.data then self.interaction.data = 1 end  --for AI
    room:addPlayerMark(target, "yijiao1", 10 * self.interaction.data)
    room:setPlayerMark(target, "@yijiao", target:getMark("yijiao1"))
    room:setPlayerMark(target, "yijiao_src", effect.from)
  end,
}
local yijiao_record = fk.CreateTriggerSkill{
  name = "#yijiao_record",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and not player.dead and target:getMark("yijiao_src") == player.id
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getMark("yijiao2") - target:getMark("yijiao1")
    room:doIndicate(player.id, {target.id})
    if n < 0 then
      player:broadcastSkillInvoke("yijiao", 1)
      room:notifySkillInvoked(player, "yijiao", "control")
      if not target:isKongcheng() then
        local cards = table.filter(target.player_cards[Player.Hand], function (id)
          return not target:prohibitDiscard(Fk:getCardById(id))
        end)
        if #cards > 0 then
          local x = math.random(1, math.min(3, #cards))
          if x < #cards then
            cards = table.random(cards, x)
          end
          room:throwCard(cards, "yijiao", target, target)
        end
      end
    elseif n == 0 then
      player:broadcastSkillInvoke("yijiao", 2)
      room:notifySkillInvoked(player, "yijiao", "support")
      player:drawCards(2, "yijiao")
      target:gainAnExtraTurn(true)
    else
      player:broadcastSkillInvoke("yijiao", 2)
      room:notifySkillInvoked(player, "yijiao", "drawcard")
      player:drawCards(3, "yijiao")
    end
  end,

  refresh_events = {fk.CardUsing, fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return target == player and player:getMark("yijiao1") ~= 0 and player.phase ~= Player.NotActive and data.card.number > 0
    elseif event == fk.AfterTurnEnd then
      return target == player and player:getMark("yijiao1") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:addPlayerMark(player, "yijiao2", data.card.number)
      room:setPlayerMark(player, "@yijiao", string.format("%d/%d", target:getMark("yijiao1"), target:getMark("yijiao2")))
    elseif event == fk.AfterTurnEnd then
      room:setPlayerMark(player, "yijiao1", 0)
      room:setPlayerMark(player, "yijiao2", 0)
      room:setPlayerMark(player, "@yijiao", 0)
      room:setPlayerMark(player, "yijiao_src", 0)
    end
  end,
}
local qibie = fk.CreateTriggerSkill{
  name = "qibie",
  anim_type = "drawcard",
  events = {fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qibie-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getHandcardNum()
    player:throwAllCards("h")
    if player.dead then return end
    if player:isWounded() then
      player.room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    player:drawCards(n + 1, self.name)
  end,
}
yijiao:addRelatedSkill(yijiao_record)
licaiwei:addSkill(yijiao)
licaiwei:addSkill(qibie)
Fk:loadTranslationTable{
  ["licaiwei"] = "李采薇",
  ["yijiao"] = "异教",
  [":yijiao"] = "出牌阶段限一次，你可以选择一名其他角色并选择一个1~4的数字，该角色获得十倍的“异”标记；"..
  "有“异”标记的角色结束阶段，若其本回合使用牌的点数之和：<br>"..
  "1.小于“异”标记数，其随机弃置一至三张手牌；<br>"..
  "2.等于“异”标记数，你摸两张牌且其于本回合结束后进行一个额外的回合；<br>"..
  "3.大于“异”标记数，你摸三张牌。",
  ["qibie"] = "泣别",
  [":qibie"] = "一名角色死亡后，你可以弃置所有手牌，然后回复1点体力值并摸X+1张牌（X为你以此法弃置牌数）。",
  ["@yijiao"] = "异",
  ["#yijiao_record"] = "异教",
  ["#qibie-invoke"] = "泣别：你可以弃置所有手牌，回复1点体力值并摸弃牌数+1张牌",

  ["$yijiao1"] = "攻乎异教，斯害也已。",
  ["$yijiao2"] = "非我同盟，其心必异。",
  ["$qibie1"] = "忽闻君别，泣下沾襟。",
  ["$qibie2"] = "相与泣别，承其遗志。",
  ["~licaiwei"] = "随君而去……",
}

local zhaoyan = General(extension, "ty__zhaoyan", "wei", 3)
local funing = fk.CreateTriggerSkill{
  name = "funing",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#funing-invoke:::"..player:usedSkillTimes(self.name, Player.HistoryTurn) + 1)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
    local n = player:usedSkillTimes(self.name, Player.HistoryTurn)
    if #player:getCardIds{Player.Hand, Player.Equip} <= n then
      player:throwAllCards("he")
    else
      player.room:askForDiscard(player, n, n, true, self.name, false, ".")
    end
  end,
}
local bingji = fk.CreateActiveSkill{
  name = "bingji",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  interaction = UI.ComboBox {choices = {"slash", "peach"}},
  can_use = function(self, player)
    if not player:isKongcheng() then
      local suit = Fk:getCardById(player.player_cards[Player.Hand][1]):getSuitString()
      return table.every(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getSuitString() == suit end) and
        (player:getMark("bingji-turn") == 0 or not table.contains(player:getMark("bingji-turn"), suit))
    end
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:showCards(player.player_cards[Player.Hand])
    local card = Fk:cloneCard(self.interaction.data)
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if self.interaction.data == "peach" then
        if p:isWounded() and not player:isProhibited(p, card) then
          table.insert(targets, p.id)
        end
      else
        if not player:isProhibited(p, card) then
          table.insert(targets, p.id)
        end
      end
    end
    if #targets == 0 then return end
    local mark = player:getMark("bingji-turn")
    local icon = player:getMark("@bingji-turn")
    if mark == 0 then mark = {} end
    if icon == 0 then icon = {} end
    local suit = Fk:getCardById(player.player_cards[Player.Hand][1]):getSuitString()
    local suits = {"spade", "heart", "club", "diamond"}
    local icons = {"♠", "♥", "♣", "♦"}
    for i = 1, 4, 1 do
      if suits[i] == suit then
        table.insert(mark, suit)
        table.insert(icon, icons[i])
      end
    end
    room:setPlayerMark(player, "bingji-turn", mark)
    room:setPlayerMark(player, "@bingji-turn", icon)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#bingji-choose:::"..self.interaction.data, self.name, false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    room:useVirtualCard(self.interaction.data, nil, player, to, self.name, false)
  end
}
zhaoyan:addSkill(funing)
zhaoyan:addSkill(bingji)
Fk:loadTranslationTable{
  ["ty__zhaoyan"] = "赵俨",
  ["funing"] = "抚宁",
  [":funing"] = "当你使用一张牌时，你可以摸两张牌然后弃置X张牌（X为此技能本回合发动次数）。",
  ["bingji"] = "秉纪",
  [":bingji"] = "出牌阶段每种花色限一次，若你的手牌均为同一花色，则你可以展示所有手牌（至少一张），然后视为对一名其他角色使用一张【杀】或一张【桃】。",
  ["#funing-invoke"] = "抚宁：你可以摸两张牌，然后弃置%arg张牌",
  ["@bingji-turn"] = "秉纪",
  ["#bingji-choose"] = "秉纪：选择一名角色视为对其使用【%arg】",
}

Fk:loadTranslationTable{
  ["wangwei"] = "王威",
  ["ruizhan"] = "锐战",
  [":ruizhan"] = "其他的角色准备阶段，若其手牌数大于等于体力值，你可以与其拼点：若你赢或者拼点牌有【杀】，你视为对其使用一张【杀】；"..
  "若两项均满足，此【杀】造成伤害后你获得其一张牌。",
  ["shilie"] = "示烈",
  [":shilie"] = "出牌阶段限一次，你可以选择一项：1.回复1点体力，然后将两张牌置于武将牌上（不足则全放，总数不能大于游戏人数）；"..
  "2.失去1点体力，然后获得武将牌上的两张牌。<br>你死亡时，你可将武将牌上的牌交给除伤害来源外的一名其他角色。",
}

local liyixiejing = General(extension, "liyixiejing", "wu", 4)
local douzhen = fk.CreateFilterSkill{
  name = "douzhen",
  anim_type = "switch",
  switch_skill_name = "douzhen",
  card_filter = function(self, card, player)
    if player:hasSkill(self.name) and player.phase ~= Player.NotActive and card.type == Card.TypeBasic then
      if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
        return card.color == Card.Black
      else
        return card.color == Card.Red
      end
    end
  end,
  view_as = function(self, card, player)
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return Fk:cloneCard("duel", card.suit, card.number)
    else
      return Fk:cloneCard("slash", card.suit, card.number)
    end
  end,
}
local douzhen_trigger = fk.CreateTriggerSkill{
  name = "#douzhen_trigger",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "douzhen") and data.tos and
      player:getSwitchSkillState("douzhen", true) == fk.SwitchYang and
      table.find(TargetGroup:getRealTargets(data.tos), function(id) return not player.room:getPlayerById(id):isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        local c = room:askForCardChosen(player, p, "he", "douzhen")
        room:obtainCard(player, c, false, fk.ReasonPrey)
      end
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.PreCardRespond},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "douzhen")
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, MarkEnum.SwithSkillPreName .. "douzhen", player:getSwitchSkillState("douzhen", true))
    player:addSkillUseHistory("douzhen")
  end,
}
local douzhen_targetmod = fk.CreateTargetModSkill{
  name = "#douzhen_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if card.trueName == "slash" and table.contains(card.skillNames, "douzhen") and scope == Player.HistoryPhase then
      return 999
    end
  end,
}
douzhen:addRelatedSkill(douzhen_trigger)
douzhen:addRelatedSkill(douzhen_targetmod)
liyixiejing:addSkill(douzhen)
Fk:loadTranslationTable{
  ["liyixiejing"] = "李异谢旌",
  ["douzhen"] = "斗阵",
  [":douzhen"] = "转换技，锁定技，你的回合内，阳：你的黑色基本牌视为【决斗】，且使用时获得目标一张牌；阴：你的红色基本牌视为【杀】，且使用时无次数限制。",
}

local mengda = General(extension, "ty__mengda", "wei", 4)
mengda.subkingdom = "shu"
local libang = fk.CreateActiveSkill{
  name = "libang",
  anim_type = "control",
  card_num = 1,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected < 2 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    room:sortPlayersByAction(effect.tos, false)
    local target1 = room:getPlayerById(effect.tos[1])
    local target2 = room:getPlayerById(effect.tos[2])
    local id1 = room:askForCardChosen(player, target1, "he", self.name)
    local id2 = room:askForCardChosen(player, target2, "he", self.name)
    room:obtainCard(player.id, id1, true, fk.ReasonPrey)
    room:obtainCard(player.id, id2, true, fk.ReasonPrey)
    player:showCards({id1, id2})
    local pattern = "."
    if Fk:getCardById(id1, true).color == Fk:getCardById(id2, true).color then
      if Fk:getCardById(id1, true).color == Card.Black then
        pattern = ".|.|spade,club"
      else
        pattern = ".|.|heart,diamond"
      end
    end
    local judge = {
      who = player,
      reason = self.name,
      pattern = pattern,
      extra_data = {effect.tos, {id1, id2}},
    }
    room:judge(judge)
  end,
}
local libang_record = fk.CreateTriggerSkill{
  name = "#libang_record",

  refresh_events = {fk.FinishJudge},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.reason == "libang"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card.color == Card.NoColor then return end
    local targets = data.extra_data[1]
    for i = 2, 1, -1 do
      if room:getPlayerById(targets[i]).dead then
        table.removeOne(targets, targets[i])
      end
    end
    if data.card.color ~= Fk:getCardById(data.extra_data[2][1], true).color and
      data.card.color ~= Fk:getCardById(data.extra_data[2][2], true).color then
      if #targets == 0 or #player:getCardIds{Player.Hand, Player.Equip} < 2 then
        room:loseHp(player, 1, "libang")
      else
        room:setPlayerMark(player, "libang-phase", targets)
        if not room:askForUseActiveSkill(player, "#libang_active", "#libang-card", true) then
          room:loseHp(player, 1, "libang")
        end
        room:setPlayerMark(player, "libang-phase", 0)
      end
    else
      if room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
      end
      targets = table.filter(targets, function(id) return not player:isProhibited(room:getPlayerById(id), Fk:cloneCard("slash")) end)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#libang-slash", "libang", false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(targets)
      end
      room:useVirtualCard("slash", nil, player, room:getPlayerById(to), "libang")
    end
  end,
}
local libang_active = fk.CreateActiveSkill{
  name = "libang_active",
  mute = true,
  card_num = 2,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return #selected < 2
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and table.contains(Self:getMark("libang-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:obtainCard(target.id, dummy, false, fk.ReasonGive)
  end,
}
local wujie = fk.CreateTriggerSkill{
  name = "wujie",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardUseDeclared, fk.BuryVictim},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.AfterCardUseDeclared then
        return player:hasSkill(self.name) and data.card.color == Card.NoColor
      else
        return player:hasSkill(self.name, false, true) and not player.room:getTag("SkipNormalDeathProcess")
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      player:addCardUseHistory(data.card.trueName, -1)
    else
      player.room:setTag("SkipNormalDeathProcess", true)
      player.room:setTag(self.name, true)
    end
  end,

  refresh_events = {fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.room:getTag(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setTag("SkipNormalDeathProcess", false)
    player.room:setTag(self.name, false)
  end,
}
local wujie_targetmod = fk.CreateTargetModSkill{
  name = "#wujie_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if player:hasSkill("wujie") and card and card.color == Card.NoColor and scope == Player.HistoryPhase then
      return 999
    end
  end,
  distance_limit_func =  function(self, player, skill, card)
    if player:hasSkill("wujie") and card and card.color == Card.NoColor then
      return 999
    end
  end,
}
Fk:addSkill(libang_active)
libang:addRelatedSkill(libang_record)
wujie:addRelatedSkill(wujie_targetmod)
mengda:addSkill(libang)
mengda:addSkill(wujie)
Fk:loadTranslationTable{
  ["ty__mengda"] = "孟达",
  ["libang"] = "利傍",
  [":libang"] = "出牌阶段限一次，你可以弃置一张牌，获得并展示两名其他角色各一张牌，然后你判定，若结果与这两张牌的颜色："..
  "均不同，你交给其中一名角色两张牌或失去1点体力；至少一张相同，你获得判定牌并视为对其中一名角色使用一张【杀】。",
  ["wujie"] = "无节",
  [":wujie"] = "锁定技，你使用的无色牌不计入次数且无距离限制；其他角色杀死你后不执行奖惩。",
  ["#libang-card"] = "利傍：交给其中一名角色两张牌，否则失去1点体力",
  ["#libang-slash"] = "利傍：视为对其中一名角色使用一张【杀】",
  ["libang_active"] = "利傍",
}

local shiyi = General(extension, "shiyi", "wu", 3)
local cuichuan = fk.CreateActiveSkill{
  name = "cuichuan",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
    local cards = {}
    for i = 1, #room.draw_pile, 1 do
      local card = Fk:getCardById(room.draw_pile[i])
      for _, type in ipairs(types) do
        if card.sub_type == type and target:getEquipment(type) == nil then
          table.insertIfNeed(cards, room.draw_pile[i])
        end
      end
    end
    if #cards > 0 then
      room:moveCardTo({table.random(cards)}, Player.Equip, target, fk.ReasonJustMove, self.name)
    end
    local n = #target.player_cards[Player.Equip]
    if n > 0 then
      player:drawCards(n, self.name)
    end
    if #cards > 0 and n > 3 then
      room:handleAddLoseSkills(player, "-cuichuan|zuojian", nil, true, false)
      target:gainAnExtraTurn(true)
    end
  end,
}
local zhengxu = fk.CreateTriggerSkill{
  name = "zhengxu",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("zhengxu1-turn") > 0 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_trigger = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu1-turn", 0)
    return self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhengxu1-invoke")
  end,
  on_use = function(self, event, target, player, data)
    return true
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu1-turn", 1)
  end,
}
local zhengxu_trigger = fk.CreateTriggerSkill{
  name = "#zhengxu_trigger",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:getMark("zhengxu2-turn") > 0 and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      self.cost_data = 0
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              self.cost_data = self.cost_data + 1
            end
          end
        end
      end
      return self.cost_data > 0
    end
  end,
  on_trigger = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu2-turn", 0)
    return self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhengxu2-invoke:::"..self.cost_data)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.cost_data, self.name)
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu2-turn", 1)
  end,
}
local zuojian = fk.CreateTriggerSkill{
  name = "zuojian",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getMark("zuojian-phase") >= player.hp and
      (#table.filter(player.room:getOtherPlayers(player), function(p)
        return #p.player_cards[Player.Equip] > #player.player_cards[Player.Equip] end) > 0 or
      #table.filter(player.room:getOtherPlayers(player), function(p)
        return #p.player_cards[Player.Equip] < #player.player_cards[Player.Equip] and not p:isKongcheng() end) > 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    local targets1 = table.filter(player.room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Equip] > #player.player_cards[Player.Equip] end)
    local targets2 = table.filter(player.room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Equip] < #player.player_cards[Player.Equip] and not p:isKongcheng() end)
    if #targets1 > 0 then
      table.insert(choices, "zuojian1")
    end
    if #targets2 > 0 then
      table.insert(choices, "zuojian2")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "zuojian1" then
      room:doIndicate(player.id, table.map(targets1, function(p) return p.id end))
      for _, p in ipairs(targets1) do
        p:drawCards(1, self.name)
      end
    end
    if choice == "zuojian2" then
      room:doIndicate(player.id, table.map(targets2, function(p) return p.id end))
      for _, p in ipairs(targets2) do
        local id = room:askForCardChosen(player, p, "h", self.name)
        room:throwCard({id}, self.name, p, player)
      end
    end
  end,

  refresh_events = {fk.CardUsing, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play then
      if event == fk.CardUsing then
        return target == player
      else
        return data == self
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:addPlayerMark(player, "zuojian-phase", 1)
      if player:hasSkill(self.name, true) then
        room:addPlayerMark(player, "@zuojian-phase", 1)
      end
    else
      local events = room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryPhase)
      room:addPlayerMark(player, "zuojian-phase", #events)
      room:addPlayerMark(player, "@zuojian-phase", #events)
    end
  end,
}
zhengxu:addRelatedSkill(zhengxu_trigger)
shiyi:addSkill(cuichuan)
shiyi:addSkill(zhengxu)
shiyi:addRelatedSkill(zuojian)
Fk:loadTranslationTable{
  ["shiyi"] = "是仪",
  ["cuichuan"] = "榱椽",
  [":cuichuan"] = "出牌阶段限一次，你可以弃置一张手牌并选择一名角色，从牌堆中将一张随机装备牌置入其装备区空位，你摸X张牌（X为其装备区牌数）。"..
  "若其装备区内的牌因此达到4张或以上，你失去〖榱椽〗并获得〖佐谏〗，然后令其在此回合结束后获得一个额外回合。",
  ["zhengxu"] = "正序",
  [":zhengxu"] = "每回合各限一次，当你失去牌后，你本回合下一次受到伤害时，你可以防止此伤害；当你受到伤害后，你本回合下一次失去牌后，你可以摸等量的牌。",
  ["zuojian"] = "佐谏",
  [":zuojian"] = "出牌阶段结束时，若你此阶段使用的牌数大于等于你的体力值，你可以选择一项：1.令装备区牌数大于你的角色摸一张牌；"..
  "2.弃置装备区牌数小于你的每名角色各一张手牌。",
  ["#zhengxu_trigger"] = "正序",
  ["#zhengxu1-invoke"] = "正序：你可以防止你受到的伤害",
  ["#zhengxu2-invoke"] = "正序：你可以摸%arg张牌",
  ["@zuojian-phase"] = "佐谏",
  ["zuojian1"] = "装备区牌数大于你的角色各摸一张牌",
  ["zuojian2"] = "你弃置装备区牌数小于你的角色各一张手牌",
}

local sunlang = General(extension, "sunlang", "shu", 4)
local tingxian = fk.CreateTriggerSkill{
  name = "tingxian",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and #AimGroup:getAllTargets(data.tos) > 0 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local n = #player.player_cards[Player.Equip] + 1
    return n > 0 and player.room:askForSkillInvoke(player, self.name, nil, "#tingxian-invoke:::"..n)
  end,
  on_use = function(self, event, target, player, data)
    local n = #player.player_cards[Player.Equip] + 1
    player:drawCards(n, self.name)
    local targets = player.room:askForChoosePlayers(player, AimGroup:getAllTargets(data.tos), 1, n, "#tingxian-choose:::"..n, self.name, true)
    if #targets > 0 then
      table.insertTable(data.nullifiedTargets, targets)
    end
  end,
}
local benshi = fk.CreateTriggerSkill{
  name = "benshi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      if not table.contains(AimGroup:getAllTargets(data.tos), p.id) and player:inMyAttackRange(p) and not player:isProhibited(p, data.card) then
        TargetGroup:pushTargets(data.targetGroup, p.id)
      end
    end
  end,
}
local benshi_attackrange = fk.CreateAttackRangeSkill{
  name = "#benshi_attackrange",
  frequency = Skill.Compulsory,
  correct_func = function (self, from, to)
    if from:hasSkill(self.name) then
      local fix = 1
      if from:getEquipment(Card.SubtypeWeapon) then
        fix = fix + 1 - Fk:getCardById(from:getEquipment(Card.SubtypeWeapon)).attack_range
      end
      return fix
    end
    return 0
  end,
}
benshi:addRelatedSkill(benshi_attackrange)
sunlang:addSkill(tingxian)
sunlang:addSkill(benshi)
Fk:loadTranslationTable{
  ["sunlang"] = "孙狼",
  ["tingxian"] = "铤险",
  [":tingxian"] = "每回合限一次，你使用【杀】指定目标后，你可以摸X张牌，然后令此【杀】对其中至多X个目标无效（X为你装备区的牌数+1）。",
  ["benshi"] = "奔矢",
  [":benshi"] = "锁定技，你装备区内的武器牌不提供攻击范围，你的攻击范围+1，你使用【杀】须指定攻击范围内所有角色为目标。",
  ["#tingxian-invoke"] = "铤险：你可以摸%arg张牌，然后可以令此【杀】对至多等量的目标无效",
  ["#tingxian-choose"] = "铤险：你可以令此【杀】对至多%arg名目标无效",
}

--千里单骑：关羽 杜夫人 秦宜禄 卞喜 胡班 关宁
local guanyu = General(extension, "ty__guanyu", "wei", 4)
local ty__danji = fk.CreateTriggerSkill{
  name = "ty__danji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getHandcardNum() > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = self.name
      })
    end
    room:handleAddLoseSkills(player, "mashu|nuchen", nil, true, false)
  end,
}
local nuchen = fk.CreateActiveSkill{
  name = "nuchen",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
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
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards(id)
    local suit = Fk:getCardById(id):getSuitString()
    if suit == "nosuit" then return end
    local cards = room:askForDiscard(player, 1, 999, true, self.name, true, ".|.|"..suit, "#nuchen-card::"..target.id..":"..suit)
    if #cards > 0 then
      room:damage{
        from = player,
        to = target,
        damage = #cards,
        skillName = self.name,
      }
    else
      local dummy = Fk:cloneCard("dilu")
      for _, id in ipairs(target.player_cards[Player.Hand]) do
        if Fk:getCardById(id):getSuitString() == suit then
          dummy:addSubcard(id)
        end
      end
      room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
    end
  end,
}
guanyu:addSkill("ex__wusheng")
guanyu:addSkill(ty__danji)
guanyu:addRelatedSkill(nuchen)
Fk:loadTranslationTable{
  ["ty__guanyu"] = "关羽",
  ["ty__wusheng"] = "武圣",
  [":ty__wusheng"] = "你可以将一张红色牌当【杀】使用或打出；你使用<font color='red'>♦</font>【杀】无距离限制。",
  ["ty__danji"] = "单骑",
  [":ty__danji"] = "觉醒技，准备阶段，若你的手牌数大于体力值，你减1点体力上限，回复体力至体力上限，然后获得〖马术〗和〖怒嗔〗。",
  ["nuchen"] = "怒嗔",
  [":nuchen"] = "出牌阶段限一次，你可以展示一名其他角色的一张手牌，然后你选择一项：1.弃置任意张相同花色的牌，对其造成等量的伤害；"..
  "2.获得其手牌中所有此花色的牌。",
  ["#nuchen-card"] = "怒嗔：你可以弃置任意张%arg牌对 %dest 造成等量伤害，或获得其全部此花色手牌",

  ["$ex__wusheng_ty__guanyu1"] = "以义传魂，以武入圣！",
  ["$ex__wusheng_ty__guanyu2"] = "义击逆流，武安黎庶。",
  ["$ty__danji1"] = "单骑护嫂千里，只为桃园之义！	",
  ["$ty__danji2"] = "独身远涉，赤心归国！",
  ["$nuchen1"] = "触关某之逆鳞者，杀无赦！",
  ["$nuchen2"] = "天下碌碌之辈，安敢小觑关某？！",
  ["~ty__guanyu"] = "樊城一去，死亦无惧……",
}

local dufuren = General(extension, "dufuren", "wei", 3, 3, General.Female)
local yise = fk.CreateTriggerSkill{
  name = "yise",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          self.yise_to = move.to
          for _, info in ipairs(move.moveInfo) do
            self.yise_color = Fk:getCardById(info.cardId).color
            if self.yise_color == Card.Red then
              return player.room:getPlayerById(move.to):isWounded()
            else
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if self.yise_color == Card.Red then
      return player.room:askForSkillInvoke(player, self.name, data, "#yise-invoke::"..self.yise_to)
    elseif self.yise_color == Card.Black then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.yise_to)
    if self.yise_color == Card.Red then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    elseif self.yise_color == Card.Black then
      room:addPlayerMark(to, "yise_damage", 1)
    end
  end,
}
local yise_record = fk.CreateTriggerSkill{
  name = "#yise_record",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("yise_damage") > 0 and data.card and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("yise_damage")
    player.room:setPlayerMark(player, "yise_damage", 0)
  end,
}
local shunshi = fk.CreateTriggerSkill{
  name = "shunshi",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and not player:isNude() then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if event == fk.EventPhaseStart or (event == fk.Damaged and p ~= data.from) then
        table.insert(targets, p.id)
      end
    end
    local tos, id = room:askForChooseCardAndPlayers(player, targets, 1, 1, ".", "#shunshi-cost", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos[1], id}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(self.cost_data[1], self.cost_data[2], false, fk.ReasonGive)
    room:addPlayerMark(player, self.name, 1)
  end,

  refresh_events = {fk.DrawNCards, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if player:getMark(self.name) > 0 then
      if event == fk.DrawNCards then
        return true
      else
        return data.to == Player.NotActive
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n + player:getMark("shunshi")
    else
      player.room:setPlayerMark(player, self.name, 0)
    end
  end,
}
local shunshi_targetmod = fk.CreateTargetModSkill{
  name = "#shunshi_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill("shunshi") and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("shunshi")
    end
  end,
}
local shunshi_maxcards = fk.CreateMaxCardsSkill{
  name = "#shunshi_maxcards",
  correct_func = function(self, player)
    return player:getMark("shunshi")
  end,
}
yise:addRelatedSkill(yise_record)
shunshi:addRelatedSkill(shunshi_targetmod)
shunshi:addRelatedSkill(shunshi_maxcards)
dufuren:addSkill(yise)
dufuren:addSkill(shunshi)
Fk:loadTranslationTable{
  ["dufuren"] = "杜夫人",
  ["yise"] = "异色",
  [":yise"] = "当其他角色获得你的牌后，若此牌为：红色，你可以令其回复1点体力；黑色，其下次受到【杀】造成的伤害时，此伤害+1。",
  ["shunshi"] = "顺世",
  [":shunshi"] = "准备阶段或当你于回合外受到伤害后，你可以交给一名其他角色一张牌（伤害来源除外），然后直到你的回合结束，你：摸牌阶段多摸一张牌、出牌阶段使用的【杀】次数上限+1、手牌上限+1。",
  ["#yise-invoke"] = "异色：你可以令 %dest 回复1点体力",
  ["#shunshi-cost"] = "顺世：你可以交给一名其他角色一张牌，然后直到你的回合结束获得效果",

  ["$yise1"] = "明丽端庄，双瞳剪水。",
  ["$yise2"] = "姿色天然，貌若桃李。",
  ["$shunshi1"] = "顺应时运，得保安康。",
  ["$shunshi2"] = "随遇而安，宠辱不惊。",
  ["~dufuren"] = "往事云烟，去日苦多。",
}

--秦宜禄

local bianxi = General(extension, "bianxi", "wei", 4)
local dunxi = fk.CreateTriggerSkill{
  name = "dunxi",
  anim_type = "control",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.is_damage_card and data.tos
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, TargetGroup:getRealTargets(data.tos), 1, 1, "#dunxi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), "@bianxi_dun", 1)
  end,

  refresh_events = {fk.TargetSpecifying, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if event == fk.TargetSpecifying then
        return player:getMark("@bianxi_dun") > 0 and (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and
          data.firstTarget and data.tos and #AimGroup:getAllTargets(data.tos) == 1
      else
        return data.extra_data and data.extra_data.dunxi
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.TargetSpecifying then
      local room = player.room
      room:removePlayerMark(player, "@bianxi_dun", 1)
      local targets = {}
      for _, p in ipairs(room:getAlivePlayers()) do
        if not player:isProhibited(p, data.card) then
          if (data.card.trueName == "slash" and p ~= player) or
            (data.card.name == "peach" and p:isWounded()) or
            (data.card.trueName ~= "slash" and data.card.name ~= "peach") then
            table.insertIfNeed(targets, p.id)
          end
        end
      end
      local to = TargetGroup:getRealTargets(data.tos)[1]
      local new_to = table.random(targets)
      TargetGroup:removeTarget(data.targetGroup, to)
      TargetGroup:pushTargets(data.targetGroup, new_to)
      room:delay(1000)  --来一段市长动画？
      room:doIndicate(player.id, {new_to})
      if to == new_to then
        room:loseHp(player, 1, self.name)
        if not player.dead and player.phase == Player.Play then
          data.extra_data = data.extra_data or {}
          data.extra_data.dunxi = true
        end
      end
    else
      local current = player.room.logic:getCurrentEvent()
      local use_event = current:findParent(GameEvent.UseCard)
      if not use_event then return end
      local phase_event = use_event:findParent(GameEvent.Phase)
      if not phase_event then return end
      use_event:addExitFunc(function()
        phase_event:shutdown()
      end)
    end
  end,
}
bianxi:addSkill(dunxi)
Fk:loadTranslationTable{
  ["bianxi"] = "卞喜",
  ["dunxi"] = "钝袭",
  [":dunxi"] = "当你使用伤害牌结算后，你可令其中一个目标获得1个“钝”标记。有“钝”标记的角色使用基本牌或锦囊牌指定唯一目标时，"..
  "移去一个“钝”，然后目标改为随机一名角色。若随机的目标与原本目标相同，则其失去1点体力并结束出牌阶段。",
  ["#dunxi-choose"] = "钝袭：你可以令一名角色获得“钝”标记，其使用下一张牌目标改为随机角色",
  ["@bianxi_dun"] = "钝",
}

local huban = General(extension, "ty__huban", "wei", 4)
local chongyi = fk.CreateTriggerSkill{
  name = "chongyi",
  anim_type = "support",
  events = {fk.CardUsing, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target.phase == Player.Play and player.tag[self.name] and #player.tag[self.name] > 0 then
      local tag = player.tag[self.name]
      if event == fk.CardUsing then
        return #tag == 1 and tag[1] == "slash"
      else
        local name = tag[#tag]
        player.tag[self.name] = {}
        return name == "slash"
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if event == fk.CardUsing then
      prompt = "#chongyi-draw::"
    else
      prompt = "#chongyi-maxcards::"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      target:drawCards(2, self.name)
      room:addPlayerMark(target, "chongyi-turn", 1)
    else
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, 1)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and target.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.tag[self.name] = player.tag[self.name] or {}
    table.insert(player.tag[self.name], data.card.trueName)
  end,
}
local chongyi_targetmod = fk.CreateTargetModSkill{
  name = "#chongyi_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("chongyi-turn") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
chongyi:addRelatedSkill(chongyi_targetmod)
huban:addSkill(chongyi)
Fk:loadTranslationTable{
  ["ty__huban"] = "胡班",
  ["chongyi"] = "崇义",
  [":chongyi"] = "一名角色出牌阶段内使用的第一张牌若为【杀】，你可令其摸两张牌且此阶段使用【杀】次数上限+1；一名角色出牌阶段结束时，若其此阶段使用的最后一张牌为【杀】，你可令其本回合手牌上限+1。",
  ["#chongyi-draw"] = "崇义：你可以令 %dest 摸两张牌且此阶段使用【杀】次数上限+1",
  ["#chongyi-maxcards"] = "崇义：你可以令 %dest 本回合手牌上限+1",

  ["$chongyi1"] = "班虽卑微，亦知何为大义。",
  ["$chongyi2"] = "大义当头，且助君一臂之力。",
  ["~ty__huban"] = "行义而亡，虽死无憾。",
}

local guannings = General(extension, "guannings", "shu", 3)
local xiuwen = fk.CreateTriggerSkill{
  name = "xiuwen",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (player:getMark("@$xiuwen") == 0 or not table.contains(player:getMark("@$xiuwen"), data.card.trueName))
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local mark = player:getMark("@$xiuwen")
    if mark == 0 then mark = {} end
    table.insert(mark, data.card.trueName)
    player.room:setPlayerMark(player, "@$xiuwen", mark)
    player:drawCards(1, self.name)
  end,
}
local longsong_active = fk.CreateActiveSkill{
  name = "longsong_active",
  mute = true,
  card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target.id, effect.cards[1], false, fk.ReasonGive)
    local skills = {}
    for _, s in ipairs(target.player_skills) do  --实际是许劭技能池。这不加强没法玩
      if not (s.attached_equip or s.name[#s.name] == "&") and not player:hasSkill(s, true) then
        if s:isInstanceOf(ActiveSkill) or s:isInstanceOf(ViewAsSkill) then
          if s.frequency ~= Skill.Limited then
            table.insertIfNeed(skills, s.name)
          end
        elseif s:isInstanceOf(TriggerSkill) then
          local str = Fk:translate(":"..s.name)
          if string.sub(str, 1, 12) == "出牌阶段" and string.sub(str, 13, 15) ~= "开始" and string.sub(str, 13, 15) ~= "结束" then
            table.insertIfNeed(skills, s.name)
          end
        end
      end
    end
    if #skills > 0 then
      room:setPlayerMark(player, "longsong-phase", skills)
      room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
    end
  end,
}
local longsong = fk.CreateTriggerSkill{
  name = "longsong",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForUseActiveSkill(player, "longsong_active", "#longsong-invoke", true)
  end,

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 and
      player:getMark("longsong-phase") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skills = player:getMark("longsong-phase")
    room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"), nil, true, false)
  end,
}
local longsong_invalidity = fk.CreateInvaliditySkill {
  name = "#longsong_invalidity",
  invalidity_func = function(self, from, skill)
    return from:getMark("longsong-phase") ~= 0 and table.contains(from:getMark("longsong-phase"), skill.name) and
      from:usedSkillTimes(skill.name, Player.HistoryPhase) > 0
  end
}
Fk:addSkill(longsong_active)
longsong:addRelatedSkill(longsong_invalidity)
guannings:addSkill(xiuwen)
guannings:addSkill(longsong)
Fk:loadTranslationTable{
  ["guannings"] = "关宁",
  ["xiuwen"] = "修文",
  [":xiuwen"] = "你使用一张牌时，若此牌名是你本局游戏第一次使用，你摸一张牌。",
  ["longsong"] = "龙诵",
  [":longsong"] = "出牌阶段开始时，你可以交给一名其他角色一张红色牌，然后你此阶段获得其拥有的“出牌阶段”的技能（每回合限发动一次）。<br>"..
  "<font color='grey'>可以获得的技能包括：<br>非限定技的转化技和主动技，技能描述前四个字为“出牌阶段”且五~六字不为“开始”和“结束”的触发技<br/>",
  ["@$xiuwen"] = "修文",
  ["#longsong-invoke"] = "龙诵：你可以交给一名其他角色一张红色牌，本阶段获得其拥有的“出牌阶段”技能",
  ["longsong_active"] = "龙诵",
}

--烽火连天：南华老仙 童渊 张宁 庞德公
local nanhualaoxian = General(extension, "ty__nanhualaoxian", "qun", 4)
local gongxiu = fk.CreateTriggerSkill{
  name = "gongxiu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and
      player:usedSkillTimes("jinghe", Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"Cancel"}
    local all_choices = {"Cancel", "gongxiu_draw", "gongxiu_discard"}
    if table.find(player.room.alive_players, function(p) return p:getMark("jinghe") ~= 0 end) then
      table.insert(choices, "gongxiu_draw")
    end
    if table.find(player.room.alive_players, function(p) return p:getMark("jinghe") == 0 and not p:isKongcheng() end) then
      table.insert(choices, "gongxiu_discard")
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#gongxiu-invoke", false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data[10] == "r" then
      for _, p in ipairs(room.alive_players) do
        if p:getMark("jinghe") ~= 0 and not p.dead then
          room:doIndicate(player.id, {p.id})
          p:drawCards(1, self.name)
        end
      end
    else
      for _, p in ipairs(room.alive_players) do
        if p:getMark("jinghe") == 0 and not p.dead then
          room:doIndicate(player.id, {p.id})
          if not p:isKongcheng() then
            room:askForDiscard(p, 1, 1, false, self.name, false)
          end
        end
      end
    end
  end,
}
local jinghe = fk.CreateActiveSkill{
  name = "jinghe",
  anim_type = "support",
  min_card_num = 1,
  min_target_num = 1,
  prompt = "#jinghe",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    if #selected < 4 and Fk:currentRoom():getCardArea(to_select) == Player.Hand then
      if #selected == 0 then
        return true
      else
        return table.every(selected, function(id) return Fk:getCardById(to_select).trueName ~= Fk:getCardById(id).trueName end)
      end
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected < #selected_cards
  end,
  feasible = function (self, selected, selected_cards)
    return #selected > 0 and #selected == #selected_cards
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "jinghe_used", 1)
    player:showCards(effect.cards)
    local skills = table.random(
      {"ex__leiji", "yinbingn", "huoqi", "guizhu", "xianshou", "lundao", "guanyue", "yanzhengn",
      "ex__biyue", "ex__tuxi", "mingce", "zhiyan"
    }, 4)
    local selected = {}
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        local choices = table.filter(skills, function(s) return not p:hasSkill(s, true) and not table.contains(selected, s) end)
        if #choices > 0 then
          local choice = room:askForChoice(p, choices, self.name, "#jinghe-choice", true, skills)
          room:setPlayerMark(p, self.name, choice)
          table.insert(selected, choice)
          room:handleAddLoseSkills(p, choice, nil, true, false)
        end
      end
    end
  end,
}
local jinghe_trigger = fk.CreateTriggerSkill {
  name = "#jinghe_trigger",
  mute = true,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("jinghe_used") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "jinghe_used", 0)
    for _, p in ipairs(room.alive_players) do
      if p:getMark("jinghe") ~= 0 then
        local skill = p:getMark("jinghe")
        room:setPlayerMark(p, "jinghe", 0)
        room:handleAddLoseSkills(p, "-"..skill, nil, true, false)
      end
    end
  end,
}
jinghe:addRelatedSkill(jinghe_trigger)
nanhualaoxian:addSkill(gongxiu)
nanhualaoxian:addSkill(jinghe)
local ex__leiji = fk.CreateTriggerSkill{
  name = "ex__leiji",
  anim_type = "offensive",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player and data.card.name == "jink"
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, "#ex__leiji-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local judge = {
      who = to,
      reason = self.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade then
      room:damage{
        from = player,
        to = to,
        damage = 2,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    elseif judge.card.suit == Card.Club then
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
      end
    end
  end,
}
local yinbingn = fk.CreateTriggerSkill{
  name = "yinbingn",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.PreDamage, fk.HpLost},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.PreDamage then
        return target == player and data.card and data.card.trueName == "slash"
      else
        return target ~= player
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PreDamage then
      room:loseHp(data.to, data.damage, self.name)
      return true
    else
      player:drawCards(1, self.name)
    end
  end,
}
local huoqi = fk.CreateActiveSkill{
  name = "huoqi",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#huoqi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return target:isWounded() and table.every(Fk:currentRoom().alive_players, function(p) return target.hp <= p.hp end)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    if target:isWounded() then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if not target.dead then
      target:drawCards(1, self.name)
    end
  end,
}
local guizhu = fk.CreateTriggerSkill{
  name = "guizhu",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
local xianshou = fk.CreateActiveSkill{
  name = "xianshou",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#xianshou",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local n = not target:isWounded() and 2 or 1
    target:drawCards(n, self.name)
  end
}
local lundao = fk.CreateTriggerSkill{
  name = "lundao",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from and not data.from.dead and
      data.from:getHandcardNum() ~= player:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    if data.from:getHandcardNum() > player:getHandcardNum() then
      return player.room:askForSkillInvoke(player, self.name, nil, "#lundao-invoke::"..data.from.id)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.from
    if data.from:getHandcardNum() > player:getHandcardNum() then
      room:doIndicate(player.id, {from.id})
      local id = room:askForCardChosen(player, from, "he", self.name)
      room:throwCard({id}, self.name, from, player)
    else
      player:drawCards(1, self.name)
    end
  end
}
local guanyue = fk.CreateTriggerSkill{
  name = "guanyue",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result = room:askForGuanxing(player, room:getNCards(2), {1, 1}, {1, 1}, self.name, true, {"Top", "prey"})
    if #result.top > 0 then
      table.insert(room.draw_pile, 1, result.top[1])
      room:sendLog{
        type = "#GuanxingResult",
        from = player.id,
        arg = 1,
        arg2 = 0,
      }
    end
    if #result.bottom > 0 then
      room:obtainCard(player.id, result.bottom[1], false, fk.ReasonJustMove)
    end
  end,
}
local yanzhengn = fk.CreateTriggerSkill{
  name = "yanzhengn",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and player:getHandcardNum() > 1
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(player.room.alive_players, function(p) return p.id end)
    local tos, card = player.room:askForChooseCardAndPlayers(player, targets, 1, player:getHandcardNum() - 1, ".|.|.|hand",
      "#yanzhengn-invoke:::"..(player:getHandcardNum() - 1), self.name, true)
    if #tos > 0 and card then
      self.cost_data = {tos, card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = player:getCardIds("h")
    table.removeOne(ids, self.cost_data[2])
    room:throwCard(ids, self.name, player, player)
    for _, id in ipairs(self.cost_data[1]) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
nanhualaoxian:addRelatedSkill(ex__leiji)
nanhualaoxian:addRelatedSkill(yinbingn)
nanhualaoxian:addRelatedSkill(huoqi)
nanhualaoxian:addRelatedSkill(guizhu)
nanhualaoxian:addRelatedSkill(xianshou)
nanhualaoxian:addRelatedSkill(lundao)
nanhualaoxian:addRelatedSkill(guanyue)
nanhualaoxian:addRelatedSkill(yanzhengn)
nanhualaoxian:addRelatedSkill("ex__biyue")
nanhualaoxian:addRelatedSkill("ex__tuxi")
nanhualaoxian:addRelatedSkill("mingce")
nanhualaoxian:addRelatedSkill("zhiyan")
Fk:loadTranslationTable{
  ["ty__nanhualaoxian"] = "南华老仙",
  ["gongxiu"] = "共修",
  [":gongxiu"] = "结束阶段，若你本回合发动过〖经合〗，你可以选择一项：1.令所有本回合因〖经合〗获得过技能的角色摸一张牌；"..
  "2.令所有本回合未因〖经合〗获得过技能的其他角色弃置一张手牌。",
  ["jinghe"] = "经合",
  [":jinghe"] = "出牌阶段限一次，你可展示至多四张牌名各不同的手牌，选择等量的角色，从“写满技能的天书”随机展示四个技能，这些角色依次选择并"..
  "获得其中一个，直到你下回合开始。",
  ["#gongxiu-invoke"] = "共修：你可以执行一项",
  ["gongxiu_draw"] = "令“经合”角色各摸一张牌",
  ["gongxiu_discard"] = "令非“经合”角色各弃置一张手牌",
  ["#jinghe"] = "经合：展示至多四张牌名各不同的手牌，令等量的角色获得技能",
  ["#jinghe-choice"] = "经合：选择你要获得的技能",
  ["ex__leiji"] = "雷击",
  [":ex__leiji"] = "当你使用或打出【闪】后，你可以令一名其他角色进行一次判定，若结果为：♠，你对其造成2点雷电伤害；♣，你回复1点体力，对其造成1点雷电伤害。",
  ["#ex__leiji-choose"] = "雷击：令一名角色进行判定，若为♠，你对其造成2点雷电伤害；若为♣，你回复1点体力，对其造成1点雷电伤害",
  ["yinbingn"] = "阴兵",
  [":yinbingn"] = "锁定技，你使用【杀】即将造成的伤害视为失去体力。当其他角色失去体力后，你摸一张牌。",
  ["huoqi"] = "活气",
  [":huoqi"] = "出牌阶段限一次，你可以弃置一张牌，然后令一名体力最少的角色回复1点体力并摸一张牌。",
  ["#huoqi"] = "活气：弃置一张牌，令一名体力最少的角色回复1点体力并摸一张牌",
  ["guizhu"] = "鬼助",
  [":guizhu"] = "每回合限一次，当一名角色进入濒死状态时，你可以摸两张牌。",
  ["xianshou"] = "仙授",
  [":xianshou"] = "出牌阶段限一次，你可以令一名角色摸一张牌。若其未受伤，则多摸一张牌。",
  ["#xianshou"] = "仙授：令一名角色摸一张牌，若其未受伤则多摸一张牌",
  ["lundao"] = "论道",
  [":lundao"] = "当你受到伤害后，若伤害来源的手牌多于你，你可以弃置其一张牌；若伤害来源的手牌数少于你，你摸一张牌。",
  ["#lundao-invoke"] = "论道：你可以弃置 %dest 一张牌",
  ["guanyue"] = "观月",
  [":guanyue"] = "结束阶段，你可以观看牌堆顶的两张牌，然后获得其中一张，将另一张置于牌堆顶。",
  ["prey"] = "获得",
  ["yanzhengn"] = "言政",
  [":yanzhengn"] = "准备阶段，若你的手牌数大于1，你可以选择一张手牌并弃置其余的牌，然后对至多等于弃置牌数的角色各造成1点伤害。",
  ["#yanzhengn-invoke"] = "言政：你可以选择保留一张手牌，弃置其余的手牌，对至多%arg名角色各造成1点伤害",
}

Fk:loadTranslationTable{
  ["ty__tongyuan"] = "童渊",
  ["chaofeng"] = "朝凤",
  [":chaofeng"] = "出牌阶段限一次，当你使用牌造成伤害时，你可以弃置一张手牌，然后摸一张牌。若弃置的牌与造成伤害的牌：颜色相同，则多摸一张牌；"..
  "类型相同，则此伤害+1。",
  ["chuanshu"] = "传术",
  [":chuanshu"] = "限定技，准备阶段若你已受伤，或当你死亡时，你可令一名其他角色获得〖朝凤〗，然后你获得〖龙胆〗、〖从谏〗、〖穿云〗。",
  ["chuanyun"] = "穿云",
  [":chuanyun"] = "当你使用【杀】指定目标后，你可令该角色随机弃置一张装备区里的牌。",
}

local zhangning = General(extension, "ty__zhangning", "qun", 3, 3, General.Female)
local tianze = fk.CreateTriggerSkill{
  name = "tianze",
  events = {fk.CardUseFinished},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Play and data.card.color == Card.Black and
      player:usedSkillTimes(self.name) == 0 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|spade,club|hand,equip", "#tianze-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:throwCard(self.cost_data, self.name, player, player)
    room:damage{ from = player, to = target, damage = 1, skillName = self.name}
  end,
}
local tianze_draw = fk.CreateTriggerSkill{
  name = "#tianze_draw",
  events = {fk.FinishJudge},
  anim_type = "drawcard",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(tianze.name) and data.card.color == Card.Black
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(tianze.name)
    player.room:notifySkillInvoked(player, tianze.name, self.anim_type)
    player.room:drawCards(player, 1, self.name)
  end,
}
local difa = fk.CreateTriggerSkill{
  name = "difa",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 and player.phase ~= Player.NotActive then
      for _, move in ipairs(data) do
        if move.to == player.id and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand and table.find(move.moveInfo, function (info)
          return info.fromArea == Card.DrawPile and player.room:getCardOwner(info.cardId) == player and
            player.room:getCardArea(info.cardId) == Player.Hand and Fk:getCardById(info.cardId).color == Card.Red end) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DrawPile and player.room:getCardOwner(info.cardId) == player and
          player.room:getCardArea(info.cardId) == Player.Hand and Fk:getCardById(info.cardId).color == Card.Red then
            table.insert(ids, info.cardId)
          end
        end
      end
    end
    if #ids == 0 then return false end
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, tostring(Exppattern{ id = ids }), "#difa-invoke", true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeTrick and not card.is_derived then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    local name = room:askForChoice(player, names, self.name)
    local cards = room:getCardsFromPileByRule(name, 1, "discardPile")
    if #cards == 0 then
      cards = room:getCardsFromPileByRule(name, 1)
    end
    if #cards > 0 then
      room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
    end
  end,
}
tianze:addRelatedSkill(tianze_draw)
zhangning:addSkill(tianze)
zhangning:addSkill(difa)
Fk:loadTranslationTable{
  ["ty__zhangning"] = "张宁",
  ["tianze"] = "天则",
  [":tianze"] = "其他角色的出牌阶段限一次，其使用黑色牌结算后，你可以弃置一张黑色牌对其造成1点伤害；其他角色的黑色判定牌生效后，你摸一张牌。",
  ["difa"] = "地法",
  [":difa"] = "你的回合内限一次，当你从牌堆摸到红色牌后，你可以弃置此牌，然后选择一种锦囊牌的牌名，从牌堆或弃牌堆获得一张。",

  ["#tianze-invoke"] = "天则：你可弃置一张黑色牌来对%dest造成1点伤害",
  ["#difa-invoke"] = "地法：你可弃置一张摸到的红色牌，然后检索一张锦囊牌",
  ["$tianze1"] = "观天则，以断人事。",
  ["$tianze2"] = "乾元用九，乃见天则。",
  ["$difa1"] = "地蕴天成，微妙玄通。",
  ["$difa2"] = "观地之法，吉在其中。",
  ["~ty__zhangning"] = "全气之地，当葬其止……",
}

--庞德公

return extension
