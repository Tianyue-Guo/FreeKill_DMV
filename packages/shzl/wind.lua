local extension = Package:new("wind")
extension.extensionName = "shzl"

Fk:loadTranslationTable{
  ["wind"] = "神话再临·风",
}

local xiahouyuan = General(extension, "xiahouyuan", "wei", 4)
local shensu = fk.CreateTriggerSkill{
  name = "shensu",
  anim_type = "offensive",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if data.to == Player.Judge then
        return true
      elseif data.to == Player.Play then
        return not player:isNude()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local slash = Fk:cloneCard("slash")
    local max_num = slash.skill:getMaxTargetNum(player, slash)
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not player:isProhibited(p, slash) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 or max_num == 0 then return end
    if data.to == Player.Judge then
      local to = room:askForChoosePlayers(player, targets, 1, max_num, "#shensu1-choose", self.name, true)
      if #to > 0 then
        self.cost_data = {to[1]}
        return true
      end
    elseif data.to == Player.Play then
      --FIXME: 这个方法在没有装备牌的时候不会询问！会暴露手牌信息！
      local tos, id = room:askForChooseCardAndPlayers(player, targets, 1, max_num, ".|.|.|.|.|equip", "#shensu2-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = {tos[1], id}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.to == Player.Judge then
      player:skip(Player.Judge)
      player:skip(Player.Draw)
    elseif data.to == Player.Play then
      player:skip(Player.Play)
      room:throwCard({self.cost_data[2]}, self.name, player, player)
    end
    room:useVirtualCard("slash", nil, player, table.map(self.cost_data, Util.Id2PlayerMapper), self.name, true)
    return true
  end,
}
xiahouyuan:addSkill(shensu)
Fk:loadTranslationTable{
  ["xiahouyuan"] = "夏侯渊",
  ["shensu"] = "神速",
  [":shensu"] = "你可以做出如下选择：1.跳过判定阶段和摸牌阶段；2.跳过出牌阶段并弃置一张装备牌。你每选择一项，便视为你使用一张无距离限制的【杀】。",
  ["#shensu1-choose"] = "神速：你可以跳过判定阶段和摸牌阶段，视为使用一张无距离限制的【杀】",
  ["#shensu2-choose"] = "神速：你可以跳过出牌阶段并弃置一张装备牌，视为使用一张无距离限制的【杀】",

  ["$shensu1"] = "吾善于千里袭人！",
  ["$shensu2"] = "取汝首级，有如探囊取物！",
  ["~xiahouyuan"] = "竟然…比我还…快…",
}

local caoren = General(extension, "caoren", "wei", 4)
local jushou = fk.CreateTriggerSkill{
  name = "jushou",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    player.room:drawCards(player, 3, self.name)
    player:turnOver()
  end,
}
caoren:addSkill(jushou)
Fk:loadTranslationTable{
  ["caoren"] = "曹仁",
  ["jushou"] = "据守",
  [":jushou"] = "结束阶段，你可以摸三张牌，然后翻面。",

  ["$jushou1"] = "我先休息一会！",
  ["$jushou2"] = "尽管来吧！",
  ["~caoren"] = "实在是守不住！",
}

local huangzhong = General(extension, "huangzhong", "shu", 4)
local liegong = fk.CreateTriggerSkill{
  name = "liegong",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self.name)) then return end
    local room = player.room
    local to = room:getPlayerById(data.to)
    local num = #to:getCardIds(Player.Hand)
    local filter = num <= player:getAttackRange() or num >= player.hp
    return data.card.trueName == "slash" and filter and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insert(data.disresponsiveList, data.to)
  end,
}
huangzhong:addSkill(liegong)
Fk:loadTranslationTable{
  ["huangzhong"] = "黄忠",
  ["liegong"] = "烈弓",
  [":liegong"] = "当你于出牌阶段内使用【杀】指定一个目标后，若该角色的手牌数不小于你的体力值或不大于你的攻击范围，则你可以令其不能使用【闪】响应此【杀】。",

  ["$liegong1"] = "百步穿杨！",
  ["$liegong2"] = "中！",
  ["~huangzhong"] = "不得不服老啦~",
}

local weiyan = General(extension, "weiyan", "shu", 4)
local kuanggu = fk.CreateTriggerSkill{
  name = "kuanggu",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player and (data.extra_data or {}).kuanggucheak and player:isWounded()
  end,
  on_trigger = function(self, event, target, player, data)
    for i = 1, data.damage do
      if not (player:isWounded() and player:hasSkill(self.name)) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
  end,

  refresh_events = {fk.BeforeHpChanged},
  can_refresh = function(self, event, target, player, data)
    if data.damageEvent and player == data.damageEvent.from and player:distanceTo(target) < 2 then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.damageEvent.extra_data = data.damageEvent.extra_data or {}
    data.damageEvent.extra_data.kuanggucheak = true
  end,
}
weiyan:addSkill(kuanggu)
Fk:loadTranslationTable{
  ["weiyan"] = "魏延",
  ["kuanggu"] = "狂骨",
  [":kuanggu"] = "锁定技，当你对距离1以内的一名角色造成1点伤害后，你回复1点体力。",

  ["$kuanggu1"] = "我会怕你吗！",
  ["$kuanggu2"] = "真是美味啊！",
  ["~weiyan"] = "谁敢杀我！饿啊！",
}

local xiaoqiao = General(extension, "xiaoqiao", "wu", 3, 3, General.Female)
local tianxiang = fk.CreateTriggerSkill{
  name = "tianxiang",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player
  end,
  on_cost = function(self, event, target, player, data)
    local tar, card =  player.room:askForChooseCardAndPlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, ".|.|heart|hand", "#tianxaing-choose", self.name, true)
    if #tar > 0 and card then
      self.cost_data = {tar[1], card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    room:throwCard(self.cost_data[2], self.name, player, player)
    room:damage{
      from = data.from,
      to = to,
      damage = data.damage,
      damageType = data.type,
      skillName = self.name,
      card = data.card,
    }
    if not to.dead then
      to:drawCards(to:getLostHp(), self.name)
    end
    return true
  end,
}
local hongyan = fk.CreateFilterSkill{
  name = "hongyan",
  card_filter = function(self, to_select, player)
    return to_select.suit == Card.Spade and player:hasSkill(self.name)
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard(to_select.name, Card.Heart, to_select.number)
  end,
}
xiaoqiao:addSkill(tianxiang)
xiaoqiao:addSkill(hongyan)
Fk:loadTranslationTable{
  ["xiaoqiao"] = "小乔",
  ["tianxiang"] = "天香",
  [":tianxiang"] = "当你受到伤害时，你可以弃置一张<font color='red'>♥</font>手牌并选择一名其他角色。若如此做，你将此伤害转移给该角色，然后其摸X张牌（X为其已损失体力值）。",
  ["#tianxaing-choose" ] = "天香：弃置一张<font color='red'>♥</font>手牌将此伤害转移给一名其他角色，然后其摸X张牌（X为其已损失体力值）",
  ["hongyan"] = "红颜",
  [":hongyan"] = "锁定技，你的♠牌视为<font color='red'>♥</font>牌。",

  ["$tianxiang2"] = "接着哦~",
  ["$tianxiang1"] = "替我挡着~",
  ["$hongyan"] = "（红颜）",
  ["~xiaoqiao"] = "公瑾，我先走一步…",
}

local zhoutai = General(extension, "zhoutai", "wu", 4)
local buqu = fk.CreateTriggerSkill{
  name = "buqu",
  anim_type = "defensive",
  events = {fk.BeforeHpChanged, fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.BeforeHpChanged then
        return data.num < 0 and player.hp <= math.abs(data.num) and (math.abs(data.num) - math.max(player.hp , 1) + 1) > 0
      elseif event == fk.HpRecover then
        return #player:getPile("zhoutai_chuang") > 0 and #player:getPile("zhoutai_chuang") + player.hp > 1
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.BeforeHpChanged then
      local n = math.abs(data.num) - math.max(player.hp , 1) + 1
      if player.room:askForSkillInvoke(player, self.name, nil, "#buqu-invoke:::"..n) then
        self.cost_data = n
        return true
      end
    elseif event == fk.HpRecover then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.BeforeHpChanged then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(room:getNCards(self.cost_data))
      player:addToPile("zhoutai_chuang", dummy, true, self.name)
      room:setPlayerMark(player, self.name, 1)--预备终止濒死结算
      local buqu_chuang = player:getPile("zhoutai_chuang")
      local duplicate_numbers = {}
      local numbers = {}
      for _, id in ipairs(buqu_chuang) do
        local number = Fk:getCardById(id).number
        if table.contains(numbers, number) then
          table.insert(duplicate_numbers, number)
        else
          table.insert(numbers, number)
        end
      end
      if #duplicate_numbers == 0 then--不进行濒死流程
        room:setPlayerMark(player, self.name, 0)
        data.preventDying = true
      end
    elseif event == fk.HpRecover then
      if player.hp >= 1 then
        local buqu_chuang = player:getPile("zhoutai_chuang")
        for _, id in ipairs(buqu_chuang) do
          local buqu_card = Fk:getCardById(id)
          room:sendLog{
            type = "#buqu_remove",
            from = player.id,
            arg = buqu_card:toLogString()
          }
          room:moveCards({
            from = player.id,
            ids = { id },
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonPutIntoDiscardPile,
            skillName = self.name,
          })
          player:removeCards(Player.Special, buqu_card, self.name)
        end
      else
        while #player:getPile("zhoutai_chuang") > 0 and #player:getPile("zhoutai_chuang") + player.hp > 1 do
          local buqu_chuang = player:getPile("zhoutai_chuang")
          room:fillAG(player, buqu_chuang)
          local id = room:askForAG(player, buqu_chuang, false, self.name)
          local buqu_card = Fk:getCardById(id)
          room:sendLog{
            type = "#buqu_remove",
            from = player.id,
            arg = buqu_card:toLogString()
          }
          room:moveCards({
            from = player.id,
            ids = { id },
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonPutIntoDiscardPile,
            skillName = self.name,
          })
          player:removeCards(Player.Special, buqu_card, self.name)
          room:closeAG(player)
        end
      end
    end
  end,

  refresh_events = {fk.AskForPeachesDone, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AskForPeachesDone then--濒死结算流程结束后
      if target == player and player:hasSkill(self.name) then
        return player.hp <= 0 and player.dying and player:getMark(self.name) > 0
      end
    elseif event == fk.EventLoseSkill then
      return data == self
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AskForPeachesDone then
      room:setPlayerMark(player, self.name, 0)
      local buqu_chuang = player:getPile("zhoutai_chuang")
      local duplicate_numbers = {}
      local numbers = {}
      for _, id in ipairs(buqu_chuang) do
        local number = Fk:getCardById(id).number
        if table.contains(numbers, number) then
          table.insert(duplicate_numbers, number)
        else
          table.insert(numbers, number)
        end
      end
      if #duplicate_numbers == 0 then--终止濒死结算
        data.ignoreDeath = true
      else
        room:sendLog{
          type = "#buqu_duplicate",
          from = player.id,
          arg = #duplicate_numbers,
          arg2 = self.name
        }
        for i = 1, #duplicate_numbers , 1 do
          local number = duplicate_numbers[i]
          --getNumberStr(number)
          local number_string = "A23456789-JQK"
          local str = number_string[number]
          if number == 10 then str = "10" end
          --
          room:sendLog{
            type = "#buqu_duplicate_group",
            from = player.id,
            arg = i ,
            arg2 = str
          }
          for _, id in ipairs(buqu_chuang) do
            local buqu_card = Fk:getCardById(id)
            if buqu_card.number == number then
              room:sendLog{
                type = "#buqu_duplicate_item",
                from = player.id,
                arg = buqu_card:toLogString()
              }
            end
          end
        end
      end
    elseif event == fk.EventLoseSkill then
      if player.hp <= 0 then
        local dyingStruct = {
          who = player.id,
        }
        room:enterDying(dyingStruct)
      end
    end
  end,
}
zhoutai:addSkill(buqu)
Fk:loadTranslationTable{
  ["zhoutai"] = "周泰",
  ["buqu"] = "不屈",
  [":buqu"] = "当你扣减1点体力时，若你的体力值为0，你可以将牌堆顶的一张牌置于你的武将牌上：若此牌的点数与你武将牌上的其他牌均不同，你不会死亡；"..
  "若你的武将牌上有点数相同的牌，你进入濒死状态。",
  ["#buqu-invoke"] = "不屈：你可以将牌堆顶%arg张牌作为“创”置于武将牌上",
  ["#buqu_duplicate"] = "%from 发动“%arg2”失败，其“创”中有 %arg 组重复点数",
  ["#buqu_duplicate_group"] = "第 %arg 组重复点数为 %arg2",
  ["#buqu_duplicate_item"] = "重复“创”牌: %arg",
  ["#buqu_remove"] = "%from 移除了“创”牌：%arg",
  ["zhoutai_chuang"] = "创",

  ["$buqu2"] = "我绝不会倒下！",
  ["$buqu1"] = "还不够！",
  ["~zhoutai"] = "已经，尽力了…",
}

local zhangjiao = General(extension, "zhangjiao", "qun", 3)
local leiji = fk.CreateTriggerSkill{
  name = "leiji",
  anim_type = "offensive",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player and data.card.name == "jink"
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, "#leiji-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tar = room:getPlayerById(self.cost_data)
    local judge = {
      who = tar,
      reason = self.name,
      pattern = ".|.|spade",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade then
      room:damage{
        from = player,
        to = tar,
        damage = 2,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    end
end,
}
local guidao = fk.CreateTriggerSkill{
  name = "guidao",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForResponse(player, self.name, ".|.|spade,club|hand,equip", "#guidao-ask::" .. target.id .. ":" .. data.reason, true)
    if card ~= nil then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(self.cost_data, player, data, self.name, true)
  end,
}

local huangtian = fk.CreateTriggerSkill{
  name = "huangtian$",
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
      return p.kingdom == "qun"
    end)
    ]]
    local targets = room.alive_players
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self.name, true) then
        table.forEach(targets, function(p)
          room:handleAddLoseSkills(p, "huangtian_other&", nil, false, true)
        end)
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      table.forEach(targets, function(p)
        room:handleAddLoseSkills(p, "-huangtian_other&", nil, false, true)
      end)
    end
  end,
}
local huangtian_other = fk.CreateActiveSkill{
  name = "huangtian_other&",
  anim_type = "support",
  mute = true,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player.kingdom == "qun" then
      return table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill("huangtian") and p ~= player end)
    end
    return false
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected < 1 and (Fk:getCardById(to_select).name == "jink" or Fk:getCardById(to_select).name == "lightning")
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room.alive_players, function(p) return p:hasSkill("huangtian") and p ~= player end)
    local target
    if #targets == 1 then
      target = targets[1]
    else
      target = room:getPlayerById(room:askForChoosePlayers(player, table.map(targets, function(p) return p.id end), 1, 1, nil, self.name, false)[1])
    end
    if not target then return false end
    room:notifySkillInvoked(player, "huangtian")
    player:broadcastSkillInvoke("huangtian")
    room:doIndicate(effect.from, { target.id })
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, self.name, nil, true)
  end,
}

zhangjiao:addSkill(leiji)
zhangjiao:addSkill(guidao)
zhangjiao:addSkill(huangtian)
Fk:addSkill(huangtian_other)

Fk:loadTranslationTable{
  ["zhangjiao"] = "张角",
  ["leiji"] = "雷击",
  [":leiji"] = "当你使用或打出【闪】时，你可以令一名角色进行判定，若结果为♠，你对其造成2点雷电伤害。",
  ["guidao"] = "鬼道",
  [":guidao"] = "当一名角色的判定牌生效前，你可以打出一张黑色牌替换之。",
  ["huangtian"] = "黄天",
  [":huangtian"] = "主公技，其他群势力角色的出牌阶段限一次，其可将一张【闪】或【闪电】（正面朝上移动）交给你。",

  ["#leiji-choose"] = "雷击：你可以令一名角色进行判定，若为♠，你对其造成2点雷电伤害。",
  ["#guidao-ask"] = "鬼道：你可以打出一张黑色牌替换 %dest 的 “%arg” 判定",

  ["huangtian_other&"] = "黄天",
  [":huangtian_other&"] = "出牌阶段限一次，你可将一张【闪】或【闪电】（正面朝上移动）交给张角。",

  ["$leiji1"] = "以我之真气，合天地之造化！",
  ["$leiji2"] = "雷公助我！",
  ["$guidao1"] = "天下大势，为我所控。",
  ['$guidao2'] = "哼哼哼哼~",
  ["$huangtian1"] = "苍天已死，黄天当立！",
  ['$huangtian2'] = "岁在甲子，天下大吉！",
  ['~zhangjiao'] = '黄天，也死了…',
}

local yuji = General(extension, "yuji", "qun", 3)
local guhuo = fk.CreateViewAsSkill{
  name = "guhuo",
  anim_type = "special",
  pattern = ".",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeBasic or card:isCommonTrick()) and
      ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, card)) or
      (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names }
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    self.cost_data = cards
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local cards = self.cost_data
    local guhuo_mark = {}
    table.insertIfNeed(guhuo_mark, cards[1])
    room:setPlayerMark(player, "guhuo_use-phase", guhuo_mark)
    room:moveCardTo(cards, Card.Void, nil, fk.ReasonPut, "guhuo", "", false)  --暂时放到Card.Void,理论上应该是Card.Processing,只要moveVisible可以false
    local targets = TargetGroup:getRealTargets(use.tos)
    if targets and #targets > 0 then
      room:sendLog{
        type = "#guhuo_use",
        from = player.id,
        to = targets,
        arg = use.card.name,
        arg2 = self.name
      }
    else
      room:sendLog{
        type = "#guhuo_no_target",
        from = player.id,
        arg = use.card.name,
        arg2 = self.name
      }
    end
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng()
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isKongcheng()
  end,
}

local guhuoResponse = fk.CreateTriggerSkill{
  name = "#guhuoResponse",
  events = {fk.PreCardUse, fk.PreCardRespond},
  mute = true,
  priority = 10,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and table.contains(data.card.skillNames, "guhuo") and
    data.card:isVirtual() and #data.card.subcards == 0 and player:getMark("guhuo_use-phase") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, TargetGroup:getRealTargets(data.tos))
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local guhuo_mark = target:getMark("guhuo_use-phase")
    local card_id = guhuo_mark[1]
    if not card_id then return true end
    local questioned = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.hp > 0 then
        local choice = room:askForChoice(p, {"noquestion", "question"}, "guhuo", "", nil)
        if choice ~= "noquestion" then
          table.insertIfNeed(questioned, p)
        end
        room:sendLog{
          type = "#guhuo_query",
          from = p.id,
          arg = choice
        }
      end
    end
    local success = false
    local canuse = false
    local guhuo_card = Fk:getCardById(card_id)
    if #questioned > 0 then
      if data.card.name == guhuo_card.name then
        success = true
        if guhuo_card.suit == Card.Heart then
          canuse = true
        end
      end
    else
      canuse = true
    end
    player:showCards({card_id})
	--暂时使用setCardArea,当moveVisible可以false之后,不必再移动到Card.Void,也就不必再setCardArea
    table.removeOne(room.void, card_id)
    table.insert(room.processing_area, card_id)
    room:setCardArea(card_id, Card.Processing, nil)
	--
    if success then
      for _, p in ipairs(questioned) do
        room:loseHp(p, 1, "guhuo")
      end
    else
      for _, p in ipairs(questioned) do
        p:drawCards(1, "guhuo")
      end
    end
    if canuse then
      data.card:addSubcard(card_id)
      return false
    else
      room:moveCardTo(card_id, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, "guhuo")
    end
    return true
  end,
}

guhuo:addRelatedSkill(guhuoResponse)
yuji:addSkill(guhuo)
Fk:loadTranslationTable{
  ["yuji"] = "于吉",
  ["guhuo"] = "蛊惑",
  ["$guhuo1"] = "你信吗？",
  ["$guhuo2"] = "猜猜看呐~",
  ["~yuji"] = "竟然…被猜到了…",
  [":guhuo"] = "你可以扣置一张手牌当做一张基本牌或非延时锦囊牌使用或打出，体力值大于0的其他角色选择是否质疑，然后你展示此牌："..
  "若无角色质疑，此牌按你所述继续结算；若有角色质疑：若此牌为真，质疑角色各失去1点体力，否则质疑角色各摸一张牌，"..
  "且若此牌为<font color='red'>♥</font>且为真，则按你所述继续结算，否则将之置入弃牌堆。",
  ["question"] = "质疑",
  ["noquestion"] = "不质疑",
  ["#guhuo_use"] = "%from 发动了“%arg2”，声明此牌为 【%arg】，指定的目标为 %to",
  ["#guhuo_no_target"] = "%from 发动了“%arg2”，声明此牌为 【%arg】",
  ["#guhuo_query"] = "%from 表示 %arg",
}
return extension
