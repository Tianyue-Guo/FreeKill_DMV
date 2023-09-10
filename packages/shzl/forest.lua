local extension = Package:new("forest")
extension.extensionName = "shzl"

Fk:loadTranslationTable{
  ["forest"] = "神话再临·林",
}

local xuhuang = General(extension, "xuhuang", "wei", 4)
local duanliang = fk.CreateViewAsSkill{
  name = "duanliang",
  anim_type = "control",
  pattern = "supply_shortage",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and Fk:getCardById(to_select).type ~= Card.TypeTrick
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("supply_shortage")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
}
local duanliang_targetmod = fk.CreateTargetModSkill{
  name = "#duanliang_targetmod",
  distance_limit_func =  function(self, player, skill)
    if player:hasSkill(self.name) and skill.name == "supply_shortage_skill" then
      return 1
    end
  end,
}
duanliang:addRelatedSkill(duanliang_targetmod)
xuhuang:addSkill(duanliang)
Fk:loadTranslationTable{
  ["xuhuang"] = "徐晃",
  ["duanliang"] = "断粮",
  [":duanliang"] = "你可以将一张黑色基本牌或黑色装备牌当【兵粮寸断】使用；你可以对距离为2的角色使用【兵粮寸断】。",

  ["$duanliang1"] = "截其源，断其粮，贼可擒也。",
  ["$duanliang2"] = "人是铁，饭是钢。",
  ["~xuhuang"] = "一顿不吃饿得慌。",
}

local caopi = General(extension, "caopi", "wei", 3)
local xingshang = fk.CreateTriggerSkill{
  name = "xingshang",
  anim_type = "drawcard",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not target:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards_id = target:getCardIds{Player.Hand, Player.Equip}
    local dummy = Fk:cloneCard'slash'
    dummy:addSubcards(cards_id)
    room:obtainCard(player.id, dummy, false, fk.Discard)
  end,
}
local fangzhu = fk.CreateTriggerSkill{
  name = "fangzhu",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#fangzhu-choose:::"..player:getLostHp(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = player.room:getPlayerById(self.cost_data)
    to:drawCards(player:getLostHp(), self.name)
    to:turnOver()
  end,
}
local songwei = fk.CreateTriggerSkill{
  name = "songwei$",
  events = {fk.FinishJudge},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.kingdom == "wei" and data.card.color == Card.Black
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(target, self.name, nil, "#songwei-invoke:"..player.id)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
caopi:addSkill(xingshang)
caopi:addSkill(fangzhu)
caopi:addSkill(songwei)
Fk:loadTranslationTable{
  ["caopi"] = "曹丕",
  ["xingshang"] = "行殇",
  [":xingshang"] = "当其他角色死亡时，你可以获得其所有牌。",
  ["fangzhu"] = "放逐",
  [":fangzhu"] = "当你受到伤害后，你可以令一名其他角色翻面，然后其摸X张牌（X为你已损失的体力值）。",
  ["songwei"] = "颂威",
  [":songwei"] = "主公技，当其他魏势力角色的判定结果确定后，若为黑色，其可令你摸一张牌。",

  ["#fangzhu-choose"] = "放逐：你可以令一名其他角色翻面，然后其摸%arg张牌",
  ["#songwei-invoke"] = "颂威：你可以令 %src 摸一张牌",

  ["$xingshang1"] = "我的是我的，你的还是我的。",
  ["$xingshang2"] = "来，管杀还管埋！",
  ["$fangzhu1"] = "死罪可免，活罪难赦！",
  ["$fangzhu2"] = "给我翻过来！",
  ["$songwei1"] = "千秋万载，一统江山！",
  ["$songwei2"] = "仙福永享，寿与天齐！",
  ["~caopi"] = "子建，子建……",
}

local menghuo = General(extension, "menghuo", "shu", 4)
local huoshou = fk.CreateTriggerSkill{
  name = "huoshou",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.card.trueName == "savage_assault" then
      if event == fk.PreCardEffect then
        return player.id == data.to
      else
        return target ~= player and data.firstTarget
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.PreCardEffect then
      return true
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.huoshou = player.id
    end
  end,

  refresh_events = {fk.PreDamage},
  can_refresh = function(self, event, target, player, data)
    if data.card and data.card.trueName == "savage_assault" then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        return use.extra_data and use.extra_data.huoshou
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data[1]
      data.from = room:getPlayerById(use.extra_data.huoshou)
    end
  end,
}
local zaiqi = fk.CreateTriggerSkill{
  name = "zaiqi",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getLostHp()
    local cards = room:getNCards(n)
    room:moveCards{
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    }
    room:delay(2000)
    local dummy = Fk:cloneCard("dilu")
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).suit ~= Card.Heart then
        dummy:addSubcard(cards[i])
        table.removeOne(cards, cards[i])
      end
    end
    if #cards > 0 then
      room:moveCards{
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      if player:isWounded() then
        room:recover({
          who = player,
          num = math.min(#cards, player:getLostHp()),
          recoverBy = player,
          skillName = self.name,
        })
      end
    end
    if #dummy.subcards > 0 and not player.dead then
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    end
    return true
  end,
}
menghuo:addSkill(huoshou)
menghuo:addSkill(zaiqi)
Fk:loadTranslationTable{
  ["menghuo"] = "孟获",
  ["huoshou"] = "祸首",
  [":huoshou"] = "锁定技，【南蛮入侵】对你无效；当其他角色使用【南蛮入侵】指定目标后，你代替其成为此牌造成的伤害的来源。",
  ["zaiqi"] = "再起",
  [":zaiqi"] = "摸牌阶段，若你已受伤，你可以放弃摸牌，改为亮出牌堆顶X张牌（X为你已损失体力值），你将其中的<font color='red'>♥</font>牌置入弃牌堆"..
  "并回复等量体力，获得其余的牌。",

  ["$huoshou1"] = "背黑锅我来，送死？你去！",
  ["$huoshou2"] = "通通算我的！",
  ["$zaiqi1"] = "丞相助我！",
  ["$zaiqi2"] = "起！",
  ["~menghuo"] = "七纵之恩……来世……再报了……",
}

local zhurong = General(extension, "zhurong", "shu", 4, 4, General.Female)
local juxiang = fk.CreateTriggerSkill{
  name = "juxiang",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.card and data.card.trueName == "savage_assault" then
      if event == fk.PreCardEffect then
        return data.to == player.id
      else
        return target ~= player and player.room:getCardArea(data.card) == Card.Processing
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.PreCardEffect then
      return true
    else
      player.room:obtainCard(player, data.card, true, fk.ReasonJustMove)
    end
  end,
}
local lieren = fk.CreateTriggerSkill{
  name = "lieren",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and
      not data.to.dead and not data.to:isNude() and not data.chain
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pindian = player:pindian({data.to}, self.name)
    if pindian.results[data.to.id].winner == player and not data.to:isNude() then
      local card = room:askForCardChosen(player, data.to, "he", self.name)
      room:obtainCard(player, card, false, fk.ReasonPrey)
    end
  end,
}
zhurong:addSkill(juxiang)
zhurong:addSkill(lieren)
Fk:loadTranslationTable{
  ["zhurong"] = "祝融",
  ["juxiang"] = "巨象",
  [":juxiang"] = "锁定技，【南蛮入侵】对你无效；其他角色使用的【南蛮入侵】结算结束后，你获得之。",
  ["lieren"] = "烈刃",
  [":lieren"] = "当你使用【杀】对一个目标造成伤害后，你可以与其拼点，若你赢，你获得其一张牌。",

  ["$juxiang1"] = "大王，看我的。",
  ["$juxiang2"] = "小小把戏~",
  ["$lieren1"] = "亮兵器吧。",
  ["$lieren2"] = "尝尝我飞刀的厉害！",
  ["~zhurong"] = "大王，我……先走一步了……",
}

local yinghun = fk.CreateTriggerSkill{
  name = "yinghun",
  anim_type = "drawcard",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, "#yinghun-choose:::"..player:getLostHp()..":"..player:getLostHp(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local n = player:getLostHp()
    local choice = room:askForChoice(player, {"#yinghun-draw:::" .. n,  "#yinghun-discard:::" .. n}, self.name)
    if choice:startsWith("#yinghun-draw") then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "support")
      to:drawCards(n, self.name)
      room:askForDiscard(to, 1, 1, true, self.name, false)
    else
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "control")
      to:drawCards(1, self.name)
      room:askForDiscard(to, n, n, true, self.name, false)
    end
  end,
}
local sunjian = General:new(extension, "sunjian", "wu", 4)
sunjian:addSkill(yinghun)
Fk:loadTranslationTable{
  ["sunjian"] = "孙坚",
  ["yinghun"] = "英魂",
  [":yinghun"] = "准备阶段，若你已受伤，你可以选择一名其他角色并选择一项：1.令其摸X张牌，然后弃置一张牌；2.令其摸一张牌，然后弃置X张牌（X为你已损失的体力值）。",
  ["#yinghun-choose"] = "英魂：你可以令一名其他角色：摸%arg张牌然后弃置一张牌，或摸一张牌然后弃置%arg2张牌",
  ["#yinghun-draw"] = "摸%arg张牌，弃置1张牌",
  ["#yinghun-discard"] = "摸1张牌，弃置%arg张牌",

  ["$yinghun1"] = "以吾魂魄，保佑吾儿之基业。",
  ["$yinghun2"] = "不诛此贼三族，则吾死不瞑目！",
  ["~sunjian"] = "有埋伏，啊……",
}
local function swapHandCards(room, from, tos, skillname) -- 抄自心变佬
  local target1 = room:getPlayerById(tos[1])
  local target2 = room:getPlayerById(tos[2])
  local cards1 = table.clone(target1.player_cards[Player.Hand])
  local cards2 = table.clone(target2.player_cards[Player.Hand])
  local moveInfos = {}
  if #cards1 > 0 then
    table.insert(moveInfos, {
      from = tos[1],
      ids = cards1,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = from,
      skillName = skillname,
    })
  end
  if #cards2 > 0 then
    table.insert(moveInfos, {
      from = tos[2],
      ids = cards2,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = from,
      skillName = skillname,
    })
  end
  if #moveInfos > 0 then
    room:moveCards(table.unpack(moveInfos))
  end
  moveInfos = {}
  if not target2.dead then
    local to_ex_cards = table.filter(cards1, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #to_ex_cards > 0 then
      table.insert(moveInfos, {
        ids = to_ex_cards,
        fromArea = Card.Processing,
        to = tos[2],
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        proposer = from,
        skillName = skillname,
      })
    end
  end
  if not target1.dead then
    local to_ex_cards = table.filter(cards2, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #to_ex_cards > 0 then
      table.insert(moveInfos, {
        ids = to_ex_cards,
        fromArea = Card.Processing,
        to = tos[1],
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        proposer = from,
        skillName = skillname,
      })
    end
  end
  if #moveInfos > 0 then
    room:moveCards(table.unpack(moveInfos))
  end
  table.insertTable(cards1, cards2)
  local dis_cards = table.filter(cards1, function (id)
    return room:getCardArea(id) == Card.Processing
  end)
  if #dis_cards > 0 then
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(dis_cards)
    room:moveCardTo(dummy, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skillname)
  end
end

local lusu = General(extension, "lusu", "wu", 3)
local haoshi = fk.CreateTriggerSkill{
  name = "haoshi",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
}
local haoshi_active = fk.CreateActiveSkill{
  name = "#haoshi_active",
  visible = false,
  max_target_num = 1,
  can_use = Util.FalseFunc,
  card_num = function ()
    return Self:getHandcardNum() // 2
  end,
  card_filter = function(self, to_select, selected)
    return #selected < Self:getHandcardNum() // 2 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected_cards ~= Self:getHandcardNum() // 2 then return false end
    local num = 999
    local targets = {}
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p ~= Self then
        local n = p:getHandcardNum()
        if n <= num then
          if n < num then
            num = n
            targets = {}
          end
          table.insert(targets, p.id)
        end
      end
    end
    if #targets <= 1 then return false end
    return table.contains(targets, to_select) and #selected < 1
  end,
}
local haoshi_give = fk.CreateTriggerSkill{
  name = "#haoshi_give",
  events = {fk.AfterDrawNCards},
  mute = true,
  anim_type = "support",
  frequency = Skill.Compulsory,
  visible = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("haoshi", Player.HistoryPhase) > 0 and player:getHandcardNum() > 5
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards, target = {}, nil
    local targets = {}
    local num = 999
    for _, p in ipairs(room.alive_players) do
      if p ~= player then
        local n = p:getHandcardNum()
        if n <= num then
          if n < num then
            num = n
            targets = {}
          end
          table.insert(targets, p.id)
        end
      end
    end
    if #targets == 0 then return false end
    local _, ret = room:askForUseActiveSkill(player, "#haoshi_active", "#haoshi-give:::"..player:getHandcardNum() // 2, false)
    if ret then
      cards = ret.cards
      target = ret.targets and ret.targets[1] or targets[1]
    else
      cards = table.random(player:getCardIds(Player.Hand), player:getHandcardNum() // 2)
      target = table.random(targets)
    end
    room:moveCardTo(cards, Card.PlayerHand, room:getPlayerById(target), fk.ReasonGive, self.name, nil, false, player.id)
  end
}
local dimeng = fk.CreateActiveSkill{
  name = "dimeng",
  anim_type = "control",
  card_num = 0,
  target_num = 2,
  prompt = "#dimeng",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and #Fk:currentRoom().alive_players > 2
  end,
  card_filter = function(self, to_select, selected, selected_targets)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if to_select == Self.id or #selected > 1 then return false end
    if #selected == 0 then
      return true
    else
      local target1 = Fk:currentRoom():getPlayerById(to_select)
      local target2 = Fk:currentRoom():getPlayerById(selected[1])
      local num, num2 = target1:getHandcardNum(), target2:getHandcardNum()
      if num == 0 and num2 == 0 then
        return false
      end
      local x = #table.filter(Self:getCardIds({Player.Hand, Player.Equip}), function(cid) return not Self:prohibitDiscard(Fk:getCardById(cid)) end)
      return math.abs( num - num2 ) <= x
    end
  end,
  --[[
  feasible = function (self, selected, selected_cards)
    return #selected == 2 and
      math.abs(Fk:currentRoom():getPlayerById(selected[1]):getHandcardNum() - Fk:currentRoom():getPlayerById(selected[2]):getHandcardNum()) == #selected_cards
  end,
  ]]
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local num = math.abs(room:getPlayerById(effect.tos[1]):getHandcardNum() - room:getPlayerById(effect.tos[2]):getHandcardNum())
    if num > 0 then
      room:askForDiscard(player, num, num, true, self.name, false, nil, "#dimeng-discard:" .. effect.tos[1] .. ":" .. effect.tos[2] .. ":" .. num)
    end
    --room:throwCard(effect.cards, self.name, player, player)
    swapHandCards(room, effect.from, effect.tos, self.name)
  end,
}
haoshi:addRelatedSkill(haoshi_active)
haoshi:addRelatedSkill(haoshi_give)
lusu:addSkill(haoshi)
lusu:addSkill(dimeng)
Fk:loadTranslationTable{
  ["lusu"] = "鲁肃",
  ["haoshi"] = "好施",
  [":haoshi"] = "摸牌阶段，你可以多摸两张牌，然后若你的手牌数大于5，你将半数（向下取整）手牌交给手牌牌最少的一名其他角色。",
  ["dimeng"] = "缔盟",
  [":dimeng"] = "出牌阶段限一次，你可以选择两名其他角色并弃置X张牌（X为这些角色手牌数差），令这两名角色交换手牌。",
  ["#haoshi-give"] = "好施：将%arg张手牌交给手牌最少的一名其他角色",
  ["#haoshi_active"] = "好施[给牌]",
  ["#haoshi_give"] = "好施[给牌]",
  ["#dimeng"] = "缔盟：选择两名其他角色，点击“确定”后，选择与其手牌数之差等量的牌，这两名角色交换手牌",
  ["#dimeng-discard"] = "缔盟：弃置 %arg 张牌，交换%src和%dest的手牌",

  ["$haoshi1"] = "拿去拿去，莫跟哥哥客气！",
  ["$haoshi2"] = "来来来，见面分一半。",
  ["$dimeng1"] = "以和为贵，以和为贵。",
  ["$dimeng2"] = "合纵连横，方能以弱胜强。",
  ["~lusu"] = "此联盟已破，吴蜀休矣……",
}

local dongzhuo = General(extension, "dongzhuo", "qun", 8)
local jiuchi = fk.CreateViewAsSkill{
  name = "jiuchi",
  anim_type = "offensive",
  pattern = "analeptic",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Spade and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("analeptic")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
}
local roulin = fk.CreateTriggerSkill{
  name = "roulin",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.card.trueName == "slash" then
      if event == fk.TargetSpecified then
        return player.room:getPlayerById(data.to).gender == General.Female
      else
        return player.room:getPlayerById(data.from).gender == General.Female
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data.fixedResponseTimes = data.fixedResponseTimes or {}
    data.fixedResponseTimes["jink"] = 2
  end,
}
local benghuai = fk.CreateTriggerSkill{
  name = "benghuai",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Finish then
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if p.hp < player.hp then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"loseMaxHp", "loseHp"}, self.name)
    if choice == "loseMaxHp" then
      room:changeMaxHp(player, -1)
    else
      room:loseHp(player, 1, self.name)
    end
  end,
}
local baonve = fk.CreateTriggerSkill{
  name = "baonve$",
  anim_type = "support",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.kingdom == "qun" and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(target, self.name, nil, "#baonve-invoke:"..player.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".|.|spade",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = target,
        skillName = self.name
      })
    end
  end
}
dongzhuo:addSkill(jiuchi)
dongzhuo:addSkill(roulin)
dongzhuo:addSkill(benghuai)
dongzhuo:addSkill(baonve)
Fk:loadTranslationTable{
  ["dongzhuo"] = "董卓",
  ["jiuchi"] = "酒池",
  [":jiuchi"] = "你可以将一张♠手牌当【酒】使用。",
  ["roulin"] = "肉林",
  [":roulin"] = "锁定技，你对女性角色使用【杀】，或女性角色对你使用【杀】均需两张【闪】才能抵消。",
  ["benghuai"] = "崩坏",
  [":benghuai"] = "锁定技，结束阶段，若你不是体力值最小的角色，你选择减1点体力上限或失去1点体力。",
  ["baonve"] = "暴虐",
  [":baonve"] = "主公技，其他群雄武将造成伤害后，其可以进行一次判定，若判定结果为♠，你回复1点体力。",
  ["loseMaxHp"] = "减1点体力上限",
  ["loseHp"] = "失去1点体力",
  ["#baonve-invoke"] = "暴虐：你可以判定，若为♠，%src 回复1点体力",

  ["$jiuchi1"] = "呃……再来……一壶……",
  ["$jiuchi2"] = "好酒！好酒！",
  ["$roulin1"] = "美人儿，来，香一个~~",
  ["$roulin2"] = "食色，性也~~",
  ["$benghuai1"] = "我是不是该减肥了？",
  ["$benghuai2"] = "呃……",
  ["$baonve1"] = "顺我者昌，逆我者亡！",
  ["$baonve2"] = "哈哈哈哈！",
  ["~dongzhuo"] = "汉室衰弱，非我一人之罪。",
}

local jiaxu = General(extension, "jiaxu", "qun", 3)
local wansha = fk.CreateTriggerSkill{
  name = "wansha",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(self.name)
  end,
}
local wansha_prohibit = fk.CreateProhibitSkill{
  name = "#wansha_prohibit",
  prohibit_use = function(self, player, card)
    if card.name == "peach" and not player.dying then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return p.phase ~= Player.NotActive and p:hasSkill(wansha.name) and p ~= player
      end)
    end
  end,
}
wansha:addRelatedSkill(wansha_prohibit)
local luanwu = fk.CreateActiveSkill{
  name = "luanwu",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function() return false end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = room:getOtherPlayers(player)
    room:doIndicate(player.id, table.map(targets, function (p) return p.id end))
    for _, target in ipairs(targets) do
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
  end,
}
local weimu = fk.CreateProhibitSkill{
  name = "weimu",
  frequency = Skill.Compulsory,
  is_prohibited = function(self, from, to, card)
    return to:hasSkill(self.name) and card.type == Card.TypeTrick and card.color == Card.Black
  end,
}

jiaxu:addSkill(wansha)
jiaxu:addSkill(luanwu)
jiaxu:addSkill(weimu)

Fk:loadTranslationTable{
  ["jiaxu"] = "贾诩",
  ["wansha"] = "完杀",
  [":wansha"] = "锁定技，除进行濒死流程的角色以外的其他角色于你的回合内不能使用【桃】。",
  ["luanwu"] = "乱武",
  [":luanwu"] = "限定技，出牌阶段，你可选择所有其他角色，这些角色各需对包括距离最小的另一名角色在内的角色使用【杀】，否则失去1点体力。",
  ["weimu"] = "帷幕",
  [":weimu"] = "锁定技，你不是黑色锦囊牌的合法目标。",

  ["#luanwu-use"] = "乱武：你需要对距离最近的一名角色使用一张【杀】，否则失去1点体力",

  ["$wansha1"] = "神仙难救，神仙难救啊。",
  ["$wansha2"] = "我要你三更死，谁敢留你到五更！",
  ["$luanwu1"] = "哼哼哼……坐山观虎斗！",
  ["$luanwu2"] = "哭喊吧，哀求吧，挣扎吧，然后，死吧！",
  ["$weimu1"] = "此计伤不到我。",
  ["$weimu2"] = "你奈我何？",
  ["~jiaxu"] = "我的时辰……也到了……",
}

return extension
