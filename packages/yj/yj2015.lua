local extension = Package("yjcm2015")
extension.extensionName = "yj"

Fk:loadTranslationTable{
  ["yjcm2015"] = "一将成名2015",
}

local caorui = General(extension, "caorui", "wei", 3)
local huituo = fk.CreateTriggerSkill{
  name = "huituo",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id end), 1, 1, "#huituo-choose", self.name, true)
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
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      if to:isWounded() then
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    elseif judge.card.color == Card.Black then
      to:drawCards(data.damage, self.name)
    end
  end,
}
local mingjian = fk.CreateActiveSkill{
  name = "mingjian",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
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
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player.player_cards[Player.Hand])
    room:obtainCard(target, dummy, false, fk.ReasonGive)
    room:addPlayerMark(target, "@@" .. self.name, 1)
  end,
}
local mingjian_record = fk.CreateTriggerSkill{
  name = "#mingjian_record",

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@@mingjian") > 0 and data.to == Player.Start and target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@@mingjian-turn", player:getMark("@@mingjian"))
    room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, player:getMark("@@mingjian"))
    room:setPlayerMark(player, "@@mingjian", 0)
  end,
}
local mingjian_targetmod = fk.CreateTargetModSkill{
  name = "#mingjian_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@mingjian-turn") > 0 and scope == Player.HistoryPhase then
      return player:getMark("@@mingjian-turn")
    end
  end,
}
local xingshuai = fk.CreateTriggerSkill{
  name = "xingshuai$",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      not table.every(player.room:getOtherPlayers(player), function(p) return p.kingdom ~= "wei" end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == "wei" and room:askForSkillInvoke(p, self.name, data, "#xingshuai-invoke::"..player.id) then
        table.insert(targets, p)
      end
    end
    if #targets > 0 then
      for _, p in ipairs(targets) do
        room:recover{
          who = player,
          num = 1,
          recoverBy = p,
          skillName = self.name
        }
      end
    end
    if not player.dying then
      for _, p in ipairs(targets) do
        room:damage{
          to = p,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
mingjian:addRelatedSkill(mingjian_record)
mingjian:addRelatedSkill(mingjian_targetmod)
caorui:addSkill(huituo)
caorui:addSkill(mingjian)
caorui:addSkill(xingshuai)
Fk:loadTranslationTable{
  ["caorui"] = "曹叡",
  ["huituo"] = "恢拓",
  [":huituo"] = "当你受到伤害后，你可以令一名角色进行判定，若结果为：红色，其回复1点体力；黑色，其摸X张牌（X为伤害值）。",
  ["mingjian"] = "明鉴",
  [":mingjian"] = "出牌阶段限一次，你可以将所有手牌交给一名其他角色，然后该角色下回合的手牌上限+1，且出牌阶段内可以多使用一张【杀】。",
  ["xingshuai"] = "兴衰",
  [":xingshuai"] = "主公技，限定技，当你进入濒死状态时，你可令其他魏势力角色依次选择是否令你回复1点体力。选择是的角色在此次濒死结算结束后受到1点无来源的伤害。",
  ["#huituo-choose"] = "恢拓：你可以令一名角色判定，若为红色，其回复1点体力；黑色，其摸X张牌",
  ["@@mingjian"] = "明鉴",
  ["@@mingjian-turn"] = "明鉴",
  ["#xingshuai-invoke"] = "兴衰：你可以令%dest回复1点体力，结算后你受到1点伤害",

  ["$huituo1"] = "大展宏图，就在今日！",
  ["$huituo2"] = "富我大魏，扬我国威！",
  ["$mingjian1"] = "你我推心置腹，岂能相负。",
  ["$mingjian2"] = "孰忠孰奸，朕尚能明辨！",
  ["$xingshuai1"] = "百年兴衰皆由人，不由天！",
  ["$xingshuai2"] = "聚群臣而嘉勋，隆天子之气运！",
  ["~caorui"] = "悔不该耽于逸乐，至有今日……",
}

Fk:loadTranslationTable{
  ["nos__caoxiu"] = "曹休",
  ["nos__taoxi"] = "讨袭",
  [":nos__taoxi"] = "出牌阶段限一次，当你使用牌仅指定一名其他角色为目标后，你可以亮出其一张手牌直到回合结束，并且你可以于此回合内将此牌如手牌般使用。回合结束时，若该角色未失去此手牌，则你失去1点体力。",

  ["$nos__taoxi1"] = "策马疾如电，溃敌一瞬间。",
  ["$nos__taoxi2"] = "虎豹骑岂能徒有虚名？杀！",
  ["~nos__caoxiu"] = "兵行险招，终有一失。",
}

local caoxiu = General(extension, "caoxiu", "wei", 4)
local qianju = fk.CreateDistanceSkill{
  name = "qianju",
  correct_func = function(self, from, to)
    if from:hasSkill(self.name) then
      return -from:getLostHp()
    end
  end,
}
local qingxi = fk.CreateTriggerSkill{
  name = "qingxi",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and data.to and player:getEquipment(Card.SubtypeWeapon)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = Fk:getCardById(player:getEquipment(Card.SubtypeWeapon)).attack_range
    if #data.to.player_cards[Player.Hand] < n then
      data.damage = data.damage + 1
      return
    end
    if #room:askForDiscard(data.to, n, n, false, self.name, true, ".", "#qingxi-discard:::"..n) == n then
      room:throwCard({player:getEquipment(Card.SubtypeWeapon)}, self.name, player, data.to)
    else
      data.damage = data.damage + 1
    end
  end,
}
caoxiu:addSkill(qianju)
caoxiu:addSkill(qingxi)
Fk:loadTranslationTable{
  ["caoxiu"] = "曹休",
  ["qianju"] = "千驹",
  [":qianju"] = "锁定技，你计算与其他角色的距离-X。（X为你已损失的体力值）",
  ["qingxi"] = "倾袭",
  [":qingxi"] = "当你使用【杀】造成伤害时，若你装备区内有武器牌，你可以令该角色选择一项：1.弃置X张手牌，然后弃置你的武器牌；2.令此【杀】伤害+1（X为该武器的攻击范围）。",
  ["#qingxi-discard"] = "倾袭：你需弃置%arg张手牌，否则伤害+1",

  ["$qingxi1"] = "策马疾如电，溃敌一瞬间。",
  ["$qingxi2"] = "虎豹骑岂能徒有虚名？杀！",
  ["~caoxiu"] = "兵行险招，终有一失。",
}

local zhongyao = General(extension, "zhongyao", "wei", 3)
local huomo = fk.CreateViewAsSkill{
  name = "huomo",
  pattern = "^nullification|.|.|.|.|basic",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and Self:usedCardTimes(card.trueName, Player.HistoryTurn) == 0 then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isNude()
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isNude()
  end,
}
local huomo_trigger = fk.CreateTriggerSkill{  --FIXME: 体验不佳！
  name = "#huomo_trigger",
  events = {fk.PreCardUse, fk.PreCardRespond},
  mute = true,
  priority = 10,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and table.contains(data.card.skillNames, "huomo")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, TargetGroup:getRealTargets(data.tos))
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForCard(player, 1, 1, true, "huomo", true, ".|.|spade,club|.|.|^basic", "#huomo-card")
    if #card > 0 then
      room:moveCards({
        ids = card,
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = "huomo",
      })
      return false
    else
      return true
    end
  end,
}
local zuoding = fk.CreateTriggerSkill{
  name = "zuoding",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Play and data.firstTarget and
      data.card.suit == Card.Spade and #AimGroup:getAllTargets(data.tos) > 0 and player:getMark("zuoding-phase") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, AimGroup:getAllTargets(data.tos), 1, 1, "#zuoding-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:getPlayerById(self.cost_data):drawCards(1, self.name)
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and player.room.current.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zuoding-phase", 1)
  end,
}
huomo:addRelatedSkill(huomo_trigger)
zhongyao:addSkill(huomo)
zhongyao:addSkill(zuoding)
Fk:loadTranslationTable{
  ["zhongyao"] = "钟繇",
  ["huomo"] = "活墨",
  [":huomo"] = "当你需要使用基本牌时（你本回合使用过的基本牌除外），你可以将一张黑色非基本牌置于牌堆顶，视为使用此基本牌。",
  ["zuoding"] = "佐定",
  [":zuoding"] = "当其他角色于其出牌阶段内使用♠牌指定目标后，若本阶段没有角色受到过伤害，你可以令其中一名目标角色摸一张牌。",
  ["#huomo-card"] = "活墨：将一张黑色非基本牌置于牌堆顶",
  ["#zuoding-choose"] = "佐定：你可以令一名目标角色摸一张牌",

  ["$huomo1"] = "笔墨写春秋，挥毫退万敌！",
  ["$huomo2"] = "妙笔在手，研墨在心。",
  ["$zuoding1"] = "只有忠心，没有谋略，是不够的。",
  ["$zuoding2"] = "承君恩宠，报效国家！",
  ["~zhongyao"] = "墨尽，岁终。",
}

local liuchen = General(extension, "liuchen", "shu", 4)
local zhanjue = fk.CreateViewAsSkill{
  name = "zhanjue",
  anim_type = "offensive",
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("duel")
    card:addSubcards(Self:getCardIds(Player.Hand))
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:getMark("zhanjue-turn") < 2 and not player:isKongcheng()
  end,
}
local zhanjue_trigger = fk.CreateTriggerSkill{
  name = "#zhanjue_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "zhanjue") and data.damageDealt
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.dead then
      player:drawCards(1, "zhanjue")
      room:addPlayerMark(player, "zhanjue-turn", 1)
    end
    for _, p in ipairs(room.alive_players) do
      if data.damageDealt[p.id] then
        p:drawCards(1, "zhanjue")
        if p == player then
          room:addPlayerMark(player, "zhanjue-turn", 1)
        end
      end
    end
  end,
}
local qinwang = fk.CreateViewAsSkill{
  name = "qinwang$",
  anim_type = "defensive",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  before_use = function(self, player)
    player.room:askForDiscard(player, 1, 1, true, self.name, false, ".")
  end,
  view_as = function(self, cards)
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    return c
  end,
  enabled_at_play = function(self, player)
    return not player:isNude() and
      table.find(Fk:currentRoom().alive_players, function(p) return p ~= player and p.kingdom == "shu" end)
  end,
  enabled_at_response = function(self, player)
    return not player:isNude() and
      table.find(Fk:currentRoom().alive_players, function(p) return p ~= player and p.kingdom == "shu" end)
  end,
}
local qinwang_response = fk.CreateTriggerSkill{
  name = "#qinwang_response",
  events = {fk.PreCardUse, fk.PreCardRespond},
  mute = true,
  priority = 10,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and table.contains(data.card.skillNames, "qinwang")
  end,
  on_cost = function(self, event, target, player, data)
    player.room:doIndicate(player.id, TargetGroup:getRealTargets(data.tos))
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == "shu" then
        local cardResponded = room:askForResponse(p, "slash", "slash", "#qinwang-ask:%s", player.id)
        if cardResponded then
          room:responseCard({
            from = p.id,
            card = cardResponded,
            skipDrop = true,
          })

          data.card = cardResponded
          p:drawCards(1, "qinwang")
          return false
        end
      end
    end
    return true
  end,
}
zhanjue:addRelatedSkill(zhanjue_trigger)
qinwang:addRelatedSkill(qinwang_response)
liuchen:addSkill(zhanjue)
liuchen:addSkill(qinwang)
Fk:loadTranslationTable{
  ["liuchen"] = "刘谌",
  ["zhanjue"] = "战绝",
  [":zhanjue"] = "出牌阶段，你可以将所有手牌当【决斗】使用，然后你和受伤的角色各摸一张牌。若你此法摸过两张或更多的牌，则本阶段〖战绝〗失效。",
  ["qinwang"] = "勤王",
  [":qinwang"] = "主公技，当你需要使用或打出【杀】时，你可以弃置一张牌，然后令其他蜀势力角色选择是否打出一张【杀】（视为由你使用或打出）。"..
  "若有角色响应，该角色摸一张牌。",

  ["$zhanjue1"] = "成败在此一举，杀！",
  ["$zhanjue2"] = "此刻，唯有死战，安能言降！",
  ["$qinwang1"] = "大厦倾危，谁堪栋梁！",
  ["$qinwang2"] = "国有危难，哪位将军请战？",
  ["~liuchen"] = "无言对百姓，有愧，见先祖……",
}

local xiahoushi = General(extension, "xiahoushi", "shu", 3, 3, General.Female)
local qiaoshi = fk.CreateTriggerSkill{
  name = "qiaoshi",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and target.phase == Player.Finish and
      player:getHandcardNum() == target:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qiaoshi-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    target:drawCards(1, self.name)
  end,
}
local yanyu = fk.CreateActiveSkill{
  name = "yanyu",
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:moveCards({
      ids = effect.cards,
      from = effect.from,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,  --TODO: reason recast
    })
    player:drawCards(1, self.name)
  end,
}
local yanyu_record = fk.CreateTriggerSkill{
  name = "#yanyu_record",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == player.Play and player:usedSkillTimes("yanyu", Player.HistoryPhase) > 1 and
      not table.every(player.room:getOtherPlayers(player), function(p) return p.gender ~= General.Male end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
      return p.gender == General.Male end), function(p) return p.id end), 1, 1, "#yanyu-draw", self.name, true)
    if #to > 0 then
      self.cost_data = room:getPlayerById(to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    self.cost_data:drawCards(2, "yanyu")
  end,
}
yanyu:addRelatedSkill(yanyu_record)
xiahoushi:addSkill(qiaoshi)
xiahoushi:addSkill(yanyu)
Fk:loadTranslationTable{
  ["xiahoushi"] = "夏侯氏",
  ["qiaoshi"] = "樵拾",
  [":qiaoshi"] = "其他角色的结束阶段，若其手牌数等于你，你可以与其各摸一张牌。",
  ["yanyu"] = "燕语",
  [":yanyu"] = "出牌阶段，你可以重铸【杀】；出牌阶段结束时，若你于此阶段内重铸过两张或更多的【杀】，则你可以令一名男性角色摸两张牌。",
  ["#qiaoshi-invoke"] = "樵拾：你可以与 %dest 各摸一张牌",
  ["#yanyu_record"] = "燕语",
  ["#yanyu-draw"] = "燕语：你可以令一名男性角色摸两张牌",

  ["~xiahoushi"] = "愿有来世，不负前缘……",
  ["$qiaoshi1"] = "樵前情窦开，君后寻迹来。",
  ["$qiaoshi2"] = "樵心遇郎君，妾心涟漪生。",
  ["$yanyu1"] = "伴君一生不寂寞。",
  ["$yanyu2"] = "感君一回顾，思君朝与暮。",
}

local zhangyi = General(extension, "zhangyi", "shu", 4)
local wurong = fk.CreateActiveSkill{
  name = "wurong",
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
    local fromCard = room:askForCard(player, 1, 1, false, self.name, false, ".", "#wurong-show")[1]
    local toCard = room:askForCard(target, 1, 1, false, self.name, false, ".", "#wurong-show")[1]
    player:showCards(fromCard)
    target:showCards(toCard)
    if Fk:getCardById(fromCard).trueName == "slash" and Fk:getCardById(toCard).name ~= "jink" then
      room:throwCard({fromCard}, self.name, player, player)
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
    if Fk:getCardById(fromCard).trueName ~= "slash" and Fk:getCardById(toCard).name == "jink" then
      room:throwCard({fromCard}, self.name, player, player)
      local id = room:askForCardChosen(player, target, "he", self.name)
      room:obtainCard(player, id, false)
    end
  end,
}
local shizhi = fk.CreateFilterSkill{
  name = "shizhi",
  card_filter = function(self, to_select, player)
    --FIXME: filter skill isn't status skill, can't filter card which exists before hp change
    return player:hasSkill(self.name) and player.hp == 1 and to_select.name == "jink"
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
}
zhangyi:addSkill(wurong)
zhangyi:addSkill(shizhi)
Fk:loadTranslationTable{
  ["zhangyi"] = "张嶷",
  ["wurong"] = "怃戎",
  [":wurong"] = "出牌阶段限一次，你可以和一名其他角色同时展示一张手牌：若你展示的是【杀】且该角色不是【闪】，你弃置此【杀】，然后对其造成1点伤害；"..
  "若你展示的不是【杀】且该角色是【闪】，你弃置此牌，然后获得其一张牌。",
  ["shizhi"] = "矢志",
  [":shizhi"] = "锁定技，若你的体力值为1，你的【闪】视为【杀】。",
  ["#wurong-show"] = "怃戎：选择一张展示的手牌",

  ["$wurong1"] = "兵不血刃，亦可先声夺人。",
  ["$wurong2"] = "从则安之，犯则诛之。",
  ["~zhangyi"] = "大丈夫当战死沙场，马革裹尸而还。",
}

local quancong = General(extension, "quancong", "wu", 4)
local zhenshan = fk.CreateViewAsSkill{
  name = "zhenshan",
  pattern = "^nullification|.|.|.|.|basic",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic then
        table.insertIfNeed(names, card.name)
      end
    end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return (#p.player_cards[Player.Hand] < player:getHandcardNum()) end), function(p) return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhenshan-choose", self.name, true)
    if #to > 0 then
      to = to[1]
    else
      to =table.random(targets)
    end
    local cards1 = table.clone(player.player_cards[Player.Hand])
    local cards2 = table.clone(room:getPlayerById(to).player_cards[Player.Hand])
    local move1 = {
      from = player.id,
      ids = cards1,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,  --FIXME: this is still visible! same problem with dimeng!
    }
    local move2 = {
      from = to,
      ids = cards2,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    room:moveCards(move1, move2)
    local move3 = {
      ids = table.filter(cards1, function(id) return room:getCardArea(id) == Card.Processing end),
      fromArea = Card.Processing,
      to = to,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    local move4 = {
      ids = table.filter(cards2, function(id) return room:getCardArea(id) == Card.Processing end),
      fromArea = Card.Processing,
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    room:moveCards(move3, move4)
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      table.find(Fk:currentRoom().alive_players, function(p) return p:getHandcardNum() < player:getHandcardNum() end)
  end,
  enabled_at_response = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      table.find(Fk:currentRoom().alive_players, function(p) return p:getHandcardNum() < player:getHandcardNum() end)
  end,
}
quancong:addSkill(zhenshan)
Fk:loadTranslationTable{
  ["quancong"] = "全琮",
  ["zhenshan"] = "振赡",
  [":zhenshan"] = "每回合限一次，当你需要使用或打出一张基本牌时，你可以与一名手牌数少于你的角色交换手牌，若如此做，视为你使用或打出此牌。",
  ["#zhenshan-choose"] = "振赡：与一名手牌数少于你的角色交换手牌",

  ["$zhenshan1"] = "看我如何以无用之力换己所需，哈哈哈！",
  ["$zhenshan2"] = "民不足食，何以养军？",
  ["~quancong"] = "儿啊，好好报答吴王知遇之恩……",
}

local sunxiu = General(extension, "sunxiu", "wu", 3)
local yanzhu = fk.CreateActiveSkill{
  name = "yanzhu",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cancelable = true
    if #target.player_cards[Player.Equip] == 0 then
      cancelable = false
    end
    if #room:askForDiscard(target, 1, 1, true, self.name, cancelable, ".", "#yanzhu-discard:"..player.id) == 0 and cancelable then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(target.player_cards[Player.Equip])
      room:obtainCard(player.id, dummy, true, fk.ReasonGive)
      room:handleAddLoseSkills(player, "-yanzhu", nil, true, false)
      room:setPlayerMark(player, self.name, 1)
    end
  end,
}
local xingxue = fk.CreateTriggerSkill{
  name = "xingxue",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local n = player.hp
    if player:getMark("yanzhu") > 0 then
      n = player.maxHp
    end
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id end), 1, n, "#xingxue-choose:::"..n, self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local to = room:getPlayerById(id)
      to:drawCards(1, self.name)
      local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#xingxue-card")
      room:moveCards({
        ids = card,
        from = id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
    end
  end,
}
local zhaofu = fk.CreateAttackRangeSkill{
  name = "zhaofu$",
  within_func = function (self, from, to)
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:hasSkill(self.name) and p:distanceTo(to) == 1 and from.kingdom == "wu" and from ~= p then
        return true
      end
    end
  end,
}
sunxiu:addSkill(yanzhu)
sunxiu:addSkill(xingxue)
sunxiu:addSkill(zhaofu)
Fk:loadTranslationTable{
  ["sunxiu"] = "孙休",
  ["yanzhu"] = "宴诛",
  [":yanzhu"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.弃置一张牌；2.交给你装备区内所有的牌，你失去〖宴诛〗并修改〖兴学〗为“X为你的体力上限”。",
  ["xingxue"] = "兴学",
  [":xingxue"] = "结束阶段，你可以令X名角色依次摸一张牌并将一张牌置于牌堆顶（X为你的体力值）。",
  ["zhaofu"] = "诏缚",
  [":zhaofu"] = "主公技，锁定技，与你距离为1的角色视为在其他吴势力角色的攻击范围内。",
  ["#yanzhu-discard"] = "宴诛：弃置一张牌，或点“取消”将所有装备交给 %src（若没装备则必须弃一张牌）",
  ["#xingxue-choose"] = "兴学：你可以令至多%arg名角色依次摸一张牌并将一张牌置于牌堆顶",
  ["#xingxue-card"] = "兴学：将一张牌置于牌堆顶",

  ["$yanzhu1"] = "不诛此权臣，朕，何以治天下？",
  ["$yanzhu2"] = "大局已定，你还是放弃吧。",
  ["$xingxue1"] = "汝等都是国之栋梁。",
  ["$xingxue2"] = "文修武备，才是兴国之道。",
  ["~sunxiu"] = "崇文抑武，朕错了吗？",
}

local nos__zhuzhi = General(extension, "nos__zhuzhi", "wu", 4)
local nos__anguo = fk.CreateActiveSkill{
  name = "nos__anguo",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and #Fk:currentRoom():getPlayerById(to_select).player_cards[Player.Equip] > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = #table.filter(room:getOtherPlayers(target), function(p) return (target:inMyAttackRange(p)) end)
    local equip = room:askForCardChosen(player, target, "e", self.name)
    room:obtainCard(target, equip, true, fk.ReasonJustMove)
    if n > #table.filter(room:getOtherPlayers(target), function(p) return (target:inMyAttackRange(p)) end) then
      player:drawCards(1, self.name)
    end
  end,
}
nos__zhuzhi:addSkill(nos__anguo)
Fk:loadTranslationTable{
  ["nos__zhuzhi"] = "朱治",
  ["nos__anguo"] = "安国",
  [":nos__anguo"] = "出牌阶段限一次，你可以选择其他角色场上的一张装备牌并令其获得之，然后若其攻击范围内的角色因此而变少，则你摸一张牌。",

  ["$nos__anguo1"] = "止干戈，休战事。",
  ["$nos__anguo2"] = "安邦定国，臣子分内之事。",
  ["~nos__zhuzhi"] = "集毕生之力，保国泰民安。",
}

local zhuzhi = General(extension, "zhuzhi", "wu", 4)
local function doAnguo(player, type, source)
  local room = player.room
  if type == "draw" then
    if table.every(room.alive_players, function (p) return p:getHandcardNum() >= player:getHandcardNum() end) then
      player:drawCards(1, "anguo")
      return true
    end
  elseif type == "recover" then
    if player:isWounded() and table.every(room.alive_players, function (p) return p.hp >= player.hp end) then
      room:recover({
        who = player,
        num = 1,
        recoverBy = source,
        skillName = "anguo",
      })
      return true
    end
  elseif type == "equip" then
    if #player.player_cards[Player.Equip] < 4 and table.every(room.alive_players, function (p)
      return #p.player_cards[Player.Equip] >= #player.player_cards[Player.Equip] end) then
      local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
      local cards = {}
      for i = 1, #room.draw_pile, 1 do
        local card = Fk:getCardById(room.draw_pile[i])
        for _, t in ipairs(types) do
          if card.sub_type == t and player:getEquipment(t) == nil then
            table.insertIfNeed(cards, room.draw_pile[i])
          end
        end
      end
      if #cards > 0 then
        room:useCard({
          from = player.id,
          tos = {{player.id}},
          card = Fk:getCardById(table.random(cards)),
        })
        return true
      end
    end
  end
  return false
end
local anguo = fk.CreateActiveSkill{
  name = "anguo",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
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
    local types = {"equip", "recover", "draw"}
    for i = 3, 1, -1 do
      if doAnguo(target, types[i], player) then
        table.removeOne(types, types[i])
      end
    end
    for i = #types, 1, -1 do
      doAnguo(player, types[i], player)
    end
  end,
}
zhuzhi:addSkill(anguo)
Fk:loadTranslationTable{
  ["zhuzhi"] = "朱治",
  ["anguo"] = "安国",
  [":anguo"] = "出牌阶段限一次，你可以选择一名其他角色，若其手牌数为全场最少，其摸一张牌；体力值为全场最低，回复1点体力；"..
  "装备区内牌数为全场最少，随机使用一张装备牌。然后若该角色有未执行的效果且你满足条件，你执行之。",

  ["~zhuzhi"] = "集毕生之力，保国泰民安。",
  ["$anguo1"] = "止干戈，休战事。",
  ["$anguo2"] = "安邦定国，臣子分内之事。",
}

local gongsunyuan = General(extension, "gongsunyuan", "qun", 4)
local huaiyi = fk.CreateActiveSkill{
  name = "huaiyi",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function()
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    local colors = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(colors, Fk:getCardById(id):getColorString())
    end
    if #colors < 2 then return end
    local color = room:askForChoice(player, colors, self.name)
    local throw = {}
    for _, id in ipairs(cards) do
      if Fk:getCardById(id):getColorString() == color then
        table.insert(throw, id)
      end
    end
    room:throwCard(throw, self.name, player, player)
    local targets = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (not p:isNude()) end), function(p) return p.id end), 1, #throw, "#huaiyi-choose:::"..tostring(#throw), self.name, true)
    if #targets > 0 then
      local get = {}
      for _, p in ipairs(targets) do
        local id = room:askForCardChosen(player, room:getPlayerById(p), "he", self.name)
        table.insert(get, id)
      end
      for _, id in ipairs(get) do
        room:obtainCard(player, id, false, fk.ReasonPrey)
      end
      if #get > 1 then
        room:loseHp(player, 1, self.name)
      end
    end
  end,
}
gongsunyuan:addSkill(huaiyi)
Fk:loadTranslationTable{
  ["gongsunyuan"] = "公孙渊",
  ["huaiyi"] = "怀异",
  [":huaiyi"] = "出牌阶段限一次，你可以展示所有手牌，若其中包含两种颜色，则你弃置其中一种颜色的牌，然后获得至多X名角色的各一张牌"..
  "（X为你以此法弃置的手牌数）。若你获得的牌大于一张，则你失去1点体力。",
  ["#huaiyi-choose"] = "怀异：你可以获得至多%arg名角色各一张牌",

  ["$huaiyi1"] = "此等小利，焉能安吾雄心？",
  ["$huaiyi2"] = "一生纵横，怎可对他人称臣！",
  ["~gongsunyuan"] = "天不容我公孙家……",
}

local guotupangji = General(extension, "guotupangji", "qun", 3)
local jigong = fk.CreateTriggerSkill{
  name = "jigong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@jigong-turn", data.damage)
  end,
}
local jigong_maxcards = fk.CreateMaxCardsSkill{
  name = "#jigong_maxcards",
  fixed_func = function (self, player)
    if player:usedSkillTimes("jigong", Player.HistoryTurn) > 0 then
      return player:getMark("@jigong-turn")
    end
  end,
}
local shifei = fk.CreateTriggerSkill{
  name = "shifei",
  events = {fk.AskForCardUse, fk.AskForCardResponse},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      player.room.current and not player.room.current.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room.current:drawCards(1, self.name)
    local n = #room.current.player_cards[Player.Hand]
    for _, p in ipairs(room:getOtherPlayers(room.current)) do
      if #p.player_cards[Player.Hand] > n then
        n = #p.player_cards[Player.Hand]
      end
    end
    local targets = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if #p.player_cards[Player.Hand] == n then
        table.insert(targets, p.id)
      end
    end
    if #targets == 1 and targets[1] == room.current.id then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#shifei-choose", self.name, false)
    local to
    if #tos > 0 then
      to = tos[1]
    else
      to = table.random(targets)
    end
    local id = room:askForCardChosen(player, room:getPlayerById(to), "he", self.name)
    room:throwCard({id}, self.name, room:getPlayerById(to), player)
    if event == fk.AskForCardUse then
      data.result = {
        from = player.id,
        card = Fk:cloneCard("jink"),
      }
      data.result.card.skillName = self.name
      if data.eventData then
        data.result.toCard = data.eventData.toCard
        data.result.responseToEvent = data.eventData.responseToEvent
      end
    else
      data.result = Fk:cloneCard("jink")
      data.result.skillName = self.name
    end
    return true
  end
}
jigong:addRelatedSkill(jigong_maxcards)
guotupangji:addSkill(jigong)
guotupangji:addSkill(shifei)
Fk:loadTranslationTable{
  ["guotupangji"] = "郭图逄纪",
  ["jigong"] = "急攻",
  [":jigong"] = "出牌阶段开始时，你可以摸两张牌，然后你本回合的手牌上限等于你本阶段造成的伤害值。",
  ["shifei"] = "饰非",
  [":shifei"] = "当你需要使用或打出【闪】时，你可以令当前回合角色摸一张牌，然后若其手牌数不是全场唯一最多的，你弃置一名手牌全场最多的角色一张牌，"..
  "视为你使用或打出一张【闪】。",
  ["@jigong-turn"] = "急攻",
  ["#shifei-choose"] = "饰非：弃置全场手牌最多的一名角色的一张牌",

  ["$jigong1"] = "不惜一切代价，拿下此人！",
  ["$jigong2"] = "曹贼势颓，主公速击之。",
  ["$shifei1"] = "良谋失利，罪在先锋！",
  ["$shifei2"] = "计略周详，怎奈指挥不当。",
  ["~guotupangji"] = "大势已去，无力回天……",
}

return extension
