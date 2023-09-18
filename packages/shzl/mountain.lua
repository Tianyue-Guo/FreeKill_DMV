local extension = Package:new("mountain")
extension.extensionName = "shzl"

Fk:loadTranslationTable{
  ["mountain"] = "神话再临·山",
}

local zhanghe = General(extension, "zhanghe", "wei", 4)
local qiaobian = fk.CreateTriggerSkill{
  name = "qiaobian",
  anim_type = "offensive",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not player:isKongcheng() and
    data.to > Player.Start and data.to < Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local phase_name_table = {
      [3] = "phase_judge",
      [4] = "phase_draw",
      [5] = "phase_play",
      [6] = "phase_discard",
    }
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#qiaobian-invoke:::" .. phase_name_table[data.to], true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    player:skip(data.to)
    if data.to == Player.Draw then
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isKongcheng() end), function(p) return p.id end)
      if #targets > 0 then
        local n = math.min(2, #targets)
        local tos = room:askForChoosePlayers(player, targets, 1, n, "#qiaobian-choose:::"..n, self.name, true)
        if #tos > 0 then
          room:sortPlayersByAction(tos)
          for _, id in ipairs(tos) do
            local p = room:getPlayerById(id)
            if not p:isKongcheng() then
              local card_id = room:askForCardChosen(player, p, "h", self.name)
              room:obtainCard(player, card_id, false, fk.ReasonPrey)
            end
          end
        end
      end
    elseif data.to == Player.Play then
      local targets = room:askForChooseToMoveCardInBoard(player, "#qiaobian-move", self.name, true, nil)
      if #targets ~= 0 then
        targets = table.map(targets, function(id) return room:getPlayerById(id) end)
        room:askForMoveCardInBoard(player, targets[1], targets[2], self.name)
      end
    end
    return true
  end,
}
zhanghe:addSkill(qiaobian)
Fk:loadTranslationTable{
  ["zhanghe"] = "张郃",
  ["qiaobian"] = "巧变",
  [":qiaobian"] = "你的阶段开始前（准备阶段和结束阶段除外），你可以弃置一张手牌跳过该阶段。若以此法跳过摸牌阶段，"..
  "你可以获得至多两名其他角色的各一张手牌；若以此法跳过出牌阶段，你可以将场上的一张牌移动至另一名角色相应的区域内。",
  ["#qiaobian-invoke"] = "巧变：你可以弃一张手牌，跳过 %arg",
  ["#qiaobian-choose"] = "巧变：你可以依次获得%arg名角色的各一张手牌",
  ["#qiaobian-move"] = "巧变：请选择两名角色，移动场上的一张牌",

  ["$qiaobian1"] = "兵无常势，水无常形。",
  ["$qiaobian2"] = "用兵之道，变化万千。",
  ["~zhanghe"] = "啊……膝盖……中箭了……",
}

local dengai = General(extension, "dengai", "wei", 4)
local tuntian = fk.CreateTriggerSkill{
  name = "tuntian",
  anim_type = "special",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.phase == Player.NotActive then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|spade,club,diamond",
    }
    room:judge(judge)
  end,

  refresh_events = {fk.FinishJudge},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.reason == self.name
  end,
  on_refresh = function(self, event, target, player, data)
    if data.card.suit ~= Card.Heart and player.room:getCardArea(data.card) == Card.Processing then
      player:addToPile("dengai_field", data.card, true, self.name)
    end
  end,
}
local tuntian_distance = fk.CreateDistanceSkill{
  name = "#tuntian_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(self.name) then
      return -#from:getPile("dengai_field")
    end
  end,
}
local zaoxian = fk.CreateTriggerSkill{
  name = "zaoxian",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("dengai_field") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "jixi", nil, true, false)
  end,
}
local jixi = fk.CreateViewAsSkill{  --FIXME: 用来急袭的那张田不应产生-1距离
  name = "jixi",
  anim_type = "control",
  pattern = "snatch",
  expand_pile = "dengai_field",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "dengai_field"
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("snatch")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
}
tuntian:addRelatedSkill(tuntian_distance)
dengai:addSkill(tuntian)
dengai:addSkill(zaoxian)
dengai:addRelatedSkill(jixi)
Fk:loadTranslationTable{
  ["dengai"] = "邓艾",
  ["tuntian"] = "屯田",
  [":tuntian"] = "当你于回合外失去牌后，你可以进行判定：若结果不为<font color='red'>♥</font>，你将生效后的判定牌置于你的武将牌上，称为“田”；"..
  "你计算与其他角色的距离-X（X为“田”的数量）。",
  ["zaoxian"] = "凿险",
  [":zaoxian"] = "觉醒技，准备阶段，若“田”的数量不少于3张，你减1点体力上限，然后获得〖急袭〗。",
  ["jixi"] = "急袭",
  [":jixi"] = "你可以将一张“田”当【顺手牵羊】使用。",
  ["dengai_field"] = "田",

  ["$tuntian1"] = "休养生息，备战待敌。",
  ["$tuntian2"] = "锄禾日当午，汗滴禾下土。",
  ["$zaoxian1"] = "屯田日久，当建奇功！",
  ["$zaoxian2"] = "开辟险路，奇袭敌军！",
  ["$jixi1"] = "偷渡阴平，直取蜀汉！",
  ["$jixi2"] = "攻其无备，出其不意！",
  ["~dengai"] = "吾破蜀克敌，竟葬于奸贼之手！",
}

local jiangwei = General(extension, "jiangwei", "shu", 4)
local tiaoxin = fk.CreateActiveSkill{
  name = "tiaoxin",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):inMyAttackRange(Self)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local use = room:askForUseCard(target, "slash", "slash", "#tiaoxin-use", true, {must_targets = {player.id}})
    if use then
      room:useCard(use)
    else
      if not target:isNude() then
        local card = room:askForCardChosen(player, target, "he", self.name)
        room:throwCard({card}, self.name, target, player)
      end
    end
  end
}
local zhiji = fk.CreateTriggerSkill{
  name = "zhiji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw2"}
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "draw2" then
      player:drawCards(2)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:changeMaxHp(player, -1)  --yes, lose maxhp after choice
    room:handleAddLoseSkills(player, "guanxing", nil, true, false)
  end,
}
jiangwei:addSkill(tiaoxin)
jiangwei:addSkill(zhiji)
jiangwei:addRelatedSkill("guanxing")
Fk:loadTranslationTable{
  ["jiangwei"] = "姜维",
  ["tiaoxin"] = "挑衅",
  [":tiaoxin"] = "出牌阶段限一次，你可以指定一名你在其攻击范围内的角色，其需包括你在内的角色使用一张【杀】，否则你弃置其一张牌。",
  ["zhiji"] = "志继",
  [":zhiji"] = "觉醒技，准备阶段，若你没有手牌，你回复1点体力或摸两张牌，减1点体力上限，然后获得〖观星〗。",
  ["#tiaoxin-use"] = "挑衅：对其使用一张【杀】，否则其弃置你一张牌",
  ["draw1"] = "摸一张牌",
  ["draw2"] = "摸两张牌",
  ["recover"] = "回复1点体力",

  ["$tiaoxin1"] = "汝等小儿，可敢杀我？",
  ["$tiaoxin2"] = "贼将早降，可免一死。",
  ["$zhiji1"] = "先帝之志，丞相之托，不可忘也！",
  ["$zhiji2"] = "丞相厚恩，维万死不能相报。",
  ["$guanxing_jiangwei1"] = "继丞相之遗志，讨篡汉之逆贼！",
  ["$guanxing_jiangwei2"] = "克复中原，指日可待！",
  ["~jiangwei"] = "我计不成，乃天命也……",
}

local liushan = General(extension, "liushan", "shu", 3)
local xiangle = fk.CreateTriggerSkill{
  name = "xiangle",
  events = {fk.TargetConfirming},
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room:askForDiscard(room:getPlayerById(data.from), 1, 1, false, self.name, true, ".|.|.|.|.|basic", "#xiangle-discard:"..player.id) == 0 then
      table.insertIfNeed(data.nullifiedTargets, player.id)
    end
  end,
}
local fangquan = fk.CreateTriggerSkill{
  name = "fangquan",
  anim_type = "support",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:skip(Player.Play)
    player.room:setPlayerMark(player, "fangquan_extra", 1)
    return true
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("fangquan_extra") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "fangquan_extra", 0)
    local tos, id = room:askForChooseCardAndPlayers(player, table.map(room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, ".|.|.|hand", "#fangquan-give", self.name, true)
    if #tos > 0 then
      room:throwCard({id}, self.name, player, player)
      room:getPlayerById(tos[1]):gainAnExtraTurn()
    end
  end,
}
local ruoyu = fk.CreateTriggerSkill{
  name = "ruoyu$",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return table.every(player.room:getOtherPlayers(player), function(p) return p.hp >= player.hp end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() then  --小心王衍
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    end
    room:handleAddLoseSkills(player, "jijiang", nil, true, false)
  end,
}
liushan:addSkill(xiangle)
liushan:addSkill(fangquan)
liushan:addSkill(ruoyu)
liushan:addRelatedSkill("jijiang")
Fk:loadTranslationTable{
  ["liushan"] = "刘禅",
  ["xiangle"] = "享乐",
  [":xiangle"] = "锁定技，每当你成为【杀】的目标时，【杀】的使用者须弃置一张基本牌，否则此【杀】对你无效。",
  ["#xiangle-discard"] = "享乐：你须弃置一张基本牌，否则此【杀】对 %src 无效",
  ["fangquan"] = "放权",
  [":fangquan"] = "你可以跳过你的出牌阶段，然后此回合结束时，你可以弃置一张手牌并选择一名其他角色：若如此做，该角色进行一个额外的回合。",
  ["#fangquan-give"] = "你可以弃置一张手牌令一名其他角色进行一个额外的回合",
  ["ruoyu"] = "若愚",
  [":ruoyu"] = "主公技，觉醒技，准备阶段开始时，若你的体力值为场上最少（或之一），你增加1点体力上限，回复1点体力，然后获得“激将”。",

  ["$xiangle1"] = "打打杀杀，真没意思。",
  ["$xiangle2"] = "我爸爸是刘备！",
  ["$fangquan1"] = "唉，这可如何是好啊！",
  ["$fangquan2"] = "哎，你办事儿，我放心~",
  ["$ruoyu1"] = "不装疯卖傻，岂能安然无恙？",
  ["$ruoyu2"] = "世人皆错看我，唉！",
  ["$jijiang_liushan1"] = "我蜀汉岂无人乎！",
  ["$jijiang_liushan2"] = "匡扶汉室，谁敢出战！",
  ["~liushan"] = "哎，别打脸，我投降还不行吗？",
}

local sunce = General(extension, "sunce", "wu", 4)
local jiang = fk.CreateTriggerSkill{
  name = "jiang",
  anim_type = "drawcard",
  events ={fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.firstTarget and
      ((data.card.trueName == "slash" and data.card.color == Card.Red) or data.card.name == "duel")
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local hunzi = fk.CreateTriggerSkill{
  name = "hunzi",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player.hp == 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "yingzi|yinghun", nil, true, false)
  end,
}

local zhiba = fk.CreateTriggerSkill{
  name = "zhiba$",
  mute = true,
  frequency = Skill.Compulsory,
  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self.name, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self and target == player
    else
      return target == player and player:hasSkill(self.name, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    --[[
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return p.kingdom == "wu"
    end)
    ]]
    local targets = room.alive_players
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self.name, true) then
        table.forEach(targets, function(p)
          room:handleAddLoseSkills(p, "zhiba_other&", nil, false, true)
        end)
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      table.forEach(targets, function(p)
        room:handleAddLoseSkills(p, "-zhiba_other&", nil, false, true)
      end)
    end
  end,
}
local zhiba_other = fk.CreateActiveSkill{
  name = "zhiba_other&",
  anim_type = "special",
  mute = true,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player.kingdom == "wu" and not player:isKongcheng() then
      return table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill("zhiba") and p ~= player and not p:isKongcheng() end)
    end
    return false
  end,
  card_num = 0,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room.alive_players, function(p) return p:hasSkill("zhiba") and p ~= player and not p:isKongcheng() end)
    local target
    if #targets == 1 then
      target = targets[1]
    else
      target = room:getPlayerById(room:askForChoosePlayers(player, table.map(targets, function(p) return p.id end), 1, 1, nil, self.name, false)[1])
    end
    if not target then return false end
    room:notifySkillInvoked(player, "zhiba")
    player:broadcastSkillInvoke("zhiba")
    room:doIndicate(effect.from, { target.id })
    if target:usedSkillTimes("hunzi", Player.HistoryGame) > 0 and room:askForChoice(target, {"zhiba_yes", "zhiba_no"}, self.name, "#zhiba-ask:" .. player.id) == "zhiba_no" then
      return false
    end
    local pindian = player:pindian({target}, self.name)
    if not pindian.results[target.id].winner or pindian.results[target.id].winner ~= player then
      local dummy = Fk:cloneCard("dilu")
      local leftFromCardIds = room:getSubcardsByRule(pindian.fromCard, { Card.DiscardPile })
      if #leftFromCardIds > 0 then
        dummy:addSubcards(leftFromCardIds)
      end
      local leftToCardIds = room:getSubcardsByRule(pindian.results[target.id].toCard, { Card.DiscardPile })
      if #leftToCardIds > 0 then
        dummy:addSubcards(leftToCardIds)
      end
      if #dummy.subcards > 0 then
        room:obtainCard(target, dummy, true, fk.ReasonJustMove)
      end
    end
  end,
}

sunce:addSkill(jiang)
sunce:addSkill(hunzi)
sunce:addRelatedSkill("yingzi")
sunce:addRelatedSkill("yinghun")
sunce:addSkill(zhiba)
Fk:addSkill(zhiba_other)
Fk:loadTranslationTable{
  ["sunce"] = "孙策",
  ["jiang"] = "激昂",
  [":jiang"] = "当你使用【决斗】或红色【杀】指定目标后，或成为【决斗】或红色【杀】的目标后，你可以摸一张牌。",
  ["hunzi"] = "魂姿",
  [":hunzi"] = "觉醒技，准备阶段，若你的体力值为1，你减1点体力上限，然后获得〖英姿〗和〖英魂〗。",
  ["zhiba"] = "制霸",
  [":zhiba"] = "主公技，其他吴势力角色的出牌阶段限一次，其可以与你拼点（若你发动过〖魂姿〗，你可以拒绝此拼点），若其没赢，你可以获得拼点的两张牌。",

  ["zhiba_other&"] = "制霸",
  [":zhiba_other&"] = "出牌阶段限一次，你可与孙策拼点（若其发动过〖魂姿〗，其可以拒绝此拼点），若你没赢，其可以获得拼点的两张牌。",

  ["#zhiba-ask"] = "%src发起“制霸”拼点，是否拒绝",
  ["zhiba_yes"] = "进行“制霸”拼点",
  ["zhiba_no"] = "拒绝“制霸”拼点",

  ["$jiang1"] = "吾乃江东小霸王孙伯符！",
  ["$jiang2"] = "江东子弟，何惧于天下！",
  ["$hunzi1"] = "父亲在上，魂佑江东；公瑾在旁，智定天下！",
  ["$hunzi2"] = "愿承父志，与公瑾共谋天下！",
  ["$zhiba1"] = "我若怕你，非孙伯符也！",
  ["$zhiba2"] = "是友是敌，一探便知。",
  ["$yingzi_sunce1"] = "公瑾，助我决一死战！",
  ["$yingzi_sunce2"] = "尔等看好了！",
  ["$yinghun_sunce1"] = "父亲，助我背水一战！",
  ["$yinghun_sunce2"] = "孙氏英烈，庇佑江东！",
  ["~sunce"] = "内事不决问张昭，外事不决问周瑜……",
}

local zhangzhaozhanghong = General(extension, "zhangzhaozhanghong", "wu", 3)
local zhijian = fk.CreateActiveSkill{
  name = "zhijian",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip and
      Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and #selected_cards == 1 and 
    Fk:currentRoom():getPlayerById(to_select):hasEmptyEquipSlot(Fk:getCardById(selected_cards[1]).sub_type)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:moveCards({
      ids = effect.cards,
      from = effect.from,
      to = effect.tos[1],
      toArea = Card.PlayerEquip,
      moveReason = fk.ReasonPut,
    })
    player:drawCards(1, self.name)
  end,
}

local guzheng = fk.CreateTriggerSkill{
  name = "guzheng",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and target.phase == Player.Discard and target:getMark("guzheng_hand-phase") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local hand_cards = {}
    local all_cards = {}
    local mark_hand = target:getMark("guzheng_hand-phase")
    local mark_all = target:getMark("guzheng_all-phase")
    for _, id in ipairs(mark_hand) do
      if room:getCardArea(id) == Card.DiscardPile then
        table.insertIfNeed(hand_cards, id)
      end
    end
    if #hand_cards > 0 and room:askForSkillInvoke(player, self.name, nil, "#guzheng-invoke::"..target.id) then
      for _, id in ipairs(mark_all) do
        if room:getCardArea(id) == Card.DiscardPile then
          table.insertIfNeed(all_cards, id)
        end
      end
      room:fillAG(player, all_cards)
      for i = #all_cards, 1, -1 do
        if not table.contains(hand_cards, all_cards[i]) then
          room:takeAG(player, all_cards[i], room.players)
        end
      end
      local id = room:askForAG(player, hand_cards, true, self.name)  --TODO: temporarily use AG. AG function need cancelable!
      room:closeAG(player)
      if id ~= nil then
        self.cost_data = id
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(target, self.cost_data, true, fk.ReasonJustMove)
    local dummy = Fk:cloneCard("dilu")
    local mark = target:getMark("guzheng_all-phase")
    for _, id in ipairs(mark) do
      if room:getCardArea(id) == Card.DiscardPile and id ~= self.cost_data then
        dummy:addSubcard(id)
      end
    end
    if #dummy.subcards > 0 then
      room:obtainCard(player, dummy, true, fk.ReasonJustMove)
    end
  end,
  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    local mark_hand = player:getMark("guzheng_hand-phase")
    local mark_all = player:getMark("guzheng_all-phase")
    if mark_hand == 0 then mark_hand = {} end
    if mark_all == 0 then mark_all = {} end
    for _, move in ipairs(data) do
      if move.moveReason == fk.ReasonDiscard then
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insertIfNeed(mark_hand, info.cardId)
            end
          end
        end
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(mark_all, info.cardId)
        end
      end
    end
    if #mark_hand > 0 then
      player.room:setPlayerMark(player, "guzheng_hand-phase", mark_hand)
      player.room:setPlayerMark(player, "guzheng_all-phase", mark_all)
    elseif #mark_all > 0 then
      player.room:setPlayerMark(player, "guzheng_all-phase", mark_all)
    end
  end,
}
zhangzhaozhanghong:addSkill(zhijian)
zhangzhaozhanghong:addSkill(guzheng)
Fk:loadTranslationTable{
  ["zhangzhaozhanghong"] = "张昭张纮",
  ["zhijian"] = "直谏",
  [":zhijian"] = "出牌阶段，你可以将你手牌中的一张装备牌置于一名其他角色装备区内：若如此做，你摸一张牌。",
  ["guzheng"] = "固政",
  [":guzheng"] = "其他角色的弃牌阶段结束时，你可以令其获得一张弃牌堆中此阶段中因弃置而置入弃牌堆的该角色的手牌："..
  "若如此做，你获得弃牌堆中其余此阶段因弃置而置入弃牌堆的牌。",
  ["#guzheng-invoke"] = "固政：你可以令 %dest 获得其弃置的其中一张牌。" ,

  ["$zhijian1"] = "请恕老臣直言！",
  ["$zhijian2"] = "为臣者，当冒死以谏！",
  ["$guzheng1"] = "固国安邦，居当如是。",
  ["$guzheng2"] = "今当稳固内政，以御外患。",
  ["~zhangzhaozhanghong"] = "竭力尽智，死而无憾……",
}

local zuoci = General(extension, "zuoci", "qun", 3)
local function DoHuanshen(player)
  local room = player.room
  local huashens = player:getMark("@&huanshen")
  if huashens == 0 or #huashens == 0 then return end
  local name = room:askForGeneral(player, huashens, 1)
  local general = Fk.generals[name]

  local kingdom = general.kingdom
  if general.kingdom == "god" or general.subkingdom then
    local allKingdoms = {}
    if general.kingdom == "god" then
      allKingdoms = {"wei", "shu", "wu", "qun", "jin"}
    elseif general.subkingdom then
      allKingdoms = { general.kingdom, general.subkingdom }
    end
    kingdom = room:askForChoice(player, allKingdoms, "AskForKingdom", "#ChooseInitialKingdom")
  end
  player.kingdom = kingdom
  room:broadcastProperty(player, "kingdom")
  player.gender = general.gender
  room:broadcastProperty(player, "gender")
  local original_general = player.general
  player.general = general.name
  room:broadcastProperty(player, "general")

  local skills = {}
  for _, s in ipairs(general.skills) do
    if not (s.lordSkill or s.switchSkillName or s.frequency > 3) then
      if #s.attachedKingdom == 0 or table.contains(s.attachedKingdom, player.kingdom) then
        table.insert(skills, s.name)
      end
    end
  end
  if #skills == 0 then return end
  local skill = room:askForChoice(player, skills, "huashen", "#huashen", true)
  local huanshen_skill = skill
  if player:getMark("@huanshen_skill") ~= 0 then huanshen_skill = skill.."|-"..player:getMark("@huanshen_skill") end
  player.general = original_general
  room:broadcastProperty(player, "general")
  room:setPlayerMark(player, "@huanshen_skill", skill)
  room:handleAddLoseSkills(player, huanshen_skill, nil, true, false)
end
local huashen = fk.CreateTriggerSkill{
  name = "huashen",
  anim_type = "special",
  events = {fk.GamePrepared, fk.TurnStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GamePrepared then
        return true
      else
        return target == player and player:getMark("@&huanshen") ~= 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GamePrepared then
      return true
    else
      return player.room:askForSkillInvoke(player, self.name)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GamePrepared then
      local generalPile = room:getTag("generalPile") or {}
      if #generalPile == 0 then
        for _, general in pairs(Fk:getAllGenerals()) do
          if (not general.hidden and not general.total_hidden) and
            not table.find(generalPile, function(g) return Fk.generals[g].trueName == general.trueName end) and
            not table.find(room.alive_players, function(p)
              return Fk.generals[p.general].trueName == general.trueName or
                (p.deputyGeneral ~= "" and Fk.generals[p.deputyGeneral].trueName == general.trueName)
                --TODO: 国战暗将不考虑
            end) then
            table.insert(generalPile, general.name)
          end
        end
        if #generalPile > 0 then
          room:setTag("generalPile", generalPile)
        end
      end
      local generals = table.random(room:getTag("generalPile"), 2)
      if #generals == 0 then return end
      for _, g in ipairs(generals) do
        table.removeOne(room:getTag("generalPile"), g)
      end
      room:setPlayerMark(player, "@&huanshen", generals)
    end
    DoHuanshen(player)
  end,
}
local xinsheng = fk.CreateTriggerSkill{
  name = "xinsheng",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.room:getTag("generalPile") and #player.room:getTag("generalPile") > 0
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost or #player.room:getTag("generalPile") == 0 then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local general = table.random(room:getTag("generalPile"))
    table.removeOne(room:getTag("generalPile"), general)
    local generals = player:getMark("@&huanshen")
    if generals == 0 then generals = {} end
    table.insert(generals, general)
    room:setPlayerMark(player, "@&huanshen", generals)
  end,
}
zuoci:addSkill(huashen)
zuoci:addSkill(xinsheng)
Fk:loadTranslationTable{
  ["zuoci"] = "左慈",
  ["huashen"] = "化身",
  [":huashen"] = "游戏开始前，你获得两张未加入游戏的武将牌，称为“化身”，然后选择一张“化身”的一个技能（主公技、限定技、觉醒技除外）。"..
  "回合开始时和回合结束后，你可以重新选择一张“化身”的一个技能。你获得你以此法选择的技能且性别与势力改为与此“化身”相同。",
  ["xinsheng"] = "新生",
  [":xinsheng"] = "当你受到1点伤害后，你可以获得一张“化身”。",
  ["@&huanshen"] = "化身",
  ["#huashen"] = "化身：请选择要化身的技能",
  ["@huanshen_skill"] = "化身",

  ["$huashen1"] = "哼，肉眼凡胎，岂能窥视仙人变幻？",
  ["$huashen2"] = "万物苍生，幻化由心。",
  ["$xinsheng1"] = "幻幻无穷，生生不息。",
  ["$xinsheng2"] = "吐故纳新，师法天地。",
  ["~zuoci"] = "腾云跨风，飞升太虚……",
}

local caiwenji = General(extension, "caiwenji", "qun", 3, 3, General.Female)
local beige = fk.CreateTriggerSkill{
  name = "beige",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and not data.to.dead and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#beige-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.suit == Card.Heart then
      if target:isWounded() then
        room:recover{
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    elseif judge.card.suit == Card.Diamond then
      target:drawCards(2, self.name)
    elseif judge.card.suit == Card.Club then
      if data.from and not data.from.dead then
        if #data.from:getCardIds{Player.Hand, Player.Equip} < 3 then
          data.from:throwAllCards("he")
        else
          room:askForDiscard(data.from, 2, 2, true, self.name, false, ".")
        end
      end
    elseif judge.card.suit == Card.Spade then
      if data.from and not data.from.dead then
        data.from:turnOver()
      end
    end
  end,
}
local duanchang = fk.CreateTriggerSkill{
  name = "duanchang",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, false, true) and data.damage and data.damage.from and not data.damage.from.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.damage.from
    local skills = {}
    for _, s in ipairs(to.player_skills) do
      if not (s.attached_equip or s.name[#s.name] == "&") then
        table.insertIfNeed(skills, s.name)
      end
    end
    if room.settings.gameMode == "m_1v2_mode" and to.role == "lord" then
      table.removeOne(skills, "m_feiyang")
      table.removeOne(skills, "m_bahu")
    end
    if #skills > 0 then
      room:handleAddLoseSkills(to, "-"..table.concat(skills, "|-"), nil, true, false)
    end
  end,
}
caiwenji:addSkill(beige)
caiwenji:addSkill(duanchang)
Fk:loadTranslationTable{
  ["caiwenji"] = "蔡文姬",
  ["beige"] = "悲歌",
  [":beige"] = "当一名角色受到【杀】造成的伤害后，你可以弃置一张牌，然后令其进行判定，若结果为：<font color='red'>♥</font>，其回复1点体力；"..
  "<font color='red'>♦</font>，其摸两张牌；♣，伤害来源弃置两张牌；♠，伤害来源翻面。",
  ["duanchang"] = "断肠",
  [":duanchang"] = "锁定技，当你死亡时，杀死你的角色失去所有武将技能。",
  ["#beige-invoke"] = "悲歌：%dest 受到伤害，你可以弃置一张牌令其判定，根据花色执行效果",

  ["$beige1"] = "悲歌可以当泣，远望可以当归。",
  ["$beige2"] = "制兹八拍兮拟排忧，何知曲成兮心转愁。",
  ["$duanchang1"] = "流落异乡愁断肠。",
  ["$duanchang2"] = "日东月西兮徒相望，不得相随兮空断肠。",
  ["~caiwenji"] = "人生几何时，怀忧终年岁。",
}

return extension