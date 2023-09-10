local extension = Package("thunder")
extension.extensionName = "shzl"

Fk:loadTranslationTable{
  ["thunder"] = "神话再临·雷",
}

local zhangxiu = General(extension, "zhangxiu", "qun", 4)
local xiongluan = fk.CreateActiveSkill{
  name = "xiongluan",
  anim_type = "offensive",
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
    (#player:getAvailableEquipSlots() > 0 or not table.contains(player.sealedSlots, Player.JudgeSlot))
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return Self.id ~= to_select
  end,
  on_use = function(self, room, effect)
    local to = room:getPlayerById(effect.tos[1])
    local player = room:getPlayerById(effect.from)
    local eqipSlots = player:getAvailableEquipSlots()
    if not table.contains(player.sealedSlots, Player.JudgeSlot) then
      table.insert(eqipSlots, Player.JudgeSlot)
    end
    room:abortPlayerArea(player, eqipSlots)
    room:addPlayerMark(to, "@@xiongluan-turn")
    local targetRecorded = type(player:getMark("xiongluan_target-turn")) == "table" and player:getMark("xiongluan_target-turn") or {}
    table.insertIfNeed(targetRecorded, to.id)
    room:setPlayerMark(player, "xiongluan_target-turn", targetRecorded)
  end,
}
local xiongluan_prohibit = fk.CreateProhibitSkill{
  name = "#xiongluan_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@@xiongluan-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@@xiongluan-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
}
local xiongluan_targetmod = fk.CreateTargetModSkill{
  name = "#xiongluan_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    if card and to then
      local targetRecorded = player:getMark("xiongluan_target-turn")
      return type(targetRecorded) == "table" and table.contains(targetRecorded, to.id)
    end
  end,
  bypass_distances = function(self, player, skill, card, to)
    if card and to then
      local targetRecorded = player:getMark("xiongluan_target-turn")
      return type(targetRecorded) == "table" and table.contains(targetRecorded, to.id)
    end
  end,
}
xiongluan:addRelatedSkill(xiongluan_targetmod)
xiongluan:addRelatedSkill(xiongluan_prohibit)
local congjian = fk.CreateTriggerSkill{
  name = "congjian",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.type == Card.TypeTrick and #AimGroup:getAllTargets(data.tos) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = AimGroup:getAllTargets(data.tos)
    table.removeOne(targets, player.id)
    local tos, cardId = room:askForChooseCardAndPlayers(
      player,
      targets,
      1,
      1,
      nil,
      "#congjian-give",
      self.name,
      true
    )
    if #tos > 0 then
      self.cost_data = {tos[1], cardId}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(self.cost_data[1], self.cost_data[2], false, fk.ReasonGive)
    if not player.dead then
      player:drawCards(Fk:getCardById(self.cost_data[2]).type == Card.TypeEquip and 2 or 1, self.name)
    end
  end,
}

zhangxiu:addSkill(xiongluan)
zhangxiu:addSkill(congjian)
Fk:loadTranslationTable{
  ["zhangxiu"] = "张绣",
  ["xiongluan"] = "雄乱",
  [":xiongluan"] = "限定技，出牌阶段，你可以废除你的判定区和装备区，然后指定一名其他角色。直到回合结束，你对其使用牌无距离和次数限制，其不能使用和打出手牌。",
  ["congjian"] = "从谏",
  [":congjian"] = "当你成为锦囊牌的目标时，若此牌的目标数大于1，则你可以交给其中一名其他目标角色一张牌，然后摸一张牌，若你给出的是装备牌，改为摸两张牌。",
  ["@@xiongluan-turn"] = "雄乱",
  ["#congjian-give"] = "从谏：你可以选择一名为目标的其他角色，交给其一张牌，然后你摸一张牌。若你以此法交出的是装备牌，改为摸两张牌。",
  ["$xiongluan1"] = "北地枭雄，乱世不败！！",
  ["$xiongluan2"] = "雄据宛城，虽乱世可安！",
  ["$congjian1"] = "听君谏言，去危亡，保宗祀!",
  ["$congjian2"] = "从谏良计，可得自保！",
  ["~zhangxiu"] = "若失文和……吾将何归~~",
}

local haozhao = General(extension, "haozhao", "wei", 4)
local zhengu = fk.CreateTriggerSkill{
  name = "zhengu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p) return p.id end),
      1, 1, "#zhengu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local mark = to:getMark("@@zhengu")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, player.id)
    room:setPlayerMark(to, "@@zhengu", mark)
    local x, y, z = player:getHandcardNum(), to:getHandcardNum(), 0
    if x > y then
      z = math.min(5, x) - y
      if z > 0 then
        room:drawCards(to, z, self.name)
      end
    elseif x < y then
      z = y-x
      room:askForDiscard(to, z, z, false, self.name, false)
    end
  end,

  refresh_events = {fk.BuryVictim, fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@@zhengu") ~= 0 and (event == fk.BuryVictim or player == target)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.BuryVictim then
      local mark = player:getMark("@@zhengu")
      if type(mark) == "table" and table.removeOne(mark, target.id) then
        room:setPlayerMark(player, "@@zhengu", #mark > 0 and mark or 0)
      end
    elseif event == fk.AfterTurnEnd then
      room:setPlayerMark(player, "@@zhengu", 0)
    end
  end,
}
local zhengu_delay = fk.CreateTriggerSkill{
  name = "#zhengu_delay",
  events = {fk.TurnEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target.dead or player.dead then return false end
    local mark = target:getMark("@@zhengu")
    if type(mark) == "table" and table.contains(mark, player.id) then
      local x, y = player:getHandcardNum(), target:getHandcardNum()
      return x < y or (x > y and y < 5)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, zhengu.name)
    player:broadcastSkillInvoke(zhengu.name)
    room:doIndicate(player.id, {target.id})
    local x, y, z = player:getHandcardNum(), target:getHandcardNum(), 0
    if x > y then
      z = math.min(5, x) - y
      if z > 0 then
        room:drawCards(target, z, self.name)
      end
    elseif x < y then
      z = y-x
      room:askForDiscard(target, z, z, false, self.name, false)
    end
  end,
}
zhengu:addRelatedSkill(zhengu_delay)
haozhao:addSkill(zhengu)
Fk:loadTranslationTable{
  ["haozhao"] = "郝昭",
  ["zhengu"] = "镇骨",
  [":zhengu"] = "结束阶段，你可以选择一名其他角色，本回合结束时和其下个回合结束时，其将手牌摸或弃至与你手牌数量相同（至多摸至五张）。",

  ["#zhengu_delay"] = "镇骨",
  ["@@zhengu"] = "镇骨",
  ["#zhengu-choose"] = "镇骨：选择一名其他角色，本回合结束时和其下个回合结束时其将手牌调整与你相同",

  ["$zhengu1"] = "镇守城池，必以骨相拼！",
  ["$zhengu2"] = "孔明计虽百算，却难敌吾镇骨千具！",
  ["~haozhao"] = "镇守陈仓，也有一失。",
}

local chendao = General(extension, "chendao", "shu", 4)
local wangliec = fk.CreateTriggerSkill{
  name = "wangliec",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasSkill(self.name) and
      (data.card:isCommonTrick() or data.card.trueName == "slash")
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wangliec-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
    player.room:addPlayerMark(player, "@wangliec-phase", 1)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "wanglie-phase", 1)
  end,
}
local wanglie_targetmod = fk.CreateTargetModSkill{
  name = "#wanglie_targetmod",
  bypass_distances =  function(self, player, skill, card, to)
    return card and player:hasSkill("wangliec") and player.phase == Player.Play and player:getMark("wanglie-phase") == 0
  end,
}
local wanglie_prohibit = fk.CreateProhibitSkill{
  name = "#wanglie_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@wangliec-phase") > 0
  end,
}
wangliec:addRelatedSkill(wanglie_targetmod)
wangliec:addRelatedSkill(wanglie_prohibit)
chendao:addSkill(wangliec)
Fk:loadTranslationTable{
  ["chendao"] = "陈到",
  ["wangliec"] = "往烈",
  [":wangliec"] = "出牌阶段，你使用的第一张牌无距离限制。你于出牌阶段使用【杀】或普通锦囊牌时，你可以令此牌无法响应，然后本阶段你不能再使用牌。",
  ["#wangliec-invoke"] = "往烈：你可以令%arg无法响应，然后你本阶段不能再使用牌",
  ["@wangliec-phase"] = "往烈",

  ["$wangliec1"] = "猛将之烈，统帅之所往。",
  ["$wangliec2"] = "与子龙忠勇相往，猛烈相合。",
  ["~chendao"] = "我的白毦兵，再也不能为先帝出力了。",
}

local zhugezhan = General(extension, "zhugezhan", "shu", 3)
local zuilun = fk.CreateTriggerSkill{
  name = "zuilun",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    local events = player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
      local damage = e.data[5]
      return damage and player == damage.from
    end, Player.HistoryTurn)
    if #events > 0 then
      n = n + 1
    end
    events = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard and table.find(move.moveInfo, function (info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end) then
          return true
        end
      end
    end, Player.HistoryTurn)
    if #events == 0 then
      n = n + 1
    end
    if table.every(room.alive_players, function(p) return p:getHandcardNum() >= player:getHandcardNum() end) then
      n = n + 1
    end
    local cards = room:getNCards(3)
    local result = room:askForGuanxing(player, cards, {3 - n, 3 - n}, {n, n}, self.name, true, {"zuilun_top", "zuilun_get"})
    if #result.top > 0 then
      for i = #result.top, 1, -1 do
        table.insert(room.draw_pile, 1, result.top[i])
      end
      room:sendLog{
        type = "#GuanxingResult",
        from = player.id,
        arg = #result.top,
        arg2 = #result.bottom,
      }
    end
    if #result.bottom > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(result.bottom)
      room:obtainCard(player.id, dummy, false, fk.ReasonJustMove)
    end
    if n == 0 and not player.dead then
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zuilun-choose", self.name, false)
      if #to > 0 then
        to = room:getPlayerById(to[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:loseHp(player, 1, self.name)
      room:loseHp(to, 1, self.name)
    end
  end,
}
local fuyin = fk.CreateTriggerSkill{
  name = "fuyin",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and table.contains({"slash", "duel"}, data.card.trueName)
      and player:getMark("fuyin-turn") == 0
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("fuyin-turn") == 0 then
      room:setPlayerMark(player, "fuyin-turn", 1)
      local src = room:getPlayerById(data.from)
      if src and not src.dead and src:getHandcardNum() >= player:getHandcardNum() then
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
}
zhugezhan:addSkill(zuilun)
zhugezhan:addSkill(fuyin)
Fk:loadTranslationTable{
  ["zhugezhan"] = "诸葛瞻",
  ["zuilun"] = "罪论",
  [":zuilun"] = "结束阶段，你可以观看牌堆顶三张牌，你每满足以下一项便获得其中的一张，然后以任意顺序放回其余的牌：1.你于此回合内造成过伤害；"..
  "2.你于此回合内未弃置过牌；3.手牌数为全场最少。若均不满足，你与一名其他角色失去1点体力。",
  ["fuyin"] = "父荫",
  [":fuyin"] = "锁定技，你每回合第一次成为【杀】或【决斗】的目标后，若你的手牌数不大于使用者，此牌对你无效。",
  ["zuilun_top"] = "置于牌堆顶",
  ["zuilun_get"] = "获得",
  ["#zuilun-choose"] = "罪论：选择一名其他角色，你与其各失去1点体力",

  ["$zuilun1"] = "吾有三罪，未能除黄皓、制伯约、守国土。",
  ["$zuilun2"] = "唉，数罪当论，吾愧对先帝恩惠。",
  ["$fuyin1"] = "得父荫庇，平步青云。",
  ["$fuyin2"] = "吾自幼心怀父诫，方不愧父亲荫庇。",
  ["~zhugezhan"] = "临难而死义，无愧先父。",
}

local yuanshu = General(extension, "thunder__yuanshu", "qun", 4)
local thunder__yongsi = fk.CreateTriggerSkill{
  name = "thunder__yongsi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.DrawNCards then
        return true
      else
        if player.phase == Player.Play then
          local n = 0
          player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 999, function(e)
            local damage = e.data[5]
            if damage and player == damage.from then
              n = n + damage.damage
            end
          end, Player.HistoryTurn)
          return (n == 0 and player:getHandcardNum() < player.hp) or n > 1
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DrawNCards then
      local kingdoms = {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      data.n = #kingdoms
    else
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 999, function(e)
        local damage = e.data[5]
        if damage and player == damage.from then
          n = n + damage.damage
        end
      end, Player.HistoryTurn)
      if n == 0 and player:getHandcardNum() < player.hp then
        player:drawCards(player.hp - player:getHandcardNum(), self.name)
      elseif n > 1 then
        room:addPlayerMark(player, "yongsi-turn", 1)
      end
    end
  end,
}
local yongsi_maxcards = fk.CreateMaxCardsSkill{
  name = "#yongsi_maxcards",
  fixed_func = function (self, player)
    if player:getMark("yongsi-turn") ~= 0 then
      return player:getLostHp()
    end
  end,
}
thunder__yongsi:addRelatedSkill(yongsi_maxcards)
yuanshu:addSkill(thunder__yongsi)
Fk:loadTranslationTable{
  ["thunder__yuanshu"] = "袁术",
  ["thunder__yongsi"] = "庸肆",
  [":thunder__yongsi"] = "锁定技，摸牌阶段，你改为摸X张牌（X为场上现存势力数）。出牌阶段结束时，若你本回合没有造成过伤害，你将手牌补至当前体力值；"..
  "若造成过伤害且大于1点，你本回合手牌上限改为已损失体力值。",

  ["$thunder__yongsi1"] = "天下，即将尽归吾袁公路！",
  ["$thunder__yongsi2"] = "朕今日雄踞淮南，明日便可一匡天下。",
  ["~thunder__yuanshu"] = "仲朝国祚，本应千秋万代，薪传不息……",
}

return extension