local extension = Package("sp_jsp")
extension.extensionName = "sp"

Fk:loadTranslationTable{
  ["sp_jsp"] = "JSP",
  ["jsp"] = "JSP",
}

local sunshangxiang = General(extension, "jsp__sunshangxiang", "shu", 3, 3, General.Female)
local liangzhu = fk.CreateTriggerSkill{
  name = "liangzhu",
  anim_type = "drawcard",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#liangzhu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"draw1", "liangzhu_draw2"}, self.name)
    if choice == "draw1" then
      player:drawCards(1, self.name)
      room:setPlayerMark(player, self.name, 1)
    else
      room:doIndicate(player.id, {target.id})
      target:drawCards(2, self.name)
      room:setPlayerMark(target, self.name, 1)
    end
  end,
}
local fanxiang = fk.CreateTriggerSkill{
  name = "fanxiang",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return table.find(player.room.alive_players, function(p) return p:isWounded() and p:getMark("liangzhu") > 0 end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:handleAddLoseSkills(player, "-liangzhu|xiaoji", nil)
  end,
}
sunshangxiang:addSkill(liangzhu)
sunshangxiang:addSkill(fanxiang)
sunshangxiang:addRelatedSkill("xiaoji")
Fk:loadTranslationTable{
  ["jsp__sunshangxiang"] = "孙尚香",
  ["liangzhu"] = "良助",
  [":liangzhu"] = "当一名角色于其出牌阶段内回复体力时，你可以选择一项：摸一张牌，或令该角色摸两张牌。",
  ["fanxiang"] = "返乡",
  [":fanxiang"] = "觉醒技，准备阶段开始时，若全场有至少一名已受伤的角色，且你曾发动〖良助〗令其摸牌，则你回复1点体力和体力上限，"..
  "失去技能〖良助〗并获得技能〖枭姬〗。",
  ["#liangzhu-invoke"] = "良助：你可以摸一张牌或令 %dest 摸两张牌",
  ["liangzhu_draw2"] = "其摸两张牌",
}

local machao = General(extension, "jsp__machao", "qun", 4)
local zhuiji = fk.CreateDistanceSkill{
  name = "zhuiji",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if from:hasSkill(self.name) then
      if from.hp > to.hp then
        from:setFixedDistance(to, 1)
      else
        from:removeFixedDistance(to)
      end
    end
    return 0
  end,
}
local cihuai = fk.CreateViewAsSkill{
  name = "cihuai",
  anim_type = "offensive",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    if Self:getMark(self.name) == 0 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    return c
  end,
}
local cihuai_invoke = fk.CreateTriggerSkill{
  name = "#cihuai_invoke",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("cihuai") and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "cihuai")
  end,
  on_use = function(self, event, target, player, data)
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).trueName == "slash" then
        return
      end
    end
    player.room:addPlayerMark(player, "cihuai", 1)
  end,

  refresh_events = {fk.AfterCardsMove, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name, true) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id or move.to == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.toArea == Card.PlayerHand then
                return true
              end
            end
          end
        end
      else
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "cihuai", 0)
  end,
}
cihuai:addRelatedSkill(cihuai_invoke)
machao:addSkill(zhuiji)
machao:addSkill(cihuai)
Fk:loadTranslationTable{
  ["jsp__machao"] = "马超",
  ["zhuiji"] = "追击",
  [":zhuiji"] = "锁定技，你计算体力值比你少的角色的距离始终为1。",
  ["cihuai"] = "刺槐",
  [":cihuai"] = "出牌阶段开始时，你可以展示你的手牌，若其中没有【杀】，则你使用或打出【杀】时不需要手牌，直到你的手牌数变化或有角色死亡。",
  ["#cihuai_invoke"] = "刺槐",
}

local guanyu = General(extension, "jsp__guanyu", "wei", 4)
local danji = fk.CreateTriggerSkill{
  name = "danji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player.player_cards[Player.Hand] > player.hp and not string.find(player.room:getLord().general, "liubei")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "mashu|nuzhan", nil)
  end,
}
local nuzhan = fk.CreateTriggerSkill{
  name = "nuzhan",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardUseDeclared, fk.PreCardUse},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name, false, true) and data.card and data.card.trueName == "slash" and
      data.card:isVirtual() and #data.card.subcards == 1 then
      if event == fk.AfterCardUseDeclared then
        return player.phase == Player.Play and Fk:getCardById(data.card.subcards[1]).type == Card.TypeTrick
      else
        return Fk:getCardById(data.card.subcards[1]).type == Card.TypeEquip
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      player:addCardUseHistory(data.card.trueName, -1)
    else
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
}
guanyu:addSkill(danji)
guanyu:addSkill("wusheng")
guanyu:addRelatedSkill(nuzhan)
Fk:loadTranslationTable{
  ["jsp__guanyu"] = "关羽",
  ["danji"] = "单骑",
  [":danji"] = "觉醒技，准备阶段开始时，若你的手牌数大于体力值且本局游戏的主公不是刘备，你须减1点体力上限，然后获得技能〖马术〗和〖怒斩〗。",
  ["nuzhan"] = "怒斩",
  [":nuzhan"] = "锁定技，你将锦囊牌当【杀】使用时，此【杀】不计入出牌阶段使用次数；你将装备牌当【杀】使用时，此【杀】伤害+1。",
}

local jiangwei = General(extension, "jsp__jiangwei", "wei", 4)
local kunfen = fk.CreateTriggerSkill{
  name = "kunfen",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    if player:usedSkillTimes("fengliang", Player.HistoryGame) == 0 then
      return true
    else
      return player.room:askForSkillInvoke(player, self.name)
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
    if player:isAlive() then
      player.room:drawCards(player, 2, self.name)
    end
  end,
}
local fengliang = fk.CreateTriggerSkill{
  name = "fengliang",
  anim_type = "defensive",
  events = {fk.EnterDying},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:recover({
      who = player,
      num = 2 - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "tiaoxin", nil)
  end,
}
jiangwei:addSkill(kunfen)
jiangwei:addSkill(fengliang)
jiangwei:addRelatedSkill("tiaoxin")
Fk:loadTranslationTable{
  ["jsp__jiangwei"] = "姜维",
  ["kunfen"] = "困奋",
  [":kunfen"] = "锁定技，结束阶段开始时，你失去1点体力，然后摸两张牌。",
  ["fengliang"] = "逢亮",
  [":fengliang"] = "觉醒技，当你进入濒死状态时，你减1点体力上限并将体力值回复至2点，然后获得技能〖挑衅〗，将技能〖困奋〗改为非锁定技。",
}

local zhaoyun = General(extension, "jsp__zhaoyun", "qun", 3)
local chixin = fk.CreateViewAsSkill{
  name = "chixin",
  pattern = "slash,jink",
  interaction = function()
    local names = {}
    if Fk.currentResponsePattern == nil and Self:canUse(Fk:cloneCard("slash")) then
      table.insertIfNeed(names, "slash")
    else
      for _, name in ipairs({"slash", "jink"}) do
        if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(name)) then
          table.insertIfNeed(names, name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}  --FIXME: 体验很不好！
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Diamond
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
}
local chixin_record = fk.CreateTriggerSkill{
  name = "#chixin_record",

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" then
      local to = player.room:getPlayerById(data.to)
      return to:getMark("chixin-turn") == 0 and player:inMyAttackRange(to)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    player:addCardUseHistory(data.card.trueName, -1)
    room:addPlayerMark(room:getPlayerById(data.to), "chixin-turn", 1)
  end,
}
local suiren = fk.CreateTriggerSkill{
  name = "suiren",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start and player:hasSkill("yicong", true)  --失去义从是发动条件吗？
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function (p)
      return p.id end), 1, 1, "#suiren-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-yicong", nil, true, false)
    room:changeMaxHp(player, 1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:getPlayerById(self.cost_data):drawCards(3, self.name)
  end,
}
chixin:addRelatedSkill(chixin_record)
zhaoyun:addSkill("yicong")
zhaoyun:addSkill(chixin)
zhaoyun:addSkill(suiren)
Fk:loadTranslationTable{
  ["jsp__zhaoyun"] = "赵云",
  ["chixin"] = "赤心",
  [":chixin"] = "你可以将<font color='red'>♦</font>牌当【杀】或【闪】使用或打出。出牌阶段，你对你攻击范围内的每名角色均可使用一张【杀】。",
  ["suiren"] = "随仁",
  [":suiren"] = "限定技，准备阶段开始时，你可以失去技能〖义从〗，然后加1点体力上限并回复1点体力，再令一名角色摸三张牌。",
  ["#suiren-choose"] = "随仁：你可以失去〖义从〗，然后加1点体力上限并回复1点体力，令一名角色摸三张牌",
}

local huangyueying = General(extension, "jsp__huangyueying", "qun", 3, 3, General.Female)
local jiqiao = fk.CreateTriggerSkill{
  name = "jiqiao",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local n = #player.room:askForDiscard(player, 1, 999, true, self.name, true, ".|.|.|.|.|equip", "#jiqiao-invoke")
    if n > 0 then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(2*self.cost_data)
    room:moveCards{
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    }
    local get = {}
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).type == Card.TypeTrick then
        table.insert(get, cards[i])
        table.removeOne(cards, cards[i])
      end
    end
    if #get > 0 then
      room:delay(1000)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    end
    if #cards > 0 then
      room:delay(1000)
      room:moveCards{
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
    end
  end,
}
local linglong = fk.CreateMaxCardsSkill{
  name = "linglong",
  correct_func = function(self, player)
    if player:hasSkill(self.name) and player:getEquipment(Card.SubtypeOffensiveRide) == nil and
      player:getEquipment(Card.SubtypeDefensiveRide) == nil then
      return 1
    end
    return 0
  end,
}
local linglong_record = fk.CreateTriggerSkill{
  name = "#linglong_record",

  refresh_events = {fk.GameStart, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
          if move.to == player.id and move.toArea == Player.Equip then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)  --FIXME: 虚拟装备技能应该用statusSkill而非triggerSkill
    if player:getEquipment(Card.SubtypeArmor) == nil and not player:hasSkill("#eight_diagram_skill", true) then
      player.room:handleAddLoseSkills(player, "#eight_diagram_skill", "linglong", false, true)
    elseif player:getEquipment(Card.SubtypeArmor) ~= nil and player:hasSkill("#eight_diagram_skill", true) then
      player.room:handleAddLoseSkills(player, "-#eight_diagram_skill", nil, false, true)
    end
    if player:getEquipment(Card.SubtypeTreasure) == nil and not player:hasSkill("qicai", true) then
      player.room:handleAddLoseSkills(player, "qicai", "linglong", false, true)
    elseif player:getEquipment(Card.SubtypeTreasure) ~= nil and player:hasSkill("qicai", true) then
      player.room:handleAddLoseSkills(player, "-qicai", nil, false, true)
    end
  end,
}
linglong:addRelatedSkill(linglong_record)
huangyueying:addSkill(jiqiao)
huangyueying:addSkill(linglong)
huangyueying:addRelatedSkill("qicai")
Fk:loadTranslationTable{
  ["jsp__huangyueying"] = "黄月英",
  ["jiqiao"] = "机巧",
  [":jiqiao"] = "出牌阶段开始时，你可以弃置任意张装备牌，然后亮出牌堆顶两倍数量的牌，你获得其中的锦囊牌，将其余的牌置入弃牌堆。",
  ["linglong"] = "玲珑",
  [":linglong"] = "锁定技，若你的装备区没有防具牌，视为你装备着【八卦阵】；若你的装备区没有坐骑牌，你的手牌上限+1；"..
  "若你的装备区没有宝物牌，视为你拥有技能〖奇才〗。",
  ["#jiqiao-invoke"] = "机巧：你可以弃置任意张装备牌，亮出牌堆顶两倍数量的牌并获得其中的锦囊牌",
}

return extension
