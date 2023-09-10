local extension = Package("tenyear_sp1")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_sp1"] = "十周年-限定专属1",
}

--祈福：关索 赵襄 鲍三娘 徐荣 曹纯 张琪瑛
local guansuo = General(extension, "ty__guansuo", "shu", 4)
local ty__zhengnan = fk.CreateTriggerSkill{
  name = "ty__zhengnan",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and (player:getMark(self.name) == 0 or not table.contains(player:getMark(self.name), target.id))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark(self.name)
    if mark == 0 then mark = {} end
    table.insert(mark, target.id)
    room:setPlayerMark(player, self.name, mark)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    local choices = {"ex__wusheng", "ty_ex__dangxian", "ty_ex__zhiman"}
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i], true) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      player:drawCards(1, self.name)
      local choice = room:askForChoice(player, choices, self.name, "#zhengnan-choice", true)
      room:handleAddLoseSkills(player, choice, nil)
      if choice == "ty_ex__dangxian" then
        room:setPlayerMark(player, "ty_ex__fuli", 1)  --直接获得升级后的当先
      end
    else
      player:drawCards(3, self.name)
    end
  end,
}
guansuo:addSkill(ty__zhengnan)
guansuo:addSkill("xiefang")
guansuo:addRelatedSkill("ex__wusheng")
guansuo:addRelatedSkill("ty_ex__dangxian")
guansuo:addRelatedSkill("ty_ex__zhiman")
Fk:loadTranslationTable{
  ["ty__guansuo"] = "关索",
  ["ty__zhengnan"] = "征南",
  [":ty__zhengnan"] = "每名角色限一次，当一名角色进入濒死状态时，你可以回复1点体力，然后摸一张牌并选择获得下列技能中的一个："..
  "〖武圣〗，〖当先〗和〖制蛮〗（若技能均已获得，则改为摸三张牌）。",
  
  ["$ty__zhengnan1"] = "南征之役，愿效死力。",
  ["$ty__zhengnan2"] = "南征之险恶，吾已有所准备。",
  ["$ex__wusheng_ty__guansuo"] = "我敬佩你的勇气。",
  ["$ty_ex__dangxian_ty__guansuo"] = "时时居先，方可快人一步。",
  ["$ty_ex__zhiman_ty__guansuo"] = "败军之将，自当纳贡！",
  ["~ty__guansuo"] = "索，至死不辱家风！",
}

local zhaoxiang = General(extension, "ty__zhaoxiang", "shu", 4, 4, General.Female)
local ty__fanghun = fk.CreateViewAsSkill{
  name = "ty__fanghun",
  pattern = "slash,jink",
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    local _c = Fk:getCardById(to_select)
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    else
      return false
    end
    return (Fk.currentResponsePattern == nil and c.skill:canUse(Self, c)) or
      (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    end
    c.skillNames = c.skillNames or {}
    table.insert(c.skillNames, "ty__fanghun")
    table.insert(c.skillNames, "longdan")
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  enabled_at_response = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@meiying")
    player:drawCards(1, self.name)
  end,
}
local ty__fanghun_trigger = fk.CreateTriggerSkill{
  name = "#ty__fanghun_trigger",
  events ={fk.TargetSpecified, fk.TargetConfirmed},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
  end,
  on_cost = function()
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "ty__fanghun")
    if not table.contains(data.card.skillNames, "ty__fanghun") or event == fk.TargetConfirmed then
      player:broadcastSkillInvoke("ty__fanghun")
    end
    room:addPlayerMark(player, "@meiying")
  end,
}
local ty__fuhan = fk.CreateTriggerSkill{
  name = "ty__fuhan",
  events = {fk.TurnStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("@meiying") > 0 and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__fuhan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@meiying")
    room:setPlayerMark(player, "@meiying", 0)
    player:drawCards(n, self.name)
    local existingGenerals = {}
    table.forEach(room.players, function(p)
      table.insertTable(existingGenerals, {p.general, p.deputyGeneral})
    end)
    local generals = table.map(Fk:getGeneralsRandomly(math.max(#room.alive_players, 4), Fk:getAllGenerals(), existingGenerals,
      (function(p) return (p.kingdom ~= "shu") end)), function(g) return g.name end)
    local names = {}
    while #names < 2 do
      local general = Fk.generals[room:askForGeneral(player, generals, 1)]
      local choices = {}
      for _, s in ipairs(general:getSkillNameList()) do
        local skill = Fk.skills[s]
        if not player:hasSkill(skill, true, true) and skill.frequency ~= Skill.Limited and skill.frequency ~= Skill.Wake then
          table.insertIfNeed(choices, skill.name)
        end
      end
      if #choices > 0 then
        local choice = room:askForChoice(player, choices, self.name, "#ty__fuhan-choice", true)
        table.insert(names, choice)
      end
    end
    room:handleAddLoseSkills(player, table.concat(names, "|"), nil, true, false)
    if player:isWounded() and table.every(room.alive_players, function(p) return p.hp >= player.hp end) then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
ty__fanghun:addRelatedSkill(ty__fanghun_trigger)
zhaoxiang:addSkill(ty__fanghun)
zhaoxiang:addSkill(ty__fuhan)
Fk:loadTranslationTable{
  ["ty__zhaoxiang"] = "赵襄",
  ["ty__fanghun"] = "芳魂",
  [":ty__fanghun"] = "当你使用【杀】指定目标后或成为【杀】的目标后，你获得1个“梅影”标记；你可以移去1个“梅影”标记发动〖龙胆〗并摸一张牌。",
  ["ty__fuhan"] = "扶汉",
  [":ty__fuhan"] = "限定技，回合开始时，若你有“梅影”标记，你可以移去所有“梅影”标记并摸等量的牌，然后从X张（X为存活人数且至少为4）蜀势力"..
  "武将牌中选择并获得至多两个技能（限定技、觉醒技、主公技除外）。若此时你是体力值最低的角色，你回复1点体力。",
  ["#ty__fuhan-invoke"] = "扶汉：你可以移去“梅影”标记，获得两个蜀势力武将的技能！",
  ["#ty__fuhan-choice"] = "扶汉：选择你要获得的技能",
  
  ["$ty__fanghun1"] = "芳年华月，不负期望。",
  ["$ty__fanghun2"] = "志洁行芳，承父高志。",
  ["$ty__fuhan1"] = "汉盛刘兴，定可指日成之。",
  ["$ty__fuhan2"] = "蜀汉兴存，吾必定尽力而为。",
  ["~ty__zhaoxiang"] = "此生为汉臣，死为汉芳魂……",
}

local baosanniang = General(extension, "ty__baosanniang", "shu", 3, 3, General.Female)
local ty__wuniang = fk.CreateTriggerSkill{
  name = "ty__wuniang",
  anim_type = "control",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and
      not table.every(player.room:getOtherPlayers(player), function(p) return p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#ty__wuniang1-choose"
    if player:usedSkillTimes("ty__xushen", Player.HistoryGame) > 0 and
      table.find(room.alive_players, function(p) return string.find(p.general, "guansuo") end) then
      prompt = "#ty__wuniang2-choose"
    end
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), function(p) return p.id end), 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, player, target, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local id = room:askForCardChosen(player, to, "he", self.name)
    room:obtainCard(player.id, id, false, fk.ReasonPrey)
    if not to.dead then
      to:drawCards(1, self.name)
    end
    if player:usedSkillTimes("ty__xushen", Player.HistoryGame) > 0 then
      for _, p in ipairs(room.alive_players) do
        if string.find(p.general, "guansuo") and not p.dead then
          p:drawCards(1, self.name)
        end
      end
    end
  end,
}
local ty__xushen = fk.CreateTriggerSkill{
  name = "ty__xushen",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "ty__zhennan", nil, true, false)
    if player.dead or table.find(room.alive_players, function(p) return string.find(p.general, "guansuo") end) then return end
    local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ty__xushen-choose", self.name, true)
    if #to > 0 then
      to = room:getPlayerById(to[1])
      if room:askForSkillInvoke(to, self.name, nil, "#ty__xushen-invoke") then
        room:changeHero(to, "ty__guansuo", false, false, true)
      end
      if not to.dead then
        to:drawCards(3, self.name)
      end
    end
  end,
}
local ty__zhennan = fk.CreateTriggerSkill{
  name = "ty__zhennan",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.card:isCommonTrick() and data.firstTarget and #AimGroup:getAllTargets(data.tos) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#ty__zhennan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player.room:getPlayerById(self.cost_data),
      damage = 1,
      skillName = self.name,
    }
  end,
}
baosanniang:addSkill(ty__wuniang)
baosanniang:addSkill(ty__xushen)
baosanniang:addRelatedSkill(ty__zhennan)
Fk:loadTranslationTable{
  ["ty__baosanniang"] = "鲍三娘",
  ["ty__wuniang"] = "武娘",
  [":ty__wuniang"] = "当你使用或打出【杀】时，你可以获得一名其他角色的一张牌，若如此做，其摸一张牌。若你已发动〖许身〗，则关索也摸一张牌。",
  ["ty__xushen"] = "许身",
  [":ty__xushen"] = "限定技，当你进入濒死状态后，你可以回复1点体力并获得技能〖镇南〗，然后如果你脱离濒死状态且关索不在场，"..
  "你可令一名其他角色选择是否用关索代替其武将并令其摸三张牌",
  ["ty__zhennan"] = "镇南",
  [":ty__zhennan"] = "当有角色使用普通锦囊牌指定目标后，若此牌目标数大于1，你可以对一名其他角色造成1点伤害。",
  ["#ty__wuniang1-choose"] = "武娘：你可以获得一名其他角色的一张牌，其摸一张牌",
  ["#ty__wuniang2-choose"] = "武娘：你可以获得一名其他角色的一张牌，其摸一张牌，关索摸一张牌",
  ["#ty__xushen-choose"] = "许身：你可以令一名其他角色摸三张牌并选择是否变身为十周年关索！",
  ["#ty__xushen-invoke"]= "许身：你可以变身为十周年关索！",
  ["#ty__zhennan-choose"] = "镇南：你可以对一名其他角色造成1点伤害",
  
  ["$ty__wuniang1"] = "得公亲传，彰其武威。",
  ["$ty__wuniang2"] = "灵彩武动，娇影摇曳。",
  ["$ty__xushen1"] = "倾郎心，许君身。",
  ["$ty__xushen2"] = "世间只与郎君好。",
  ["$ty__zhennan1"] = "遵丞相之志，护南中安乐。",
  ["$ty__zhennan2"] = "哼，又想扰乱南中安宁？",
  ["~ty__baosanniang"] = "彼岸花开红似火，花期苦短终别离……",
}

local xurong = General(extension, "xurong", "qun", 4)
local xionghuo = fk.CreateActiveSkill{
  name = "xionghuo",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("@baoli") > 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("@baoli") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:removePlayerMark(player, "@baoli", 1)
    room:addPlayerMark(target, "@baoli", 1)
  end,
}
local xionghuo_record = fk.CreateTriggerSkill{
  name = "#xionghuo_record",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.DamageCaused, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill("xionghuo", false, true) then
      if event == fk.GameStart then
        return true
      elseif event == fk.DamageCaused then
        return target == player and data.to ~= player and data.to:getMark("@baoli") > 0
      else
        return target ~= player and target:getMark("@baoli") > 0 and target.phase == Player.Play
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:addPlayerMark(player, "@baoli", 3)
    elseif event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      room:removePlayerMark(target, "@baoli", 1)
      local n = 3
      if target:isNude() or player.dead then
        n = 2
      end
      local rand = math.random(1, n)
      if rand == 1 then
        room:damage {
          to = target,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = "xionghuo",
        }
        room:addPlayerMark(target, "xionghuo-turn", 1)
      elseif rand == 2 then
        room:loseHp(target, 1, "xionghuo")
        room:addPlayerMark(target, "MinusMaxCards-turn", 1)
      else
        local dummy = Fk:cloneCard("dilu")
        if not target:isKongcheng() then
          dummy:addSubcard(table.random(target.player_cards[Player.Hand]))
        end
        if #target.player_cards[Player.Equip] > 0 then
          dummy:addSubcard(table.random(target.player_cards[Player.Equip]))
        end
        room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
      end
    end
  end,
}
local xionghuo_prohibit = fk.CreateProhibitSkill{
  name = "#xionghuo_prohibit",
  is_prohibited = function(self, from, to, card)
    if to:hasSkill("xionghuo") and from:getMark("xionghuo-turn") > 0 then
      return card.trueName == "slash"
    end
  end,
}
local shajue = fk.CreateTriggerSkill{
  name = "shajue",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self.name) then
      return data.damage ~= nil and data.damage.card ~= nil and target.hp < 0 and
      player.room:getCardArea(data.damage.card) == Card.Processing
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@baoli", 1)
    room:obtainCard(player, data.damage.card, true, fk.ReasonPrey)
  end
}
xionghuo:addRelatedSkill(xionghuo_record)
xionghuo:addRelatedSkill(xionghuo_prohibit)
xurong:addSkill(xionghuo)
xurong:addSkill(shajue)
Fk:loadTranslationTable{
  ["xurong"] = "徐荣",
  ["xionghuo"] = "凶镬",
  [":xionghuo"] = "游戏开始时，你获得3个“暴戾”标记。出牌阶段，你可以交给一名其他角色一个“暴戾”标记，你对有此标记的角色造成的伤害+1，"..
  "且其出牌阶段开始时，移去“暴戾”并随机执行一项：<br>受到1点火焰伤害且本回合不能对你使用【杀】；<br>流失1点体力且本回合手牌上限-1；<br>"..
  "你随机获得其一张手牌和一张装备区里的牌。",
  ["shajue"] = "杀绝",
  [":shajue"] = "锁定技，其他角色进入濒死状态时，若其需要超过一张【桃】或【酒】救回，则你获得一个“暴戾”标记，并获得使其进入濒死状态的牌。",
  ["#xionghuo_record"] = "凶镬",
  ["@baoli"] = "暴戾",

  ["$xionghuo1"] = "此镬加之于你，定有所伤！",
  ["$xionghuo2"] = "凶镬沿袭，怎会轻易无伤？",
  ["$shajue1"] = "杀伐决绝，不留后患。",
  ["$shajue2"] = "吾即出，必绝之！",
  ["~xurong"] = "此生无悔，心中无愧。",
}

local caochun = General(extension, "ty__caochun", "wei", 4)
local ty__shanjia = fk.CreateTriggerSkill{
  name = "ty__shanjia",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, self.name)
    local cards = {}
    if player:getMark(self.name) < 3 then
      local x = 3 - player:getMark(self.name)
      if #player:getCardIds{Player.Hand, Player.Equip} < x then
        cards = table.simpleClone(player:getCardIds{Player.Hand, Player.Equip})
        player:throwAllCards("he")
      else
        cards = room:askForDiscard(player, x, x, true, self.name, false, ".", "#ty__shanjia-discard:::"..x)
      end
    end
    if not table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeBasic end) then
      room:setPlayerMark(player, "ty__shanjia_basic-turn", 1)
    end
    if not table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeTrick end) then
      room:setPlayerMark(player, "ty__shanjia_trick-turn", 1)
    end
    if player:getMark("ty__shanjia_basic-turn") > 0 and player:getMark("ty__shanjia_trick-turn") > 0 then
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not player:isProhibited(p, Fk:cloneCard("slash")) end), function(p) return p.id end)
      if #targets == 0 then return end
      local success, dat = room:askForUseActiveSkill(player, "ty__shanjia_viewas", "#ty__shanjia-choose", true)
      if success then
        local card = Fk:cloneCard("slash")
        card.skillName = self.name
        room:useCard{
          from = player.id,
          tos = table.map(dat.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) < 3
  end,
  on_refresh = function(self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason ~= fk.ReasonUse then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).type == Card.TypeEquip then
            n = n + 1
          end
        end
      end
    end
    if n > 0 then
      player.room:addPlayerMark(player, self.name, math.min(n, 3 - player:getMark(self.name)))
      if player:hasSkill(self.name, true) then
        player.room:setPlayerMark(player, "@ty__shanjia", player:getMark(self.name))
      end
    end
  end,
}
local ty__shanjia_viewas = fk.CreateViewAsSkill{
  name = "ty__shanjia_viewas",
  pattern = "slash",
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = "ty__shanjia_viewas"
    return card
  end,
}
local ty__shanjia_targetmod = fk.CreateTargetModSkill{
  name = "#ty__shanjia_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if card.trueName == "slash" and player:getMark("ty__shanjia_basic-turn") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
  distance_limit_func =  function(self, player, skill, card)
    if player:getMark("ty__shanjia_trick-turn") > 0 then
      return 999
    end
  end,
}
Fk:addSkill(ty__shanjia_viewas)
ty__shanjia:addRelatedSkill(ty__shanjia_targetmod)
caochun:addSkill(ty__shanjia)
Fk:loadTranslationTable{
  ["ty__caochun"] = "曹纯",
  ["ty__shanjia"] = "缮甲",
  [":ty__shanjia"] = "出牌阶段开始时，你可以摸三张牌，然后弃置三张牌（你每不因使用而失去过一张装备牌，便少弃置一张），若你本次没有弃置过："..
  "基本牌，你此阶段使用【杀】次数上限+1；锦囊牌，你此阶段使用牌无距离限制；都满足，你可以视为使用一张不计入次数限制的【杀】。",
  ["#ty__shanjia-discard"] = "缮甲：你需弃置%arg张牌",
  ["#ty__shanjia-choose"] = "缮甲：你可以视为使用【杀】",
  ["ty__shanjia_viewas"] = "缮甲",
  ["@ty__shanjia"] = "缮甲",
  
  ["$ty__shanjia1"] = "百锤锻甲，披之可陷靡阵、断神兵、破坚城！",
  ["$ty__shanjia2"] = "千炼成兵，邀天下群雄引颈，且试我剑利否！",
  ["~ty__caochun"] = "不胜即亡，唯一死而已！",
}

local zhangqiying = General(extension, "zhangqiying", "qun", 3, 3, General.Female)
local falu = fk.CreateTriggerSkill{
  name = "falu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        for _, move in ipairs(data) do
          if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
            self.cost_data = {}
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                local suit = Fk:getCardById(info.cardId):getSuitString()
                if player:getMark("@@falu" .. suit) == 0 then
                  table.insertIfNeed(self.cost_data, suit)
                end
              end
            end
            return #self.cost_data > 0
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local suits = {"spade", "club", "heart", "diamond"}
      for i = 1, 4, 1 do
        room:addPlayerMark(player, "@@falu" .. suits[i], 1)
      end
    else
      for _, suit in ipairs(self.cost_data) do
        room:addPlayerMark(player, "@@falu" .. suit, 1)
      end
    end
  end,
}
local zhenyi = fk.CreateTriggerSkill {
  name = "zhenyi",
  anim_type = "control",
  events = {fk.AskForRetrial, fk.AskForPeaches, fk.DamageCaused, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AskForRetrial then
        return player:getMark("@@faluspade") > 0
      elseif event == fk.AskForPeaches then
        return target == player and player:getMark("@@faluclub") > 0 and player.dying and not player:isKongcheng()
      elseif event == fk.DamageCaused then
        return target == player and player:getMark("@@faluheart") > 0
      elseif event == fk.Damaged then
        return target == player and player:getMark("@@faludiamond") > 0 and data.damageType ~= fk.NormalDamage
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AskForPeaches then
      local card = room:askForCard(player, 1, 1, false, self.name, true, ".", "#zhenyi2")
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      local prompt
      if event == fk.AskForRetrial then
        prompt = "#zhenyi1::"..target.id
      elseif event == fk.DamageCaused then
        prompt = "#zhenyi3::"..data.to.id
      elseif event == fk.Damaged then
        prompt = "#zhenyi4"
      end
      return room:askForSkillInvoke(player, self.name, nil, prompt)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AskForRetrial then
      room:removePlayerMark(player, "@@faluspade", 1)
      local choice = room:askForChoice(player, {"spade", "heart"}, self.name, self.name)
      room:setPlayerMark(target, self.name, {data.card.id, choice})
    elseif event == fk.AskForPeaches then
      room:removePlayerMark(player, "@@faluclub", 1)
      local peach = Fk:cloneCard("peach")
      peach:addSubcards(self.cost_data)
      peach.skillName = self.name
      room:useCard({
        card = peach,
        from = player.id,
        tos = {{target.id}},
      })
    elseif event == fk.DamageCaused then
      room:removePlayerMark(player, "@@faluheart", 1)
      self.zhenyi_damage = false
      local judge = {
        who = data.to,
        reason = self.name,
        pattern = ".|.|spade,club",
      }
      room:judge(judge)
      if judge.card.color == Card.Black then
        data.damage = data.damage + 1
      end
    elseif event == fk.Damaged then
      room:removePlayerMark(player, "@@faludiamond", 1)
      local cards = {}
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|basic"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|trick"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|equip"))
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,

  refresh_events = {fk.FinishJudge},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(self.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
  end,
}
local zhenyi_filter1 = fk.CreateFilterSkill{
  name = "#zhenyi_filter1",
  card_filter = function(self, to_select, player)
    return player:getMark("zhenyi") ~= 0 and to_select.id == player:getMark("zhenyi")[1] and player:getMark("zhenyi")[2] == "heart"
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard(to_select.name, Card.Heart, 5)
  end,
}
local zhenyi_filter2 = fk.CreateFilterSkill{
  name = "#zhenyi_filter2",
  card_filter = function(self, to_select, player)
    return player:getMark("zhenyi") ~= 0 and to_select.id == player:getMark("zhenyi")[1]
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard(to_select.name, Card.Spade, 5)
  end,
}
local dianhua = fk.CreateTriggerSkill{
  name = "dianhua",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_cost = function(self, event, target, player, data)
    local n = 0
    for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
      if player:getMark("@@falu"..suit) > 0 then
        n = n + 1
      end
    end
    if n > 0 and player.room:askForSkillInvoke(player, self.name) then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForGuanxing(player, room:getNCards(self.cost_data), nil, {0, 0}, self.name)
  end,
}
zhenyi:addRelatedSkill(zhenyi_filter1)
zhenyi:addRelatedSkill(zhenyi_filter2)
zhangqiying:addSkill(falu)
zhangqiying:addSkill(zhenyi)
zhangqiying:addSkill(dianhua)
Fk:loadTranslationTable{
  ["zhangqiying"] = "张琪瑛",
  ["falu"] = "法箓",
  [":falu"] = "锁定技，当你的牌因弃置而移至弃牌堆后，根据这些牌的花色，你获得对应标记：<br>"..
  "♠，你获得1枚“紫微”；<br>"..
  "♣，你获得1枚“后土”；<br>"..
  "<font color='red'>♥</font>，你获得1枚“玉清”；<br>"..
  "<font color='red'>♦</font>，你获得1枚“勾陈”。<br>"..
  "每种标记限拥有一个。游戏开始时，你获得以上四种标记。",
  ["zhenyi"] = "真仪",
  [":zhenyi"] = "你可以在以下时机弃置相应的标记来发动以下效果：<br>"..
  "当一张判定牌生效前，你可以弃置“紫微”，然后将判定结果改为♠5或<font color='red'>♥5</font>；<br>"..
  "当你处于濒死状态时，你可以弃置“后土”，然后将你的一张手牌当【桃】使用；<br>"..
  "当你造成伤害时，你可以弃置“玉清”，然后你进行一次判定，若结果为黑色，此伤害+1；<br>"..
  "当你受到属性伤害后，你可以弃置“勾陈”，然后你从牌堆中随机获得三种类型的牌各一张。",
  ["dianhua"] = "点化",
  [":dianhua"] = "准备阶段或结束阶段，你可以观看牌堆顶的X张牌（X为你的标记数）。若如此做，你将这些牌以任意顺序放回牌堆顶。",
  ["@@faluspade"] = "♠紫微",
  ["@@faluclub"] = "♣后土",
  ["@@faluheart"] = "<font color='red'>♥</font>玉清",
  ["@@faludiamond"] = "<font color='red'>♦</font>勾陈",
  ["#zhenyi1"] = "真仪：你可以弃置♠紫微，将 %dest 的判定结果改为♠5或<font color='red'>♥5</font>",
  ["#zhenyi2"] = "真仪：你可以弃置♣后土，将一张手牌当【桃】使用",
  ["#zhenyi3"] = "真仪：你可以弃置<font color='red'>♥</font>玉清，你进行判定，若结果为黑色，你对 %dest 造成的伤害+1",
  ["#zhenyi4"] = "真仪：你可以弃置<font color='red'>♦</font>勾陈，从牌堆中随机获得三种类型的牌各一张",
  ["#zhenyi_filter1"] = "真仪",
  ["#zhenyi_filter2"] = "真仪",

  ["$falu1"] = "求法之道，以司箓籍。",
  ["$falu2"] = "取舍有法，方得其法。",
  ["$zhenyi1"] = "不疾不徐，自爱自重。",
  ["$zhenyi2"] = "紫薇星辰，斗数之仪。",
  ["$dianhua1"] = "大道无形，点化无为。",
  ["$dianhua2"] = "得此点化，必得大道。",
  ["~zhangqiying"] = "米碎面散，我心欲绝。",
}

--隐山之玉：周夷 卢弈
local zhouyi = General(extension, "zhouyi", "wu", 3, 3, General.Female)
local zhukou = fk.CreateTriggerSkill{
  name = "zhukou",
  anim_type = "offensive",
  events = {fk.Damage, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      local room = player.room
      if event == fk.Damage then
        if room.current and room.current.phase == Player.Play then
          local damage_event = room.logic:getCurrentEvent()
          if not damage_event then return false end
          local x = player:getMark("zhukou_record-phase")
          if x == 0 then
            room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
              local reason = e.data[3]
              if reason == "damage" then
                local first_damage_event = e:findParent(GameEvent.Damage)
                if first_damage_event and first_damage_event.data[1].from == player then
                  x = first_damage_event.id
                  room:setPlayerMark(player, "zhukou_record-phase", x)
                end
                return true
              end
            end, Player.HistoryPhase)
          end
          if damage_event.id == x then
            local events = room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
            local end_id = player:getMark("zhukou_record-turn")
            if end_id == 0 then
              local turn_event = damage_event:findParent(GameEvent.Turn, false)
              end_id = turn_event.id
            end
            room:setPlayerMark(player, "zhukou_record-turn", room.logic.current_event_id)
            local y = player:getMark("zhukou_usecard-turn")
            for i = #events, 1, -1 do
              local e = events[i]
              if e.id <= end_id then break end
              local use = e.data[1]
              if use.from == player.id then
                y = y + 1
              end
            end
            room:setPlayerMark(player, "zhukou_usecard-turn", y)
            return y > 0
          end
        end
      else
        if player.phase == Player.Finish and #room.alive_players > 2 then
          if player:getMark("zhukou_damaged-turn") > 0 then return false end
          local events = room.logic.event_recorder[GameEvent.ChangeHp] or Util.DummyTable
          local end_id = player:getMark("zhukou_damage_record-turn")
          if end_id == 0 then
            local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
            end_id = turn_event.id
          end
          room:setPlayerMark(player, "zhukou_damage_record-turn", room.logic.current_event_id)
          for i = #events, 1, -1 do
            local e = events[i]
            if e.id <= end_id then break end
            local damage = e.data[5]
            if damage and damage.from == player then
              room:setPlayerMark(player, "zhukou_damaged-turn", 1)
              return false
            end
          end
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      return room:askForSkillInvoke(player, self.name)
    else
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      if #targets < 2 then return end
      local tos = room:askForChoosePlayers(player, targets, 2, 2, "#zhukou-choose", self.name, true)
      if #tos == 2 then
        self.cost_data = tos
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.Damage then
      local x = player:getMark("zhukou_usecard-turn")
      if x > 0 then
        player:drawCards(x, self.name)
      end
    else
      local room = player.room
      local tar
      for _, p in ipairs(self.cost_data) do
        tar = room:getPlayerById(p)
        if not tar.dead then
          room:damage{
            from = player,
            to = tar,
            damage = 1,
            skillName = self.name,
          }
        end
      end
    end
  end,
}
local mengqing = fk.CreateTriggerSkill{
  name = "mengqing",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #table.filter(player.room.alive_players, function(p) return p:isWounded() end) > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 3)
    room:recover({
      who = player,
      num = 3,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "-zhukou|yuyun", nil)
  end,
}
local yuyun = fk.CreateTriggerSkill{
  name = "yuyun",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local chs = {"loseHp"}
    if player.maxHp > 1 then table.insert(chs, "loseMaxHp") end
    local chc = room:askForChoice(player, chs, self.name)
    if chc == "loseMaxHp" then
      room:changeMaxHp(player, -1)
    else
      room:loseHp(player, 1, self.name)
    end
    local choices = {"yuyun1", "yuyun2", "yuyun3", "yuyun4", "yuyun5", "Cancel"}
    local n = 1 + player:getLostHp()
    for i = 1, n, 1 do
      if player.dead or #choices < 2 then return end
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "Cancel" then return end
      table.removeOne(choices, choice)
      if choice == "yuyun1" then
        player:drawCards(2, self.name)
      elseif choice == "yuyun2" then
        local targets = table.map(room:getOtherPlayers(player, false), function(p) return p.id end)
        if #targets > 0 then
          local to = room:askForChoosePlayers(player, targets, 1, 1, "#yuyun2-choose", self.name, false)
          if #to > 0 then
            local tar = room:getPlayerById(to[1])
            room:damage{
              from = player,
              to = tar,
              damage = 1,
              skillName = self.name,
            }
            if not tar.dead then
              room:addPlayerMark(tar, "@@yuyun-turn")
              local targetRecorded = type(player:getMark("yuyun2-turn")) == "table" and player:getMark("yuyun2-turn") or {}
              table.insertIfNeed(targetRecorded, to[1])
              room:setPlayerMark(player, "yuyun2-turn", targetRecorded)
            end
          end
        end
      elseif choice == "yuyun3" then
        room:addPlayerMark(player, "@@yuyun-turn")
        room:addPlayerMark(player, "yuyun3-turn", 1)
      elseif choice == "yuyun4" then
        local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
          return not p:isAllNude() end), function(p) return p.id end)
        if #targets > 0 then
          local to = room:askForChoosePlayers(player, targets, 1, 1, "#yuyun4-choose", self.name, false)
          if #to > 0 then
            local id = room:askForCardChosen(player, room:getPlayerById(to[1]), "hej", self.name)
            room:obtainCard(player.id, id, false, fk.ReasonPrey)
          end
        end
      elseif choice == "yuyun5" then
        local targets = table.map(room:getOtherPlayers(player, false), function(p) return p.id end)
        if #targets > 0 then
          local to = room:askForChoosePlayers(player, targets, 1, 1, "#yuyun5-choose", self.name, false)
          if #to > 0 then
            local p = room:getPlayerById(to[1])
            local x = math.min(p.maxHp, 5) - p:getHandcardNum()
            if x > 0 then
              room:drawCards(p, x, self.name)
            end
          end
        end
      end
    end
  end,
}
local yuyun_targetmod = fk.CreateTargetModSkill{
  name = "#yuyun_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    local targetRecorded = player:getMark("yuyun2-turn")
    return type(targetRecorded) == "table" and to and table.contains(targetRecorded, to.id)
  end,
  bypass_distances =  function(self, player, skill, card, to)
    local targetRecorded = player:getMark("yuyun2-turn")
    return type(targetRecorded) == "table" and to and table.contains(targetRecorded, to.id)
  end,
}
local yuyun_maxcards = fk.CreateMaxCardsSkill{
  name = "#yuyun_maxcards",
  correct_func = function(self, player)
    if player:getMark("yuyun3-turn") > 0 then
      return 999
    end
    return 0
  end,
}
yuyun:addRelatedSkill(yuyun_targetmod)
yuyun:addRelatedSkill(yuyun_maxcards)
zhouyi:addSkill(zhukou)
zhouyi:addSkill(mengqing)
zhouyi:addRelatedSkill(yuyun)
Fk:loadTranslationTable{
  ["zhouyi"] = "周夷",
  ["zhukou"] = "逐寇",
  [":zhukou"] = "当你于每回合的出牌阶段第一次造成伤害后，你可以摸X张牌（X为本回合你已使用的牌数）。结束阶段，若你本回合未造成过伤害，"..
  "你可以对两名其他角色各造成1点伤害。",
  ["mengqing"] = "氓情",
  [":mengqing"] = "觉醒技，准备阶段，若已受伤的角色数大于你的体力值，你加3点体力上限并回复3点体力，失去〖逐寇〗，获得〖玉殒〗。",
  ["yuyun"] = "玉陨",
  [":yuyun"] = "锁定技，出牌阶段开始时，你失去1点体力或体力上限（你的体力上限不能以此法被减至1以下），然后选择X+1项（X为你已损失的体力值）：<br>"..
  "1.摸两张牌；<br>"..
  "2.对一名其他角色造成1点伤害，然后本回合对其使用【杀】无距离和次数限制；<br>"..
  "3.本回合没有手牌上限；<br>"..
  "4.获得一名其他角色区域内的一张牌；<br>"..
  "5.令一名其他角色将手牌摸至体力上限（最多摸至5）。",
  ["#zhukou-choose"] = "是否发动逐寇，选择2名其他角色，对其各造成1点伤害",
  ["yuyun1"] = "摸两张牌",
  ["yuyun2"] = "对一名其他角色造成1点伤害，本回合对其使用【杀】无距离和次数限制",
  ["yuyun3"] = "本回合没有手牌上限",
  ["yuyun4"] = "获得一名其他角色区域内的一张牌",
  ["yuyun5"] = "令一名其他角色将手牌摸至体力上限（最多摸至5）",
  ["#yuyun2-choose"] = "玉陨：对一名其他角色造成1点伤害，本回合对其使用【杀】无距离和次数限制",
  ["#yuyun4-choose"] = "玉陨：获得一名其他角色区域内的一张牌",
  ["#yuyun5-choose"] = "玉陨：令一名其他角色将手牌摸至体力上限（最多摸至5）",
  ["@@yuyun-turn"] = "玉陨",

  ["$zhukou1"] = "草莽贼寇，不过如此。",
  ["$zhukou2"] = "轻装上阵，利剑出鞘。",
  ["$mengqing1"] = "女之耽兮，不可说也。",
  ["$mengqing2"] = "淇水汤汤，渐车帷裳。",
  ["$yuyun1"] = "春依旧，人消瘦。",
  ["$yuyun2"] = "泪沾青衫，玉殒香消。",
  ["~zhouyi"] = "江水寒，萧瑟起……",
}

local luyi = General(extension, "luyi", "qun", 3, 3, General.Female)

local function searchFuxueCards(room, findOne)
  if #room.discard_pile == 0 then return {} end
  local ids = {}
  local discard_pile = table.simpleClone(room.discard_pile)
  local logic = room.logic
  local events = logic.event_recorder[GameEvent.MoveCards] or Util.DummyTable
  for i = #events, 1, -1 do
    local e = events[i]
    for _, move in ipairs(e.data) do
      for _, info in ipairs(move.moveInfo) do
        local id = info.cardId
        if table.removeOne(discard_pile, id) then
          if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
            table.insertIfNeed(ids, id)
            if findOne then
              return ids
            end
          end
        end
      end
    end
    if #discard_pile == 0 then break end
  end
  return ids
end

local fuxue = fk.CreateTriggerSkill{
  name = "fuxue",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if player.phase == Player.Start then
        return #searchFuxueCards(player.room, true) > 0
      elseif player.phase == Player.Finish then
        return player:isKongcheng() or
          table.every(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@fuxue-inhand") == 0 end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.phase == Player.Start then
      return player.room:askForSkillInvoke(player, self.name, nil, "#fuxue-invoke:::"..player.hp)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if player.phase == Player.Start then
      local room = player.room
      local cards = searchFuxueCards(room, false)
      if #cards == 0 then return false end
      table.sort(cards, function (a, b)
        local cardA, cardB = Fk:getCardById(a), Fk:getCardById(b)
        if cardA.type == cardB.type then
          if cardA.sub_type == cardB.sub_type then
            if cardA.name == cardB.name then
              return a > b
            else
              return cardA.name > cardB.name
            end
          else
            return cardA.sub_type < cardB.sub_type
          end
        else
          return cardA.type < cardB.type
        end
      end)
      local get = room:askForCardsChosen(player, player, 1, player.hp, {
        card_data = {
          { self.name, cards }
        }
      }, self.name)
      if #get > 0 then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(get)
        room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
        for _, id in ipairs(get) do
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            room:setCardMark(Fk:getCardById(id), "@@fuxue-inhand", 1)
          end
        end
      end
    else
      player:drawCards(player.hp, self.name)
    end
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      player.room:setCardMark(Fk:getCardById(id), "@@fuxue-inhand", 0)
    end
  end,
}
local yaoyi = fk.CreateTriggerSkill{
  name = "yaoyi",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(player.room:getAlivePlayers()) do
      local yes = true
      for _, skill in ipairs(p.player_skills) do
        if skill.switchSkillName then
          yes = false
          break
        end
      end
      if yes then
        room:handleAddLoseSkills(p, "shoutan", nil, true, false)
      end
    end
  end,

  refresh_events = {fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAllPlayers()) do
      room:handleAddLoseSkills(p, "-shoutan", nil, true, true)
    end
  end,
}
local yaoyi_prohibit = fk.CreateProhibitSkill{
  name = "#yaoyi_prohibit",
  frequency = Skill.Compulsory,
  is_prohibited = function(self, from, to, card)
    if table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill("yaoyi") end) then
      if from ~= to then
        local fromskill = {}
        for _, skill in ipairs(from.player_skills) do
          if skill.switchSkillName then
            table.insertIfNeed(fromskill, skill.switchSkillName)
          end
        end
        local toskill = {}
        for _, skill in ipairs(to.player_skills) do
          if skill.switchSkillName then
            table.insertIfNeed(toskill, skill.switchSkillName)
          end
        end
        if #fromskill == 0 or #toskill == 0 then return false end
        if #fromskill > 1 then  --FIXME: 多个转换技
        end
        return from:getSwitchSkillState(fromskill[1], false) == to:getSwitchSkillState(toskill[1], false)
      end
    end
  end,
}
local shoutan = fk.CreateActiveSkill{
  name = "shoutan",
  anim_type = "switch",
  switch_skill_name = "shoutan",
  card_num = function()
    if Self:hasSkill("yaoyi") then
      return 0
    else
      return 1
    end
  end,
  target_num = 0,
  can_use = function(self, player)
    if player:hasSkill("yaoyi") then
      return true--player:getMark("shoutan-phase") == 0 FIXME: 避免无限空发
    else
      return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
    end
  end,
  card_filter = function(self, to_select, selected)
    if Self:hasSkill("yaoyi") then
      return false
    elseif #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip then
      if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
        return Fk:getCardById(to_select).color ~= Card.Black
      else
        return Fk:getCardById(to_select).color == Card.Black
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
  end,
}
yaoyi:addRelatedSkill(yaoyi_prohibit)
luyi:addSkill(fuxue)
luyi:addSkill(yaoyi)
luyi:addRelatedSkill(shoutan)
Fk:loadTranslationTable{
  ["luyi"] = "卢弈",
  ["fuxue"] = "复学",
  [":fuxue"] = "准备阶段，你可以从弃牌堆中获得至多X张不因使用而进入弃牌堆的牌。结束阶段，若你手中没有以此法获得的牌，你摸X张牌。（X为你的体力值）",
  ["yaoyi"] = "邀弈",
  [":yaoyi"] = "锁定技，游戏开始时，所有没有转换技的角色获得〖手谈〗；你发动〖手谈〗无需弃置牌且无次数限制。"..
  "所有角色使用牌只能指定自己及与自己转换技状态不同的角色为目标。",
  ["shoutan"] = "手谈",
  [":shoutan"] = "转换技，出牌阶段限一次，你可以弃置一张：阳：非黑色手牌；阴：黑色手牌。",
  ["#fuxue-invoke"] = "复学：你可以获得弃牌堆中至多%arg张不因使用而进入弃牌堆的牌",
  ["@@fuxue-inhand"] = "复学",

  ["is_selected"] = "已选择",

  ["$fuxue1"] = "普天之大，唯此处可安书桌。",
  ["$fuxue2"] = "书中自有风月，何故东奔西顾？",
  ["$yaoyi1"] = "对弈未分高下，胜负可问春风。",
  ["$yaoyi2"] = "我掷三十六道，邀君游弈其中。",
  ["$shoutan1"] = "对弈博雅，落子珠玑胜无声。",
  ["$shoutan2"] = "弈者无言，手执黑白谈古今。",
  ["~luyi"] = "此生博弈，落子未有悔……",
}

local sunlingluan = General(extension, "sunlingluan", "wu", 3, 3, General.Female)
local lingyue = fk.CreateTriggerSkill{
  name = "lingyue",
  anim_type = "drawcard",
  events = {fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) or not target then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    if not damage_event then return false end
    local x = target:getMark("lingyue_record-round")
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local reason = e.data[3]
        if reason == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event and first_damage_event.data[1].from == target then
            x = first_damage_event.id
            room:setPlayerMark(target, "lingyue_record-round", x)
            return true
          end
        end
      end, Player.HistoryRound)
    end
    return damage_event.id == x
  end,
  on_use = function(self, event, target, player, data)
    if target.phase == Player.NotActive then
      local room = player.room
      local events = room.logic.event_recorder[GameEvent.ChangeHp] or Util.DummyTable
      local end_id = player:getMark("lingyue_record-turn")
      if end_id == 0 then
        local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
        if not turn_event then return false end
        end_id = turn_event.id
      end
      room:setPlayerMark(player, "lingyue_record-turn", room.logic.current_event_id)
      local x = player:getMark("lingyue_damage-turn")
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id <= end_id then break end
        local damage = e.data[5]
        if damage and damage.from then
          x = x + damage.damage
        end
      end
      room:setPlayerMark(player, "lingyue_damage-turn", x)
      if x > 0 then
        player:drawCards(x, self.name)
      end
    else
      player:drawCards(1, self.name)
    end
  end,
}
local pandi = fk.CreateActiveSkill{
  name = "pandi",
  anim_type = "control",
  prompt = "#pandi-active",
  can_use = function(self, player)
    return player:getMark("pandi_prohibit-phase") == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("pandi_damaged-turn") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = effect.tos[1]
    room:setPlayerMark(player, "pandi_prohibit-phase", 1)
    room:setPlayerMark(player, "pandi_target", target)
    local general_info = {player.general, player.deputyGeneral}
    local tar_player = room:getPlayerById(target)
    player.general = tar_player.general
    player.deputyGeneral = tar_player.deputyGeneral
    room:broadcastProperty(player, "general")
    room:broadcastProperty(player, "deputyGeneral")
    local _, ret = room:askForUseActiveSkill(player, "pandi_use", "#pandi-use::" .. target, true)
    room:setPlayerMark(player, "pandi_target", 0)
    player.general = general_info[1]
    player.deputyGeneral = general_info[2]
    room:broadcastProperty(player, "general")
    room:broadcastProperty(player, "deputyGeneral")
    if ret then
      room:useCard({
        from = target,
        tos = table.map(ret.targets, function(pid) return { pid } end),
        card = Fk:getCardById(ret.cards[1]),
      })
    end
  end,
}
local pandi_refresh = fk.CreateTriggerSkill{
  name = "#pandi_refresh",

  refresh_events = {fk.EventAcquireSkill, fk.Damage, fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      return player == target and player:getMark("pandi_damaged-turn") == 0
    elseif event == fk.EventAcquireSkill then
      return player == target and data == self and player.room.current == player
    elseif event == fk.PreCardUse then
      return player:getMark("pandi_prohibit-phase") > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:addPlayerMark(player, "pandi_damaged-turn")
    elseif event == fk.EventAcquireSkill then
      local room = player.room
      local current_event = room.logic:getCurrentEvent()
      if current_event == nil then return false end
      local start_event = current_event:findParent(GameEvent.Turn, true)
      if start_event == nil then return false end
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local damage = e.data[5]
        if damage and damage.from then
          room:addPlayerMark(damage.from, "pandi_damaged-turn")
        end
      end, Player.HistoryTurn)
    elseif event == fk.PreCardUse then
      player.room:setPlayerMark(player, "pandi_prohibit-phase", 0)
    end
  end,
}
local pandi_use = fk.CreateActiveSkill{
  name = "pandi_use",
  card_filter = function(self, to_select, selected)
    if #selected > 0 then return false end
    local room = Fk:currentRoom()
    if room:getCardArea(to_select) == Card.PlayerEquip then return false end
    local target_id = Self:getMark("pandi_target")
    local target = room:getPlayerById(target_id)
    local card = Fk:getCardById(to_select)
    return target:canUse(card) and not target:prohibitUse(card)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected_cards ~= 1 then return false end
    local card = Fk:getCardById(selected_cards[1])
    local card_skill = card.skill
    local room = Fk:currentRoom()
    local target_id = Self:getMark("pandi_target")
    local target = room:getPlayerById(target_id)
    if card_skill:getMinTargetNum() == 0 or #selected >= card_skill:getMaxTargetNum(target, card) then return false end
    return not target:isProhibited(room:getPlayerById(to_select), card) and
      card_skill:modTargetFilter(to_select, selected, target_id, card, true)
  end,
  feasible = function(self, selected, selected_cards)
    if #selected_cards ~= 1 then return false end
    local card = Fk:getCardById(selected_cards[1])
    local card_skill = card.skill
    local room = Fk:currentRoom()
    local target_id = Self:getMark("pandi_target")
    local target = room:getPlayerById(target_id)
    return #selected >= card_skill:getMinTargetNum() and #selected <= card_skill:getMaxTargetNum(target, card)
  end,
}
Fk:addSkill(pandi_use)
pandi:addRelatedSkill(pandi_refresh)
sunlingluan:addSkill(lingyue)
sunlingluan:addSkill(pandi)
Fk:loadTranslationTable{
  ["sunlingluan"] = "孙翎鸾",
  ["lingyue"] = "聆乐",
  [":lingyue"] = "锁定技，一名角色在本轮首次造成伤害后，你摸一张牌。若此时是该角色回合外，改为摸X张牌（X为本回合全场造成的伤害值）。",
  ["pandi"] = "盻睇",
  [":pandi"] = "出牌阶段，你可以选择一名本回合未造成过伤害的其他角色，你此阶段内使用的下一张牌改为由其对你选择的目标使用。" ..
  '<br /><font color="red">（村：发动后必须立即使用牌，且不支持转化使用，否则必须使用一张牌之后才能再次发动此技能）</font>',

  ["pandi_use"] = "盻睇",
  ["#pandi-active"] = "发动盻睇，选择一名其他角色，下一张牌视为由该角色使用",
  ["#pandi-use"] = "盻睇：选择一张牌，视为由 %dest 使用（若需要选目标则你来选择目标）",

  ["$lingyue1"] = "宫商催角羽，仙乐自可聆。	",
  ["$lingyue2"] = "玉琶奏折柳，天地尽箫声。",
  ["$pandi1"] = "待君归时，共泛轻舟于湖海。",
  ["$pandi2"] = "妾有一曲，可壮卿之峥嵘。",
  ["~sunlingluan"] = "良人当归，苦酒何妨……",
}

--神·武：姜维 马超 张飞 张角 邓艾
local godjiangwei = General(extension, "godjiangwei", "god", 4)
local tianren = fk.CreateTriggerSkill {
  name = "tianren",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card.type == Card.TypeBasic or card:isCommonTrick() then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = 0
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card.type == Card.TypeBasic or card:isCommonTrick() then
            x = x + 1
          end
        end
      end
    end
    room:addPlayerMark(player, "@tianren", x)
    while player:getMark("@tianren") >= player.maxHp do
      room:removePlayerMark(player, "@tianren", player.maxHp)
      room:changeMaxHp(player, 1)
      player:drawCards(2, self.name)
    end
  end,
}
local jiufa = fk.CreateTriggerSkill{
  name = "jiufa",
  events = {fk.CardUsing, fk.CardResponding},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      local mark = player:getMark("@$jiufa")
      return type(mark) ~= "table" or not table.contains(mark, data.card.trueName)
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@$jiufa")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, data.card.trueName)
    room:setPlayerMark(player, "@$jiufa", mark)
    if #mark < 9 or not room:askForSkillInvoke(player, self.name, nil, "#jiufa-invoke") then return false end
    room:setPlayerMark(player, "@$jiufa", 0)
    local card_ids = room:getNCards(9)
    local get, throw = {}, {}
    room:moveCards({
      ids = card_ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
    })

    local number_table = {}
    for _ = 1, 13, 1 do
      table.insert(number_table, 0)
    end
    for _, id in ipairs(card_ids) do
      local x = Fk:getCardById(id).number
      number_table[x] = number_table[x] + 1
      if number_table[x] == 2 then
        table.insert(get, id)
      else
        table.insert(throw, id)
      end
    end
    local patterns = {}
    for index, value in ipairs(number_table) do
      if value > 1 then
        table.insert(patterns, ".|"..index)
      end
    end

    local result = room:askForCustomDialog(player, self.name,
    "packages/tenyear/qml/JiufaBox.qml", {
      card_ids, patterns, #patterns, #patterns, "#jiufa", "AGCards", "toGetCards"
    })

    if result ~= "" then
      local d = json.decode(result)
      throw = d[1]
      get = d[2]
    end

    if #get > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    end
    if #throw > 0 then
      room:moveCards({
        ids = throw,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
    end
  end,
}
local pingxiang = fk.CreateActiveSkill{
  name = "pingxiang",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player.maxHp > 9 and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected, selected_targets)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:changeMaxHp(player, -9)
    for i = 1, 9, 1 do
      if player.dead then return end
      local success, data = room:askForUseActiveSkill(player, "pingxiang_viewas", "#pingxiang-slash:::"..tostring(i), true)
      if success then
        local card = Fk:cloneCard("fire__slash")
        card.skillName = self.name
        room:useCard{
          from = player.id,
          tos = table.map(data.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
      else
        break
      end
    end
    room:handleAddLoseSkills(player, "-jiufa", nil, true, false)
  end,
}
local pingxiang_viewas = fk.CreateViewAsSkill{
  name = "pingxiang_viewas",
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("fire__slash")
    card.skillName = "pingxiang"
    return card
  end,
}
local pingxiang_maxcards = fk.CreateMaxCardsSkill{
  name = "#pingxiang_maxcards",
  fixed_func = function(self, player)
    if player:usedSkillTimes("pingxiang", Player.HistoryGame) > 0 then
      return player.maxHp
    end
  end
}
local pingxiang_targetmod = fk.CreateTargetModSkill{
  name = "#pingxiang_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, pingxiang.name)
  end,
}
Fk:addSkill(pingxiang_viewas)
pingxiang:addRelatedSkill(pingxiang_maxcards)
pingxiang:addRelatedSkill(pingxiang_targetmod)
godjiangwei:addSkill(tianren)
godjiangwei:addSkill(jiufa)
godjiangwei:addSkill(pingxiang)
Fk:loadTranslationTable{
  ["godjiangwei"] = "神姜维",
  ["tianren"] = "天任",
  [":tianren"] = "锁定技，当一张基本牌或普通锦囊牌不是因使用而置入弃牌堆后，你获得1个“天任”标记，"..
  "然后若“天任”标记数不小于X，你移去X个“天任”标记，加1点体力上限并摸两张牌（X为你的体力上限）。",
  ["jiufa"] = "九伐",
  [":jiufa"] = "当你每累计使用或打出九张不同牌名的牌后，你可以亮出牌堆顶的九张牌，然后若其中有点数相同的牌，你选择并获得其中每个重复点数的牌各一张。",
  ["pingxiang"] = "平襄",
  [":pingxiang"] = "限定技，出牌阶段，若你的体力上限大于9，你可以减9点体力上限，然后你视为使用至多九张火【杀】。"..
  "若如此做，你失去技能〖九伐〗且本局游戏内你的手牌上限等于体力上限。",
  ["@tianren"] = "天任",
  ["@$jiufa"] = "九伐",
  ["#jiufa-invoke"] = "九伐：是否亮出牌堆顶九张牌，获得重复点数的牌各一张！",
  ["pingxiang_viewas"] = "平襄",
  ["#pingxiang-slash"] = "平襄：你可以视为使用火【杀】（第%arg张，共9张）！",

  ["#jiufa"] = "九伐：从亮出的牌中选择并获得其中每个重复点数的牌各一张",
  ["AGCards"] = "亮出的牌",
  ["toGetCards"] = "获得的牌",

  ["$tianren1"] = "举石补苍天，舍我更复其谁？",
  ["$tianren2"] = "天地同协力，何愁汉道不昌？",
  ["$jiufa1"] = "九伐中原，以圆先帝遗志。",
  ["$jiufa2"] = "日日砺剑，相报丞相厚恩。",
  ["$pingxiang1"] = "策马纵慷慨，捐躯抗虎豺。",
  ["$pingxiang2"] = "解甲事仇雠，竭力挽狂澜。",
  ["~godjiangwei"] = "武侯遗志，已成泡影矣……",
}

local godmachao = General(extension, "godmachao", "god", 4)
local shouli = fk.CreateViewAsSkill{
  name = "shouli",
  pattern = "slash,jink",
  prompt = "#shouli-active",
  interaction = function()
    local names = {}
    local pat = Fk.currentResponsePattern
    if pat == nil and Self:canUse(Fk:cloneCard("slash")) and table.find(Fk:currentRoom().alive_players, function(p)
      return p:getEquipment(Card.SubtypeOffensiveRide) ~= nil end) then
      table.insert(names, "slash")
    else
      if Exppattern:Parse(pat):matchExp("slash") and table.find(Fk:currentRoom().alive_players, function(p)
        return p:getEquipment(Card.SubtypeOffensiveRide) ~= nil end) then
          table.insert(names, "slash")
      end
      if Exppattern:Parse(pat):matchExp("jink") and table.find(Fk:currentRoom().alive_players, function(p)
        return p:getEquipment(Card.SubtypeDefensiveRide) ~= nil end) then
          table.insert(names, "jink")
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}  --FIXME: 体验很不好！
  end,
  view_as = function(self, cards)
    if self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local horse_type = use.card.trueName == "slash" and Card.SubtypeOffensiveRide or Card.SubtypeDefensiveRide
    local horse_name = use.card.trueName == "slash" and "offensive_horse" or "defensive_horse"
    local targets = table.filter(room.alive_players, function (p)
      return p:getEquipment(horse_type) ~= nil
    end)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, table.map(targets, function (p)
        return p.id end), 1, 1, "#shouli-horse:::" .. horse_name, self.name, false, true)
      if #tos > 0 then
        local to = room:getPlayerById(tos[1])
        room:addPlayerMark(to, "@@shouli-turn")
        if to ~= player then
          room:addPlayerMark(player, "@@shouli-turn")
          room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity .. "-turn")
        end
        local horse = to:getEquipment(horse_type)
        if horse then
          room:obtainCard(player.id, horse, false, fk.ReasonPrey)
          if room:getCardOwner(horse) == player and room:getCardArea(horse) == Player.Hand then
            use.card:addSubcard(horse)
            use.extraUse = true
            return
          end
        end
      end
    end
  end,
  enabled_at_play = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p:getEquipment(Card.SubtypeOffensiveRide) ~= nil end)
  end,
  enabled_at_response = function(self, player)
    local pat = Fk.currentResponsePattern
    return pat and table.find(Fk:currentRoom().alive_players, function(p)
      return (Exppattern:Parse(pat):matchExp("slash") and p:getEquipment(Card.SubtypeOffensiveRide) ~= nil) or
        (Exppattern:Parse(pat):matchExp("jink") and p:getEquipment(Card.SubtypeDefensiveRide) ~= nil)
    end)
  end,
}
local shouli_trigger = fk.CreateTriggerSkill{
  name = "#shouli_trigger",
  events = {fk.GameStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shouli.name)
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(shouli.name)
    room:notifySkillInvoked(player, shouli.name)
    local temp = player.next
    local players = {}
    while temp ~= player do
      if not temp.dead then
        table.insert(players, temp)
      end
      temp = temp.next
    end
    table.insert(players, player)
    room:doIndicate(player.id, table.map(players, function (p) return p.id end))
    for _, p in ipairs(players) do
      if not p.dead then
        local cards = {}
        for i = 1, #room.draw_pile, 1 do
          local card = Fk:getCardById(room.draw_pile[i])
          if (card.sub_type == Card.SubtypeOffensiveRide or card.sub_type == Card.SubtypeDefensiveRide) and
              card.skill:canUse(p, card) and not p:prohibitUse(card) then
            table.insertIfNeed(cards, card)
          end
        end
        if #cards > 0 then
          local horse = cards[math.random(1, #cards)]
          room:useCard{
            from = p.id,
            card = horse,
          }
        end
      end
    end
  end,
}
local shouli_delay = fk.CreateTriggerSkill{
  name = "#shouli_delay",
  events = {fk.DamageInflicted},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@shouli-turn") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
    data.damageType = fk.ThunderDamage
  end,
}
local shouli_negated = fk.CreateTriggerSkill{
  name = "#shouli_negated",
  events = {fk.PreCardUse, fk.PreCardRespond},
  mute = true,
  priority = 10,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, shouli.name) and #data.card.subcards == 0
  end,
  on_cost = function() return true end,
  on_use = function() return true end,
}
shouli:addRelatedSkill(shouli_trigger)
shouli:addRelatedSkill(shouli_delay)
shouli:addRelatedSkill(shouli_negated)
local hengwu = fk.CreateTriggerSkill{
  name = "hengwu",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      local suit = data.card.suit
      return table.every(player.player_cards[Player.Hand], function (id)
        return Fk:getCardById(id).suit ~= suit end) and table.find(player.room.alive_players, function (p)
          return table.find(p.player_cards[Player.Equip], function (id)
            return Fk:getCardById(id).suit == suit end) end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local x = 0
    local suit = data.card.suit
    for _, p in ipairs(player.room.alive_players) do
      for _, id in ipairs(p.player_cards[Player.Equip]) do
        if Fk:getCardById(id).suit == suit then
          x = x + 1
        end
      end
    end
    if x > 0 then
      player:drawCards(x, self.name)
    end
  end,
}
godmachao:addSkill(shouli)
godmachao:addSkill(hengwu)
Fk:loadTranslationTable{
  ["godmachao"] = "神马超",
  ["shouli"] = "狩骊",
  ["#shouli_trigger"] = "狩骊",
  ["#shouli_delay"] = "狩骊",
  [":shouli"] = "游戏开始时，从下家开始所有角色随机使用牌堆中的一张坐骑。你可将场上的一张进攻马当【杀】（不计入次数）、"..
  "防御马当【闪】使用或打出，以此法失去坐骑的其他角色本回合非锁定技失效，你与其本回合受到的伤害+1且改为雷电伤害。",
  ["hengwu"] = "横骛",
  [":hengwu"] = "当你使用或打出牌时，若你没有该花色的手牌，你可摸X张牌（X为场上与此牌花色相同的装备数量）。",

  ["#shouli-active"] = "发动狩骊，将场上的一张进攻马当【杀】、防御马当【闪】使用或打出",
  ["@@shouli-turn"] = "狩骊",
  ["#shouli-horse"] = "狩骊：选择一名装备着 %arg 的角色",

  ["$shouli1"] = "赤骊骋疆，巡狩八荒！",
  ["$shouli2"] = "长缨在手，百骥可降！",
  ["$hengwu1"] = "横枪立马，独啸秋风！",
  ["$hengwu2"] = "世皆彳亍，唯我纵横！",
  ["~godmachao"] = "离群之马，虽强亦亡……",
}

local godzhangfei = General(extension, "godzhangfei", "god", 4)
local shencai = fk.CreateActiveSkill{
  name = "shencai",
  prompt = "#shencai-active",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) < 1 + player:getMark("xunshi")
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local data = {
      who = target,
      reason = self.name,
      pattern = ".",
      extra_data = {shencaiSource = effect.from}
    }
    room:judge(data)
    local result = {}
    if table.contains({"peach", "analeptic", "silver_lion", "god_salvation", "celestial_calabash"}, data.card.trueName) then
      table.insert(result, "@@shencai_chi")
    end
    if data.card.sub_type == Card.SubtypeWeapon or data.card.name == "collateral" then
      table.insert(result, "@@shencai_zhang")
    end
    if table.contains({"savage_assault", "archery_attack", "duel", "spear", "eight_diagram", "raid_and_frontal_attack"}, data.card.trueName) then
      table.insert(result, "@@shencai_tu")
    end
    if data.card.sub_type == Card.SubtypeDefensiveRide or data.card.sub_type == Card.SubtypeOffensiveRide or
    table.contains({"snatch", "supply_shortage", "chasing_near"}, data.card.trueName) then
      table.insert(result, "@@shencai_liu")
    end
    if #result == 0 then
      table.insert(result, "@shencai_si")
    end
    if result[1] ~= "@shencai_si" then
      for _, mark in ipairs({"@@shencai_chi", "@@shencai_zhang", "@@shencai_tu", "@@shencai_liu"}) do
        room:setPlayerMark(data.who, mark, 0)
      end
    end
    for _, mark in ipairs(result) do
      room:addPlayerMark(data.who, mark, 1)
      if mark == "@shencai_si" and not data.who:isNude() then
        local card = room:askForCardChosen(player, target, "he", "shencai")
        room:obtainCard(player.id, card, false, fk.ReasonPrey)
      end
    end
  end,
}
local shencai_delay = fk.CreateTriggerSkill{
  name = "#shencai_delay",
  anim_type = "offensive",
  events = {fk.FinishJudge, fk.Damaged, fk.TargetConfirmed, fk.AfterCardsMove, fk.EventPhaseStart, fk.TurnEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    if event == fk.FinishJudge then
      return data.extra_data and data.extra_data.shencaiSource == player.id and player.room:getCardArea(data.card) == Card.Processing
    elseif event == fk.Damaged then
      return player == target and player:getMark("@@shencai_chi") > 0
    elseif event == fk.TargetConfirmed then
      return player == target and data.card.trueName == "slash" and player:getMark("@@shencai_zhang") > 0
    elseif event == fk.AfterCardsMove and player:getMark("@@shencai_tu") > 0 and not player:isKongcheng() then
      for _, move in ipairs(data) do
        if move.skillName ~= shencai.name and move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    elseif event == fk.EventPhaseStart then
      return player == target and player:getMark("@@shencai_liu") > 0 and player.phase == Player.Finish
    elseif event == fk.TurnEnd then
      return player == target and player:getMark("@shencai_si") > #player.room.alive_players
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.FinishJudge then
      if room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
      end
      return false
    end
    room:notifySkillInvoked(player, shencai.name, "negative")
    player:broadcastSkillInvoke(shencai.name)
    if event == fk.Damaged then
      room:loseHp(player, data.damage, shencai.name)
    elseif event == fk.TargetConfirmed then
      data.disresponsive = true
    elseif event == fk.AfterCardsMove then
      if not player:isKongcheng() then
        room:throwCard({table.random(player.player_cards[Player.Hand])}, shencai.name, player, player)
      end
    elseif event == fk.EventPhaseStart then
      player:turnOver()
    elseif event == fk.TurnEnd then
      room:killPlayer({who = player.id})
    end
  end,
}
local shencai_maxcards = fk.CreateMaxCardsSkill {
  name = "#shencai_maxcards",
  correct_func = function(self, player)
    return -player:getMark("@shencai_si")
  end,
}
local xunshi = fk.CreateFilterSkill{
  name = "xunshi",
  mute = true,
  frequency = Skill.Compulsory,
  card_filter = function(self, card, player)
    local names = {"savage_assault", "archery_attack", "amazing_grace", "god_salvation", "iron_chain", "redistribute"}
    return player:hasSkill(self.name) and table.contains(names, card.name) and
      not table.contains(player.player_cards[Player.Judge], card.id)
  end,
  view_as = function(self, card)
    local card = Fk:cloneCard("slash", Card.NoSuit, card.number)
    card.skillName = self.name
    return card
  end,
}
local function getUseExtraTargets(room, data, bypass_distances)
  if not (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then return {} end
  if data.card.skill:getMinTargetNum() > 1 then return {} end --stupid collateral
  local tos = {}
  local current_targets = TargetGroup:getRealTargets(data.tos)
  for _, p in ipairs(room.alive_players) do
    if not table.contains(current_targets, p.id) and not room:getPlayerById(data.from):isProhibited(p, data.card) then
      if data.card.skill:modTargetFilter(p.id, {}, data.from, data.card, not bypass_distances) then
        table.insert(tos, p.id)
      end
    end
  end
  return tos
end
local xunshi_trigger = fk.CreateTriggerSkill{
  name = "#xunshi_trigger",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xunshi.name) and data.card.color == Card.NoColor
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, xunshi.name)
    player:broadcastSkillInvoke(xunshi.name)
    if player:getMark("xunshi") < 4 then
      player.room:addPlayerMark(player, "xunshi", 1)
    end
    local targets = getUseExtraTargets(room, data)
    local n = #targets
    if n == 0 then return false end
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#xunshi-choose:::"..data.card:toLogString(), xunshi.name, true)
    if #tos > 0 then
      table.forEach(tos, function (id)
        table.insert(data.tos, {id})
      end)
    end
  end,
}
local xunshi_targetmod = fk.CreateTargetModSkill{
  name = "#xunshi_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return player:hasSkill(xunshi.name) and card and card.color == Card.NoColor
  end,
  bypass_distances =  function(self, player, skill, card)
    return player:hasSkill(xunshi.name) and card and card.color == Card.NoColor
  end,
}
shencai:addRelatedSkill(shencai_delay)
shencai:addRelatedSkill(shencai_maxcards)
xunshi:addRelatedSkill(xunshi_trigger)
xunshi:addRelatedSkill(xunshi_targetmod)
godzhangfei:addSkill(shencai)
godzhangfei:addSkill(xunshi)
Fk:loadTranslationTable{
  ["godzhangfei"] = "神张飞",
  ["shencai"] = "神裁",
  ["#shencai_delay"] = "神裁",
  [":shencai"] = "出牌阶段限一次，你可以令一名其他角色进行判定，你获得判定牌。若判定牌包含以下内容，其获得（已有标记则改为修改）对应标记：<br>"..
  "体力：“笞”标记，每次受到伤害后失去等量体力；<br>"..
  "武器：“杖”标记，无法响应【杀】；<br>"..
  "打出：“徒”标记，以此法外失去手牌后随机弃置一张手牌；<br>"..
  "距离：“流”标记，结束阶段将武将牌翻面；<br>"..
  "若判定牌不包含以上内容，该角色获得一个“死”标记且手牌上限减少其身上“死”标记个数，然后你获得其区域内一张牌。"..
  "“死”标记个数大于场上存活人数的角色回合结束时，其直接死亡。",
  ["xunshi"] = "巡使",
  ["#xunshi_trigger"] = "巡使",
  [":xunshi"] = "锁定技，你的多目标锦囊牌均视为无色【杀】。你使用无色牌无距离和次数限制且可以额外指定任意个目标，然后〖神裁〗的发动次数+1（至多为5）。",
  ["@@shencai_chi"] = "笞",
  ["@@shencai_zhang"] = "杖",
  ["@@shencai_tu"] = "徒",
  ["@@shencai_liu"] = "流",
  ["@shencai_si"] = "死",
  ["#shencai-active"] = "发动神裁，选择一名其他角色，令其判定",
  ["#xunshi-choose"] = "巡使：可为此【%arg】额外指定任意个目标",

  ["$shencai1"] = "我有三千炼狱，待汝万世轮回！",
  ["$shencai2"] = "纵汝王侯将相，亦须俯首待裁！",
  ["$xunshi1"] = "秉身为正，辟易万邪！",
  ["$xunshi2"] = "巡御两界，路寻不平！",
  ["~godzhangfei"] = "尔等，欲复斩我头乎？",
}

local godzhangjiao = General(extension, "godzhangjiao", "god", 3)
local yizhao = fk.CreateTriggerSkill{
  name = "yizhao",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.number > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n1 = tostring(player:getMark("@zhangjiao_huang"))
    room:addPlayerMark(player, "@zhangjiao_huang", math.min(data.card.number, 184 - player:getMark("@zhangjiao_huang")))
    local n2 = tostring(player:getMark("@zhangjiao_huang"))
    if #n1 == 1 then
      if #n2 == 1 then return end
    else
      if n1:sub(#n1 - 1, #n1 - 1) == n2:sub(#n2 - 1, #n2 - 1) then return end
    end
    local x = n2:sub(#n2 - 1, #n2 - 1)
    if x == 0 then x = 10 end  --yes, tenyear is so strange
    local card = room:getCardsFromPileByRule(".|"..x)
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
local sanshou = fk.CreateTriggerSkill{
  name = "sanshou",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    local yes = false
    for _, id in ipairs(cards) do
      if player:getMark("sanshou_"..Fk:getCardById(id):getTypeString().."-turn") == 0 then
        room:setCardEmotion(id, "judgegood")
        yes = true
      else
        room:setCardEmotion(id, "judgebad")
      end
    end
    room:delay(1000)
    room:moveCards({
      ids = cards,
      fromArea = Card.Processing,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    if yes then
      return true
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "sanshou_"..data.card:getTypeString().."-turn", 1)
  end,
}
local sijun = fk.CreateTriggerSkill{
  name = "sijun",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and
    player:getMark("@zhangjiao_huang") > #player.room.draw_pile
  end,
  on_use = function(self, event, tar, player, data)
    local room = player.room
    room:setPlayerMark(player, "@zhangjiao_huang", 0)
    room:shuffleDrawPile()
    local cards = {}
    if #room.draw_pile > 3 then
      local ret = {}
      local total = 36
      local numnums = {}
      local maxs = {}
      local pileToSearch = {}
      for i = 1, 13, 1 do
        table.insert(numnums, 0)
        table.insert(maxs, 36//i)
        table.insert(pileToSearch, {})
      end
      for _, id in ipairs(room.draw_pile) do
        local x = Fk:getCardById(id).number
        if x > 0 and x < 14 then
          table.insert(pileToSearch[x], id)
          if numnums[x] < maxs[x] then
            numnums[x] = numnums[x] + 1
          end
        end
      end
      local nums = {}
      for index, value in ipairs(numnums) do
        for _ = 1, value, 1 do
          table.insert(nums, index)
        end
      end
      local postsum = {}
      local nn = #nums
      postsum[nn+1] = 0
      for i = nn, 1, -1 do
        postsum[i] = postsum[i+1] + nums[i]
      end
      local function nSum(n, l, r, target)
        local ret = {}
        if n == 1 then
          for i = l, r, 1 do
            if nums[i] == target then
              table.insert(ret, {target})
              break
            end
          end
        elseif n == 2 then
          while l < r do
            local now = nums[l] + nums[r]
            if now > target then
              r = r - 1
            elseif now < target then
              l = l + 1
            else
              table.insert(ret, {nums[l], nums[r]})
              l = l + 1
              r = r - 1
              while l < r and nums[l] == nums[l-1] do
                l = l + 1
              end
              while l < r and nums[r] == nums[r+1] do
                r = r - 1
              end
            end
          end
        else
          for i = l, r-(n-1), 1 do
            if (i > l and nums[i] == nums[i-1]) or
              (nums[i] + postsum[r - (n-1) + 1] < target) then
            else
              if postsum[i] - postsum[i+n] > target then
                break
              end
              local v = nSum(n-1, i+1, r, target - nums[i])
              for j = 1, #v, 1 do
                table.insert(v[j], nums[i])
                table.insert(ret, v[j])
              end
            end
          end
        end
        return ret
      end
      for i = 3, total, 1 do
        table.insertTable(ret, nSum(i, 1, #nums, total))
      end
      if #ret > 0 then
        local compare = table.random(ret)
        table.sort(compare)
        local x = 0
        local current_n = compare[1]
        for _, value in ipairs(compare) do
          if value == current_n then
            x = x + 1
          else
            table.insertTable(cards, table.random(pileToSearch[current_n], x))
            x = 1
            current_n = value
          end
        end
        table.insertTable(cards, table.random(pileToSearch[current_n], x))
      end
    end
    if #cards == 0 then
      local tmp_drawPile = table.simpleClone(room.draw_pile)
      local sum = 0
      while sum < 36 and #tmp_drawPile > 0 do
        local id = table.remove(tmp_drawPile, math.random(1, #tmp_drawPile))
        sum = sum + Fk:getCardById(id).number
        table.insert(cards, id)
      end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
local tianjie = fk.CreateTriggerSkill{
  name = "tianjie",
  anim_type = "offensive",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if player:getMark(self.name) > 0 then
        player.room:setPlayerMark(player, self.name, 0)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 3, "#tianjie-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      local n = math.max(1, #table.filter(p.player_cards[Player.Hand], function(c) return Fk:getCardById(c).name == "jink" end))
      room:damage{
        from = player,
        to = p,
        damage = n,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    end
  end,

  refresh_events = {fk.AfterDrawPileShuffle},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, self.name, 1)
  end,
}
godzhangjiao:addSkill(yizhao)
godzhangjiao:addSkill(sanshou)
godzhangjiao:addSkill(sijun)
godzhangjiao:addSkill(tianjie)
Fk:loadTranslationTable{
  ["godzhangjiao"] = "神张角",
  ["yizhao"] = "异兆",
  [":yizhao"] = "锁定技，当你使用或打出一张牌后，获得等同于此牌点数的“黄”标记，然后若“黄”标记数的十位数变化，你随机获得牌堆中一张点数为变化后十位数的牌。",
  ["sanshou"] = "三首",
  [":sanshou"] = "当你受到伤害时，你可以亮出牌堆顶的三张牌，若其中有本回合所有角色均未使用过的牌的类型，防止此伤害。",
  ["sijun"] = "肆军",
  [":sijun"] = "准备阶段，若“黄”标记数大于牌堆里的牌数，你可以移去所有“黄”标记并洗牌，然后获得随机张点数之和为36的牌。",
  ["tianjie"] = "天劫",
  [":tianjie"] = "一名角色的回合结束时，若本回合牌堆进行过洗牌，你可以对至多三名其他角色各造成X点雷电伤害（X为其手牌中【闪】的数量且至少为1）。",
  ["@zhangjiao_huang"] = "黄",
  ["#tianjie-choose"] = "天劫：你可以对至多三名其他角色各造成X点雷电伤害（X为其手牌中【闪】数，至少为1）",
  
  ["$yizhao1"] = "苍天已死，此黄天当立之时。",
  ["$yizhao2"] = "甲子尚水，显炎汉将亡之兆。",
  ["$sanshou1"] = "三公既现，领大道而立黄天。",
  ["$sanshou2"] = "天地三才，载厚德以驱魍魉。",
  ["$sijun1"] = "联九州黎庶，撼一家之王庭。",
  ["$sijun2"] = "吾以此身为药，欲医天下之疾。",
  ["$tianjie1"] = "苍天既死，贫道当替天行道。",
  ["$tianjie2"] = "贫道张角，请大汉赴死！",
  ["~godzhangjiao"] = "诸君唤我为贼，然我所窃何物？",
}

local goddengai = General(extension, "goddengai", "god", 4)
local tuoyu = fk.CreateTriggerSkill{
  name = "tuoyu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
      table.find({"1", "2", "3"}, function(n) return player:getMark("tuoyu"..n) > 0 end) and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for i = 1, 3, 1 do
      if player:getMark("tuoyu"..i) > 0 then
        local cards = room:askForCard(player, 1, 5, false, self.name, true, ".", "#tuoyu"..i.."-cards")
        if #cards > 0 then
          for _, id in ipairs(player.player_cards[Player.Hand]) do
            local card = Fk:getCardById(id)
            if card:getMark("@@tuoyu"..i) > 0 and not table.contains(cards, id) then
              room:setCardMark(card, "@@tuoyu"..i, 0)
            elseif table.contains(cards, id) then
              for j = 1, 3, 1 do
                room:setCardMark(card, "@@tuoyu"..j, 0)
              end
              room:setCardMark(card, "@@tuoyu"..i, 1)
            end
          end
        end
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      return true
    elseif event == fk.EventLoseSkill then
      return target == player and data == self
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.toArea ~= Card.Processing then
          for _, info in ipairs(move.moveInfo) do
            room:setCardMark(Fk:getCardById(info.cardId), "@@tuoyu1", 0)
            room:setCardMark(Fk:getCardById(info.cardId), "@@tuoyu2", 0)
            room:setCardMark(Fk:getCardById(info.cardId), "@@tuoyu3", 0)
          end
        end
      end
    elseif event == fk.EventLoseSkill then
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        room:setCardMark(Fk:getCardById(id), "@@tuoyu1", 0)
        room:setCardMark(Fk:getCardById(id), "@@tuoyu2", 0)
        room:setCardMark(Fk:getCardById(id), "@@tuoyu3", 0)
      end
    end
  end,
}
local tuoyu_targetmod = fk.CreateTargetModSkill{
  name = "#tuoyu_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if player:hasSkill("tuoyu") and card:getMark("@@tuoyu2") > 0 then
      return 999
    end
  end,
  distance_limit_func =  function(self, player, skill, card)
    if player:hasSkill("tuoyu") and card:getMark("@@tuoyu2") > 0 then
      return 999
    end
  end,
}
local tuoyu_trigger = fk.CreateTriggerSkill{
  name = "#tuoyu_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.card:getMark("@@tuoyu1") > 0 or data.card:getMark("@@tuoyu3") > 0)
  end,
  on_use = function(self, event, target, player, data)
    if data.card:getMark("@@tuoyu1") > 0 then
      if data.card.is_damage_card then
        data.additionalDamage = (data.additionalDamage or 0) + 1
      elseif data.card.name == "peach" or (data.card.name == "analeptic" and data.extra_data and data.extra_data.analepticRecover) then
        data.additionalRecover = (data.additionalRecover or 0) + 1
      end
      --[[if data.card.trueName == "slash" and data.extra_data and data.extra_data.drankBuff then
        data.additionalDamage = (data.additionalDamage or 0) + data.extra_data.drankBuff
      end]]--
    elseif data.card:getMark("@@tuoyu3") > 0 then
      data.disresponsiveList = table.map(player.room.alive_players, function(p) return p.id end)
    end
  end,
}
local xianjin = fk.CreateTriggerSkill{
  name = "xianjin",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:addPlayerMark(player, "xianjin_damage", 1)
      if player:getMark("xianjin_damage") < 2 then return end
      room:setPlayerMark(player, "xianjin_damage", 0)
    elseif event == fk.Damaged then
      room:addPlayerMark(player, "xianjin_damaged", 1)
      if player:getMark("xianjin_damaged") < 2 then return end
      room:setPlayerMark(player, "xianjin_damaged", 0)
    end
    self:doCost(event, target, player, data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = table.map(table.filter({"1", "2", "3"}, function(n)
      return player:getMark("tuoyu"..n) == 0 end), function(n) return "tuoyu"..n end)
    if #choices > 0 then
      local choice = room:askForChoice(player, choices, self.name, "#xianjin-choice", true)
      room:setPlayerMark(player, choice, 1)
    end
    if table.every(room.alive_players, function(p) return player:getHandcardNum() >= p:getHandcardNum() end) then
      player:drawCards(1, self.name)
    else
      player:drawCards(#table.filter({"1", "2", "3"}, function(n) return player:getMark("tuoyu"..n) > 0 end), self.name)
    end
  end,
}
local qijing = fk.CreateTriggerSkill{
  name = "qijing",
  frequency = Skill.Wake,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and
      #player.room.alive_players > 2 and  --傻逼
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("tuoyu1") > 0 and player:getMark("tuoyu2") > 0 and player:getMark("tuoyu3") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    if #room.alive_players > 2 then
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
        return p.id end), 1, 1, "#qijing-choose", self.name, false)
      if #to > 0 then
        to = room:getPlayerById(to[1])
        if to:getNextAlive() ~= player then
          local players = table.simpleClone(room.players)
          local n
          for i, v in ipairs(room.players) do
            if v == to then
              if i == #room.players then
                n = 1
              else
                n = i + 1
              end
              break
            end
          end
          players[n] = player
          for i = 1, #room.players do
            for j = 1, #room.players do
              if i ~= n and not table.contains(players, room.players[j]) then
                players[i] = room.players[j]
              end
            end
          end
          room.players = players
          local player_circle = {}
          for i = 1, #room.players do
            room.players[i].seat = i
            table.insert(player_circle, room.players[i].id)
          end
          for i = 1, #room.players - 1 do
            room.players[i].next = room.players[i + 1]
          end
          room.players[#room.players].next = room.players[1]
          room:doBroadcastNotify("ArrangeSeats", json.encode(player_circle))
        end
      end
    end
    room:handleAddLoseSkills(player, "cuixin", nil, true, false)
    player:gainAnExtraTurn(true)
  end,
}
local cuixin = fk.CreateTriggerSkill{
  name = "cuixin",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.extra_data and data.extra_data.cuixin_tos
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    if #data.extra_data.cuixin_tos == 1 then
      if #data.extra_data.cuixin_adjacent == 1 then
        if not player:isProhibited(player:getNextAlive(), data.card) then
          table.insert(targets, player:getNextAlive().id)
        else
          return
        end
      else
        for _, id in ipairs(data.extra_data.cuixin_adjacent) do
          if id ~= data.extra_data.cuixin_tos[1] then
            local p = room:getPlayerById(id)
            if not p.dead and not player:isProhibited(p, data.card) then
              table.insert(targets, id)
              break
            end
          end
        end
      end
    else
      for _, id in ipairs(data.extra_data.cuixin_adjacent) do
        local p = room:getPlayerById(id)
        if not p.dead and not player:isProhibited(p, data.card) then
          table.insert(targets, id)
        end
      end
    end
    if #targets == 0 then
      return
    elseif #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, "#cuixin-invoke::"..targets[1]..":"..data.card.name) then
        self.cost_data = targets[1]
        return true
      end
    elseif #targets == 2 then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#cuixin2-choose:::"..data.card.name, self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard(data.card.name, nil, player, player.room:getPlayerById(self.cost_data), self.name, true)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and not table.contains(data.card.skillNames, self.name) and
      data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local tos, adjacent = {}, {}
    for _, p in ipairs(room.alive_players) do
      if player:getNextAlive() == p or p:getNextAlive() == player then
        table.insertIfNeed(adjacent, p.id)
        if table.contains(TargetGroup:getRealTargets(data.tos), p.id) then
          table.insertIfNeed(tos, p.id)
        end
      end
    end
    if #tos > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.cuixin_tos = tos
      data.extra_data.cuixin_adjacent = adjacent
    end
  end,
}
tuoyu:addRelatedSkill(tuoyu_targetmod)
tuoyu:addRelatedSkill(tuoyu_trigger)
goddengai:addSkill(tuoyu)
goddengai:addSkill(xianjin)
goddengai:addSkill(qijing)
goddengai:addRelatedSkill(cuixin)
Fk:loadTranslationTable{
  ["goddengai"] = "神邓艾",
  ["tuoyu"] = "拓域",
  [":tuoyu"] = "锁定技，你的手牌区域添加三个未开发的副区域：<br>丰田：伤害和回复值+1；<br>清渠：无距离和次数限制；<br>峻山：不能被响应。<br>"..
  "出牌阶段开始时和结束时，你将手牌分配至已开发的副区域中，每个区域至多五张。",
  ["xianjin"] = "险进",
  [":xianjin"] = "锁定技，你每造成或受到两次伤害后开发一个手牌副区域，摸X张牌（X为你已开发的手牌副区域数，若你手牌全场最多则改为1）。",
  ["qijing"] = "奇径",
  [":qijing"] = "觉醒技，每个回合结束时，若你的手牌副区域均已开发，你减1点体力上限，将座次移动至两名其他角色之间，获得〖摧心〗并执行一个额外回合。",
  ["cuixin"] = "摧心",
  [":cuixin"] = "当你不以此法对上家/下家使用的牌结算后，你可以视为对下家/上家使用一张同名牌。",
  ["tuoyu1"] = "丰田",
  ["@@tuoyu1"] = "丰田",
  [":tuoyu1"] = "伤害和回复值+1",
  ["#tuoyu1-cards"] = "拓域：你可以将至多五张手牌置入“丰田”（伤害和回复值+1）",
  ["tuoyu2"] = "清渠",
  ["@@tuoyu2"] = "清渠",
  [":tuoyu2"] = "无距离和次数限制",
  ["#tuoyu2-cards"] = "拓域：你可以将至多五张手牌置入“清渠”（无距离和次数限制）",
  ["tuoyu3"] = "峻山",
  ["@@tuoyu3"] = "峻山",
  [":tuoyu3"] = "不能被响应",
  ["#tuoyu3-cards"] = "拓域：你可以将至多五张手牌置入“峻山”（不能被响应）",
  ["#xianjin-choice"] = "险进：选择你要开发的手牌副区域",
  ["#qijing-choose"] = "奇径：选择一名角色，你移动座次成为其下家",
  ["#cuixin-invoke"] = "摧心：你可以视为对 %dest 使用【%arg】",
  ["#cuixin2-choose"] = "摧心：你可以视为对其中一名角色使用【%arg】",

  ["$tuoyu1"] = "本尊目之所及，皆为麾下王土。",
  ["$tuoyu2"] = "擎五丁之神力，碎万仞之高山。",
  ["$xianjin1"] = "大风！大雨！大景！！",
  ["$xianjin2"] = "行役沙场，不战胜，则战死！",
  ["$qijing1"] = "今神兵于天降，贯奕世之长虹！",
  ["$qijing2"] = "辟罗浮之险径，捣伪汉之黄龙！",
  ["$cuixin1"] = "今兵临城下，其王庭可摧。",
  ["$cuixin2"] = "四面皆奏楚歌，问汝降是不降？",
  ["~goddengai"] = "灭蜀者，邓氏士载也！",
}

--百战虎贲：兀突骨 文鸯 皇甫嵩 王双 留赞 黄祖 雷铜 吴兰 陈泰
local wutugu = General(extension, "ty__wutugu", "qun", 15)
local ty__ranshang = fk.CreateTriggerSkill{
  name = "ty__ranshang",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.Damaged then
        return data.damageType == fk.FireDamage
      else
        return player.phase == Player.Finish and player:getMark("@wutugu_ran") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      room:addPlayerMark(player, "@wutugu_ran", data.damage)
    else
      room:loseHp(player, player:getMark("@wutugu_ran"), self.name)
      if not player.dead and player:getMark("@wutugu_ran") > 2 then
        room:changeMaxHp(player, -2)
        if not player.dead then
          player:drawCards(2, self.name)
        end
      end
    end
  end,
}
local ty__hanyong = fk.CreateTriggerSkill{
  name = "ty__hanyong",
  anim_type = "offensive",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:isWounded() and
      (table.contains({"savage_assault", "archery_attack"}, data.card.trueName) or (data.card.name == "slash" and data.card.suit == Card.Spade))
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__hanyong-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.additionalDamage = (data.additionalDamage or 0) + 1
    if player.hp > room:getTag("RoundCount") then
      room:addPlayerMark(player, "@wutugu_ran", 1)
    end
  end,
}
wutugu:addSkill(ty__ranshang)
wutugu:addSkill(ty__hanyong)
Fk:loadTranslationTable{
  ["ty__wutugu"] = "兀突骨",
  ["ty__ranshang"] = "燃殇",
  [":ty__ranshang"] = "锁定技，当你受到1点火焰伤害后，你获得1枚“燃”标记；结束阶段，你失去X点体力（X为“燃”标记数），"..
  "然后若“燃”标记的数量超过2个，则你减2点体力上限并摸两张牌。",
  ["ty__hanyong"] = "悍勇",
  [":ty__hanyong"] = "当你使用【南蛮入侵】、【万箭齐发】或♠普通【杀】时，若你已受伤，你可以令此牌造成的伤害+1，然后若你的体力值大于游戏轮数，"..
  "你获得一个“燃”标记。",
  ["#ty__hanyong-invoke"] = "悍勇：你可以令此%arg伤害+1",
}

local wenyang = General(extension, "wenyang", "wei", 5)
local lvli = fk.CreateTriggerSkill{
  name = "lvli",
  anim_type = "drawcard",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player:getHandcardNum() ~= player.hp then
      if player:getHandcardNum() > player.hp and not player:isWounded() then return end
      local n = 1
      if player:usedSkillTimes("choujue", Player.HistoryGame) > 0 then
        if player.phase ~= Player.NotActive then
          n = 2
        end
      end
      if event == fk.Damage then
        return player:usedSkillTimes(self.name) < n
      else
        return player:usedSkillTimes("beishui", Player.HistoryGame) > 0 and player:usedSkillTimes(self.name) < n
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getHandcardNum() - player.hp
    if n < 0 then
      player:drawCards(-n, self.name)
    else
      player.room:recover{
        who = player,
        num = math.min(n, player:getLostHp()),
        recoverBy = player,
        skillName = self.name
      }
    end
  end
}
local choujue = fk.CreateTriggerSkill{
  name = "choujue",
  anim_type = "special",
  frequency = Skill.Wake,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return math.abs(player:getHandcardNum() - player.hp) > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "beishui", nil)
  end,
}
local beishui = fk.CreateTriggerSkill{
  name = "beishui",
  anim_type = "special",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getHandcardNum() < 2 or player.hp < 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, self.name, 1)
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "qingjiao", nil)
  end,
}
local qingjiao = fk.CreateTriggerSkill{
  name = "qingjiao",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("h")
    
    local wholeCards = table.clone(room.draw_pile)
    table.insertTable(wholeCards, room.discard_pile)

    local cardSubtypeStrings = {
      [Card.SubtypeWeapon] = "weapon",
      [Card.SubtypeArmor] = "armor",
      [Card.SubtypeDefensiveRide] = "defensive_horse",
      [Card.SubtypeOffensiveRide] = "offensive_horse",
      [Card.SubtypeTreasure] = "treasure",
    }

    local cardDic = {}
    for _, id in ipairs(wholeCards) do
      local card = Fk:getCardById(id)
      local cardName = card.type == Card.TypeEquip and cardSubtypeStrings[card.sub_type] or card.trueName
      cardDic[cardName] = cardDic[cardName] or {}
      table.insert(cardDic[cardName], id)
    end

    local toObtain = {}
    while #toObtain < 8 and next(cardDic) ~= nil do
      local dicLength = 0
      for _, ids in pairs(cardDic) do
        dicLength = dicLength + #ids
      end

      local randomIdx = math.random(1, dicLength)
      dicLength = 0
      for cardName, ids in pairs(cardDic) do
        dicLength = dicLength + #ids
        if dicLength >= randomIdx then
          table.insert(toObtain, ids[dicLength - randomIdx + 1])
          cardDic[cardName] = nil
          break
        end
      end
    end

    if #toObtain > 0 then
      room:moveCards({
        ids = toObtain,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player:throwAllCards("he")
  end,
}
wenyang:addSkill(lvli)
wenyang:addSkill(choujue)
wenyang:addRelatedSkill(beishui)
wenyang:addRelatedSkill(qingjiao)
Fk:loadTranslationTable{
  ["wenyang"] = "文鸯",
  ["lvli"] = "膂力",
  [":lvli"] = "每名角色的回合限一次，当你造成伤害后，你可以将手牌摸至与体力值相同或将体力回复至与手牌数相同。",
  ["choujue"] = "仇决",
  [":choujue"] = "觉醒技，每名角色的回合结束时，若你的手牌数和体力值相差3或更多，你减1点体力上限并获得〖背水〗，"..
  "然后修改〖膂力〗为“每名其他角色的回合限一次（在自己的回合限两次）”。",
  ["beishui"] = "背水",
  [":beishui"] = "觉醒技，准备阶段，若你的手牌数或体力值小于2，你减1点体力上限并获得〖清剿〗，然后修改〖膂力〗为“当你造成或受到伤害后”。",
  ["qingjiao"] = "清剿",
  [":qingjiao"] = "出牌阶段开始时，你可以弃置所有手牌，然后从牌堆或弃牌堆中随机获得八张牌名各不相同且副类别不同的牌。若如此做，结束阶段，你弃置所有牌。",

  ["$lvli1"] = "此击若中，万念俱灰！",
  ["$lvli2"] = "姿器膂力，万人之雄。",
  ["$choujue1"] = "家仇未报，怎可独安？",
  ["$choujue2"] = "逆臣之军，不足畏惧！",
  ["$beishui1"] = "某若退却半步，诸将可立斩之！",
  ["$beishui2"] = "效淮阴之举，力敌数千！",
  ["$qingjiao1"] = "慈不掌兵，义不养财！",
  ["$qingjiao2"] = "清蛮夷之乱，剿不臣之贼！",
  ["~wenyang"] = "痛贯心膂，天灭大魏啊！",
}

local huangfusong = General(extension, "ty__huangfusong", "qun", 4)
local ty__fenyue = fk.CreateActiveSkill{
  name = "ty__fenyue",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) < player:getMark(self.name)
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
      if pindian.fromCard.number < 6 then
        if not target:isNude() then
          local id = room:askForCardChosen(player, target, "he", self.name)
          room:obtainCard(player, id, false, fk.ReasonPrey)
        end
      end
      if pindian.fromCard.number < 10 then
        local card = room:getCardsFromPileByRule("slash")
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
      end
      if pindian.fromCard.number < 14 then
        room:useVirtualCard("thunder__slash", nil, player, target, self.name, true)
      end
    end
  end,
}
local ty__fenyue_record = fk.CreateTriggerSkill{
  name = "#ty__fenyue_record",

  refresh_events = {fk.GameStart, fk.BeforeGameOverJudge},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local n = 0
      if room.settings.gameMode == "aaa_role_mode" then
        local total = #room.alive_players
        if player.role == "lord" or player.role == "loyalist" then
          if total == 8 then n = 4
          elseif total == 7 or total == 6 then n = 3
          elseif total == 5 then n = 2
          else n = 1
          end
        elseif player.role == "rebel" then
          if total == 8 or total == 7 then n = 4
          elseif total == 6 or total == 5 or total == 4 then n = 3
          elseif total == 3 then n = 2
          else n = 1
          end
        elseif player.role == "renegade" then
          n = total - 1
        end
      elseif room.settings.gameMode == "m_1v2_mode" or room.settings.gameMode == "m_2v2_mode" then
        n = 2
      end
      room:setPlayerMark(player, "ty__fenyue", n)
    else
      if player.role == "renegade" or target.role == "renegade" or
        (player.role == "lord" or player.role == "loyalist" and target.role == "rebel") or
        (player.role == "rebel" and target.role == "loyalist") then
        room:removePlayerMark(player, "ty__fenyue", 1)
      end
    end
  end,
}
ty__fenyue:addRelatedSkill(ty__fenyue_record)
huangfusong:addSkill(ty__fenyue)
Fk:loadTranslationTable{
  ["ty__huangfusong"] = "皇甫嵩",
  ["ty__fenyue"] = "奋钺",
  [":ty__fenyue"] = "出牌阶段限X次（X为与你不同阵营的存活角色数），你可以与一名角色拼点，若你赢，根据你拼点的牌的点数执行以下效果："..
  "小于等于K：视为对其使用一张雷【杀】；小于等于9：获得牌堆中的一张【杀】；小于等于5：获得其一张牌。",

  ["$ty__fenyue1"] = "逆贼势大，且扎营寨，击其懈怠。",
  ["$ty__fenyue2"] = "兵有其变，不在众寡。",
  ["~ty__huangfusong"] = "吾只恨黄巾未平，不能报效朝廷……",
}

local wangshuang = General(extension, "wangshuang", "wei", 8)
local zhuilie = fk.CreateTriggerSkill{
  name = "zhuilie",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and
      not player:inMyAttackRange(player.room:getPlayerById(data.to))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:addCardUseHistory(data.card.trueName, -1)
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|.|.|.|equip",
    }
    room:judge(judge)
    if judge.card.sub_type and (judge.card.sub_type == Card.SubtypeWeapon or
      judge.card.sub_type == Card.SubtypeOffensiveRide or judge.card.sub_type == Card.SubtypeDefensiveRide) then
      data.additionalDamage = (data.additionalDamage or 0) + room:getPlayerById(data.to).hp - 1
    else
      room:loseHp(player, 1, self.name)
    end
  end,
}
local zhuilie_targetmod = fk.CreateTargetModSkill{
  name = "#zhuilie_targetmod",
  distance_limit_func =  function(self, player, skill)
    if player:hasSkill(self.name) and skill.trueName == "slash_skill" then
      return 999
    end
  end,
}
zhuilie:addRelatedSkill(zhuilie_targetmod)
wangshuang:addSkill(zhuilie)
Fk:loadTranslationTable{
  ["wangshuang"] = "王双",
  ["zhuilie"] = "追猎",
  [":zhuilie"] = "锁定技，你使用【杀】无距离限制；当你使用【杀】指定你攻击范围外的一名角色为目标后，此【杀】不计入次数且你进行一次判定，"..
  "若结果为武器牌或坐骑牌，此【杀】伤害基数值增加至该角色的体力值，否则你失去1点体力。",

  ["$zhuilie1"] = "我喜欢，猎夺沙场的快感。",
  ["$zhuilie2"] = "追敌夺魂，猎尽贼寇。",
  ["~wangshuang"] = "我居然，被蜀军所击倒。",
}

local liuzan = General(extension, "ty__liuzan", "wu", 4)
local ty__fenyin = fk.CreateTriggerSkill{
  name = "ty__fenyin",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.phase ~= Player.NotActive then
      local room = player.room
      self.fenyin_draw = 0
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            room:addPlayerMark(player, "liji-turn", 1)  --move this to liji would be proper...
            local mark = "fenyin_"..Fk:getCardById(info.cardId):getSuitString().."-turn"
            if player:getMark(mark) == 0 then
              room:addPlayerMark(player, mark, 1)
              self.fenyin_draw = self.fenyin_draw + 1
            end
          end
        end
      end
      return self.fenyin_draw > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.fenyin_draw, self.name)
  end,
}
local liji = fk.CreateActiveSkill{
  name = "liji",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local n = 8
    if #Fk:currentRoom().alive_players < 5 then n = 4 end
    return player:getMark("liji-turn") >= n and player:usedSkillTimes(self.name, Player.HistoryPhase) < player:getMark("liji-turn")/n
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
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
  end,
}
liuzan:addSkill(ty__fenyin)
liuzan:addSkill(liji)
Fk:loadTranslationTable{
  ["ty__liuzan"] = "留赞",
  ["ty__fenyin"] = "奋音",
  [":ty__fenyin"] = "锁定技，你的回合内，每当有一种花色的牌进入弃牌堆后（每回合每种花色各限一次），你摸一张牌。",
  ["liji"] = "力激",
  [":liji"] = "出牌阶段限0次，你可以弃置一张牌然后对一名其他角色造成1点伤害。你的回合内，本回合进入弃牌堆的牌每次达到8的倍数张时"..
  "（存活人数小于5时改为4的倍数），此技能使用次数+1。",

  ["$ty__fenyin1"] = "斗志高歌，士气昂扬！",
  ["$ty__fenyin2"] = "抗音而歌，左右应之！",
  ["$liji1"] = "破敌搴旗，未尝负败！",
  ["$liji2"] = "鸷猛壮烈，万人不敌！",
  ["~ty__liuzan"] = "若因病困此，命矣。",
}

local huangzu = General(extension, "ty__huangzu", "qun", 4)
local jinggong = fk.CreateViewAsSkill{
  name = "jinggong",
  anim_type = "offensive",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local card = Fk:cloneCard("slash")
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local to = player.room:getPlayerById(TargetGroup:getRealTargets(use.tos)[1])
    use.additionalDamage = (use.additionalDamage or 0) + math.min(player:distanceTo(to), 5) - 1
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
}
local jinggong_targetmod = fk.CreateTargetModSkill{
  name = "#jinggong_targetmod",
  distance_limit_func =  function(self, player, skill, card)
    if card and table.contains(card.skillNames, "jinggong") then
      return 999
    end
  end,
}
local xiaojun = fk.CreateTriggerSkill{
  name = "xiaojun",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.firstTarget and #AimGroup:getAllTargets(data.tos) == 1 then
      local to = AimGroup:getAllTargets(data.tos)[1]
      return to ~= player.id and player.room:getPlayerById(to):getHandcardNum() > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = AimGroup:getAllTargets(data.tos)[1]
    return player.room:askForSkillInvoke(player, self.name, nil,
      "#xiaojun-invoke::"..to..":"..tostring(player.room:getPlayerById(to):getHandcardNum() // 2)..":"..data.card:getSuitString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(AimGroup:getAllTargets(data.tos)[1])
    local n = to:getHandcardNum() // 2
    local cards = room:askForCardsChosen(player, to, n, n, "h", self.name)
    room:throwCard(cards, self.name, to, player)
    if not player:isKongcheng() and data.card ~= Card.NoSuit and table.find(cards, function(id)
        return Fk:getCardById(id).suit == data.card.suit end) then
      room:askForDiscard(player, 1, 1, false, self.name, false)
    end
  end,
}
jinggong:addRelatedSkill(jinggong_targetmod)
huangzu:addSkill(jinggong)
huangzu:addSkill(xiaojun)
Fk:loadTranslationTable{
  ["ty__huangzu"] = "黄祖",
  ["jinggong"] = "精弓",
  [":jinggong"] = "你可以将装备牌当无距离限制的【杀】使用，此【杀】的伤害基数值改为X（X为你计算与该角色的距离且至多为5）。",
  ["xiaojun"] = "骁隽",
  [":xiaojun"] = "你使用牌指定其他角色为唯一目标后，你可以弃置其一半手牌（向下取整）。若其中有与你指定其为目标的牌花色相同的牌，"..
  "你弃置一张手牌。",
  ["#xiaojun-invoke"] = "骁隽：你可以弃置 %dest 一半手牌（%arg张），若其中有%arg2牌，你弃置一张手牌",
}

local leitong = General(extension, "leitong", "shu", 4)
local kuiji = fk.CreateActiveSkill{
  name = "kuiji",
  anim_type = "offensive",
  target_num = 0,
  card_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:hasDelayedTrick("supply_shortage")
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic and Fk:getCardById(to_select).color == Card.Black
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:cloneCard("supply_shortage")
    card:addSubcards(effect.cards)
    room:useCard{
      from = effect.from,
      tos = {{effect.from}},
      card = card,
    }
    player:drawCards(1, self.name)
    local targets = {}
    local n = 0
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.hp > n then
        n = p.hp
      end
    end
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.hp == n then
        table.insert(targets, p.id)
      end
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#kuiji-damage", self.name, true)
    if #to > 0 then
      room:damage{
        from = player,
        to = room:getPlayerById(to[1]),
        damage = 2,
        skillName = self.name,
      }
    end
  end,
}
local kuiji_trigger = fk.CreateTriggerSkill{
  name = "#kuiji_trigger",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.damage and data.damage.skillName == "kuiji"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local n = 999
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if p.hp < n then
        n = p.hp
      end
    end
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if p.hp == n and p:isWounded() then
        table.insert(targets, p.id)
      end
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#kuiji-recover::"..target.id, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
      player.room:recover({
        who = player.room:getPlayerById(self.cost_data),
        num = 1,
        recoverBy = player,
        skillName = "kuiji"
      })
  end,
}
kuiji:addRelatedSkill(kuiji_trigger)
leitong:addSkill(kuiji)
Fk:loadTranslationTable{
  ["leitong"] = "雷铜",
  ["kuiji"] = "溃击",
  [":kuiji"] = "出牌阶段限一次，你可以将一张黑色基本牌当作【兵粮寸断】对你使用，然后摸一张牌。若如此做，你可以对体力值最多的一名其他角色造成2点伤害。"..
  "该角色因此进入濒死状态时，你可令另一名体力值最少的角色回复1点体力。",
  ["#kuiji-damage"] = "溃击：你可以对其他角色中体力值最大的一名角色造成2点伤害",
  ["#kuiji-recover"] = "溃击：你可以令除 %dest 以外体力值最小的一名角色回复1点体力",
  ["#kuiji_trigger"] = "溃击",

  ["$kuiji1"] = "绝域奋击，孤注一掷。",
  ["$kuiji2"] = "舍得一身剐，不畏君王威。",
  ["~leitong"] = "翼德救我……",
}

local wulan = General(extension, "wulan", "shu", 4)
local cuoruiw = fk.CreateTriggerSkill{
  name = "cuoruiw",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if player:distanceTo(p) < 2 and not p:isAllNude() then
        table.insert(targets, p.id)
      end
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#cuoruiw-cost", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askForCardChosen(player, room:getPlayerById(self.cost_data), "hej", self.name)
    local color = Fk:getCardById(id).color
    room:throwCard({id}, self.name, room:getPlayerById(self.cost_data), player)
    local targets = {}
    local targets1 = {}
    local targets2 = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isKongcheng() then
        table.insertIfNeed(targets, p.id)
        table.insert(targets2, p.id)
      end
      if #p.player_cards[Player.Equip] > 0 then
        for _, id in ipairs(p.player_cards[Player.Equip]) do
          if Fk:getCardById(id).color == color then
            table.insertIfNeed(targets, p.id)
            table.insert(targets1, p.id)
            break
          end
        end
      end
    end
    table.removeOne(targets, self.cost_data)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#cuoruiw-use", self.name, true)
    local to
    if #tos > 0 then
      to = room:getPlayerById(tos[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    local choices = {}
    if table.contains(targets1, to.id) then
      table.insert(choices, "cuoruiw_equip")
    end
    if table.contains(targets2, to.id) then
      table.insert(choices, "cuoruiw_hand")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "cuoruiw_equip" then
      local ids = {}
      for _, id in ipairs(to.player_cards[Player.Equip]) do
        if Fk:getCardById(id).color == color then
          table.insert(ids, id)
        end
      end
      if #ids == 1 then
        room:throwCard(ids, self.name, to, player)
      else
        local throw = {}
        room:fillAG(player, ids)
        while #ids > 0 and #throw < 2 do
          local id = room:askForAG(player, ids, true, self.name)
          if id ~= nil then
            room:takeAG(player, id, {player})
            table.insert(throw, id)
            table.removeOne(ids, id)
          else
            break
          end
        end
        room:closeAG(player)
        room:throwCard(throw, self.name, to, player)
      end
    else
      local cards = room:askForCardsChosen(player, to, 1, 2, "h", self.name)
      to:showCards(cards)
      room:delay(1500)
      local dummy = Fk:cloneCard("dilu")
      for _, id in ipairs(cards) do
        if Fk:getCardById(id).color == color then
          dummy:addSubcard(id)
        end
      end
      if #dummy.subcards > 0 then
        room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
      end
    end
  end,
}
wulan:addSkill(cuoruiw)
Fk:loadTranslationTable{
  ["wulan"] = "吴兰",
  ["cuoruiw"] = "挫锐",
  [":cuoruiw"] = "出牌阶段开始时，你可以弃置一名你计算与其距离不大于1的角色区域里的一张牌。若如此做，你选择一项："..
  "1.弃置另一名其他角色装备区里至多两张与此牌颜色相同的牌；2.展示另一名其他角色的至多两张手牌，然后获得其中与此牌颜色相同的牌。",
  ["#cuoruiw-cost"] = "挫锐：你可以弃置距离不大于1的角色区域里的一张牌",
  ["#cuoruiw-use"] = "挫锐：选择另一名其他角色，弃置其至多两张颜色相同的装备，或展示其至多两张手牌",
  ["cuoruiw_equip"] = "弃置其至多两张颜色相同的装备",
  ["cuoruiw_hand"] = "展示其至多两张手牌并获得其中相同颜色牌",

  ["$cuoruiw1"] = "减辎疾行，挫敌军锐气。",
  ["$cuoruiw2"] = "外物当舍，摄敌为重。",
  ["~wulan"] = "蛮狗，尔敢杀我！",
}

local chentai = General(extension, "chentai", "wei", 4)
local jiuxianc = fk.CreateActiveSkill{
  name = "jiuxianc",
  anim_type = "support",
  card_num = function()
    return (1 + Self:getHandcardNum()) // 2
  end,
  target_num = 0,
  prompt = function(self)
    return "#jiuxianc:::"..(1 + Self:getHandcardNum()) // 2
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected < (1 + Self:getHandcardNum()) // 2 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:recastCard(effect.cards, player, self.name)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not player:isProhibited(p, Fk:cloneCard("duel")) end), function(p) return p.id end)
    if #targets > 0 and not player.dead then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#jiuxianc-slash", self.name, false)
      if #to > 0 then
        to = room:getPlayerById(to[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      targets = table.filter(room:getOtherPlayers(player), function(p) return to:inMyAttackRange(p) and p:isWounded() end)
      local use = {
        from = player.id,
        tos = {{to.id}},
        card = Fk:cloneCard("duel"),
      }
      use.card.skillName = self.name
      room:useCard(use)
      if not player.dead and use.damageDealt and use.damageDealt[to.id] then
        if to.dead then
          targets = table.map(table.filter(targets, function(p) return not p.dead and p:isWounded() end), function(p) return p.id end)
        else
          targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
            return to:inMyAttackRange(p) and p:isWounded() end), function(p) return p.id end)
        end
        if #targets > 0 then
          to = room:askForChoosePlayers(player, targets, 1, 1, "#jiuxianc-recover", self.name, true)
          if #to > 0 then
            room:recover({
              who = room:getPlayerById(to[1]),
              num = 1,
              recoverBy = player,
              skillName = self.name
            })
          end
        end
      end
    end
  end
}
local chenyong = fk.CreateTriggerSkill{
  name = "chenyong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and player:getMark("chenyong-turn") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(#player:getMark("chenyong-turn"), self.name)
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase < Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("chenyong-turn")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, data.card:getTypeString())
    room:setPlayerMark(player, "chenyong-turn", mark)
    if player:hasSkill(self.name, true) then
      room:setPlayerMark(player, "@chenyong-turn", #player:getMark("chenyong-turn"))
    end
  end,
}
chentai:addSkill(jiuxianc)
chentai:addSkill(chenyong)
Fk:loadTranslationTable{
  ["chentai"] = "陈泰",
  ["jiuxianc"] = "救陷",
  [":jiuxianc"] = "出牌阶段限一次，你可以重铸一半手牌（向上取整），然后视为使用一张【决斗】。此牌对目标角色造成伤害后，"..
  "你可令其攻击范围内的一名其他角色回复1点体力。",
  ["chenyong"] = "沉勇",
  [":chenyong"] = "结束阶段，你可以摸X张牌（X为本回合你使用过牌的类型数）。",
  ["#jiuxianc"] = "救陷：你可以重铸一半手牌（%arg张），然后视为使用一张【决斗】",
  ["#jiuxianc-slash"] = "救陷：选择一名角色，视为对其使用【决斗】",
  ["#jiuxianc-recover"] = "救陷：你可以令其中一名角色回复1点体力",
  ["@chenyong-turn"] = "沉勇",

  ["$jiuxianc1"] = "救袍泽于水火，返清明于天下。",
  ["$jiuxianc2"] = "与君共扼王旗，焉能见死不救。",
  ["$chenyong1"] = "将者，当泰山崩于前而不改色。",
  ["$chenyong2"] = "救将陷之城，焉求益兵之助。",
  ["~chentai"] = "公非旦，我非勃……",
}

local wangjun = General(extension, "ty__wangjun", "qun", 4)
wangjun.subkingdom = "jin"
local mianyao = fk.CreateTriggerSkill{
  name = "mianyao",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd, fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseEnd then
        return player:hasSkill(self.name) and player.phase == player.Draw and not player:isKongcheng()
      else
        return player:getMark("mianyao-turn") > 0 and data.to == Player.NotActive
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      local room = player.room
      local ids = table.filter(player:getCardIds("h"), function(id)
        return table.every(player:getCardIds("h"), function(id2)
          return Fk:getCardById(id).number <= Fk:getCardById(id2).number end) end)
      local cards = room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|.|.|.|"..table.concat(ids, ","), "#mianyao-invoke")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      local room = player.room
      player:showCards(self.cost_data)
      if player.dead then return end
      room:setPlayerMark(player, "mianyao-turn", Fk:getCardById(self.cost_data[1]).number)
      room:moveCards({
        ids = self.cost_data,
        from = player.id,
        fromArea = Player.Hand,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        drawPilePosition = math.random(1, #room.draw_pile),
      })
    else
      player:drawCards(player:getMark("mianyao-turn"), self.name)
    end
  end,
}
local changqu = fk.CreateActiveSkill{
  name = "changqu",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    if to_select == Self.id then return false end
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return target:getNextAlive() == Self or Self:getNextAlive() == target
    else
      if table.contains(selected, Self:getNextAlive().id) then
        if Fk:currentRoom():getPlayerById(selected[#selected]):getNextAlive() == target then
          return true
        end
      end
      if Fk:currentRoom():getPlayerById(selected[1]):getNextAlive() == Self then
        if target:getNextAlive().id == selected[#selected] then
          return true
        end
      end
    end
  end,
  feasible = function(self, selected, selected_cards)
    if #selected > 0 then
      local p1 = Fk:currentRoom():getPlayerById(selected[1])
      if not (p1:getNextAlive() == Self or Self:getNextAlive() == p1) then return false end
      if #selected == 1 then return true end
      if p1:getNextAlive() == Self then
        for i = 1, #selected - 1, 1 do
          if Fk:currentRoom():getPlayerById(selected[i+1]):getNextAlive() ~= Fk:currentRoom():getPlayerById(selected[i]) then
            return false
          end
        end
        return true
      end
      if Self:getNextAlive() == p1 then
        for i = 1, #selected - 1, 1 do
          if Fk:currentRoom():getPlayerById(selected[i]):getNextAlive() ~= Fk:currentRoom():getPlayerById(selected[i+1]) then
            return false
          end
        end
        return true
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = 0
    for _, id in ipairs(effect.tos) do
      local target = room:getPlayerById(id)
      if not target.dead then
        room:setPlayerMark(target, "@@battleship", 1)
        local cards = {}
        local x = math.max(n, 1)
        if target:getHandcardNum() >= x then
          cards = room:askForCard(target, x, x, false, self.name, true, ".", "#changqu-card:"..player.id.."::"..x)
        end
        if #cards > 0 then
          local dummy = Fk:cloneCard("dilu")
          dummy:addSubcards(cards)
          room:obtainCard(player, dummy, false, fk.ReasonGive)
          n = n + 1
        else
          room:doIndicate(player.id, {target.id})
          if not target.chained then
            target:setChainState(true)
          end
          room:setPlayerMark(target, "@changqu", x)
          room:setPlayerMark(target, "@@battleship", 0)
          break
        end
        room:setPlayerMark(target, "@@battleship", 0)
      end
      if player.dead then return end
    end
  end,
}
local changqu_trigger = fk.CreateTriggerSkill{
  name = "#changqu_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@changqu") > 0 and data.damageType ~= fk.NormalDamage
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("@changqu")
    player.room:setPlayerMark(player, "@changqu", 0)
  end,
}
local tongye = fk.CreateTriggerSkill{
  name = "tongye",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.Deathed, fk.DrawNCards},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and (event ~= fk.DrawNCards or (player == target and player:getMark("@tongye_count") > 3))
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n + 3
    else
      local room = player.room
      local kingdoms = {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      local x = 5 - #kingdoms
      if x > 0 then
        room:setPlayerMark(player, "@tongye_count", x)
      end
    end
  end,
}
local tongye_maxcards = fk.CreateMaxCardsSkill{
  name = "#tongye_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(tongye.name) and player:getMark("@tongye_count") > 0 then
      return 3
    end
  end,
}
local tongye_attackrange = fk.CreateAttackRangeSkill{
  name = "#tongye_attackrange",
  correct_func = function (self, from, to)
    if from:hasSkill(tongye.name) and from:getMark("@tongye_count") > 1 then
      return 3
    end
  end,
}
local tongye_targetmod = fk.CreateTargetModSkill{
  name = "#tongye_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:hasSkill(tongye.name) and player:getMark("@tongye_count") > 2 then
      return 3
    end
    return 0
  end,
}
changqu:addRelatedSkill(changqu_trigger)
tongye:addRelatedSkill(tongye_maxcards)
tongye:addRelatedSkill(tongye_attackrange)
tongye:addRelatedSkill(tongye_targetmod)
wangjun:addSkill(tongye)
wangjun:addSkill(changqu)
Fk:loadTranslationTable{
  ["ty__wangjun"] = "王濬",
  ["mianyao"] = "免徭",
  [":mianyao"] = "摸牌阶段结束时，你可以展示手牌中点数最小的一张牌并将之置于牌堆随机位置，若如此做，本回合结束时，你摸此牌点数张牌。",
  ["tongye"] = "统业",
  [":tongye"] = "锁定技，游戏开始时或有角色死亡后，若场上现存势力数：不大于4，你的手牌上限+3；不大于3，你的攻击范围+3；不大于2，你出牌阶段可以多使用三张【杀】；为1，你摸牌阶段多摸三张牌。",
  ["changqu"] = "长驱",
  [":changqu"] = "出牌阶段限一次，你可以<font color='red'>开一艘战舰</font>，从你的上家或下家开始选择任意名座次连续的其他角色，第一个目标角色获得战舰标记。"..
  "获得战舰标记的角色选择一项：1.交给你X张手牌，然后将战舰标记移动至下一个目标；2.下次受到的属性伤害+X，然后横置武将牌（X为本次选择1的次数，至少为1）。",
  ["#mianyao-invoke"] = "免徭：你可以将点数最小的手牌洗入牌堆，回合结束时摸其点数的牌",
  ["@@battleship"] = "战舰",
  ["#changqu-card"] = "长驱：交给 %src %arg张手牌以使战舰驶向下一名角色",
  ["@changqu"] = "长驱",
  ["@tongye_count"] = "统业",

  ["$tongye1"] = "白首全金瓯，著风流于春秋。",
  ["$tongye2"] = "长戈斩王气，统大业于四海。",
  ["$changqu1"] = "布横江之铁索，徒自缚耳。",
  ["$changqu2"] = "艨艟击浪，可下千里江陵。",
  ["~ty__wangjun"] = "未蹈曹刘覆辙，险遭士载之厄……",
}

local duyu = General(extension, "ty__duyu", "wei", 4)
duyu.subkingdom = "jin"
local jianguo = fk.CreateActiveSkill{
  name = "jianguo",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#jianguo",
  interaction = function(self)
    return UI.ComboBox { choices = {"jianguo1", "jianguo2"} }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if self.interaction.data == "jianguo1" then
      return #selected == 0
    elseif self.interaction.data == "jianguo2" then
      return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
    end
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    if self.interaction.data == "jianguo1" then
      target:drawCards(1, self.name)
      if not target.dead and target:getHandcardNum() > 1 then
        local n = target:getHandcardNum() // 2
        room:askForDiscard(target, n, n, false, self.name, false)
      end
    else
      room:askForDiscard(target, 1, 1, false, self.name, false)
      if not target.dead and target:getHandcardNum() > 1 then
        local n = target:getHandcardNum() // 2
        target:drawCards(n, self.name)
      end
    end
  end,
}
local qingshid = fk.CreateTriggerSkill{
  name = "qingshid",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase ~= Player.NotActive and
      player:getHandcardNum() == player:getMark("qingshid-turn") and
      data.tos and data.firstTarget and table.find(AimGroup:getAllTargets(data.tos), function(id) return id ~= player.id end)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, AimGroup:getAllTargets(data.tos), 1, 1, "#qingshid-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player.room:getPlayerById(self.cost_data),
      damage = 1,
      skillName = self.name,
    }
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "qingshid-turn", 1)
    if player:hasSkill(self.name, true) then
      room:setPlayerMark(player, "@qingshid-turn", player:getMark("qingshid-turn"))
    end
  end,
}
duyu:addSkill(jianguo)
duyu:addSkill(qingshid)
Fk:loadTranslationTable{
  ["ty__duyu"] = "杜预",
  ["jianguo"] = "谏国",
  [":jianguo"] = "出牌阶段限一次，你可以选择一项：令一名角色摸一张牌然后弃置一半的手牌（向下取整）；"..
  "令一名角色弃置一张牌然后摸与当前手牌数一半数量的牌（向下取整）",
  ["qingshid"] = "倾势",
  [":qingshid"] = "当你于回合内使用【杀】或锦囊牌指定其他角色为目标后，若此牌是你本回合使用的第X张牌（X为你的手牌数），你可以对其中一名目标角色造成1点伤害。",
  ["#jianguo"] = "谏国：你可以选择一项令一名角色执行（向下取整）",
  ["jianguo1"] = "摸一张牌，弃置一半手牌",
  ["jianguo2"] = "弃置一张牌，摸一半手牌",
  ["@qingshid-turn"] = "倾势",
  ["#qingshid-choose"] = "倾势：你可以对其中一名目标角色造成1点伤害",

  ["$jianguo1"] = "彭蠡雁惊，此诚平吴之时。",
  ["$jianguo2"] = "奏三陈之诏，谏一国之弊。",
  ["$qingshid1"] = "潮起万丈之仞，可阻江南春风。",
  ["$qingshid2"] = "缮甲兵，耀威武，伐吴指日可待。",
  ["~ty__duyu"] = "六合即归一统，奈何寿数已尽……",
}

--奇人异士：张宝 司马徽 蒲元 管辂 葛玄 杜夔 朱建平 吴范 赵直 周宣 笮融

--张宝 司马徽

local puyuan = General(extension, "ty__puyuan", "shu", 4)
local puyuan_equips = {"red_spear", "quenched_blade", "poisonous_dagger", "water_sword", "thunder_blade"}
local tianjiang = fk.CreateActiveSkill{
  name = "tianjiang",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return #player.player_cards[Player.Equip] > 0
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and #cards == 1 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:getCardById(effect.cards[1])
    local type = card.sub_type
    local ids = table.clone(effect.cards)
    room:moveCards({
      from = effect.from,
      ids = ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = self.name,
    })
    local move3 = {
      ids = ids,
      fromArea = Card.Processing,
      to = target.id,
      toArea = Card.PlayerEquip,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = self.name,
    }
    if target:getEquipment(type) ~= nil then
      local move2 = {
        ids = {target:getEquipment(type)},
        from = target.id,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
      }
      room:moveCards(move2, move3)
    else
      room:moveCards(move3)
    end
    if table.contains(puyuan_equips, card.name) then
      player:drawCards(2, self.name)
    end
  end,
}
local tianjiang_trigger = fk.CreateTriggerSkill{
  name = "#tianjiang_trigger",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    repeat
      local id = table.random(room.draw_pile)
      if Fk:getCardById(id).type == Card.TypeEquip then
        if #cards == 0 then
          table.insertIfNeed(cards, id)
        elseif Fk:getCardById(id).sub_type ~= Fk:getCardById(cards[1]).sub_type then
          table.insertIfNeed(cards, id)
        end
      end
    until #cards == 2
    room:moveCards({
      fromArea = Card.DrawPile,
      ids = table.random(cards, 2),
      to = player.id,
      toArea = Card.PlayerEquip,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    })
  end,
}
local zhuren = fk.CreateActiveSkill{
  name = "zhuren",
  anim_type = "special",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local card = Fk:getCardById(effect.cards[1])
    local name = "slash"
    if card.name == "lightning" then
      name = "thunder_blade"
    elseif card.suit == Card.Heart then
      name = "red_spear"
    elseif card.suit == Card.Diamond then
      name = "quenched_blade"
    elseif card.suit == Card.Spade then
      name = "poisonous_dagger"
    elseif card.suit == Card.Club then
      name = "water_sword"
    end
    if name ~= "slash" then
      for _, id in ipairs(Fk:getAllCardIds()) do
        if Fk:getCardById(id).name == name and Fk:currentRoom():getCardArea(id) ~= Card.Void then
          name = "slash"
          break
        end
      end
    end
    if name ~= "slash" and name ~= "lightning" then
      if (0 < card.number and card.number < 5 and math.random() > 0.85) or
        (4 < card.number and card.number < 9 and math.random() > 0.9) or
        (8 < card.number and card.number < 13 and math.random() > 0.95) then
        name = "slash"
      end
    end
    if name == "slash" then
      room:setCardEmotion(effect.cards[1], "judgebad")
    else
      room:setCardEmotion(effect.cards[1], "judgegood")
    end
    room:delay(1000)
    if name == "slash" then
      local ids = room:getCardsFromPileByRule("slash")
      if #ids > 0 then
        room:moveCards({
          ids = ids,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    else
      for _, id in ipairs(Fk:getAllCardIds()) do
        if Fk:getCardById(id).name == name then
          room:moveCards({
            ids = {id},
            fromArea = Card.Void,
            to = player.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = player.id,
            skillName = self.name,
          })
          break
        end
      end
    end
  end,
}
local zhuren_destruct = fk.CreateTriggerSkill{
  name = "#zhuren_destruct",

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name, true, true) then
      for _, move in ipairs(data) do
        return move.toArea == Card.DiscardPile
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      local ids = {}
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(puyuan_equips, Fk:getCardById(info.cardId).name) then
            table.insert(ids, info.cardId)
          end
        end
      end
      if #ids > 0 then
        for _, id in ipairs(ids) do
          player.room:sendLog{
            type = "#destructDerivedCard",
            arg = Fk:getCardById(id, true):toLogString(),
          }
          table.insert(player.room.void, id)
          player.room:setCardArea(id, Card.Void, nil)
        end
      end
    end
  end,
}
tianjiang:addRelatedSkill(tianjiang_trigger)
zhuren:addRelatedSkill(zhuren_destruct)
puyuan:addSkill(tianjiang)
puyuan:addSkill(zhuren)
Fk:loadTranslationTable{
  ["ty__puyuan"] = "蒲元",
  ["tianjiang"] = "天匠",
  [":tianjiang"] = "游戏开始时，你随机获得两张不同副类别的装备牌，并置入你的装备区。出牌阶段，你可以将装备区里的一张牌移动至其他角色的装备区"..
  "（可替换原装备），若你移动的是〖铸刃〗打造的装备，你摸两张牌。",
  ["zhuren"] = "铸刃",
  [":zhuren"] = "出牌阶段限一次，你可以弃置一张手牌。根据此牌的花色点数，你有一定概率打造成功并获得一张武器牌（若打造失败或武器已有则改为摸一张【杀】，"..
  "花色决定武器名称，点数决定成功率）。此武器牌进入弃牌堆时，将之移出游戏。",
  ["#tianjiang_trigger"] = "天匠",

  ["$tianjiang1"] = "巧夺天工，超凡脱俗。",
  ["$tianjiang2"] = "天赐匠法，精心锤炼。",
  ["$zhuren1"] = "造刀三千口，用法各不同。",
  ["$zhuren2"] = "此刀，可劈铁珠之筒。",
  ["~ty__puyuan"] = "铸木镂冰，怎成大器。",
}

local guanlu = General(extension, "guanlu", "wei", 3)
local tuiyan = fk.CreateTriggerSkill{
  name = "tuiyan",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room.draw_pile < 3 then
      room:shuffleDrawPile()
      if #room.draw_pile < 3 then
        room:gameOver("")
      end
    end
    local ids = {}
    for i = 1, 3, 1 do
      table.insert(ids, room.draw_pile[i])
    end
    room:fillAG(player, ids)
    room:delay(5000)
    room:closeAG(player)
  end,
}
local busuan = fk.CreateActiveSkill {
  name = "busuan",
  anim_type = "control",
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
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeBasic or card.type == Card.TypeTrick) and not card.is_derived then
        table.insertIfNeed(names, card.trueName)
      end
    end
    local mark = target:getMark(self.name)
    if mark == 0 then mark = {} end
    for i = 1, 2, 1 do
      local name = room:askForChoice(player, names, self.name)
      if name == "Cancel" then break end
      table.insert(mark, name)
      table.removeOne(names, name)
      if i == 1 then
        table.insert(names, "Cancel")
      end
    end
    room:setPlayerMark(target, self.name, mark)
  end,
}
local busuan_trigger = fk.CreateTriggerSkill {
  name = "#busuan_trigger",
  mute = true,
  events = {fk.BeforeDrawCard},
  can_trigger = function(self, event, target, player, data)
    return player == target and data.num > 0 and player.phase == Player.Draw and type(player:getMark(busuan.name)) == "table"
    --FIXME: can't find skillName(game_rule)!!
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local card_names = player:getMark(busuan.name)
    for i = 1, #card_names, 1 do
      table.insert(cards, -1)
    end
    for i = 1, #card_names, 1 do
      if cards[i] == -1 then
        local name = card_names[i]
        local x = #table.filter(card_names, function (card_name)
          return card_name == name end)

        local tosearch = room:getCardsFromPileByRule(name, x, "discardPile")
        if #tosearch < x then
          table.insertTable(tosearch, room:getCardsFromPileByRule(name, x - #tosearch))
        end

        for i2 = 1, #card_names, 1 do
          if card_names[i2] == name then
            if #tosearch > 0 then
              cards[i2] = tosearch[1]
              table.remove(tosearch, 1)
            else
              cards[i2] = -2
            end
          end
        end
      end
    end
    local to_get = {}
    local card_names_copy = table.clone(card_names)
    for i = 1, #card_names, 1 do
      if #to_get >= data.num then break end
      if cards[i] > -1 then
        table.insert(to_get, cards[i])
        table.removeOne(card_names_copy, card_names[i])
      end
    end
    
    room:setPlayerMark(player, busuan.name, (#card_names_copy > 0) and card_names_copy or 0)
    
    data.num = data.num - #to_get

    if #to_get > 0 then
      room:moveCards({
        ids = to_get,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = busuan.name,
        moveVisible = false,
      })
    end
  end,
}
local mingjie = fk.CreateTriggerSkill {
  name = "mingjie",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(player:drawCards(1)[1])
    if card.color == Card.Black then
      if player.hp > 1 then
        room:loseHp(player, 1, self.name)
      end
      return
    else
      for i = 1, 2, 1 do
        if room:askForSkillInvoke(player, self.name) then
          card = Fk:getCardById(player:drawCards(1)[1])
          if card.color == Card.Black then
            if player.hp > 1 then
              room:loseHp(player, 1, self.name)
            end
            return
          end
        else
          return
        end
      end
    end
  end,
}
busuan:addRelatedSkill(busuan_trigger)
guanlu:addSkill(tuiyan)
guanlu:addSkill(busuan)
guanlu:addSkill(mingjie)
Fk:loadTranslationTable{
  ["guanlu"] = "管辂",
  ["tuiyan"] = "推演",
  [":tuiyan"] = "出牌阶段开始时，你可以观看牌堆顶的三张牌。",
  ["busuan"] = "卜算",
  [":busuan"] = "出牌阶段限一次，你可以选择一名其他角色，然后选择至多两张不同的卡牌名称（限基本牌或锦囊牌）。"..
  "该角色下次摸牌阶段摸牌时，改为从牌堆或弃牌堆中获得你选择的牌。",
  ["mingjie"] = "命戒",
  [":mingjie"] = "结束阶段，你可以摸一张牌，若此牌为红色，你可以重复此流程直到摸到黑色牌或摸到第三张牌。当你以此法摸到黑色牌时，"..
  "若你的体力值大于1，你失去1点体力。",

  ["$tuiyan1"] = "鸟语略知，万物略懂。",
  ["$tuiyan2"] = "玄妙之舒巧，推微而知晓。",
  ["$busuan1"] = "今日一卦，便知命数。",
  ["$busuan2"] = "喜仰视星辰，夜不肯寐。",
  ["$mingjie1"] = "戒律循规，不可妄贪。",
  ["$mingjie2"] = "王道文明，何忧不平。",
  ["~guanlu"] = "怀我好英，心非草木……",
}

local gexuan = General(extension, "gexuan", "wu", 3)
local lianhua = fk.CreateTriggerSkill{
  name = "lianhua",
  anim_type = "special",
  events = {fk.Damaged, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.Damaged then
        return target ~= player and player.phase == Player.NotActive
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      local color = "black"
      if table.contains({"lord", "loyalist"}, player.role) and table.contains({"lord", "loyalist"}, player.role) or
        (player.role == target.role) then
        color = "red"
      end
      room:addPlayerMark(player, "lianhua-"..color, 1)
      room:setPlayerMark(player, "@lianhua", player:getMark("lianhua-red") + player:getMark("lianhua-black"))
    elseif event == fk.EventPhaseStart then
      local pattern, skill
      if player:getMark("@lianhua") < 4 then
        pattern, skill = "peach", "ex__yingzi"
      else
        if player:getMark("lianhua-red") > player:getMark("lianhua-black") then
          pattern, skill = "ex_nihilo", "ex__guanxing"
        elseif player:getMark("lianhua-red") < player:getMark("lianhua-black") then
          pattern, skill = "snatch", "zhiyan"
        elseif player:getMark("lianhua-red") == player:getMark("lianhua-black") then
          pattern, skill = "slash", "gongxin"
        end
      end
      local cards = room:getCardsFromPileByRule(pattern)
      if player:getMark("@lianhua") > 3 and player:getMark("lianhua-red") == player:getMark("lianhua-black") then
        table.insertTable(cards, room:getCardsFromPileByRule("duel"))
      end
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
      if not player:hasSkill(skill, true) then
        room:setPlayerMark(player, "lianhua-turn", skill)
        room:handleAddLoseSkills(player, skill, nil, true, false)
      end
    end
  end,
}
local lianhua_trigger = fk.CreateTriggerSkill{
  name = "#lianhua_trigger",
  mute = true,
  events = {fk.EventPhaseStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseStart then
        return player:getMark("@lianhua") > 0 and player.phase == Player.Play
      elseif event == fk.TurnEnd then
        return player:getMark("lianhua-turn") ~= 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(player, "@lianhua", 0)
      room:setPlayerMark(player, "lianhua-red", 0)
      room:setPlayerMark(player, "lianhua-black", 0)
    elseif event == fk.TurnEnd then
      room:handleAddLoseSkills(player, "-"..player:getMark("lianhua-turn"), nil, true, false)
    end
  end,
}
local zhafu = fk.CreateActiveSkill{
  name = "zhafu",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = target:getMark("@@zhafu")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, player.id)
    room:setPlayerMark(target, "@@zhafu", mark)
  end,
}
local zhafu_trigger = fk.CreateTriggerSkill{
  name = "#zhafu_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and player:getMark("@@zhafu") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local src = room:getPlayerById(player:getMark("@@zhafu")[1])
    room:setPlayerMark(player, "@@zhafu", 0)
    if player:getHandcardNum() < 2 or src.dead then return end
    room:doIndicate(src.id, {player.id})
    src:broadcastSkillInvoke("zhafu")
    room:notifySkillInvoked(src, "zhafu", "control")
    local card = room:askForCard(player, 1, 1, false, "zhafu", false, ".|.|.|hand", "#zhafu-invoke:"..src.id)
    if #card > 0 then
      card = card[1]
    else
      card = table.random(player.player_cards[Player.Hand])
    end
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(table.filter(player.player_cards[Player.Hand], function(id) return id ~= card end))
    room:obtainCard(src, dummy, false, fk.ReasonGive)
  end,
}
lianhua:addRelatedSkill(lianhua_trigger)
zhafu:addRelatedSkill(zhafu_trigger)
gexuan:addSkill(lianhua)
gexuan:addSkill(zhafu)
gexuan:addRelatedSkill("ex__yingzi")
gexuan:addRelatedSkill("ex__guanxing")
gexuan:addRelatedSkill("zhiyan")
gexuan:addRelatedSkill("gongxin")
Fk:loadTranslationTable{
  ["gexuan"] = "葛玄",
  ["lianhua"] = "炼化",
  [":lianhua"] = "你的回合外，当其他角色受到伤害后，你获得一枚“丹血”标记（阵营与你相同为红色，不同则为黑色，颜色不可见）直到你的出牌阶段开始。<br>"..
  "准备阶段，根据“丹血”标记的数量和颜色，你获得相应的游戏牌，获得相应的技能直到回合结束：<br>"..
  "3枚或以下：【桃】和〖英姿〗；<br>"..
  "超过3枚且红色“丹血”较多：【无中生有】和〖观星〗；<br>"..
  "超过3枚且黑色“丹血”较多：【顺手牵羊】和〖直言〗；<br>"..
  "超过3枚且红色和黑色一样多：【杀】、【决斗】和〖攻心〗。",
  ["zhafu"] = "札符",
  [":zhafu"] = "限定技，出牌阶段，你可以选择一名其他角色。该角色的下个弃牌阶段开始时，其选择保留一张手牌，将其余手牌交给你。",
  ["@lianhua"] = "丹血",
  ["@@zhafu"] = "札符",
  ["#zhafu-invoke"] = "札符：选择一张保留的手牌，其他手牌全部交给 %src ！",

  ["$lianhua1"] = "白日青山，飞升化仙。",
  ["$lianhua2"] = "草木精炼，万物化丹。",
  ["$zhafu1"] = "垂恩广救，慈悲在怀。",
  ["$zhafu2"] = "行符敕鬼，神变善易。",
  ["$ex__yingzi_gexuan"] = "仙人之姿，凡目岂见！",
  ["$zhiyan_gexuan"] = "仙人之语，凡耳震聩！",
  ["$gongxin_gexuan"] = "仙人之目，因果即现！",
  ["$ex__guanxing_gexuan"] = "仙人之栖，群星浩瀚！",
  ["~gexuan"] = "善变化，拙用身。",
}

--杜夔

local zhujianping = General(extension, "zhujianping", "qun", 3)
local xiangmian = fk.CreateActiveSkill{
  name = "xiangmian",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("xiangmian_suit") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    room:setPlayerMark(target, "xiangmian_suit", judge.card:getSuitString(true))
    room:setPlayerMark(target, "xiangmian_num", judge.card.number)
    room:setPlayerMark(target, "@xiangmian", string.format("%s%d", Fk:translate(target:getMark("xiangmian_suit")), target:getMark("xiangmian_num")))
  end,
}
local xiangmian_record = fk.CreateTriggerSkill{
  name = "#xiangmian_record",
  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and target:getMark("xiangmian_num") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card:getSuitString(true) == target:getMark("xiangmian_suit") or target:getMark("xiangmian_num") == 1 then
      room:setPlayerMark(target, "xiangmian_num", 0)
      room:setPlayerMark(target, "@xiangmian", 0)
      room:loseHp(target, target.hp, "xiangmian")
    else
      room:addPlayerMark(target, "xiangmian_num", -1)
      room:setPlayerMark(target, "@xiangmian", string.format("%s%d",Fk:translate(target:getMark("xiangmian_suit")), target:getMark("xiangmian_num")))
    end
  end,
}
local tianji = fk.CreateTriggerSkill{
  name = "tianji",
  events = {fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonJudge then
          self.cost_data = move
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local move = self.cost_data
    for _, info in ipairs(move.moveInfo) do
      local card = Fk:getCardById(info.cardId, true)
      local cards = {}
      local bigNumber = #room.draw_pile
      local rule = { ".|.|.|.|.|"..card:getTypeString(), ".|.|"..card:getSuitString(), ".|"..card.number }
      for _, r in ipairs(rule) do
        local targetCards = table.filter(room:getCardsFromPileByRule(r, bigNumber), function(cid) return not table.contains(cards, cid) end)
        if #targetCards > 0 then
          local loc = math.random(1, #targetCards)
          table.insert(cards, targetCards[loc])
        end
      end
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
xiangmian:addRelatedSkill(xiangmian_record)
zhujianping:addSkill(xiangmian)
zhujianping:addSkill(tianji)
Fk:loadTranslationTable{
  ["zhujianping"] = "朱建平",
  ["xiangmian"] = "相面",
  [":xiangmian"] = "出牌阶段限一次，你可以令一名其他角色进行一次判定，当该角色使用判定花色的牌或使用第X张牌后（X为判定点数），其失去所有体力。"..
  "每名其他角色限一次。",
  ["tianji"] = "天机",
  [":tianji"] = "锁定技，生效后的判定牌进入弃牌堆后，你从牌堆随机获得与该牌类型、花色和点数相同的牌各一张。",
  ["@xiangmian"] = "相面",

  ["$xiangmian1"] = "以吾之见，阁下命不久矣。",
  ["$xiangmian2"] = "印堂发黑，将军危在旦夕。",
  ["$tianji1"] = "顺天而行，坐收其利。",
  ["$tianji2"] = "只可意会，不可言传。",
  ["~zhujianping"] = "天机，不可泄露啊……",
}

local wufan = General(extension, "wufan", "wu", 4)
local tianyun = fk.CreateTriggerSkill{
  name = "tianyun",
  events = {fk.GameStart, fk.TurnStart},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.GameStart then
      local suits = {"spade", "heart", "club", "diamond"}
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        table.removeOne(suits, Fk:getCardById(id):getSuitString())
      end
      return #suits > 0
    elseif event == fk.TurnStart then
      return target.seat == player.room:getTag("RoundCount") and not player:isKongcheng()
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    elseif event == fk.TurnStart then
      return player.room:askForSkillInvoke(player, self.name)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "heart", "club", "diamond"}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      table.removeOne(suits, Fk:getCardById(id):getSuitString())
    end
    if event == fk.GameStart then
      local cards = {}
      while #suits > 0 do
        local pattern = table.random(suits)
        table.removeOne(suits, pattern)
        table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
      end
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
    elseif event == fk.TurnStart then
      local x = 4-#suits
      if x == 0 then return false end
      local result = room:askForGuanxing(player, room:getNCards(x))
      if #result.top == 0 then
        local targets = player.room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper),
        1, 1, "#tianyun-choose:::" .. tostring(x), self.name, true)
        if #targets > 0 then
          room:drawCards(room:getPlayerById(targets[1]), x, self.name)
          if not player.dead then
            room:loseHp(player, 1, self.name)
          end
        end
      end
    end
  end,
}

local yuyan = fk.CreateTriggerSkill{
  name = "yuyan",
  anim_type = "control",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper),
    1, 1, "#yuyan-choose", self.name, true, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "yuyan-round", self.cost_data)
  end,
}
local yuyan_delay = fk.CreateTriggerSkill{
  name = "#yuyan_delay",
  anim_type = "control",
  events = {fk.AfterDying, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target == nil or player.dead or player:getMark("yuyan-round") ~= target.id then return false end
    local room = player.room
    if event == fk.AfterDying then
      --FIXME:exit_funcs时，无法获取当前事件的信息（迷信规则集不可取……）
      if player:getMark("yuyan_dying_effected-round") > 0 then return false end
      local x = player:getMark("yuyan_dying_record-round")
      if x == 0 then
        room.logic:getEventsOfScope(GameEvent.Dying, 1, function (e)
          local dying = e.data[1]
          x = dying.who
          room:setPlayerMark(player, "yuyan_dying_record-round", x)
          return true
        end, Player.HistoryRound)
      end
      return target.id == x
    elseif event == fk.Damage then
      local damage_event = room.logic:getCurrentEvent()
      if not damage_event then return false end
      local x = player:getMark("yuyan_damage_record-round")
      if x == 0 then
        room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          local reason = e.data[3]
          if reason == "damage" then
            local first_damage_event = e:findParent(GameEvent.Damage)
            if first_damage_event then
              x = first_damage_event.id
              room:setPlayerMark(player, "yuyan_damage_record-round", x)
            end
            return true
          end
        end, Player.HistoryRound)
      end
      return damage_event.id == x
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(yuyan.name)
    player.room:addPlayerMark(target, "@@yuyan-round")
    if event == fk.AfterDying then
      player.room:addPlayerMark(player, "yuyan_dying_effected-round")
      if not player:hasSkill("ty__fenyin", true) then
        player.room:addPlayerMark(player, "yuyan_tmpfenyin")
        player.room:handleAddLoseSkills(player, "ty__fenyin", nil, true, false)
      end
    elseif event == fk.Damage then
      player:drawCards(2, yuyan.name)
    end
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("yuyan_tmpfenyin") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-ty__fenyin", nil, true, false)
  end,
}

yuyan:addRelatedSkill(yuyan_delay)
wufan:addSkill(tianyun)
wufan:addSkill(yuyan)
wufan:addRelatedSkill("ty__fenyin")

Fk:loadTranslationTable{
  ["wufan"] = "吴范",
  ["tianyun"] = "天运",
  [":tianyun"] = "获得起始手牌后，你再从牌堆中随机获得手牌中没有的花色各一张牌。<br>"..
  "一名角色的回合开始时，若其座次等于游戏轮数，你可以观看牌堆顶的X张牌，然后以任意顺序置于牌堆顶或牌堆底，若你将所有牌均置于牌堆底，"..
  "则你可以令一名角色摸X张牌（X为你手牌中的花色数），若如此做，你失去1点体力。",
  ["yuyan"] = "预言",
  [":yuyan"] = "每轮游戏开始时，你选择一名角色，若其是本轮第一个进入濒死状态的角色，则你获得技能〖奋音〗直到你的回合结束。"..
  "若其是本轮第一个造成伤害的角色，则你摸两张牌。",

  ["#tianyun-choose"] = "天运：你可以令一名角色摸%arg张牌，然后你失去1点体力",
  ["#yuyan-choose"] = "是否发动预言，选择一名角色，若其是本轮第一个进入濒死状态或造成伤害的角色，你获得增益",
  ["#yuyan_delay"] = "预言",
  ["@@yuyan-round"] = "预言",

  ["$tianyun1"] = "天垂象，见吉凶。",
  ["$tianyun2"] = "治历数，知风气。",
  ["$yuyan1"] = "差若毫厘，谬以千里，需慎之。",
  ["$yuyan2"] = "六爻之动，三极之道也。",
  ["$ty__fenyin_wufan1"] = "奋音鼓劲，片甲不留！",
  ["$ty__fenyin_wufan2"] = "奋勇杀敌，声罪致讨！",
  ["~wufan"] = "天运之术今绝矣……",
}

local zhaozhi = General(extension, "zhaozhi", "shu", 3)
local tongguan = fk.CreateTriggerSkill{
  name = "tongguan",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and data.from == Player.RoundStart and
      table.every({1, 2, 3, 4, 5}, function(i) return target:getMark("@@tongguan"..i) == 0 end)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local count = {0, 0, 0, 0, 0}
    for _, p in ipairs(room:getAlivePlayers()) do
      for i = 1, 5, 1 do
        if p:getMark("@@tongguan"..i) > 0 then
          count[i] = count[i] + 1
        end
      end
    end
    local choices = {}
    for i = 1, 5, 1 do
      if count[i] < 2 then
        table.insert(choices, "@@tongguan"..i)
      end
    end
    local choice = room:askForChoice(player, choices, self.name, "#tongguan-choice::"..target.id, true)
    room:setPlayerMark(target, choice, 1)
  end,
}
local mengjiez = fk.CreateTriggerSkill{
  name = "mengjiez",
  anim_type = "control",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and (target:getMark(self.name) > 0 or
      (target:getMark("@@tongguan2") > 0 and target:getHandcardNum() > target.hp))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if target:getMark("@@tongguan3") > 0 then
      return room:askForSkillInvoke(player, self.name, nil, "#mengjiez3-invoke")
    else
      local targets, prompt
      if target:getMark("@@tongguan1") > 0 then
        targets = table.map(room:getOtherPlayers(player), function(p)
          return p.id end)
        prompt = "#mengjiez1-invoke"
      elseif target:getMark("@@tongguan2") > 0 then
        targets = table.map(table.filter(room:getAlivePlayers(), function(p)
          return p:isWounded() end), function(p) return p.id end)
        prompt = "#mengjiez2-invoke"
      elseif target:getMark("@@tongguan4") > 0 then
        targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
          return not p:isAllNude() end), function(p) return p.id end)
        prompt = "#mengjiez4-invoke"
      elseif target:getMark("@@tongguan5") > 0 then
        targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
          return p:getHandcardNum() < p.maxHp end), function(p) return p.id end)
        prompt = "#mengjiez5-invoke"
      end
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if target:getMark("@@tongguan3") > 0 then
      player:drawCards(2, self.name)
    else
      local room = player.room
      local to = room:getPlayerById(self.cost_data)
      if target:getMark("@@tongguan1") > 0 then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = self.name,
        }
      elseif target:getMark("@@tongguan2") > 0 then
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      elseif target:getMark("@@tongguan4") > 0 then
        local cards = room:askForCardsChosen(player, to, 1, 2, "hej", self.name)
        room:throwCard(cards, self.name, to, player)
      elseif target:getMark("@@tongguan5") > 0 then
        to:drawCards(math.min(5, to.maxHp - #to.player_cards[Player.Hand]), self.name)
      end
    end
  end,

  refresh_events = {fk.EventPhaseChanging, fk.Damage, fk.HpRecover, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      return target == player and data.from == Player.RoundStart
    elseif player.phase ~= Player.NotActive then
      if event == fk.Damage then
        return target == player and player:getMark("@@tongguan1") > 0
      elseif event == fk.HpRecover then
        return target == player and player:getMark("@@tongguan2") > 0
      else
        for _, move in ipairs(data) do
          if player:getMark("@@tongguan3") > 0 and
            move.to == player.id and move.moveReason == fk.ReasonDraw and player.phase ~= Player.Draw then
            return true
          end
          if player:getMark("@@tongguan4") > 0 and
            move.from ~= player.id and (move.proposer == player or move.proposer == player.id) and
            (move.moveReason == fk.ReasonDiscard or move.moveReason == fk.ReasonPrey) then
            return true
          end
          if player:getMark("@@tongguan5") > 0 and
            move.from == player.id and move.moveReason == fk.ReasonGive then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      player.room:setPlayerMark(player, self.name, 0)
    else
      player.room:addPlayerMark(player, self.name, 1)
    end
  end,
}
zhaozhi:addSkill(tongguan)
zhaozhi:addSkill(mengjiez)
Fk:loadTranslationTable{
  ["zhaozhi"] = "赵直",
  ["tongguan"] = "统观",
  [":tongguan"] = "一名角色的第一个回合开始时，你为其选择一项属性（每种属性至多被选择两次）。",
  ["mengjiez"] = "梦解",
  [":mengjiez"] = "一名角色的回合结束时，若其本回合完成了其属性对应内容，你执行对应效果。<br>"..
  "武勇：造成伤害；对一名其他角色造成1点伤害<br>"..
  "刚硬：回复体力或手牌数大于体力值；令一名角色回复1点体力<br>"..
  "多谋：摸牌阶段外摸牌；摸两张牌<br>"..
  "果决：弃置或获得其他角色的牌；弃置一名其他角色区域内的至多两张牌<br>"..
  "仁智：交给其他角色牌；令一名其他角色将手牌摸至体力上限（至多摸五张）",
  ["#tongguan-choice"] = "统观：为 %dest 选择一项属性（每种属性至多被选择两次）",
  ["@@tongguan1"] = "武勇",
  [":@@tongguan1"] = "回合结束时，若其本回合造成过伤害，你对一名其他角色造成1点伤害",
  ["@@tongguan2"] = "刚硬",
  [":@@tongguan2"] = "回合结束时，若其手牌数大于体力值，或其本回合回复过体力，你令一名角色回复1点体力",
  ["@@tongguan3"] = "多谋",
  [":@@tongguan3"] = "回合结束时，若其本回合摸牌阶段外摸过牌，你摸两张牌",
  ["@@tongguan4"] = "果决",
  [":@@tongguan4"] = "回合结束时，若其本回合弃置或获得过其他角色的牌，你弃置一名其他角色区域内的至多两张牌",
  ["@@tongguan5"] = "仁智",
  [":@@tongguan5"] = "回合结束时，若其本回合交给其他角色牌，你令一名其他角色将手牌摸至体力上限（至多摸五张）",
  ["#mengjiez1-invoke"] = "梦解：你可以对一名其他角色造成1点伤害",
  ["#mengjiez2-invoke"] = "梦解：你可以令一名角色回复1点体力",
  ["#mengjiez3-invoke"] = "梦解：你可以摸两张牌",
  ["#mengjiez4-invoke"] = "梦解：你可以弃置一名其他角色区域内至多两张牌",
  ["#mengjiez5-invoke"] = "梦解：你可以令一名其他角色将手牌摸至体力上限（至多摸五张）",

  ["$tongguan1"] = "极目宇宙，可观如织之命数。",
  ["$tongguan2"] = "命河长往，唯我立于川上。",
  ["$mengjiez1"] = "唇舌之语，难言虚实之境。",
  ["$mengjiez2"] = "解梦之术，如镜中观花尔。",
  ["~zhaozhi"] = "解人之梦者，犹在己梦中。",
}

local zhouxuan = General(extension, "zhouxuan", "wei", 3)
local wumei = fk.CreateTriggerSkill{
  name = "wumei",
  anim_type = "support",
  events = {fk.BeforeTurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function (p)
      return p:getMark("@@wumei_extra") == 0 end), function(p) return p.id end), 1, 1, "#wumei-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:addPlayerMark(to, "@@wumei_extra", 1)
    local hp_record = {}
    for _, p in ipairs(room.alive_players) do
      table.insert(hp_record, {p.id, p.hp})
    end
    room:setPlayerMark(to, "wumei_record", hp_record)
    to:gainAnExtraTurn()
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@wumei_extra") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@wumei_extra", 0)
    room:setPlayerMark(player, "wumei_record", 0)
  end,
}
local wumei_delay = fk.CreateTriggerSkill{
  name = "#wumei_delay",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Finish and player:getMark("@@wumei_extra") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, wumei.name, "special")
    local hp_record = player:getMark("wumei_record")
    if type(hp_record) ~= "table" then return false end
    for _, p in ipairs(room:getAlivePlayers()) do
      local p_record = table.find(hp_record, function (sub_record)
        return #sub_record == 2 and sub_record[1] == p.id
      end)
      if p_record then
        p.hp = math.min(p.maxHp, p_record[2])
        room:broadcastProperty(p, "hp")
      end
    end
  end,
}
local zhanmeng = fk.CreateTriggerSkill{
  name = "zhanmeng",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      for i = 1, 3, 1 do
        if player:getMark(self.name .. tostring(i).."-turn") == 0 then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    self.cost_data = {}
    if player:getMark("zhanmeng1-turn") == 0 and not table.contains(room:getTag("zhanmeng1") or {}, data.card.trueName) then
      table.insert(choices, "zhanmeng1")
    end
    if player:getMark("zhanmeng2-turn") == 0 then
      table.insert(choices, "zhanmeng2")
    end
    local targets = {}
    if player:getMark("zhanmeng3-turn") == 0 then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not p:isNude() then
          table.insertIfNeed(choices, "zhanmeng3")
          table.insert(targets, p.id)
        end
      end
    end
    table.insert(choices, "Cancel")
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "Cancel" then return end
    self.cost_data[1] = choice
    if choice == "zhanmeng3" then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhanmeng-choose", self.name, false)
      if #to > 0 then
        self.cost_data[2] = to[1]
      else
        self.cost_data[2] = table.random(targets)
      end
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data[1]
    room:setPlayerMark(player, choice.."-turn", 1)
    if choice == "zhanmeng1" then
      local cards = {}
      for i = 1, #room.draw_pile, 1 do
        local card = Fk:getCardById(room.draw_pile[i])
        if not card.is_damage_card then
          table.insertIfNeed(cards, room.draw_pile[i])
        end
      end
      if #cards > 0 then
        local card = table.random(cards)
        room:moveCards({
          ids = {card},
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    elseif choice == "zhanmeng2" then
      room:setPlayerMark(player, "zhanmeng2_invoke", data.card.trueName)
    elseif choice == "zhanmeng3" then
      local p = room:getPlayerById(self.cost_data[2])
      local n = math.min(2, #p:getCardIds{Player.Hand, Player.Equip})
      local cards = room:askForDiscard(p, n, 2, true, self.name, false, ".", "#zhanmeng-discard:"..player.id.."::"..tostring(n))
      local x = Fk:getCardById(cards[1]).number
      if #cards == 2 then
        x = x + Fk:getCardById(cards[2]).number
      end
      if x > 10 then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = self.name,
        }
      end
    end
  end,
}
local zhanmeng_record = fk.CreateTriggerSkill{
  name = "#zhanmeng_record",

  refresh_events = {fk.CardUsing, fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if event == fk.CardUsing then
        return true
      else
        return player.phase == Player.Start
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      local zhanmeng2 = room:getTag("zhanmeng2") or {}
      if not table.contains(zhanmeng2, data.card.trueName) then
        table.insert(zhanmeng2, data.card.trueName)
        room:setTag("zhanmeng2", zhanmeng2)
      end
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:getMark("zhanmeng2_get-turn") == data.card.trueName then
          room:setPlayerMark(p, "zhanmeng2_get-turn", 0)
          local cards = {}
          for i = 1, #room.draw_pile, 1 do
            local card = Fk:getCardById(room.draw_pile[i])
            if card.is_damage_card then
              table.insertIfNeed(cards, room.draw_pile[i])
            end
          end
          if #cards > 0 then
            local card = table.random(cards)
            room:moveCards({
              ids = {card},
              to = p.id,
              toArea = Card.PlayerHand,
              moveReason = fk.ReasonJustMove,
              proposer = p.id,
              skillName = "zhanmeng",
            })
          end
        end
      end
    else
      local zhanmeng2 = room:getTag("zhanmeng2") or {}
      room:setTag("zhanmeng1", zhanmeng2)  --上回合使用的牌
      zhanmeng2 = {}
      room:setTag("zhanmeng2", zhanmeng2)  --当前回合使用的牌
      for _, p in ipairs(room:getAlivePlayers()) do
        if type(p:getMark("zhanmeng2_invoke")) == "string" then
          room:setPlayerMark(p, "zhanmeng2_get-turn", p:getMark("zhanmeng2_invoke"))
          room:setPlayerMark(p, "zhanmeng2_invoke", 0)
        end
      end
    end
  end,
}
wumei:addRelatedSkill(wumei_delay)
zhanmeng:addRelatedSkill(zhanmeng_record)
zhouxuan:addSkill(wumei)
zhouxuan:addSkill(zhanmeng)
Fk:loadTranslationTable{
  ["zhouxuan"] = "周宣",
  ["wumei"] = "寤寐",
  ["#wumei_delay"] = "寤寐",
  [":wumei"] = "每轮限一次，回合开始前，你可以令一名角色执行一个额外的回合：该回合结束时，将所有存活角色的体力值调整为此额外回合开始时的数值。",
  ["zhanmeng"] = "占梦",
  [":zhanmeng"] = "你使用牌时，可以执行以下一项（每回合每项各限一次）：<br>"..
  "1.上一回合内，若没有同名牌被使用，你获得一张非伤害牌。<br>"..
  "2.下一回合内，当同名牌首次被使用后，你获得一张伤害牌。<br>"..
  "3.令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害。",
  ["#wumei-choose"] = "寤寐: 你可以令一名角色执行一个额外的回合",
  ["@@wumei_extra"] = "寤寐",
  ["zhanmeng1"] = "你获得一张非伤害牌",
  ["zhanmeng2"] = "下一回合内，当同名牌首次被使用后，你获得一张伤害牌",
  ["zhanmeng3"] = "令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害",
  ["#zhanmeng-choose"] = "占梦: 令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害",
  ["#zhanmeng-discard"] = "占梦：弃置%arg张牌，若点数之和大于10，%src 对你造成1点火焰伤害",

  ["$wumei1"] = "大梦若期，皆付一枕黄粱。",
  ["$wumei2"] = "日所思之，故夜所梦之。",
  ["$zhanmeng1"] = "梦境缥缈，然有迹可占。",
  ["$zhanmeng2"] = "万物有兆，唯梦可卜。",
  ["~zhouxuan"] = "人生如梦，假时亦真。",
}

local zerong = General(extension, "zerong", "qun", 4)
local cansi = fk.CreateTriggerSkill{
  name = "cansi",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#cansi-choose", self.name, false)
    local to
    if #tos > 0 then
      to = room:getPlayerById(tos[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if to:isWounded() then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:setPlayerMark(player, self.name, to.id)
    for _, name in ipairs({"slash", "duel", "fire_attack"}) do
      if player.dead or to.dead then break end
      room:useVirtualCard(name, nil, player, to, self.name)
    end
    room:setPlayerMark(player, self.name, 0)
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, self.name) and not player.dead
  end,
  on_refresh = function(self, event, target, player, data)
    if data.damageDealt and data.damageDealt[player:getMark(self.name)] then
      player:drawCards(2*data.damageDealt[player:getMark(self.name)], self.name)
    end
  end,
}
local fozong = fk.CreateTriggerSkill{
  name = "fozong",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getHandcardNum() > 7
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum() - 7
    local cards = room:askForCard(player, n, n, false, self.name, false, ".", "#fozong-card:::"..n)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(cards)
    player:addToPile(self.name, dummy, true, self.name)
    if #player:getPile(self.name) >= 7 then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if player.dead then return end
        local choices = {"fozong_lose"}
        if #player:getPile(self.name) > 0 then  --很难想象怎样才会不够发
          table.insert(choices, 1, "fozong_get")
        end
        local choice = room:askForChoice(p, choices, self.name, "#fozong-choice:"..player.id)  --之后应该改成选牌框
        if choice == "fozong_get" then
          local cards = player:getPile(self.name)
          table.forEach(room.players, function(p) room:fillAG(p, cards) end)
          local id = room:askForAG(p, cards, false, self.name)
          room:takeAG(p, id, room.players)
          room:obtainCard(p.id, id, true, fk.ReasonJustMove)
          table.removeOne(cards, id)
          table.forEach(room.players, function(p) room:closeAG(p) end)
          if player:isWounded() then
            room:recover({
              who = player,
              num = 1,
              recoverBy = player,
              skillName = self.name
            })
          end
        else
          room:loseHp(player, 1, self.name)
        end
      end
    end
  end,
}
zerong:addSkill(cansi)
zerong:addSkill(fozong)
Fk:loadTranslationTable{
  ["zerong"] = "笮融",
  ["cansi"] = "残肆",
  [":cansi"] = "锁定技，准备阶段，你选择一名其他角色，你与其各回复1点体力，然后依次视为对其使用【杀】、【决斗】和【火攻】，其每因此受到1点伤害，你摸两张牌。",
  ["fozong"] = "佛宗",
  [":fozong"] = "锁定技，出牌阶段开始时，若你的手牌多于七张，你将超出数量的手牌置于武将牌上，然后若你武将牌上有至少七张牌，"..
  "其他角色依次选择一项：1.获得其中一张牌并令你回复1点体力；2.令你失去1点体力。",
  ["#cansi-choose"] = "残肆：选择一名角色，你与其各回复1点体力，然后依次视为对其使用【杀】、【决斗】和【火攻】",
  ["#fozong-card"] = "佛宗：将 %arg 张手牌置于武将牌上",
  ["#fozong-choice"] = "佛宗：选择对 %src 执行的一项",
  ["fozong_get"] = "获得一张“佛宗”牌，其回复1点体力",
  ["fozong_lose"] = "其失去1点体力",
  
  ["$cansi1"] = "君不入地狱，谁入地狱？",
  ["$cansi2"] = "众生皆苦，唯渡众生于极乐。",
  ["$fozong1"] = "此身无长物，愿奉骨肉为浮屠。",
  ["$fozong2"] = "驱大白牛车，颂无上功德。",
  ["~zerong"] = "此劫，不可避……",
}

--计将安出：程昱 蒋干 赵昂 刘晔 杨弘 桓范
--程昱

local jianggan = General(extension, "jianggan", "wei", 3)
local weicheng = fk.CreateTriggerSkill{
  name = "weicheng",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:getHandcardNum() < player.hp then
      for _, move in ipairs(data) do
        if move.from and move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
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
    player:drawCards(1, self.name)
  end,
}
local daoshu = fk.CreateActiveSkill{
  name = "daoshu",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local suits = {"spade", "heart", "club", "diamond"}
    local choice = room:askForChoice(player, suits, self.name)
    local card = room:askForCardChosen(player, target, "h", self.name)
    room:obtainCard(player, card, false, fk.ReasonPrey)
    if Fk:getCardById(card):getSuitString() == choice then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
      player:addSkillUseHistory(self.name, -1)
    else
      local suit = Fk:getCardById(card):getSuitString()
      table.removeOne(suits, suit)
      local others = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getSuitString() ~= suit end)
      if #others > 0 then
        local cards = room:askForCard(player, 1, 1, false, self.name, false, ".|.|"..table.concat(suits, ","),
          "#daoshu-give::"..target.id..":"..suit)
        if #cards > 0 then
          cards = cards[1]
        else
          cards = table.random(others)
        end
        room:obtainCard(target, cards, true, fk.ReasonGive)
        return
      end
      player:showCards(player.player_cards[Player.Hand])
    end
  end,
}
jianggan:addSkill(weicheng)
jianggan:addSkill(daoshu)
Fk:loadTranslationTable{
  ["jianggan"] = "蒋干",
  ["weicheng"] = "伪诚",
  [":weicheng"] = "你交给其他角色手牌，或你的手牌被其他角色获得后，若你的手牌数小于体力值，你可以摸一张牌。",
  ["daoshu"] = "盗书",
  [":daoshu"] = "出牌阶段限一次，你可以选择一名其他角色并选择一种花色，然后获得该角色一张手牌。若此牌与你选择的花色："..
  "相同，你对其造成1点伤害且此技能视为未发动过；不同，你交给该角色一张其他花色的手牌（若没有需展示所有手牌）。",
  ["#daoshu-give"] = "盗书：你需交给 %dest 一张非%arg手牌，若没有则展示所有手牌",

  ["$weicheng1"] = "略施谋略，敌军便信以为真。",
  ["$weicheng2"] = "吾只观雅规，而非说客。",
  ["$daoshu1"] = "得此文书，丞相定可高枕无忧。",
  ["$daoshu2"] = "让我看看，这是什么机密。",
  ["~jianggan"] = "丞相，再给我一次机会啊！",
}

--赵昂

local liuye = General(extension, "ty__liuye", "wei", 3)
local poyuan = fk.CreateTriggerSkill{
  name = "poyuan",
  anim_type = "control",
  events = {fk.GameStart, fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and (event == fk.GameStart or (event == fk.TurnStart and target == player))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if not player:getEquipment(Card.SubtypeTreasure) or Fk:getCardById(player:getEquipment(Card.SubtypeTreasure)).name ~= "ty__catapult" then
      return room:askForSkillInvoke(player, self.name, nil, "#poyuan-invoke")
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isNude() end), function(p) return p.id end)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#poyuan-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getEquipment(Card.SubtypeTreasure) then
      if Fk:getCardById(player:getEquipment(Card.SubtypeTreasure)).name == "ty__catapult" then
        local to = room:getPlayerById(self.cost_data)
        local cards = room:askForCardsChosen(player, to, 1, 2, "he", self.name)
        room:throwCard(cards, self.name, to, player)
        return
      end
    end
    for _, id in ipairs(Fk:getAllCardIds()) do
      if Fk:getCardById(id, true).name == "ty__catapult" and room:getCardArea(id) == Card.Void then
        room:moveCards({
          ids = {id},
          fromArea = Card.Void,
          to = player.id,
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
        break
      end
    end
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local id = 0
    for i = #data, 1, -1 do
      local move = data[i]
      if move.toArea ~= Card.Void then
        for j = #move.moveInfo, 1, -1 do
          local info = move.moveInfo[j]
          if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId, true).name == "ty__catapult" then
            id = info.cardId
            table.removeOne(move.moveInfo, info)
            break
          end
        end
      end
    end
    if id ~= 0 then
      local room = player.room
      room:sendLog{
        type = "#destructDerivedCard",
        arg = Fk:getCardById(id, true):toLogString(),
      }
      room:moveCardTo(Fk:getCardById(id, true), Card.Void, nil, fk.ReasonJustMove, "", "", true)
    end
  end,
}
local huace = fk.CreateViewAsSkill{
  name = "huace",
  interaction = function()
    local names = {}
    local mark = Self:getMark("huace2")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id, true)
      if card:isCommonTrick() and card.trueName ~= "nullification" and card.name ~= "adaptation" and not card.is_derived then
        if mark == 0 or (not table.contains(mark, card.trueName)) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    return UI.ComboBox {choices = names}
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
}
local huace_record = fk.CreateTriggerSkill{
  name = "#huace_record",

  refresh_events = {fk.AfterCardUseDeclared, fk.RoundStart},
  can_refresh = function(self, event, target, player, data)
    return (event == fk.AfterCardUseDeclared and data.card:isCommonTrick()) or event == fk.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      local mark = player:getMark("huace1")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, data.card.trueName)
      room:setPlayerMark(player, "huace1", mark)
    else
      room:setPlayerMark(player, "huace2", player:getMark("huace1"))
      room:setPlayerMark(player, "huace1", 0)
    end
  end,
}
huace:addRelatedSkill(huace_record)
liuye:addSkill(poyuan)
liuye:addSkill(huace)
Fk:loadTranslationTable{
  ["ty__liuye"] = "刘晔",
  ["poyuan"] = "破垣",
  [":poyuan"] = "游戏开始时或回合开始时，若你的装备区里没有【霹雳车】，你可以将【霹雳车】置于装备区；若有，你可以弃置一名其他角色至多两张牌。<br>"..
  "<font color='grey'>【霹雳车】<br>♦9 装备牌·宝物<br /><b>装备技能</b>：锁定技，你回合内使用基本牌的伤害和回复数值+1且无距离限制，"..
  "使用的【酒】使【杀】伤害基数值增加的效果+1。你回合外使用或打出基本牌时摸一张牌。离开装备区时销毁。",
  ["huace"] = "画策",
  [":huace"] = "出牌阶段限一次，你可以将一张手牌当上一轮没有角色使用过的普通锦囊牌使用。",
  ["#poyuan-invoke"] = "破垣：你可以装备【霹雳车】",
  ["#poyuan-choose"] = "破垣：你可以弃置一名其他角色至多两张牌",
  ["#destructDerivedCard"] = "%arg 被销毁",

  ["$poyuan1"] = "砲石飞空，坚垣难存。",
  ["$poyuan2"] = "声若霹雳，人马俱摧。",
  ["$huace1"] = "筹画所料，无有不中。",
  ["$huace2"] = "献策破敌，所谋皆应。",
  ["~ty__liuye"] = "功名富贵，到头来，不过黄土一抔……",
}

local yanghong = General(extension, "yanghong", "qun", 3)
local function IsNext(from, to)
  if from.dead or to.dead then return false end
  if from.next == to then return true end
  local temp = table.simpleClone(from.next)
  while true do
    if temp.dead then
      temp = temp.next
    else
      return temp == to
    end
  end
end
local ty__jianji = fk.CreateActiveSkill{
  name = "ty__jianji",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = function()
    return Self:getAttackRange()
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if not target:isNude() and #selected < Self:getAttackRange() then
      if #selected == 0 then
        return true
      else
        for _, id in ipairs(selected) do
          if IsNext(target, Fk:currentRoom():getPlayerById(id)) or IsNext(Fk:currentRoom():getPlayerById(id), target) then
            return true
          end
        end
        return false
      end
    end
  end,
  on_use = function(self, room, effect)
    for _, id in ipairs(effect.tos) do
      room:askForDiscard(room:getPlayerById(id), 1, 1, true, self.name, false, ".")
    end
    if #effect.tos < 2 then return end
    local n = 0
    for _, id in ipairs(effect.tos) do
      local num = #room:getPlayerById(id).player_cards[Player.Hand]
      if num > n then
        n = num
      end
    end
    local src = table.filter(effect.tos, function(id) return #room:getPlayerById(id).player_cards[Player.Hand] == n end)
    src = room:getPlayerById(table.random(src))
    table.removeOne(effect.tos, src.id)
    local targets = table.filter(effect.tos, function(id) return not src:isProhibited(room:getPlayerById(id), Fk:cloneCard("slash")) end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(src, effect.tos, 1, 1, "#ty__jianji-choose", self.name, true)
    if #to > 0 then
      room:useVirtualCard("slash", nil, src, room:getPlayerById(to[1]), self.name, true)
    end
  end,
}
local yuanmo = fk.CreateTriggerSkill{
  name = "yuanmo",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start or (player.phase == Player.Finish and
          table.every(player.room:getOtherPlayers(player), function(p) return not player:inMyAttackRange(p) end))
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#yuanmo1-invoke"
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      prompt = "#yuanmo2-invoke"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)  --此处不能用addMark
    else
      local choice = room:askForChoice(player, {"yuanmo_add", "yuanmo_minus"}, self.name)
      if choice == "yuanmo_add" then
        local nos = table.filter(room:getOtherPlayers(player), function(p) return player:inMyAttackRange(p) end)
        room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)
        local targets = {}
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if player:inMyAttackRange(p) and not table.contains(nos, p) and not p:isNude() then
            table.insert(targets, p.id)
          end
        end
        local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#yuanmo-choose", self.name, true)
        if #tos > 0 then
          for _, id in ipairs(tos) do
            room:doIndicate(player.id, {id})
            local card = room:askForCardChosen(player, room:getPlayerById(id), "he", self.name)
            room:obtainCard(player.id, card, false, fk.ReasonPrey)
          end
        end
      else
        room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") - 1)
        player:drawCards(2, self.name)
      end
    end
  end,
}
local yuanmo_attackrange = fk.CreateAttackRangeSkill{
  name = "#yuanmo_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@yuanmo")
  end,
}
yuanmo:addRelatedSkill(yuanmo_attackrange)
yanghong:addSkill(ty__jianji)
yanghong:addSkill(yuanmo)
Fk:loadTranslationTable{
  ["yanghong"] = "杨弘",
  ["ty__jianji"] = "间计",
  [":ty__jianji"] = "出牌阶段限一次，你可以令至多X名相邻的角色各弃置一张牌（X为你的攻击范围），然后其中手牌最多的角色可以视为对其中另一名角色使用【杀】。",
  ["yuanmo"] = "远谟",
  [":yuanmo"] = "①准备阶段或你受到伤害后，你可以选择一项：1.令你的攻击范围+1，然后获得任意名因此进入你攻击范围内的角色各一张牌；"..
  "2.令你的攻击范围-1，然后摸两张牌。<br>②结束阶段，若你攻击范围内没有角色，你可以令你的攻击范围+1。",
  ["#ty__jianji-choose"] = "间计：你可以视为对其中一名角色使用【杀】",
  ["#yuanmo1-invoke"]= "远谟：你可以令攻击范围+1并获得进入你攻击范围的角色各一张牌，或攻击范围-1并摸两张牌",
  ["#yuanmo2-invoke"]= "远谟：你可以令攻击范围+1",
  ["@yuanmo"] = "远谟",
  ["yuanmo_add"] = "攻击范围+1，获得因此进入攻击范围的角色各一张牌",
  ["yuanmo_minus"] = "攻击范围-1，摸两张牌",
  ["#yuanmo-choose"] = "远谟：你可以获得任意名角色各一张牌",
}

local huanfan = General(extension, "huanfan", "wei", 3)
local jianzheng = fk.CreateActiveSkill{
  name = "jianzheng",
  anim_type = "control",
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = target.player_cards[Player.Hand]
    local availableCards = {}
    for _, id in ipairs(cards) do
      local card = Fk:getCardById(id)
      if not player:prohibitUse(card) and player:canUse(card) then
        table.insertIfNeed(availableCards, id)
      end
    end
    room:fillAG(player, cards)
    local yes = false
    for i = #cards, 1, -1 do
      if not table.contains(availableCards, cards[i]) then
        room:takeAG(player, cards[i], room.players)
      end
    end
    if #availableCards == 0 then
      room:delay(3000)
      room:closeAG(player)
    else
      local id = room:askForAG(player, availableCards, true, self.name)
      room:closeAG(player)
      if id then
        room:obtainCard(player.id, id, false, fk.ReasonPrey)
        if not player.dead and room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand then
          local card = Fk:getCardById(id)
          local use = room:askForUseCard(player, card.name, "^(jink,nullification)|.|.|.|.|.|"..tostring(id),
            "#jianzheng-use:::"..card:toLogString(), true)
          if use then
            use.extraUse = true
            room:useCard(use)
            if table.contains(TargetGroup:getRealTargets(use.tos), target.id) then
              yes = true
            end
          end
        end
      end
    end
    if yes then
      if not player.dead and not player.chained then
        player:setChainState(true)
      end
      if not target.dead and not target.chained then
        target:setChainState(true)
      end
      if not player.dead and not target.dead and not player:isKongcheng() then
        room:fillAG(target, player:getCardIds("h"))
        room:delay(3000)
        room:closeAG(target)
      end
    end
  end,
}
local fumou = fk.CreateTriggerSkill{
  name = "fumou",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room.alive_players, function(p) return p.id end)
    local tos = room:askForChoosePlayers(player, targets, 1, player:getLostHp(), "#fumou-choose:::"..player:getLostHp(), self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p.dead then
        local choices = {}
        if #room:canMoveCardInBoard() > 0 then
          table.insert(choices, "fumou1")
        end
        if not p:isKongcheng() then
          table.insert(choices, "fumou2")
        end
        if #p:getCardIds("e") > 0 then
          table.insert(choices, "fumou3")
        end
        if #choices == 0 then
          --continue
        else
          local choice = room:askForChoice(p, choices, self.name)
          if choice == "fumou1" then
            local targets = room:askForChooseToMoveCardInBoard(p, "#fumou-move", self.name, false)
            room:askForMoveCardInBoard(p, room:getPlayerById(targets[1]), room:getPlayerById(targets[2]), self.name)
          elseif choice == "fumou2" then
            p:throwAllCards("h")
            if not p.dead then
              p:drawCards(2, self.name)
            end
          elseif choice == "fumou3" then
            p:throwAllCards("e")
            if p:isWounded() then
              room:recover({
                who = p,
                num = 1,
                recoverBy = player,
                skillName = self.name
              })
            end
          end
        end
      end
    end
  end,
}
huanfan:addSkill(jianzheng)
huanfan:addSkill(fumou)
Fk:loadTranslationTable{
  ["huanfan"] = "桓范",
  ["jianzheng"] = "谏诤",
  [":jianzheng"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后若其中有你可以使用的牌，你可以获得并使用其中一张。"..
  "若此牌指定了其为目标，则横置你与其武将牌，然后其观看你的手牌。",
  ["fumou"] = "腹谋",
  [":fumou"] = "当你受到伤害后，你可以令至多X名角色依次选择一项：1.移动场上一张牌；2.弃置所有手牌并摸两张牌；3.弃置装备区所有牌并回复1点体力。"..
  "（X为你已损失的体力值）",
  ["#jianzheng-use"] = "谏诤：你可以使用%arg",
  ["#fumou-choose"] = "腹谋：你可以令至多%arg名角色依次选择执行一项",
  ["fumou1"] = "移动场上一张牌",
  ["fumou2"] = "弃置所有手牌，摸两张牌",
  ["fumou3"] = "弃置所有装备，回复1点体力",
  ["#fumou-move"] = "腹谋：请选择要移动装备的角色",

  ["$jianzheng1"] = "将军今出洛阳，恐难再回。",
  ["$jianzheng2"] = "贼示弱于外，必包藏祸心。",
  ["$fumou1"] = "某有良谋，可为将军所用。",
  ["$fumou2"] = "吾负十斗之囊，其盈一石之智。",
  ["~huanfan"] = "有良言而不用，君何愚哉……",
}

local xizheng = General(extension, "xizheng", "shu", 3)
local danyi = fk.CreateTriggerSkill{
  name = "danyi",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.firstTarget then
      local room = player.room
      local events = room.logic.event_recorder[GameEvent.UseCard]
      if #events < 2 then return end
      for i = #events - 1, 1, -1 do
        local use = events[i].data[1]
        if use.from == player.id then
          if use.tos then
            if #TargetGroup:getRealTargets(use.tos) ~= #AimGroup:getAllTargets(data.tos) then return false end
            for _, id in ipairs(TargetGroup:getRealTargets(use.tos)) do
              if not table.contains(AimGroup:getAllTargets(data.tos), id) then
                return false
              end
            end
            for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
              if not table.contains(TargetGroup:getRealTargets(use.tos), id) then
                return false
              end
            end
            return true
          else
            return false
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(#AimGroup:getAllTargets(data.tos), self.name)
  end,
}
local wencan = fk.CreateActiveSkill{
  name = "wencan",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  prompt = "#wencan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    if #selected > 1 or to_select == Self.id then return false end
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return target.hp ~= Self.hp
    elseif #selected == 1 then
      return target.hp ~= Self.hp and target.hp ~= Fk:currentRoom():getPlayerById(selected[1]).hp
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        if #p:getCardIds("he") < 2 or not room:askForUseActiveSkill(p, "wencan_active", "#wencan-discard:"..player.id, true) then
          room:setPlayerMark(p, "@@wencan-turn", 1)
        end
      end
    end
  end,
}
local wencan_active = fk.CreateActiveSkill{
  name = "wencan_active",
  mute = true,
  card_num = 2,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    if not Self:prohibitDiscard(card) and card.suit ~= Card.NoSuit then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return card.suit ~= Fk:getCardById(selected[1]).suit
      else
        return false
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, "wencan", player, player)
  end,
}
local wencan_targetmod = fk.CreateTargetModSkill{
  name = "#wencan_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:usedSkillTimes("wencan", Player.HistoryTurn) > 0 and scope == Player.HistoryPhase and to:getMark("@@wencan-turn") > 0
  end,
}
Fk:addSkill(wencan_active)
wencan:addRelatedSkill(wencan_targetmod)
xizheng:addSkill(danyi)
xizheng:addSkill(wencan)
Fk:loadTranslationTable{
  ["xizheng"] = "郤正",
  ["danyi"] = "耽意",
  [":danyi"] = "你使用牌指定目标后，若此牌目标与你使用的上一张牌完全相同，你可以摸X张牌（X为此牌目标数）。",
  ["wencan"] = "文灿",
  [":wencan"] = "出牌阶段限一次，你可以选择至多两名体力值不同且均与你不同的角色，这些角色依次选择一项：1.弃置两张花色不同的牌；"..
  "2.本回合你对其使用牌无次数限制。",
  ["#wencan"] = "文灿：选择至多两名体力值不同且均与你不同的角色，其弃牌或你对其使用牌无次数限制",
  ["@@wencan-turn"] = "文灿",
  ["wencan_active"] = "文灿",
  ["#wencan-discard"] = "文灿：弃置两张不同花色的牌，否则 %src 本回合对你使用牌无次数限制",
  
  ["$danyi1"] = "满城锦绣，何及笔下春秋？",
  ["$danyi2"] = "一心向学，不闻窗外风雨。",
  ["$wencan1"] = "宴友以文，书声喧哗，众宾欢也。",
  ["$wencan2"] = "众星灿于九天，犹雅文耀于万世。",
  ["~xizheng"] = "此生有涯，奈何学海无涯……",
}

return extension
