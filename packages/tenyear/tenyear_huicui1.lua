local extension = Package("tenyear_huicui1")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_huicui1"] = "十周年-群英荟萃1",
}

---@param player ServerPlayer @ 执行的玩家
---@param targets ServerPlayer[] @ 可选的目标范围
---@param num integer @ 可选的目标数
---@param can_minus boolean @ 是否可减少
---@param prompt string @ 提示信息
---@param skillName string @ 技能名
---@param data CardUseStruct @ 使用数据
--枚举法为使用牌增减目标（无距离限制）
local function AskForAddTarget(player, targets, num, can_minus, prompt, skillName, data)
  num = num or 1
  can_minus = can_minus or false
  prompt = prompt or ""
  skillName = skillName or ""
  local room = player.room
  local tos = {}
  if can_minus and #AimGroup:getAllTargets(data.tos) > 1 then  --默认不允许减目标至0
    tos = table.map(table.filter(targets, function(p)
      return table.contains(AimGroup:getAllTargets(data.tos), p.id) end), function(p) return p.id end)
  end
  for _, p in ipairs(targets) do
    if not table.contains(AimGroup:getAllTargets(data.tos), p.id) and not room:getPlayerById(data.from):isProhibited(p, data.card) then
      if data.card.name == "jink" or data.card.trueName == "nullification" or data.card.name == "adaptation" or
        (data.card.name == "peach" and not p:isWounded()) then
        --continue
      else
        if data.from ~= p.id then
          if (data.card.trueName == "slash") or
            ((table.contains({"dismantlement", "snatch", "chasing_near"}, data.card.name)) and not p:isAllNude()) or
            (table.contains({"fire_attack", "unexpectation"}, data.card.name) and not p:isKongcheng()) or
            (table.contains({"peach", "analeptic", "ex_nihilo", "duel", "savage_assault", "archery_attack", "amazing_grace", "god_salvation", 
              "iron_chain", "foresight", "redistribute", "enemy_at_the_gates", "raid_and_frontal_attack"}, data.card.name)) or
            (data.card.name == "collateral" and p:getEquipment(Card.SubtypeWeapon) and
              #table.filter(room:getOtherPlayers(p), function(v) return p:inMyAttackRange(v) end) > 0) then
            table.insertIfNeed(tos, p.id)
          end
        else
          if (data.card.name == "analeptic") or
            (table.contains({"ex_nihilo", "foresight", "iron_chain", "amazing_grace", "god_salvation", "redistribute"}, data.card.name)) or
            (data.card.name == "fire_attack" and not p:isKongcheng()) then
            table.insertIfNeed(tos, p.id)
          end
        end
      end
    end
  end
  if #tos > 0 then
    tos = room:askForChoosePlayers(player, tos, 1, num, prompt, skillName, true)
    if data.card.name ~= "collateral" then
      return tos
    else
      local result = {}
      for _, id in ipairs(tos) do
        local to = room:getPlayerById(id)
        local target = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(v)
          return to:inMyAttackRange(v) end), function(p) return p.id end), 1, 1,
          "#collateral-choose::"..to.id..":"..data.card:toLogString(), "collateral_skill", true)
        if #target > 0 then
          table.insert(result, {id, target[1]})
        end
      end
      if #result > 0 then
        return result
      else
        return {}
      end
    end
  end
  return {}
end

--无双上将：潘凤 邢道荣 曹性 淳于琼 夏侯杰 蔡阳 周善
local panfeng = General(extension, "ty__panfeng", "qun", 4)
local ty__kuangfu = fk.CreateActiveSkill{
  name = "ty__kuangfu",
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
    return #selected == 0 and #Fk:currentRoom():getPlayerById(to_select).player_cards[Player.Equip] > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "e", self.name)
    room:throwCard({id}, self.name, target, player)
    if player.dead then return end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not player:isProhibited(p, Fk:cloneCard("slash")) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ty__kuangfu-slash", self.name, false)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    local use = {
      from = player.id,
      tos = {{to}},
      card = Fk:cloneCard("slash"),
      extraUse = true,
    }
    use.card.skillName = self.name
    room:useCard(use)
    if not player.dead then
      if effect.from == effect.tos[1] and use.damageDealt then
        player:drawCards(2, self.name)
      end
      if effect.from ~= effect.tos[1] and not use.damageDealt then
        if #player.player_cards[Player.Hand] < 3 then
          player:throwAllCards("he")
        else
          player.room:askForDiscard(player, 2, 2, false, self.name, false)
        end
      end
    end
  end,
}
panfeng:addSkill(ty__kuangfu)
Fk:loadTranslationTable{
  ["ty__panfeng"] = "潘凤",
  ["ty__kuangfu"] = "狂斧",
  [":ty__kuangfu"] = "出牌阶段限一次，你可以弃置场上的一张装备牌，视为使用一张【杀】（此【杀】无距离限制且不计次数）。"..
  "若你弃置的不是你的牌且此【杀】未造成伤害，你弃置两张手牌；若弃置的是你的牌且此【杀】造成伤害，你摸两张牌。",
  ["#ty__kuangfu-slash"] = "狂斧：选择视为使用【杀】的目标",
}

local xingdaorong = General(extension, "xingdaorong", "qun", 4, 6)
local xuhe = fk.CreateTriggerSkill{
  name = "xuhe",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return true
      else
        return not table.every(player.room:getOtherPlayers(player), function(p) return p.maxHp <= player.maxHp end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#xuhe-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:changeMaxHp(player, -1)
      if not player.dead then
        local choice = room:askForChoice(player, {"xuhe_discard", "xuhe_draw"}, self.name)
        if choice == "xuhe_discard" then
          for _, p in ipairs(room:getAlivePlayers()) do
            if player:distanceTo(p) < 2 and not p:isNude() then
              room:doIndicate(player.id, {p.id})
              local id = room:askForCardChosen(player, p, "he", self.name)
              room:throwCard({id}, self.name, p, player)
            end
          end
        else
          for _, p in ipairs(room:getAlivePlayers()) do
            if player:distanceTo(p) < 2  then
              p:drawCards(1, self.name)
            end
          end
        end
      end
    else
      room:changeMaxHp(player, 1)
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
    end
  end,
}
xingdaorong:addSkill(xuhe)
Fk:loadTranslationTable{
  ["xingdaorong"] = "邢道荣",
  ["xuhe"] = "虚猲",
  [":xuhe"] = "出牌阶段开始时，你可以减1点体力上限，然后你弃置距离1以内的每名角色各一张牌或令这些角色各摸一张牌。出牌阶段结束时，"..
  "若你体力上限不为全场最高，你加1点体力上限，然后回复1点体力或摸两张牌。",
  ["#xuhe-invoke"] = "虚猲：你可以减1点体力上限，然后弃置距离1以内每名角色各一张牌或令这些角色各摸一张牌",
  ["xuhe_discard"] = "弃置距离1以内角色各一张牌",
  ["xuhe_draw"] = "距离1以内角色各摸一张牌",

  ["$xuhe1"] = "说出吾名，吓汝一跳！",
  ["$xuhe2"] = "我乃是零陵上将军！",
  ["~xingdaorong"] = "孔明之计，我难猜透啊。",
}

local caoxing = General(extension, "caoxing", "qun", 4)
local liushi = fk.CreateActiveSkill{
  name = "liushi",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Heart
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), Fk:cloneCard("slash"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    local use = {
      from = player.id,
      tos = {{target.id}},
      card = Fk:cloneCard("slash"),
      skillName = self.name,
      extraUse = true,
    }
    room:useCard(use)
    if use.damageDealt then
      for _, p in ipairs(room.alive_players) do
        if use.damageDealt[p.id] then
          room:addPlayerMark(target, "@@liushi", 1)
        end
      end
    end
  end,
}
local liushi_maxcards = fk.CreateMaxCardsSkill{
  name = "#liushi_maxcards",
  correct_func = function(self, player)
    if player:getMark("@@liushi") > 0 then
      return -player:getMark("@@liushi")
    end
    return 0
  end,
}
local zhanwan = fk.CreateTriggerSkill{
  name = "zhanwan",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Discard and target:getMark("zhanwan-phase") > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(target:getMark("zhanwan-phase"), self.name)
    player.room:setPlayerMark(target, "@@liushi", 0)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@@liushi") > 0 and player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        player.room:addPlayerMark(player, "zhanwan-phase", #move.moveInfo)
      end
    end
  end,
}
liushi:addRelatedSkill(liushi_maxcards)
caoxing:addSkill(liushi)
caoxing:addSkill(zhanwan)
Fk:loadTranslationTable{
  ["caoxing"] = "曹性",
  ["liushi"] = "流矢",
  [":liushi"] = "出牌阶段，你可以将一张<font color='red'>♥</font>牌置于牌堆顶，视为对一名角色使用一张【杀】（不计入次数且无距离限制）。"..
  "受到此【杀】伤害的角色手牌上限-1。",
  ["zhanwan"] = "斩腕",
  [":zhanwan"] = "锁定技，受到〖流矢〗效果影响的角色弃牌阶段结束时，若其于此阶段内弃置过牌，你摸等量的牌，然后移除其〖流矢〗的效果。",
  ["@@liushi"] = "流矢",
}

Fk:loadTranslationTable{
  ["chunyuqiong"] = "淳于琼",
  ["cangchu"] = "仓储",
  [":cangchu"] = "锁定技，游戏开始时，你获得3枚“粮”标记；每拥有1枚“粮”手牌上限+1；当你于回合外获得牌时，获得1枚“粮”。"..
  "（每回合限一枚，且“粮”的总数不能大于存活角色数）",
  ["liangying"] = "粮营",
  [":liangying"] = "弃牌阶段开始时，你可以摸至多X张牌，然后交给等量的角色各一张手牌（X为“粮”的数量）。",
  ["shishou"] = "失守",
  [":shishou"] = "锁定技，当你使用【酒】或受到火焰伤害后，你失去1枚“粮”。准备阶段，若你没有“粮”，你失去1点体力。",
}

local xiahoujie = General(extension, "xiahoujie", "wei", 5)
local liedan = fk.CreateTriggerSkill{
  name = "liedan",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Start and player:getMark("@@zhuangdan") == 0 and
      (target ~= player or (target == player and player:getMark("@liedan")) > 4)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target ~= player then
      local n = 0
      if player:getHandcardNum() > target:getHandcardNum() then
        n = n + 1
      end
      if player.hp > target.hp then
        n = n + 1
      end
      if #player.player_cards[Player.Equip] > #target.player_cards[Player.Equip] then
        n = n + 1
      end
      if n > 0 then
        player:drawCards(n, self.name)
        if n == 3 and player.maxHp < 8 then
          room:changeMaxHp(player, 1)
        end
      else
        room:loseHp(player, 1, self.name)
        if not player.dead then
          room:addPlayerMark(player, "@liedan", 1)
        end
      end
    else
      room:killPlayer({who = player.id,})
    end
  end,
}
local zhuangdan = fk.CreateTriggerSkill{
  name = "zhuangdan",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and player:getMark("@@zhuangdan") == 0 and
      table.every(player.room:getOtherPlayers(player), function(p) return player:getHandcardNum() > p:getHandcardNum() end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@zhuangdan", 1)
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@zhuangdan") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@zhuangdan", 0)
  end,
}
xiahoujie:addSkill(liedan)
xiahoujie:addSkill(zhuangdan)
Fk:loadTranslationTable{
  ["xiahoujie"] = "夏侯杰",
  ["liedan"] = "裂胆",
  [":liedan"] = "锁定技，其他角色的准备阶段，你的手牌数、体力值和装备区里的牌数每有一项大于该角色，便摸一张牌。"..
  "若均大于其，你加1点体力上限（至多加至8）；若均不大于其，你失去1点体力并获得1枚“裂胆”标记。准备阶段，若“裂胆”标记不小于5，你死亡。",
  ["zhuangdan"] = "壮胆",
  [":zhuangdan"] = "锁定技，其他角色的回合结束时，若你的手牌数为全场唯一最大，〖裂胆〗失效直到你的回合结束。",
  ["@liedan"] = "裂胆",
  ["@@zhuangdan"] = "裂胆失效",

  ["$liedan1"] = "声若洪钟，震胆发聩！",
  ["$liedan2"] = "阴雷滚滚，肝胆俱颤！",
  ["$zhuangdan1"] = "我家丞相在此，哪个有胆敢动我？",
  ["$zhuangdan2"] = "假丞相虎威，壮豪将龙胆。",
  ["~xiahoujie"] = "你吼那么大声干嘛……",
}

local caiyang = General(extension, "caiyang", "wei", 4)
local xunji = fk.CreateActiveSkill{
  name = "xunji",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#xunji",
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
    local mark = target:getMark("@@xunji")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, player.id)
    room:setPlayerMark(target, "@@xunji", mark)
  end,
}
local xunji_trigger = fk.CreateTriggerSkill{
  name = "#xunji_trigger",
  mute = true,
  events = {fk.EventPhaseStart, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:getMark("@@xunji") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@@xunji")
    room:setPlayerMark(player, "@@xunji", 0)
    local events = room.logic:getEventsOfScope(GameEvent.Damage, 999, function(e)
      local damage = e.data[1]
      return damage.from == player
    end, Player.HistoryTurn)
    if #events == 0 then return end
    for _, id in ipairs(mark) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead and not p:isProhibited(player, Fk:cloneCard("duel")) then
        p:broadcastSkillInvoke("xunji")
        room:notifySkillInvoked(p, "xunji", "offensive")
        room:doIndicate(p.id, {player.id})
        local use = {
          from = p.id,
          tos = {{player.id}},
          card = Fk:cloneCard("duel"),
          skillName = "xunji",
        }
        room:useCard(use)
        if not p.dead and use.damageDealt and use.damageDealt[player.id] then
          room:damage{
            from = player,
            to = p,
            damage = use.damageDealt[player.id],
            skillName = "xunji",
          }
        end
      end
    end
  end,
}
local jiaofeng = fk.CreateTriggerSkill{
  name = "jiaofeng",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    if player:getLostHp() > 0 then
      player:drawCards(1, self.name)
    end
    if player:getLostHp() > 1 then
      data.damage = data.damage + 1
    end
    if player:getLostHp() > 2 then
      player.room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,
}
xunji:addRelatedSkill(xunji_trigger)
caiyang:addSkill(xunji)
caiyang:addSkill(jiaofeng)
Fk:loadTranslationTable{
  ["caiyang"] = "蔡阳",
  ["xunji"] = "寻嫉",
  [":xunji"] = "出牌阶段限一次，你可以选择一名其他角色。该角色下个回合结束阶段，若其本回合造成过伤害，则你视为对其使用一张【决斗】；"..
  "此【决斗】对其造成伤害后，其对你造成等量的伤害。",
  ["jiaofeng"] = "交锋",
  [":jiaofeng"] = "锁定技，当你每回合首次造成伤害时，若你已损失体力值：大于0，你摸一张牌；大于1，此伤害+1；大于2，你回复1点体力。",
  ["#xunji"] = "寻嫉：选择一名其他角色，若其下回合内造成过伤害，则你视为对其使用【决斗】",
  ["@@xunji"] = "寻嫉",
}

local zhoushan = General(extension, "zhoushan", "wu", 4)
local miyun_active = fk.CreateActiveSkill{
  name = "miyun_active",
  target_num = 1,
  min_card_num = 1,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip then return false end
    local id = Self:getMark("miyun")
    return to_select == id or table.contains(selected, id)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return table.contains(selected_cards, Self:getMark("miyun")) and #selected == 0 and to_select ~= Self.id
  end,
}
local miyun = fk.CreateTriggerSkill{
  name = "miyun",
  frequency = Skill.Compulsory,
  events = {fk.RoundStart, fk.RoundEnd, fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.RoundStart then
      return not table.every(player.room.alive_players, function (p) return p == player or p:isNude() end)
    elseif event == fk.RoundEnd then
      return table.contains(player.player_cards[player.Hand], player:getMark(self.name))
    elseif event == fk.AfterCardsMove then
      local miyun_losehp = (data.extra_data or {}).miyun_losehp or {}
      return table.contains(miyun_losehp, player.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      local targets = table.filter(room.alive_players, function (p)
        return p ~= player and not p:isNude()
      end)
      if #targets == 0 then return false end
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke(self.name)
      local tos = room:askForChoosePlayers(player, table.map(targets, function (p)
        return p.id end), 1, 1, "#miyun-choose", self.name, false, true)
      local cid = room:askForCardChosen(player, room:getPlayerById(tos[1]), "he", self.name)
      local move = {
        from = tos[1],
        ids = {cid},
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = "miyun_prey",
      }
      room:moveCards(move)
    elseif event == fk.RoundEnd then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)

      local cid = player:getMark(self.name)
      local card = Fk:getCardById(cid)

      local _, ret = room:askForUseActiveSkill(player, "miyun_active", "#miyun-give:::" .. card:toLogString(), false)
      local to_give = {cid}
      local target = room:getOtherPlayers(to_give)[1].id
      if ret and #ret.cards > 0 and #ret.targets == 1 then
        to_give = ret.cards
        target = ret.targets[1]
      end
      local move = {
        from = player.id,
        ids = to_give,
        to = target,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = player.id,
        skillName = "miyun_give",
      }
      room:moveCards(move)
      if not player.dead then
        local x = player.maxHp - player:getHandcardNum()
        if x > 0 then
          room:drawCards(player, x, self.name)
        end
      end
    elseif event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "negative")
      room:loseHp(player, 1, self.name)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local marked = {}
    for _, move in ipairs(data) do
      if move.from == player.id and (move.to ~= player.id or move.toArea ~= Card.PlayerHand) then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if player:getMark(self.name) == info.cardId then
            room:setPlayerMark(player, self.name, 0)
            room:setPlayerMark(player, "@miyun_safe", 0)
            room:setCardMark(Fk:getCardById(info.cardId), "@@miyun_safe", 0)
            if move.skillName ~= "miyun_give" then
              data.extra_data = data.extra_data or {}
              local miyun_losehp = data.extra_data.miyun_losehp or {}
              table.insert(miyun_losehp, player.id)
              data.extra_data.miyun_losehp = miyun_losehp
            end
          end
        end
      elseif move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == "miyun_prey" then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            table.insert(marked, id)
          end
        end
      end
    end
    if #marked > 0 then
      for _, id in ipairs(player.player_cards[player.Hand]) do
        room:setCardMark(Fk:getCardById(id), "@@miyun_safe", 0)
      end
      local card = Fk:getCardById(marked[1])
      room:setPlayerMark(player, self.name, card.id)
      local num = card.number
      if num > 0 then
        if num == 1 then
          num = "A"
        elseif num == 11 then
          num = "J"
        elseif num == 12 then
          num = "Q"
        elseif num == 13 then
          num = "K"
        end
      end
      room:setPlayerMark(player, "@miyun_safe", {card.name, card:getSuitString(true), num})
      room:setCardMark(card, "@@miyun_safe", 1)
    end
  end,
}
local danying = fk.CreateViewAsSkill{
  name = "danying",
  pattern = "slash,jink",
  interaction = function()
    local names = {}
    local pat = Fk.currentResponsePattern
    local slash = Fk:cloneCard("slash")
    if pat == nil and slash.skill:canUse(Self, slash)  then
      table.insert(names, "slash")
    else
      if Exppattern:Parse(pat):matchExp("slash") then
          table.insert(names, "slash")
      end
      if Exppattern:Parse(pat):matchExp("jink")  then
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
    local cid = player:getMark(miyun.name)
    if table.contains(player.player_cards[player.Hand], cid) then
      player:showCards({cid})
    end
  end,
  enabled_at_play = function(self, player)
    if player:usedSkillTimes(self.name) > 0 or not table.contains(player.player_cards[player.Hand], player:getMark(miyun.name)) then
      return false
    end
    local slash = Fk:cloneCard("slash")
    return slash.skill:canUse(player, slash)
  end,
  enabled_at_response = function(self, player)
    if player:usedSkillTimes(self.name) > 0 or not table.contains(player.player_cards[player.Hand], player:getMark(miyun.name)) then
      return false
    end
    local pat = Fk.currentResponsePattern
    return pat and Exppattern:Parse(pat):matchExp(self.pattern)
  end,
}
local danying_delay = fk.CreateTriggerSkill{
  name = "#danying_delay",
  events = {fk.TargetConfirming},
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(danying.name) > 0 and player:usedSkillTimes(self.name) == 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    if not from.dead and not player.dead and not player:isNude() then
      local cid = room:askForCardChosen(from, player, "he", danying.name)
      room:throwCard({cid}, danying.name, player, from)
    end
  end,
}
Fk:addSkill(miyun_active)
zhoushan:addSkill(miyun)
danying:addRelatedSkill(danying_delay)
zhoushan:addSkill(danying)

Fk:loadTranslationTable{
  ["zhoushan"] = "周善",
  ["miyun"] = "密运",
  ["miyun_active"] = "密运",
  [":miyun"] = "锁定技，每轮开始时，你展示并获得一名其他角色的一张牌，称为『安』；"..
  "每轮结束时，你将包括『安』在内的任意张手牌交给一名其他角色，然后你将手牌摸至体力上限。你不以此法失去『安』时，你失去1点体力。",
  ["danying"] = "胆迎",
  ["#danying_delay"] = "胆迎",
  [":danying"] = "每回合限一次，你可展示手牌中的『安』，然后视为使用或打出一张【杀】或【闪】。"..
  "若如此做，本回合你下次成为牌的目标后，使用者弃置你一张牌。",

  ["#miyun-choose"] = "密运：选择一名角色，获得其一张牌作为『安』",
  ["#miyun-give"] = "密运：选择包含『安』（%arg）在内的任意张手牌，交给一名角色",
  ["@miyun_safe"] = "安",
  ["@@miyun_safe"] = "安",

  ["$miyun1"] = "不要大张旗鼓，要神不知鬼不觉。",
  ["$miyun2"] = "小阿斗，跟本将军走一趟吧。",
  ["$danying1"] = "早就想会会你常山赵子龙了。",
  ["$danying2"] = "赵子龙是吧？兜鍪给你打掉。",
  ["~zhoushan"] = "夫人救我！夫人救我！",
}

--才子佳人：何晏 王桃 王悦 赵嫣 滕胤 张嫙 夏侯令女 孙茹 张媱
Fk:loadTranslationTable{
  ["heyan"] = "何晏",
  ["yachai"] = "崖柴",
  [":yachai"] = "当你受到伤害后，你可以令伤害来源选择一项：1.弃置一半手牌（向上取整）；2.其本回合不能再使用手牌，你摸两张牌；"..
  "3.展示所有手牌，然后交给你一种花色的所有手牌。",
  ["qingtan"] = "清谈",
  [":qingtan"] = "出牌阶段限一次，你可令所有角色同时选择一张手牌并展示。你可以获得其中一种花色的牌，然后展示此花色牌的角色各摸一张牌。弃置其余的牌。",
}

local wangtao = General(extension, "wangtao", "shu", 3, 3, General.Female)
local huguan = fk.CreateTriggerSkill{
  name = "huguan",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target.phase == Player.Play and data.card.color == Card.Red then
      local n = 0
      for _, v in pairs(target.cardUsedHistory) do
        if v[Player.HistoryPhase] > 0 then
          n = n + v[Player.HistoryPhase]
          if n > 1 then return end
        end
      end
      return n == 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, ".", "#huguan-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"log_spade", "log_heart", "log_club", "log_diamond"}
    local choices = table.map(suits, function(s) return Fk:translate(s) end)
    local choice = room:askForChoice(player, choices, self.name, "#huguan-choice::"..target.id)
    local mark = target:getMark("huguan-turn")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, suits[table.indexOf(choices, choice)])
    room:setPlayerMark(target, "huguan-turn", mark)
    room:setPlayerMark(target, "@huguan-turn", table.concat(table.map(mark, function(s) return Fk:translate(s) end)))
  end,
}
local huguan_maxcards = fk.CreateMaxCardsSkill{
  name = "#huguan_maxcards",
  exclude_from = function(self, player, card)
    return player:getMark("huguan-turn") ~= 0 and table.contains(player:getMark("huguan-turn"), card:getSuitString(true))
  end,
}
local yaopei = fk.CreateTriggerSkill{
  name = "yaopei",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Discard and player:usedSkillTimes("huguan", Player.HistoryTurn) > 0 and
      target ~= player and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local pattern = "."
    if target:getMark("yaopei-phase") ~= 0 then
      local suits = {"spade", "heart", "club", "diamond"}
      pattern = ".|.|"
      for _, s in ipairs(suits) do
        if not table.contains(target:getMark("yaopei-phase"), s) then
          pattern = pattern..s..","
        end
      end
    end
    if pattern[#pattern] == "," then
      pattern = string.sub(pattern, 1, #pattern - 1)
    end
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, pattern, "#yaopei-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if player.dead or target.dead then return end
    local to1 = room:askForChoosePlayers(player, {player.id, target.id}, 1, 1, "#yaopei-choose", self.name, false)
    if #to1 > 0 then
      to1 = room:getPlayerById(to1[1])
    else
      to1 = room:getPlayerById(player.id)
    end
    local to2 = player
    if to1 == player then
      to2 = target
    end
    if to1:isWounded() then
      room:recover{
        who = to1,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    end
    to2:drawCards(2, self.name)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("yaopei-phase")
    if mark == 0 then mark = {} end
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(mark, Fk:getCardById(info.cardId):getSuitString())
        end
      end
    end
    if #mark == 0 then mark = 0 end
    player.room:setPlayerMark(player, "yaopei-phase", mark)
  end,
}
huguan:addRelatedSkill(huguan_maxcards)
wangtao:addSkill(yaopei)
wangtao:addSkill(huguan)
Fk:loadTranslationTable{
  ["wangtao"] = "王桃",
  ["huguan"] = "护关",
  [":huguan"] = "一名角色于其出牌阶段内使用第一张牌时，若为红色，你可以声明一个花色，本回合此花色的牌不计入其手牌上限。",
  ["yaopei"] = "摇佩",
  [":yaopei"] = "其他角色弃牌阶段结束时，若你本回合对其发动过〖护关〗，你可以弃置一张其此阶段没弃置过的花色的牌，然后令你与其中一名角色回复1点体力，"..
  "另一名角色摸两张牌。",
  ["#huguan-invoke"] = "护关：你可以声明一种花色，令 %dest 本回合此花色牌不计入手牌上限",
  ["#huguan-choice"] = "护关：选择令 %dest 本回合不计入手牌上限的花色",
  ["@huguan-turn"] = "护关",
  ["#yaopei-invoke"] = "摇佩：你可以弃置一张 %dest 此阶段未弃置过花色的牌，你与其一方回复1点体力，另一方摸两张牌",
  ["#yaopei-choose"] = "摇佩：选择回复体力的角色，另一方摸两张牌",
}

local wangyue = General(extension, "wangyues", "shu", 3, 3, General.Female)
local mingluan = fk.CreateTriggerSkill{
  name = "mingluan",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self.name) and target.phase == Player.Finish then
      local events = player.room.logic:getEventsOfScope(GameEvent.Recover, 1, function(e) return true end, Player.HistoryTurn)
      return #events > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 0, 999, true, self.name, true, ".", "#mingluan-invoke::"..target.id, true)
    if card then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if player.dead or target:isKongcheng() or player:getHandcardNum() > 4 then return end
    local n = math.min(5 - player:getHandcardNum(), target:getHandcardNum())
    player:drawCards(n, self.name)
  end,
}
wangyue:addSkill(mingluan)
wangyue:addSkill("huguan")
Fk:loadTranslationTable{
  ["wangyues"] = "王悦",
  ["mingluan"] = "鸣鸾",
  [":mingluan"] = "其他角色的结束阶段，若本回合有角色回复过体力，你可以弃置任意张牌，然后摸等同于当前回合角色手牌数的牌（最多摸至五张）。",
  ["#mingluan-invoke"] = "鸣鸾：你可以弃置任意张牌（可以不弃置），然后摸 %dest 手牌数的牌，最多摸至五张",
}

local zhaoyanw = General(extension, "zhaoyanw", "wu", 3, 3, General.Female)
local jinhui = fk.CreateActiveSkill{
  name = "jinhui",
  anim_type = "support",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local names = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if not card.is_damage_card and (card.skill.target_num == 1 or card.type == Card.TypeEquip or
        table.contains({"peach", "ex_nihilo", "collateral", "lightning", "analeptic", "foresight"}, card.trueName)) then
        table.insertIfNeed(names, card.trueName)
      end
    end
    if #names == 0 then return end
    names = table.random(names, math.min(3, #names))
    local cards = {}
    for _, name in ipairs(names) do
      table.insertTable(cards, room:getCardsFromPileByRule(name))
    end
    if #cards == 0 then return end
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(cards)
    player:addToPile(self.name, dummy, true, self.name)
    local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#jinhui-choose", self.name, false)
    local to
    if #tos > 0 then
      to = room:getPlayerById(tos[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    local ids = table.simpleClone(player:getPile(self.name))
    local fakemove = {
      toArea = Card.PlayerHand,
      to = to.id,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.Void} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({to}, {fakemove})
    local availableCards = {}
    for _, id in ipairs(ids) do
      local card = Fk:getCardById(id)
      if not to:prohibitUse(card) and card.skill:canUse(to, card) then
        table.insertIfNeed(availableCards, id)
      end
    end
    room:setPlayerMark(to, "jinhui_cards", {availableCards, {player.id, to.id}})
    local success, dat = room:askForUseActiveSkill(to, "jinhui_viewas", "#jinhui-use:"..player.id, false)
    room:setPlayerMark(to, "jinhui_cards", 0)
    fakemove = {
      from = to.id,
      toArea = Card.Void,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({to}, {fakemove})
    if success then
      room:moveCards({
        from = player.id,
        ids = dat.cards,
        toArea = Card.Processing,
        moveReason = fk.ReasonUse,
        skillName = self.name,
      })
      local card = Fk.skills["jinhui_viewas"]:viewAs(dat.cards)
      room:useCard{
        from = to.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    else
      room:moveCards({
        from = player.id,
        ids = player:getPile(self.name),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
    end
    while not player.dead and #player:getPile(self.name) > 0 do
      ids = table.simpleClone(player:getPile(self.name))
      fakemove = {
        toArea = Card.PlayerHand,
        to = player.id,
        moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.Void} end),
        moveReason = fk.ReasonJustMove,
      }
      room:notifyMoveCards({player}, {fakemove})
      availableCards = {}
      for _, id in ipairs(ids) do
        local card = Fk:getCardById(id)
        if not player:prohibitUse(card) and card.skill:canUse(player, card) then
          table.insertIfNeed(availableCards, id)
        end
      end
      room:setPlayerMark(player, "jinhui_cards", {availableCards, {player.id, to.id}})
      success, dat = room:askForUseActiveSkill(player, "jinhui_viewas", "#jinhui2-use::"..to.id, true)
      room:setPlayerMark(player, "jinhui_cards", 0)
      fakemove = {
        from = player.id,
        toArea = Card.Void,
        moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
        moveReason = fk.ReasonJustMove,
      }
      room:notifyMoveCards({player}, {fakemove})
      if success then
        room:moveCards({
          from = player.id,
          ids = dat.cards,
          toArea = Card.Processing,
          moveReason = fk.ReasonUse,
          skillName = self.name,
        })
        local card = Fk.skills["jinhui_viewas"]:viewAs(dat.cards)
        room:useCard{
          from = player.id,
          tos = table.map(dat.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
      else
        break
      end
    end
    room:moveCards({
      from = player.id,
      ids = player:getPile(self.name),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
  end
}
local jinhui_viewas = fk.CreateViewAsSkill{
  name = "jinhui_viewas",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local mark = Self:getMark("jinhui_cards")
      return type(mark) == "table" and table.contains(mark[1], to_select)
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      local card = Fk:getCardById(cards[1])
      card.skillName = "jinhui"
      return card
    end
  end,
}
local jinhui_prohibit = fk.CreateProhibitSkill{
  name = "#jinhui_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("jinhui_cards") ~= 0 and table.contains(card.skillNames, "jinhui") and
      not table.contains(from:getMark("jinhui_cards")[2], to.id)
  end,
}
local jinhui_targetmod = fk.CreateTargetModSkill{
  name = "#jinhui_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, "jinhui")
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, "jinhui")
  end,
}
local qingman = fk.CreateTriggerSkill{
  name = "qingman",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:getHandcardNum() < 5 - #target:getCardIds("e")
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(5 - #target:getCardIds("e") - player:getHandcardNum(), self.name)
  end,
}
Fk:addSkill(jinhui_viewas)
jinhui:addRelatedSkill(jinhui_prohibit)
jinhui:addRelatedSkill(jinhui_targetmod)
zhaoyanw:addSkill(jinhui)
zhaoyanw:addSkill(qingman)
Fk:loadTranslationTable{
  ["zhaoyanw"] = "赵嫣",
  ["jinhui"] = "锦绘",
  [":jinhui"] = "出牌阶段限一次，你可以将牌堆中随机三张不同名且目标数为一的非伤害牌置于你的武将牌上，然后选择一名其他角色，该角色使用其中一张，"..
  "然后你可以依次使用其余两张（必须选择你或其为目标，无距离和次数限制）。",
  ["qingman"] = "轻幔",
  [":qingman"] = "锁定技，每个回合结束时，你将手牌摸至X张（X为当前回合角色装备区内的空位数）。",
  ["#jinhui-choose"] = "锦绘：令一名其他角色使用其中一张牌，然后你可以使用其余两张",
  ["#jinhui-use"] = "锦绘：使用其中一张牌（必须指定你或 %src 为目标），然后其可以使用其余两张",
  ["#jinhui2-use"] = "锦绘：你可以使用剩余的牌（必须指定你或 %dest 为目标）",
  ["jinhui_viewas"] = "锦绘",

  ["$jinhui1"] = "大则盈尺，小则方寸。",
  ["$jinhui2"] = "十指纤纤，万分机巧。",
  ["$qingman1"] = "经纬分明，片片罗縠。",
  ["$qingman2"] = "罗帐轻幔，可消酷暑烦躁。",
  ["~zhaoyanw"] = "彩绘锦绣，二者不可缺其一。",
}

local tengyin = General(extension, "tengyin", "wu", 3)
local chenjian = fk.CreateTriggerSkill{
  name = "chenjian",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3 + player:getMark(self.name))
    room:moveCards({
      ids = ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    local choices = {"Cancel", "chenjian1", "chenjian2"}
    local n = 0
    while not player.dead and #ids > 0 do
      ids = table.filter(ids, function(id) return room:getCardArea(id) == Card.Processing end)
      if table.contains(choices, "chenjian1") then
        for _, id in ipairs(player:getCardIds("he")) do
          if table.find(ids, function(i) return Fk:getCardById(id).suit == Fk:getCardById(i).suit end) and
            not player:prohibitDiscard(Fk:getCardById(id)) then
            --continue
          else
            table.removeOne(choices, "chenjian1")
          end
        end
      end

      --TODO: 理应也判断chenjian2的，但现在All choices有bug

      local choice = room:askForChoice(player, choices, self.name)
      if choice == "Cancel" then
        break
      else
        table.removeOne(choices, choice)
        if choice == "chenjian1" then
          local suits = {}
          for _, id in ipairs(ids) do
            table.insertIfNeed(suits, Fk:getCardById(id):getSuitString())
          end
          local to, card =  room:askForChooseCardAndPlayers(player, table.map(player.room.alive_players, function(p)
            return p.id end), 1, 1, ".|.|"..table.concat(suits, ","), "#chenjian-choose", self.name, true)
          if #to > 0 and card then
            local suit = Fk:getCardById(card).suit
            room:throwCard({card}, self.name, player, player)
            local dummy = Fk:cloneCard("dilu")
            for i = #ids, 1, -1 do
              if Fk:getCardById(ids[i]).suit == suit then
                dummy:addSubcard(ids[i])
                table.removeOne(ids, ids[i])
              end
            end
            if not room:getPlayerById(to[1]).dead then
              room:obtainCard(to[1], dummy, true, fk.ReasonJustMove)
            end
            n = n + 1
          end
        elseif choice == "chenjian2" then
          local fakemove = {
            toArea = Card.PlayerHand,
            to = player.id,
            moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.Void} end),
            moveReason = fk.ReasonJustMove,
          }
          room:notifyMoveCards({player}, {fakemove})
          local availableCards = {}
          for _, id in ipairs(ids) do
            local card = Fk:getCardById(id)
            if not player:prohibitUse(card) and card.skill:canUse(player, card) then
              table.insertIfNeed(availableCards, id)
            end
          end
          room:setPlayerMark(player, "chenjian_cards", availableCards)
          local success, dat = room:askForUseActiveSkill(player, "chenjian_viewas", "#chenjian-use", true)
          room:setPlayerMark(player, "chenjian_cards", 0)
          fakemove = {
            from = player.id,
            toArea = Card.Void,
            moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
            moveReason = fk.ReasonJustMove,
          }
          room:notifyMoveCards({player}, {fakemove})
          if success then
            room:moveCards({
              from = player.id,
              ids = dat.cards,
              toArea = Card.Processing,
              moveReason = fk.ReasonUse,
              skillName = self.name,
            })
            local card = Fk.skills["chenjian_viewas"]:viewAs(dat.cards)
            room:useCard{
              from = player.id,
              tos = table.map(dat.targets, function(id) return {id} end),
              card = card,
              extraUse = true,
            }
            n = n + 1
          end
        end
      end
    end
    ids = table.filter(ids, function(id) return room:getCardArea(id) == Card.Processing end)
    if #ids > 0 then
      room:moveCards({
        ids = ids,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
    end
    if n == 2 and not player.dead then
      if player:getMark(self.name) < 2 then
        room:addPlayerMark(player, self.name, 1)
      end
      if not player:isKongcheng() then
        room:recastCard(player:getCardIds("h"), player, self.name)
      end
    end
  end
}
local chenjian_viewas = fk.CreateViewAsSkill{
  name = "chenjian_viewas",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = Self:getMark("chenjian_cards")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      return Fk:getCardById(cards[1])
    end
  end,
}
local xixiu = fk.CreateTriggerSkill{
  name = "xixiu",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirming, fk.BeforeCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.TargetConfirming then
        return target == player and data.from ~= player.id and
          table.find(player:getCardIds("e"), function(id) return Fk:getCardById(id).suit == data.card.suit end)
      else
        if #player:getCardIds("e") ~= 1 then return end
        for _, move in ipairs(data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard and (move.proposer ~= player and move.proposer ~= player.id) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.TargetConfirming then
      player:drawCards(1, self.name)
    else
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard and (move.proposer ~= player and move.proposer ~= player.id) then
          for i = #move.moveInfo, 1, -1 do
            local info = move.moveInfo[i]
            if info.fromArea == Card.PlayerEquip then
              table.removeOne(move.moveInfo, info)
              break
            end
          end
        end
      end
    end
  end,
}
Fk:addSkill(chenjian_viewas)
tengyin:addSkill(chenjian)
tengyin:addSkill(xixiu)
Fk:loadTranslationTable{
  ["tengyin"] = "滕胤",
  ["chenjian"] = "陈见",
  [":chenjian"] = "准备阶段，你可以亮出牌堆顶的三张牌并可以执行：1.弃置一张牌，令一名角色获得其中此牌花色的牌；2.使用其中一张牌。"..
  "若两项均执行，则本局游戏你发动〖陈见〗亮出牌数+1（最多五张），然后你重铸所有手牌。",
  ["xixiu"] = "皙秀",
  [":xixiu"] = "锁定技，当你成为其他角色使用牌的目标时，若你装备区内有与此牌花色相同的牌，你摸一张牌；其他角色不能弃置你装备区内的最后一张牌。",
  ["chenjian1"] = "弃一张牌，令一名角色获得此花色的牌",
  ["chenjian2"] = "使用其中一张牌",
  ["#chenjian-choose"] = "陈见：弃置一张牌并选择一名角色，令其获得与之相同花色的牌",
  ["chenjian_viewas"] = "陈见",
  ["#chenjian-use"] = "陈见：使用其中一张牌",
}

local zhangxuan = General(extension, "zhangxuan", "wu", 4, 4, General.Female)
local tongli = fk.CreateTriggerSkill{
  name = "tongli",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.firstTarget and
      (not data.card:isVirtual() or #data.card.subcards > 0) and not table.contains(data.card.skillNames, self.name) and
      data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick and
      not (table.contains({"peach", "analeptic"}, data.card.trueName) and table.find(player.room.alive_players, function(p) return p.dying end)) then
      local suits = {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        if Fk:getCardById(id).suit ~= Card.NoSuit then
          table.insertIfNeed(suits, Fk:getCardById(id).suit)
        end
      end
      return #suits == player:getMark("@tongli-turn")
    end
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.tongli = player:getMark("@tongli-turn")
    player.room:setPlayerMark(player, "tongli_tos", AimGroup:getAllTargets(data.tos))
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.AfterCardUseDeclared then
        return player.phase == Player.Play and not table.contains(data.card.skillNames, self.name)
      else
        return data.extra_data and data.extra_data.tongli and player:getMark("tongli_tos") ~= 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      room:addPlayerMark(player, "@tongli-turn", 1)
    else
      local n = data.extra_data.tongli
      local targets = player:getMark("tongli_tos")
      room:setPlayerMark(player, "tongli_tos", 0)
      local tos = table.simpleClone(targets)
      for i = 1, n, 1 do
        if player.dead then return end
        for _, id in ipairs(targets) do
          if room:getPlayerById(id).dead then
            return
          end
        end
        if table.contains({"savage_assault", "archery_attack"}, data.card.name) then  --to modify tenyear's stupid processing
          for _, p in ipairs(room:getOtherPlayers(player)) do
            if not player:isProhibited(p, Fk:cloneCard(data.card.name)) then
              table.insertIfNeed(tos, p.id)
            end
          end
        elseif table.contains({"amazing_grace", "god_salvation"}, data.card.name) then
          for _, p in ipairs(room:getAlivePlayers()) do
            if not player:isProhibited(p, Fk:cloneCard(data.card.name)) then
              table.insertIfNeed(tos, p.id)
            end
          end
        end
        room:sortPlayersByAction(tos)
        room:useVirtualCard(data.card.name, nil, player, table.map(tos, function(id) return room:getPlayerById(id) end), self.name, true)
      end
    end
  end,
}
local shezang = fk.CreateTriggerSkill{
  name = "shezang",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and (target == player or player.phase ~= Player.NotActive) and
      player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
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
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
zhangxuan:addSkill(tongli)
zhangxuan:addSkill(shezang)
Fk:loadTranslationTable{
  ["zhangxuan"] = "张嫙",
  ["tongli"] = "同礼",
  [":tongli"] = "出牌阶段，当你使用牌指定目标后，若你手牌中的花色数等于你此阶段已使用牌的张数，你可令此牌效果额外执行X次（X为你手牌中的花色数）。",
  ["shezang"] = "奢葬",
  [":shezang"] = "每轮限一次，当你或你回合内有角色进入濒死状态时，你可以从牌堆获得不同花色的牌各一张。",
  ["@tongli-turn"] = "同礼",

  ["$tongli1"] = "胞妹殊礼，妾幸同之。",
  ["$tongli2"] = "夫妻之礼，举案齐眉。",
  ["$shezang1"] = "世间千百物，物物皆相思。",
  ["$shezang2"] = "伊人将逝，何物为葬？",
  ["~zhangxuan"] = "陛下，臣妾绝无异心！",
}

local sunru = General(extension, "ty__sunru", "wu", 3, 3, General.Female)
local xiecui = fk.CreateTriggerSkill{
  name = "xiecui",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.from and not data.from.dead and data.from.phase ~= Player.NotActive and data.card then
      if data.from:getMark("xiecui-turn") == 0 then
        player.room:addPlayerMark(data.from, "xiecui-turn", 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#xiecui-invoke:"..data.from.id..":"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.damage = data.damage + 1
    if data.from.kingdom == "wu" and room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(data.from, data.card, false)
      room:addPlayerMark(data.from, MarkEnum.AddMaxCardsInTurn, 1)
    end
  end,
}
local youxu = fk.CreateTriggerSkill{
  name = "youxu",
  anim_type = "control",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target:getHandcardNum() > target.hp and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#youxu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards({id})
    local targets = table.map(room:getOtherPlayers(target), function(p) return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#youxu-choose:::"..Fk:getCardById(id):toLogString(), self.name, false)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    room:obtainCard(to, id, true, fk.ReasonGive)
    to = room:getPlayerById(to)
    if to:isWounded() and table.every(room:getOtherPlayers(to), function (p) return p.hp >= to.hp end) then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
sunru:addSkill(xiecui)
sunru:addSkill(youxu)
Fk:loadTranslationTable{
  ["ty__sunru"] = "孙茹",
  ["xiecui"] = "撷翠",
  [":xiecui"] = "当一名角色于其回合内使用牌首次造成伤害时，你可令此伤害+1。若该角色为吴势力角色，其获得此伤害牌且本回合手牌上限+1。",
  ["youxu"] = "忧恤",
  [":youxu"] = "一名角色回合结束时，若其手牌数大于体力值，你可以展示其一张手牌然后交给另一名角色。若获得牌的角色体力值全场最低，其回复1点体力。",
  ["#xiecui-invoke"] = "撷翠：你可以令 %src 对 %dest造成的伤害+1",
  ["#youxu-invoke"] = "忧恤：你可以展示 %dest 的一张手牌，然后交给另一名角色",
  ["#youxu-choose"] = "忧恤：选择获得%arg的角色",

  ["$xiecui1"] = "东隅既得，亦收桑榆。",
  ["$xiecui2"] = "江东多娇，锦花相簇。",
  ["$youxu1"] = "积富之家，当恤众急。",
  ["$youxu2"] = "周忧济难，请君恤之。",
  ["~ty__sunru"] = "伯言，抗儿便托付于你了。",
}

local xiahoulingnv = General(extension, "xiahoulingnv", "wei", 4, 4, General.Female)
local fuping = fk.CreateViewAsSkill{
  name = "fuping",
  anim_type = "special",
  pattern = ".",
  prompt = "#fuping-viewas",
  interaction = function()
    if type(Self:getMark("@$fuping")) ~= "table" then return end
    local all_names, names = Self:getMark("@$fuping"), {}
    local used_names = type(Self:getMark("fuping-turn")) == "table" and Self:getMark("fuping-turn") or {}
    for _, name in ipairs(all_names) do
      if not table.contains(used_names, name) then
        local to_use = Fk:cloneCard(name)
        to_use.skillName = "fuping"
        if ((Fk.currentResponsePattern == nil and Self:canUse(to_use) and not Self:prohibitUse(to_use)) or
          (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
          table.insertIfNeed(names, name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names, all_choices = all_names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    local names = player:getMark("@$fuping")
    if type(names) ~= "table" then return false end
    local used_names = type(player:getMark("fuping-turn")) == "table" and player:getMark("fuping-turn") or {}
    for _, name in ipairs(names) do
      if not table.contains(used_names, name) then
        local to_use = Fk:cloneCard(name)
        to_use.skillName = self.name
        if player:canUse(to_use) and not player:prohibitUse(to_use) then
          return true
        end
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    local names = player:getMark("@$fuping")
    if type(names) ~= "table" then return false end
    local used_names = type(player:getMark("fuping-turn")) == "table" and player:getMark("fuping-turn") or {}
    for _, name in ipairs(names) do
      if not table.contains(used_names, name) then
        local to_use = Fk:cloneCard(name)
        to_use.skillName = self.name
        if (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use)) then
          return true
        end
      end
    end
  end,
  before_use = function(self, player, useData)
    local names = type(player:getMark("fuping-turn")) == "table" and player:getMark("fuping-turn") or {}
    table.insert(names, useData.card.trueName)
    player.room:setPlayerMark(player, "fuping-turn", names)
  end,
}
local fuping_trigger = fk.CreateTriggerSkill{
  name = "#fuping_trigger",
  events = {fk.CardUseFinished},
  main_skill = fuping,
  can_trigger = function(self, event, target, player, data)
    if target == player or not player:hasSkill(fuping.name) or #player:getAvailableEquipSlots() == 0 then return false end
    if data.card.type ~= Card.TypeEquip and table.contains(TargetGroup:getRealTargets(data.tos), player.id) then
      local mark = player:getMark("@$fuping")
      return type(mark) ~= "table" or not table.contains(mark, data.card.trueName)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"WeaponSlot", "ArmorSlot", "DefensiveRideSlot", "OffensiveRideSlot", "TreasureSlot"}
    local subtypes = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
    local choices = {}
    for i = 1, 5, 1 do
      if #player:getAvailableEquipSlots(subtypes[i]) > 0 then
        table.insert(choices, all_choices[i])
      end
    end
    table.insert(all_choices, "Cancel")
    table.insert(choices, "Cancel")
    local choice = player.room:askForChoice(player, choices, fuping.name, "#fuping-choice:::" .. data.card.trueName, false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(fuping.name)
    room:abortPlayerArea(player, {self.cost_data})
    local mark = type(player:getMark("@$fuping")) == "table" and player:getMark("@$fuping") or {}
    table.insertIfNeed(mark, data.card.trueName)
    room:setPlayerMark(player, "@$fuping", mark)
  end,
}
local fuping_targetmod = fk.CreateTargetModSkill{
  name = "#fuping_targetmod",
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(fuping.name) and #player:getAvailableEquipSlots() == 0
  end,
}
local weilie = fk.CreateActiveSkill{
  name = "weilie",
  anim_type = "support",
  prompt = function ()
    local max_times = type(Self:getMark("@$fuping")) == "table" and #Self:getMark("@$fuping") or 0
    return "#weilie-active:::" .. tostring(max_times - Self:usedSkillTimes("weilie", Player.HistoryGame) + 1)
  end,
  can_use = function(self, player)
    local max_times = type(player:getMark("@$fuping")) == "table" and #player:getMark("@$fuping") or 0
    return player:usedSkillTimes(self.name, Player.HistoryGame)  <= max_times
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):isWounded()
  end,
  target_num = 1,
  card_num = 1,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, from, from)
    local target = room:getPlayerById(effect.tos[1])
    room:recover({
      who = target,
      num = 1,
      recoverBy = from,
      skillName = self.name
    })
    if not target.dead and target:isWounded() then
      room:drawCards(target, 1, self.name)
    end
  end,
}
fuping:addRelatedSkill(fuping_trigger)
fuping:addRelatedSkill(fuping_targetmod)
xiahoulingnv:addSkill(fuping)
xiahoulingnv:addSkill(weilie)
Fk:loadTranslationTable{
  ["xiahoulingnv"] = "夏侯令女",
  ["fuping"] = "浮萍",
  [":fuping"] = "当其他角色以你为目标的基本牌或锦囊牌牌结算后，若你未记录此牌，你可以废除一个装备栏并记录此牌。"..
  "你可以将一张非基本牌当记录的牌使用或打出（每种牌名每回合限一次）。若你的装备栏均已废除，你使用牌无距离限制。",
  ["weilie"] = "炜烈",
  [":weilie"] = "每局游戏限一次，出牌阶段，你可以弃置一张牌令一名角色回复1点体力，然后若其已受伤，则其摸一张牌。你每次发动〖浮萍〗记录牌名时，"..
  "此技能可发动次数+1。",

  ["#fuping_trigger"] = "浮萍",
  ["#fuping-choice"] = "是否发动 浮萍，废除一个装备栏，记录牌名【%arg】",
  ["@$fuping"] = "浮萍",
  ["#fuping-viewas"] = "发动 浮萍，将一张非基本牌当记录过的牌使用",
  ["#weilie-active"] = "发动 炜烈，弃置一张牌令一名已受伤的角色回复体力（剩余 %arg 次）",

  ["$fuping1"] = "有草生清池，无根碧波上。",
  ["$fuping2"] = "愿为浮萍草，托身寄清池。",
  ["$weilie1"] = "好学尚贞烈，义形必沾巾。",
  ["$weilie2"] = "贞烈过男子，何处弱须眉？",
  ["~xiahoulingnv"] = "心存死志，绝不肯从！",
}

local zhangyao = General(extension, "zhangyao", "wu", 3, 3, General.Female)
local yuanyu = fk.CreateActiveSkill{
  name = "yuanyu",
  anim_type = "control",
  prompt = "#yuanyu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 + player:getMark("yuanyu_extra_times-phase")
  end,
  card_filter = function() return false end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:drawCards(player, 1, self.name)
    if player:isKongcheng() then return end
    local tar, card =  player.room:askForChooseCardAndPlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, ".|.|.|hand", "#yuanyu-choose", self.name, false)
    if #tar > 0 and card then
      local targetRecorded = type(player:getMark("yuanyu_targets")) == "table" and player:getMark("yuanyu_targets") or {}
      if not table.contains(targetRecorded, tar[1]) then
        table.insert(targetRecorded, tar[1])
        room:addPlayerMark(room:getPlayerById(tar[1]), "@@yuanyu")
      end
      room:setPlayerMark(player, "yuanyu_targets", targetRecorded)
      player:addToPile("yuanyu_resent", card, true, self.name)
    end
  end
}
local yuanyu_trigger = fk.CreateTriggerSkill{
  name = "#yuanyu_trigger",
  events = {fk.Damage, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yuanyu.name) then
      if event == fk.Damage then
        return target and not target:isKongcheng() and player:getMark("yuanyu_targets") ~= 0 and table.contains(player:getMark("yuanyu_targets"), target.id)
      elseif event == fk.EventPhaseStart and target.phase == Player.Discard then
        if target == player then
          return player:getMark("yuanyu_targets") ~= 0 and table.find(player:getMark("yuanyu_targets"), function (pid)
            local p = player.room:getPlayerById(pid)
            return not p:isKongcheng() and not p.dead end)
        else
          return not target:isKongcheng() and player:getMark("yuanyu_targets") ~= 0 and table.contains(player:getMark("yuanyu_targets"), target.id)
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local x = 1
    if event == fk.Damage then
      x = data.damage
    end
    for i = 1, x do
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    if event == fk.EventPhaseStart and target == player then
      local targetRecorded = player:getMark("yuanyu_targets")
      tos = table.filter(room:getAlivePlayers(), function (p) return table.contains(targetRecorded, p.id) end)
    else
      table.insert(tos, target)
    end
    room:doIndicate(player.id, table.map(tos, function (p) return p.id end))
    for _, to in ipairs(tos) do
      if player.dead then break end
      local targetRecorded = player:getMark("yuanyu_targets")
      if targetRecorded == 0 then break end
      if not to.dead and not to:isKongcheng() and table.contains(targetRecorded, to.id) then
        local card = room:askForCard(to, 1, 1, false, self.name, false, ".|.|.|hand", "#yuanyu-push:" .. player.id)
        player:addToPile("yuanyu_resent", card, true, self.name) --原为false
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventLoseSkill and data ~= yuanyu then return false end
    return player == target and type(player:getMark("yuanyu_targets")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getMark("yuanyu_targets")
    if type(targets) == "table" then
      for _, pid in ipairs(targets) do
        room:removePlayerMark(room:getPlayerById(pid), "@@yuanyu")
      end
    end
    room:setPlayerMark(player, "yuanyu_targets", 0)
  end,
}
local xiyan = fk.CreateTriggerSkill{
  name = "xiyan",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerSpecial and move.specialName == "yuanyu_resent" then
          local suits = {}
          for _, id in ipairs(player:getPile("yuanyu_resent")) do
            table.insertIfNeed(suits, Fk:getCardById(id).suit)
          end
          table.removeOne(suits, Card.NoSuit)
          return #suits > 3
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getMark("yuanyu_targets")
    if type(targets) == "table" then
      for _, pid in ipairs(targets) do
        room:removePlayerMark(room:getPlayerById(pid), "@@yuanyu")
      end
    end
    room:setPlayerMark(player, "yuanyu_targets", 0)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player:getPile("yuanyu_resent"))
    room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    if room.current and not room.current.dead and room.current.phase ~= Player.NotActive then
      if room.current == player then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 4)
        if player:usedSkillTimes(yuanyu.name, Player.HistoryPhase) > player:getMark("yuanyu_extra_times-phase") then
          room:addPlayerMark(player, "yuanyu_extra_times-phase")
        end
        room:addPlayerMark(player, "xiyan_targetmod-turn")
      elseif room:askForSkillInvoke(player, self.name, nil, "#xiyan-debuff::"..room.current.id) then
        room:addPlayerMark(room.current, MarkEnum.MinusMaxCardsInTurn, 4)
        room:addPlayerMark(room.current, "@@xiyan_prohibit-turn")
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if (move.from == player.id and table.find(move.moveInfo, function (info)
        return info.fromSpecialName == "yuanyu_resent" end)) or (move.to == player.id and move.specialName == "yuanyu_resent") then
          return true
        end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local suitsRecorded = {}
    if player:hasSkill(self.name, true) then
      for _, id in ipairs(player:getPile("yuanyu_resent")) do
        table.insertIfNeed(suitsRecorded, Fk:getCardById(id):getSuitString(true))
      end
    end
    player.room:setPlayerMark(player, "@xiyan", #suitsRecorded > 0 and suitsRecorded or 0)
  end,
}
local xiyan_targetmod = fk.CreateTargetModSkill{
  name = "#xiyan_targetmod",
  residue_func = function(self, player, skill, scope, card)
    return (card and player:getMark("xiyan_targetmod-turn") > 0) and 999 or 0
  end,
}
local xiyan_prohibit = fk.CreateProhibitSkill{
  name = "#xiyan_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@xiyan_prohibit-turn") > 0 and card.type == Card.TypeBasic
  end,
}
yuanyu:addRelatedSkill(yuanyu_trigger)
xiyan:addRelatedSkill(xiyan_targetmod)
xiyan:addRelatedSkill(xiyan_prohibit)
zhangyao:addSkill(yuanyu)
zhangyao:addSkill(xiyan)
Fk:loadTranslationTable{
  ["zhangyao"] = "张媱",
  ["yuanyu"] = "怨语",
  ["#yuanyu_trigger"] = "怨语",
  [":yuanyu"] = "出牌阶段限一次，你可以摸一张牌并将一张手牌置于武将牌上，称为“怨”。然后选择一名其他角色，你与其的弃牌阶段开始时，"..
  "该角色每次造成1点伤害后也须放置一张“怨”直到你触发〖夕颜〗。",
  ["xiyan"] = "夕颜",
  [":xiyan"] = "每次增加“怨”时，若“怨”的花色数达到4种，你可以获得所有“怨”。然后若此时是你的回合，你的〖怨语〗视为未发动过，"..
  "本回合手牌上限+4且使用牌无次数限制；若不是你的回合，你可令当前回合角色本回合手牌上限-4且本回合不能使用基本牌。",

  ["yuanyu_resent"] = "怨",
  ["@@yuanyu"] = "怨语",
  ["#yuanyu"] = "怨语：你可以摸一张牌，然后放置一张手牌作为“怨”",
  ["#yuanyu-choose"] = "怨语：选择作为“怨”的一张手牌以及作为目标的一名其他角色",
  ["#yuanyu-push"] = "怨语：选择一张手牌作为%src的“怨”",
  ["@xiyan"] = "夕颜",
  ["#xiyan-debuff"] = "夕颜：是否令%dest本回合不能使用基本牌且手牌上限-4",
  ["@@xiyan_prohibit-turn"] = "夕颜 不能出牌",

  ["$yuanyu1"] = "此生最恨者，吴垣孙氏人。",
  ["$yuanyu2"] = "愿为宫外柳，不做建章卿。",
  ["$xiyan1"] = "夕阳绝美，只叹黄昏。",
  ["$xiyan2"] = "朱颜将逝，知我何求。",
  ["~zhangyao"] = "花开人赏，花败谁怜……",
}

--芝兰玉树：张虎 吕玲绮 刘永 万年公主 滕公主 庞会
local zhanghu = General(extension, "zhanghu", "wei", 4)
local cuijian = fk.CreateActiveSkill{
  name = "cuijian",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = table.filter(target:getCardIds("h"), function(id) return Fk:getCardById(id).trueName == "jink" end)
    if #cards == 0 then
      if player:getMark("@tongyuan") ~= 0 and string.find(player:getMark("@tongyuan"), "1") then
        player:drawCards(2, self.name)
      end
    else
      table.insertTable(cards, table.filter(target:getCardIds("he"), function(id) return Fk:getCardById(id).sub_type == Card.SubtypeArmor end))
      local n = #cards
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      room:obtainCard(player, dummy, true, fk.ReasonGive)
      if player:getMark("@tongyuan") ~= 0 and string.find(player:getMark("@tongyuan"), "2") then
        return
      end
      if player.dead or target.dead or player:isNude() then return end
      local dummy2 = Fk:cloneCard("dilu")
      if #player:getCardIds("he") <= n then
        dummy2:addSubcards(player:getCardIds("he"))
        room:obtainCard(target, dummy2, true, fk.ReasonGive)
      else
        cards = room:askForCard(player, n, n, true, self.name, false, ".", "#cuijian-card::"..target.id..":"..n)
        dummy2:addSubcards(cards)
        room:obtainCard(target, dummy2, true, fk.ReasonGive)
      end
    end
  end,
}
local tongyuan = fk.CreateTriggerSkill{
  name = "tongyuan",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.card.color == Card.Red and player:getMark("@tongyuan") == "1,2" then
      if event == fk.CardUsing then
        return data.card:isCommonTrick()
      else
        return data.card.type == Card.TypeBasic and data.targetGroup and data.firstTarget
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      data.disresponsiveList = table.map(room.alive_players, function(p) return p.id end)
    else
      local targets = AskForAddTarget(player, room.alive_players, 1, false, "#tongyuan-choose:::"..data.card:toLogString(), self.name, data)
      if #targets > 0 then
        TargetGroup:pushTargets(data.targetGroup, targets)
      end
    end
  end,
}
local tongyuan_trigger = fk.CreateTriggerSkill{
  name = "#tongyuan_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill("tongyuan") and data.card.color == Card.Red then
      if data.card.type == Card.TypeTrick then
        return event == fk.CardUseFinished and (player:getMark("@tongyuan") == 0 or not string.find(player:getMark("@tongyuan"), "1"))
      elseif data.card.type == Card.TypeBasic then
        return player:getMark("@tongyuan") == 0 or not string.find(player:getMark("@tongyuan"), "2")
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("tongyuan")
    room:notifySkillInvoked(player, "tongyuan", "special")
    if data.card.type == Card.TypeTrick then
      if player:getMark("@tongyuan") == 0 then
        room:setPlayerMark(player, "@tongyuan", "1")
      else
        room:setPlayerMark(player, "@tongyuan", "1,2")
      end
    else
      if player:getMark("@tongyuan") == 0 then
        room:setPlayerMark(player, "@tongyuan", "2")
      else
        room:setPlayerMark(player, "@tongyuan", "1,2")
      end
    end
  end,
}
tongyuan:addRelatedSkill(tongyuan_trigger)
zhanghu:addSkill(cuijian)
zhanghu:addSkill(tongyuan)
Fk:loadTranslationTable{
  ["zhanghu"] = "张虎",
  ["cuijian"] = "摧坚",
  [":cuijian"] = "出牌阶段限一次，你可以选择一名有手牌的其他角色，若其手牌中有【闪】，其将所有【闪】和防具牌交给你，然后你交给其等量的牌。",
  ["tongyuan"] = "同援",
  [":tongyuan"] = "锁定技，你使用红色锦囊牌后，〖摧坚〗增加效果“若其没有【闪】，你摸两张牌”；<br>"..
  "你使用或打出红色基本牌后，〖摧坚〗将“交给”的效果删除；<br>"..
  "若以上两个效果均已触发，则你本局游戏接下来你使用红色普通锦囊牌无法被响应，使用红色基本牌可以额外指定一个目标。",
  ["#cuijian-card"] = "摧坚：交给 %dest %arg张牌",
  ["@tongyuan"] = "同援",
  ["#tongyuan-choose"] = "同援：你可以为%arg额外指定一个目标",
}

local lvlingqi = General(extension, "lvlingqi", "qun", 4, 4, General.Female)
local guowu = fk.CreateTriggerSkill{
  name = "guowu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    local types = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    local card = room:getCardsFromPileByRule("slash", 1, "discardPile")
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
    if #types > 1 then
      room:addPlayerMark(player, "guowu2-phase", 1)
    end
    if #types > 2 then
      room:addPlayerMark(player, "guowu3-phase", 1)
    end
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
local guowu_delay = fk.CreateTriggerSkill{
  name = "#guowu_delay",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("guowu3-phase") > 0 and not player.dead and
      (data.card:isCommonTrick() or data.card.trueName == "slash") and #getUseExtraTargets(player.room, data) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = getUseExtraTargets(room, data)
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, targets, 1, 2, "#guowu-choose:::"..data.card:toLogString(), guowu.name, true)
    if #tos > 0 then
      table.forEach(tos, function (id)
        table.insert(data.tos, {id})
      end)
    end
  end,
}
local guowu_targetmod = fk.CreateTargetModSkill{
  name = "#guowu_targetmod",
  bypass_distances =  function(self, player)
    return player:getMark("guowu2-phase") > 0
  end,
}
local zhuangrong = fk.CreateTriggerSkill{
  name = "zhuangrong",
  frequency = Skill.Wake,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player.player_cards[Player.Hand] == 1 or player.hp == 1
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
    local n = player.maxHp - #player.player_cards[Player.Hand]
    if n > 0 then
      player:drawCards(n, self.name)
    end
    room:handleAddLoseSkills(player, "shenwei|wushuang", nil, true, false)
  end,
}
guowu:addRelatedSkill(guowu_delay)
guowu:addRelatedSkill(guowu_targetmod)
lvlingqi:addSkill(guowu)
lvlingqi:addSkill(zhuangrong)
lvlingqi:addRelatedSkill("shenwei")
lvlingqi:addRelatedSkill("wushuang")
Fk:loadTranslationTable{
  ["lvlingqi"] = "吕玲绮",
  ["guowu"] = "帼武",
  ["#guowu_delay"] = "帼武",
  [":guowu"] = "出牌阶段开始时，你可以展示所有手牌，若包含的类别数：不小于1，你从弃牌堆中获得一张【杀】；不小于2，你本阶段使用牌无距离限制；"..
  "不小于3，你本阶段使用【杀】或普通锦囊牌可以多指定两个目标。",
  ["zhuangrong"] = "妆戎",
  [":zhuangrong"] = "觉醒技，一名角色的回合结束时，若你的手牌数或体力值为1，你减1点体力上限并将体力值回复至体力上限，然后将手牌摸至体力上限。"..
  "若如此做，你获得技能〖神威〗和〖无双〗。",
  ["#guowu-choose"] = "帼武：你可以为%arg增加至多两个目标",

  ["$guowu1"] = "方天映黛眉，赤兔牵红妆。",
  ["$guowu2"] = "武姬青丝利，巾帼女儿红。",
  ["$zhuangrong1"] = "锋镝鸣手中，锐戟映秋霜。",
  ["$zhuangrong2"] = "红妆非我愿，学武觅封侯。",
  ["$shenwei_lvlingqi1"] = "继父神威，无坚不摧！",
  ["$shenwei_lvlingqi2"] = "我乃温侯吕奉先之女！",
  ["$wushuang_lvlingqi1"] = "猛将策良骥，长戟破敌营。",
  ["$wushuang_lvlingqi2"] = "杀气腾剑戟，严风卷戎装。",
  ["~lvlingqi"] = "父亲，女儿好累……",
}

local liuyong = General(extension, "liuyong", "shu", 3)
local zhuning = fk.CreateActiveSkill{
  name = "zhuning",
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("zhuning-phase") < 2 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return true
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addPlayerMark(player, "zhuning-phase", 2)
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      to = target.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonGive,
      proposer = player.id,
      skillName = self.name,
    })
    if not player.dead then
      local success, data = room:askForUseActiveSkill(player, "zhuning_viewas", "#zhuning-choice", true)
      if success then
        local card = Fk.skills["zhuning_viewas"]:viewAs(data.cards)
        local use = {
          from = player.id,
          tos = table.map(data.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
        room:useCard(use)
        if not player.dead and not use.damageDealt then
          room:removePlayerMark(player, "zhuning-phase", 1)
        end
      end
    end
  end,
}
local zhuning_viewas = fk.CreateViewAsSkill{
  name = "zhuning_viewas",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.is_damage_card and not card.is_derived then
        table.insertIfNeed(names, card.name)
      end
    end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "zhuning"
    return card
  end,
}
local zhuning_targetmod = fk.CreateTargetModSkill{
  name = "#zhuning_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "zhuning")
  end,
}
local function getFengxiangPlayer(room)
  local nums = table.map(room.alive_players, function(p)
    return #table.filter(p:getCardIds("h"), function(id)
      return Fk:getCardById(id, true):getMark("@@zhuning-inhand") > 0
    end)
  end)
  local n = math.max(table.unpack(nums))
  if #table.filter(room.alive_players, function(p)
      return #table.filter(p:getCardIds("h"), function(id)
        return Fk:getCardById(id, true):getMark("@@zhuning-inhand") > 0
      end) == n
    end) > 1 then
      return 0
  else
    return room.alive_players[table.indexOf(nums, n)].id
  end
end
local fengxiang = fk.CreateTriggerSkill{
  name = "fengxiang",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.Damaged then
        return target == player
      else
        local to = getFengxiangPlayer(player.room)
        for _, move in ipairs(data) do
          if move.extra_data and move.extra_data.fengxiang and move.extra_data.fengxiang ~= to then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      local to = getFengxiangPlayer(room)
      if to ~= 0 then
        room:doIndicate(player.id, {to})
        to = room:getPlayerById(to)
        if to:isWounded() then
          room:recover({
            who = to,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
      else
        player:drawCards(1, self.name)
      end
    else
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.BeforeCardsMove, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if event == fk.BeforeCardsMove then
      if player:hasSkill(self.name, true) then
        for _, move in ipairs(data) do
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
          if move.toArea == Card.PlayerHand then
            return true
          end
        end
      end
    else
      for _, move in ipairs(data) do
        if move.skillName == "zhuning" then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.BeforeCardsMove then
      for _, move in ipairs(data) do
        move.extra_data = move.extra_data or {}
        move.extra_data.fengxiang = getFengxiangPlayer(player.room)
      end
    else
      for _, move in ipairs(data) do
        if move.skillName == "zhuning" then
          for _, info in ipairs(move.moveInfo) do
            player.room:setCardMark(Fk:getCardById(info.cardId, true), "@@zhuning-inhand", 1)
          end
        end
      end
    end
  end,
}
Fk:addSkill(zhuning_viewas)
zhuning:addRelatedSkill(zhuning_targetmod)
liuyong:addSkill(zhuning)
liuyong:addSkill(fengxiang)
Fk:loadTranslationTable{
  ["liuyong"] = "刘永",
  ["zhuning"] = "诛佞",
  [":zhuning"] = "出牌阶段限一次，你可以交给一名其他角色任意张牌，这些牌标记为“隙”，然后你可以视为使用一张不计次数的【杀】或伤害类锦囊牌，"..
  "然后若此牌没有造成伤害，此技能本阶段改为“出牌阶段限两次”。",
  ["fengxiang"] = "封乡",
  [":fengxiang"] = "锁定技，当你受到伤害后，手牌中“隙”唯一最多的角色回复1点体力（没有唯一最多的角色则改为你摸一张牌）；"..
  "当有角色因手牌数改变而使“隙”唯一最多的角色改变后，你摸一张牌。",
  ["@@zhuning-inhand"] = "隙",
  ["zhuning_viewas"] = "诛佞",
  ["#zhuning-choice"] = "诛佞：你可以视为使用一张不计次数的伤害牌",

  ["$zhuning1"] = "此剑半丈，当斩奸佞人头！",
  ["$zhuning2"] = "此身八尺，甘为柱国之石。",
  ["$fengxiang1"] = "北风摧蜀地，王爵换乡侯。",
  ["$fengxiang2"] = "汉皇可负我，我不负父兄。",
  ["~liuyong"] = "他日若是凛风起，你自长哭我自笑。",
}

local wanniangongzhu = General(extension, "wanniangongzhu", "qun", 3, 3, General.Female)
local zhenge = fk.CreateTriggerSkill{
  name = "zhenge",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local p = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id end), 1, 1, "#zhenge-choose", self.name)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if to:getMark("@zhenge") < 5 then
      room:addPlayerMark(to, "@zhenge", 1)
    end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(to)) do
      if to:inMyAttackRange(p) and not to:isProhibited(p, Fk:cloneCard("slash")) then
        if p ~= player then
          table.insert(targets, p.id)
        end
      else
        return
      end
    end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#zhenge-slash::"..to.id, self.name, true)
    if #tos > 0 then
      room:useVirtualCard("slash", nil, to, room:getPlayerById(tos[1]), self.name, true)
    end
  end,
}
local zhenge_attackrange = fk.CreateAttackRangeSkill{
  name = "#zhenge_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@zhenge")
  end,
}
local xinghan = fk.CreateTriggerSkill{
  name = "xinghan",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target and target:getMark("@zhenge") > 0 and
      data.card and data.card.trueName == "slash" and data.card.extra_data and table.contains(data.card.extra_data, "xinghan")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not table.every(room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Hand] < player:getHandcardNum() end) then
        player:drawCards(math.min(target:getAttackRange(), 5), self.name)
    else
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return player.phase ~= Player.NotActive and data.card.trueName == "slash" and player:getMark("xinghan-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "xinghan-turn", 1)
    if target:getMark("@zhenge") > 0 then
      data.card.extra_data = data.card.extra_data or {}
      table.insert(data.card.extra_data, "xinghan")
    end
  end,
}
zhenge:addRelatedSkill(zhenge_attackrange)
wanniangongzhu:addSkill(zhenge)
wanniangongzhu:addSkill(xinghan)
Fk:loadTranslationTable{
  ["wanniangongzhu"] = "万年公主",
  ["zhenge"] = "枕戈",
  [":zhenge"] = "准备阶段，你可以令一名角色的攻击范围+1（加值至多为5），然后若其他角色都在其的攻击范围内，你可以令其视为对另一名你选择的角色使用一张【杀】。",
  ["xinghan"] = "兴汉",
  [":xinghan"] = "锁定技，当〖枕戈〗选择过的角色使用【杀】造成伤害后，若此【杀】是本回合的第一张【杀】，你摸一张牌。若你的手牌数不是全场唯一最多的，则改为摸X张牌（X为该角色的攻击范围且最多为5）。",
  ["@zhenge"] = "枕戈",
  ["#zhenge-choose"] = "枕戈：你可以令一名角色的攻击范围+1（至多+5）",
  ["#zhenge-slash"] = "枕戈：你可以选择另一名角色，视为 %dest 对此角色使用【杀】",

  ["$zhenge1"] = "常备不懈，严阵以待。",
  ["$zhenge2"] = "枕戈待旦，日夜警惕。",
  ["$xinghan1"] = "汉之兴旺，不敢松懈。",
  ["$xinghan2"] = "兴汉除贼，吾之所愿。",
  ["~wanniangongzhu"] = "兴汉的使命，还没有完成。",
}

local tenggongzhu = General(extension, "tenggongzhu", "wu", 3, 3, General.Female)
local xingchong = fk.CreateTriggerSkill{
  name = "xingchong",
  anim_type = "drawcard",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xingchong-invoke:::"..tostring(player.maxHp))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player.maxHp
    local choices = {}
    local i1 = 0
    if player:isKongcheng() then
      i1 = 1
    end
    for i = i1, n, 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askForChoice(player, choices, self.name, "#xingchong-draw")
    if choice ~= "0" then
      player:drawCards(tonumber(choice), self.name)
    end
    if player:isKongcheng() then return end
    n = n - tonumber(choice)
    local cards = room:askForCard(player, 1, n, false, self.name, true, ".", "#xingchong-card:::"..tostring(n))
    if #cards > 0 then
      player:showCards(cards)
      room:sendCardVirtName(cards, self.name)
      if not player.dead then
        for _, id in ipairs(cards) do
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            room:setCardMark(Fk:getCardById(id), "@@xingchong-round", 1)
          end
        end
      end
    end
  end,
}
local xingchong_trigger = fk.CreateTriggerSkill{
  name = "#xingchong_trigger",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes("xingchong", Player.HistoryRound) > 0 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId):getMark("@@xingchong-round") > 0 and info.fromArea == Card.PlayerHand then
            n = n + 1
            room:setCardMark(Fk:getCardById(info.cardId), "@@xingchong-round", 0)
          end
        end
      end
    end
    if n > 0 then
      player:drawCards(2 * n, "xingchong")
    end
  end,
}
local liunian = fk.CreateTriggerSkill{
  name = "liunian",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:getMark("liunian-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(self.name) == 1 then
      room:changeMaxHp(player, 1)
    else
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 10)
    end
  end,

  refresh_events = {fk.AfterDrawPileShuffle},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) < 2
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, self.name, 1)
    player.room:setPlayerMark(player, "liunian-turn", 1)
  end,
}
xingchong:addRelatedSkill(xingchong_trigger)
tenggongzhu:addSkill(xingchong)
tenggongzhu:addSkill(liunian)
Fk:loadTranslationTable{
  ["tenggongzhu"] = "滕公主",
  ["xingchong"] = "幸宠",
  [":xingchong"] = "每轮游戏开始时，你可以摸任意张牌并展示任意张牌（摸牌和展示牌的总数不能超过你的体力上限）。"..
  "若如此做，本轮内当你失去一张以此法展示的手牌后，你摸两张牌。",
  ["liunian"] = "流年",
  [":liunian"] = "锁定技，牌堆第一次洗牌的回合结束时，你加1点体力上限。牌堆第二次洗牌的回合结束时，你回复1点体力，然后本局游戏手牌上限+10。",
  ["#xingchong-invoke"] = "幸宠：你可以摸牌、展示牌合计至多%arg张，本轮失去展示的牌后摸两张牌",
  ["#xingchong-draw"] = "幸宠：选择摸牌数",
  ["#xingchong-card"] = "幸宠：展示至多%arg张牌，本轮失去一张展示牌后摸两张牌",
  ["@@xingchong-round"] = "幸宠",

  ["$xingchong1"] = "佳人有荣幸，好女天自怜。",
  ["$xingchong2"] = "世间万般宠爱，独聚我于一身。",
  ["$liunian1"] = "佳期若梦，似水流年。",
  ["$liunian2"] = "逝者如流水，昼夜不将息。",
  ["~tenggongzhu"] = "已过江北，再无江南……",
}

local panghui = General(extension, "panghui", "wei", 5)
local yiyong = fk.CreateTriggerSkill{
  name = "yiyong",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      data.to and data.to ~= player and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 999, true, self.name, true, ".", "#yiyong-invoke::"..data.to.id, true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local n1, n2 = 0, 0
    for _, id in ipairs(self.cost_data) do
      n1 = n1 + Fk:getCardById(id).number
    end
    local cards = player.room:askForDiscard(data.to, 1, 999, true, self.name, false, ".",
      "#yiyong-discard:"..player.id.."::"..tostring(n1))
    for _, id in ipairs(cards) do
      n2 = n2 + Fk:getCardById(id).number
    end
    if n1 <= n2 and #cards > 0 then
      player:drawCards(#cards, self.name)
    end
    if n1 >= n2 then
      data.damage = data.damage + 1
    end
  end,
}
panghui:addSkill(yiyong)
Fk:loadTranslationTable{
  ["panghui"] = "庞会",
  ["yiyong"] = "异勇",
  [":yiyong"] = "当你对其他角色造成伤害时，你可以弃置任意张牌，令该角色弃置任意张牌。若你弃置的牌的点数之和：不大于其，你摸X张牌"..
  "（X为该角色弃置的牌数）；不小于其，此伤害+1。",
  --"当你对其他角色造成伤害时，你可以与其同时弃置任意张牌，若你弃置的牌点数之和：不大于其，你摸X张牌（X为该角色弃置的牌数）；不小于其，此伤害+1。",
  ["#yiyong-invoke"] = "异勇：你可以弃置任意张牌，令 %dest 弃置任意张牌，根据双方弃牌点数之和执行效果",
  ["#yiyong-discard"] = "异勇：弃置任意张牌，若点数之和大于等于%arg则 %src 摸牌，若小于则伤害+1",

  ["$yiyong1"] = "关氏鼠辈，庞令明之子来邪！",
  ["$yiyong2"] = "凭一腔勇力，父仇定可报还。",
  ["~panghui"] = "大仇虽报，奈何心有余创。",
}

Fk:loadTranslationTable{
  ["yuechen"] = "乐綝",
  ["porui"] = "破锐",
  [":porui"] = "每轮限一次，其他角色的结束阶段，你可以弃置一张牌并选择本回合内失去过牌的另一名其他角色，你视为对该角色依次使用X+1张【杀】，然后你"..
  "交给其X张手牌（X为其本回合失去的牌数且最多为5，不足则全交给）。",
  ["gonghu"] = "共护",
  [":gonghu"] = "锁定技，当你于回合外一回合失去超过一张基本牌后，〖破锐〗改为“每轮限两次”；当你于回合外一回合造成或受到伤害超过1点伤害后，"..
  "你删除〖破锐〗中交给牌的效果。若以上两个效果均已触发，则你本局游戏使用红色基本牌无法响应，使用红色普通锦囊牌可以额外指定一个目标。",
}

--天下归心：魏贾诩 陈登 蔡瑁张允 高览 尹夫人 吕旷吕翔 陈珪 陈矫 秦朗 唐咨
local jiaxu = General(extension, "ty__jiaxu", "wei", 3)
local ty__jianshu = fk.CreateActiveSkill{
  name = "ty__jianshu",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target.id, Fk:getCardById(effect.cards[1]), false, fk.ReasonGive)
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if not p:isKongcheng() and p ~= player then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ty__jianshu-choose::"..target.id, self.name, false)
    if #to == 0 then
      to = room:getPlayerById(table.random(targets))
    else
      to = room:getPlayerById(to[1])
    end
    local pindian = target:pindian({to}, self.name)
    if pindian.results[to.id].winner then
      local winner, loser
      if pindian.results[to.id].winner == target then
        winner = target
        loser = to
      else
        winner = to
        loser = target
      end
      if not winner:isNude() and not winner.dead then
        local id = table.random(winner:getCardIds{Player.Hand, Player.Equip})
        room:throwCard({id}, self.name, winner, winner)
      end
      if not loser.dead then
        room:loseHp(loser, 1, self.name)
      end
    else
      if not target.dead then
        room:loseHp(target, 1, self.name)
      end
      if not to.dead then
        room:loseHp(to, 1, self.name)
      end
    end
  end
}
local ty__jianshu_record = fk.CreateTriggerSkill{
  name = "#ty__jianshu_record",

  refresh_events = {fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if player:usedSkillTimes("ty__jianshu", Player.HistoryPhase) > 0 then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.LoseHp)
      if e then
        return e.data[3] == "ty__jianshu"
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player:setSkillUseHistory("ty__jianshu", 0, Player.HistoryPhase)
  end,
}
local ty__yongdi = fk.CreateActiveSkill{
  name = "ty__yongdi",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select).gender == General.Male
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if table.every(room.alive_players, function(p) return p.hp >= target.hp end) and target:isWounded() then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if table.every(room.alive_players, function(p) return p.maxHp >= target.maxHp end) then
      room:changeMaxHp(target, 1)
    end
    if table.every(room.alive_players, function(p) return p:getHandcardNum() >= target:getHandcardNum() end) then
      target:drawCards(math.min(target.maxHp, 5), self.name)
    end
   end
}
ty__jianshu:addRelatedSkill(ty__jianshu_record)
jiaxu:addSkill("zhenlve")
jiaxu:addSkill(ty__jianshu)
jiaxu:addSkill(ty__yongdi)
Fk:loadTranslationTable{
  ["ty__jiaxu"] = "贾诩",
  ["ty__jianshu"] = "间书",
  [":ty__jianshu"] = "出牌阶段限一次，你可以将一张黑色手牌交给一名其他角色，然后选择另一名其他角色，令这两名角色拼点：赢的角色随机弃置一张牌，"..
  "没赢的角色失去1点体力。若有角色因此死亡，此技能视为未发动过。",
  ["ty__yongdi"] = "拥嫡",
  [":ty__yongdi"] = "限定技，出牌阶段，你可选择一名男性角色：若其体力值全场最少，其回复1点体力；体力上限全场最少，其加1点体力上限；"..
  "手牌数全场最少，其摸体力上限张牌（最多摸五张）。",
  ["#ty__jianshu-choose"] = "间书：选择另一名其他角色，令其和 %dest 拼点",
}

Fk:loadTranslationTable{
  ["ty__chendeng"] = "陈登",
  ["wangzu"] = "望族",
  [":wangzu"] = "每回合限一次，当你受到其他角色造成的伤害时，你可以随机弃置一张手牌令此伤害-1，若你所在的阵营存活人数全场最多，则改为选择一张手牌弃置。",
  ["yingshui"] = "营说",
  [":yingshui"] = "出牌阶段限一次，你可以交给你攻击范围内的一名其他角色一张牌，然后令其选择一项：1.你对其造成的1点伤害；2.交给你至少两张装备牌。",
  ["fuyuan"] = "扶援",
  [":fuyuan"] = "当一名角色成为【杀】的目标后，若其本回合没有成为过红色牌的目标，你可令其摸一张牌。",
}

local caimaozhangyun = General(extension, "caimaozhangyun", "wei", 4)
local lianzhou = fk.CreateTriggerSkill{
  name = "lianzhou",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.chained then
      player:setChainState(true)
    end
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.hp == player.hp and not p.chained end), function(p) return p.id end)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 999, "#lianzhou-choose", self.name, true)
    if #tos > 0 then
      table.forEach(tos, function(p) room:getPlayerById(p):setChainState(true) end)
    end
  end,
}
local jinglan = fk.CreateTriggerSkill{
  name = "jinglan",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() > player.hp then
      room:askForDiscard(player, 4, 4, false, self.name, false)
    elseif player:getHandcardNum() == player.hp then
      room:askForDiscard(player, 1, 1, true, self.name, false)
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    elseif player:getHandcardNum() < player.hp then
      room:damage{
        to = player,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = self.name,
      }
      if not player.dead then
        player:drawCards(5, self.name)
      end
    end
  end,
}
caimaozhangyun:addSkill(lianzhou)
caimaozhangyun:addSkill(jinglan)
Fk:loadTranslationTable{
  ["caimaozhangyun"] = "蔡瑁张允",
  ["lianzhou"] = "连舟",
  [":lianzhou"] = "锁定技，准备阶段，将你的武将牌横置，然后横置任意名体力值等于你的角色。",
  ["jinglan"] = "惊澜",
  [":jinglan"] = "锁定技，当你造成伤害后，若你的手牌数：大于体力值，你弃四张手牌；等于体力值，你弃一张牌并回复1点体力；"..
  "小于体力值，你受到1点火焰伤害并摸五张牌。",
  ["#lianzhou-choose"] = "连舟：你可以横置任意名体力值等于你的角色",
}

local gaolan = General(extension, "ty__gaolan", "qun", 4)
local xizhen = fk.CreateTriggerSkill{
  name = "xizhen",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not (player:isProhibited(p, Fk:cloneCard("slash")) and player:isProhibited(p, Fk:cloneCard("duel"))) then
        table.insert(targets, p.id)
      end
    end
    if #targets > 0 then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#xizhen-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:setPlayerMark(player, "xizhen-phase", to.id)
    local choices = {}
    for _, name in ipairs({"slash", "duel"}) do
      if not player:isProhibited(to, Fk:cloneCard(name)) then
        table.insert(choices, name)
      end
    end
    local choice = room:askForChoice(player, choices, self.name, "#xizhen-choice::"..to.id)
    room:useVirtualCard(choice, nil, player, to, self.name, true)
  end,
}
local xizhen_trigger = fk.CreateTriggerSkill{
  name = "#xizhen_trigger",
  mute = true,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("xizhen-phase") ~= 0 and data.responseToEvent and data.responseToEvent.from and
      data.responseToEvent.from == player.id
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("xizhen-phase"))
    if not to.dead then
      if to:isWounded() then
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = "xizhen",
        }
        player:drawCards(1, "xizhen")
      else
        player:drawCards(2, "xizhen")
      end
    end
  end,
}
xizhen:addRelatedSkill(xizhen_trigger)
gaolan:addSkill(xizhen)
Fk:loadTranslationTable{
  ["ty__gaolan"] = "高览",
  ["xizhen"] = "袭阵",
  [":xizhen"] = "出牌阶段开始时，你可选择一名其他角色，视为对其使用【杀】或【决斗】，然后本阶段你的牌每次被使用或打出牌响应时，"..
  "该角色回复1点体力，你摸一张牌（若其未受伤，改为两张）。",
  ["#xizhen-choose"] = "袭阵：你可视为对一名角色使用【杀】或【决斗】；<br>本阶段你的牌被响应时其回复1点体力，你摸一张牌（若其未受伤则改为摸两张）",
  ["#xizhen-choice"] = "袭阵：选择视为对 %dest 使用的牌",

  ["$xizhen1"] = "今我为刀俎，尔等皆为鱼肉。",
  ["$xizhen2"] = "先发可制人，后发制于人。",
  ["~ty__gaolan"] = "郭公则害我！",
}

local yinfuren = General(extension, "yinfuren", "wei", 3, 3, General.Female)
local yingyu = fk.CreateTriggerSkill{
  name = "yingyu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (player.phase == Player.Play or (player.phase == Player.Finish and player:usedSkillTimes("yongbi", Player.HistoryGame) > 0))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isKongcheng() end), function(p) return p.id end)
    if #targets < 2 then return end
    local tos = room:askForChoosePlayers(player, targets, 2, 2, "#yingyu-choose", self.name, true)
    if #tos == 2 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target1 = room:getPlayerById(self.cost_data[1])
    local target2 = room:getPlayerById(self.cost_data[2])
    room:doIndicate(player.id, {self.cost_data[1]})
    local id1 = room:askForCardChosen(player, target1, "h", self.name)
    room:doIndicate(player.id, {self.cost_data[2]})
    local id2 = room:askForCardChosen(player, target2, "h", self.name)
    target1:showCards(id1)
    target2:showCards(id2)
    if Fk:getCardById(id1).suit ~= Fk:getCardById(id2).suit and
      Fk:getCardById(id1).suit ~= Card.NoSuit and Fk:getCardById(id1).suit ~= Card.NoSuit then
      local to = room:askForChoosePlayers(player, self.cost_data, 1, 1, "#yingyu2-choose", self.name, false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(self.cost_data)
      end
      if to == target1.id then
        room:obtainCard(self.cost_data[1], id2, true, fk.ReasonPrey)
      else
        room:obtainCard(self.cost_data[2], id1, true, fk.ReasonPrey)
      end
    end
  end,
}
local yongbi = fk.CreateActiveSkill{
  name = "yongbi",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select).gender == General.Male
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player.player_cards[Player.Hand])
    room:obtainCard(target.id, dummy, false, fk.ReasonGive)
    local suits = {}
    for _, id in ipairs(dummy.subcards) do
      if Fk:getCardById(id, true).suit ~= Card.NoSuit then
        table.insertIfNeed(suits, Fk:getCardById(id, true).suit)
      end
    end
    if #suits > 1 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 2)
      room:addPlayerMark(target, MarkEnum.AddMaxCards, 2)
    end
    if #suits > 2 then
      room:setPlayerMark(player, "@@yongbi", 1)
      room:setPlayerMark(target, "@@yongbi", 1)
    end
  end,
}
local yingyu_trigger = fk.CreateTriggerSkill{
  name = "#yingyu_trigger",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yongbi") > 0 and data.damage > 1
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage - 1
  end,
}
yongbi:addRelatedSkill(yingyu_trigger)
yinfuren:addSkill(yingyu)
yinfuren:addSkill(yongbi)
Fk:loadTranslationTable{
  ["yinfuren"] = "尹夫人",
  ["yingyu"] = "媵予",
  [":yingyu"] = "准备阶段，你可以展示两名角色的各一张手牌，若花色不同，则你选择其中的一名角色获得另一名角色的展示牌。",
  ["yongbi"] = "拥嬖",
  [":yongbi"] = "限定技，出牌阶段，你可将所有手牌交给一名男性角色，然后〖媵予〗改为结束阶段也可以发动。根据其中牌的花色数量，"..
  "你与其永久获得以下效果：至少两种，手牌上限+2；至少三种，受到大于1点的伤害时伤害-1。",
  ["#yingyu-choose"] = "媵予：你可以展示两名角色各一张手牌，若花色不同，选择其中一名角色获得另一名角色的展示牌",
  ["#yingyu2-choose"] = "媵予：选择一名角色，其获得另一名角色的展示牌",
  ["@@yongbi"] = "拥嬖",
  ["#yingyu_trigger"] = "拥嬖",

  ["$yingyu1"] = "妾身蒲柳，幸蒙将军不弃。",
  ["$yingyu2"] = "妾之所有，愿尽予君。",
  ["$yongbi1"] = "海誓山盟，此生不渝。",
  ["$yongbi2"] = "万千宠爱，幸君怜之。",
  ["~yinfuren"] = "奈何遇君何其晚乎？",
}

local lvkuanglvxiang = General(extension, "ty__lvkuanglvxiang", "wei", 4)
local shuhe = fk.CreateActiveSkill{
  name = "shuhe",
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:showCards(effect.cards)
    local card = Fk:getCardById(effect.cards[1])
    local yes = false
    for _, p in ipairs(room:getAlivePlayers()) do
      for _, id in ipairs(p:getCardIds{Player.Equip, Player.Judge}) do
        if Fk:getCardById(id).number == card.number then
          room:obtainCard(player, id, true, fk.ReasonPrey)
          yes = true
        end
      end
    end
    if not yes then
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#shuhe-choose:::"..card:toLogString(), self.name, false)
      if #to > 0 then
        to = room:getPlayerById(to[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:obtainCard(to, card, true, fk.ReasonGive)
      if player:getMark("@ty__liehou") < 5 then
        room:addPlayerMark(player, "@ty__liehou", 1)
      end
    end
  end,
}
local ty__liehou = fk.CreateTriggerSkill{
  name = "ty__liehou",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards, fk.AfterDrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n + 1 + player:getMark("@ty__liehou")
    else
      local room = player.room
      local n = 1 + player:getMark("@ty__liehou")
      if #room:askForDiscard(player, n, n, true, self.name, true, ".", "#ty__liehou-discard:::"..n) < n then
        room:loseHp(player, 1, self.name)
      end
    end
  end,
}
lvkuanglvxiang:addSkill(shuhe)
lvkuanglvxiang:addSkill(ty__liehou)
Fk:loadTranslationTable{
  ["ty__lvkuanglvxiang"] = "吕旷吕翔",
  ["shuhe"] = "数合",
  [":shuhe"] = "出牌阶段限一次，你可以展示一张手牌，并获得场上与展示牌相同点数的牌。如果你没有因此获得牌，你需将展示牌交给一名其他角色，"..
  "然后〖列侯〗的额外摸牌数+1（至多为5）。",
  ["ty__liehou"] = "列侯",
  [":ty__liehou"] = "锁定技，摸牌阶段，你额外摸一张牌，然后选择一项：1.弃置等量的牌；2.失去1点体力。",
  ["#shuhe-choose"] = "数合：选择一名其他角色，将%arg交给其",
  ["@ty__liehou"] = "列侯",
  ["#ty__liehou-discard"] = "列侯：你需弃置%arg张牌，否则失去1点体力",
}

local chengui = General(extension, "chengui", "qun", 3)
local yingtu = fk.CreateTriggerSkill{
  name = "yingtu",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 then
      for _, move in ipairs(data) do
        if move.to ~= nil and move.toArea == Card.PlayerHand then
          local p = player.room:getPlayerById(move.to)
          if p.phase ~= Player.Draw and (p:getNextAlive() == player or player:getNextAlive() == p) and not p:isKongcheng() then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, move in ipairs(data) do
      if move.to ~= nil and move.toArea == Card.PlayerHand then
        local p = player.room:getPlayerById(move.to)
        if p.phase ~= Player.Draw and (p:getNextAlive() == player or player:getNextAlive() == p) and not p:isKongcheng() then
          table.insertIfNeed(targets, move.to)
        end
      end
    end
    if #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, "#yingtu-invoke::"..targets[1]) then
        self.cost_data = targets[1]
        return true
      end
    elseif #targets > 1 then
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#yingtu-invoke-multi", self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(self.cost_data)
    local lastplayer = (player:getNextAlive() == from)
    local card = room:askForCardChosen(player, from, "he", self.name)
    room:obtainCard(player.id, card, false, fk.ReasonPrey)
    local to = player:getNextAlive()
    if lastplayer then
      to = table.find(room.alive_players, function (p)
        return p:getNextAlive() == player
      end)
    end
    if to == nil or to == player then return false end
    local id = room:askForCard(player, 1, 1, true, self.name, false, ".", "#yingtu-choose::"..to.id)[1]
    room:obtainCard(to, id, false, fk.ReasonGive)
    local to_use = Fk:getCardById(id)
    if to_use.type == Card.TypeEquip and not to.dead and room:getCardOwner(id) == to and room:getCardArea(id) == Card.PlayerHand and
        not to:prohibitUse(to_use) then
      --FIXME: stupid 赠物 and 废除装备栏
      room:useCard({
        from = to.id,
        tos = {{to.id}},
        card = to_use,
      })
    end
  end,
}
local congshi = fk.CreateTriggerSkill{
  name = "congshi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return not target.dead and player:hasSkill(self.name) and data.card.type == Card.TypeEquip and table.every(player.room.alive_players, function(p)
      return #target.player_cards[Player.Equip] >= #p.player_cards[Player.Equip]
    end)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
chengui:addSkill(yingtu)
chengui:addSkill(congshi)
Fk:loadTranslationTable{
  ["chengui"] = "陈珪",
  ["yingtu"] = "营图",
  [":yingtu"] = "每回合限一次，当一名角色于其摸牌阶段外获得牌后，若其是你的上家或下家，你可以获得该角色的一张牌，然后交给你的下家或上家一张牌。若以此法给出的牌为装备牌，获得牌的角色使用之。",
  ["congshi"] = "从势",
  [":congshi"] = "锁定技，当一名角色使用一张装备牌结算结束后，若其装备区里的牌数为全场最多的，你摸一张牌。",
  ["#yingtu-invoke"] = "营图：你可以获得 %dest 的一张牌",
  ["#yingtu-invoke-multi"] = "营图：你可以获得上家或下家的一张牌",
  ["#yingtu-choose"] = "营图：选择一张牌交给 %dest，若为装备牌则其使用之",

  ["$yingtu1"] = "不过略施小计，聊戏莽夫耳。",
  ["$yingtu2"] = "栖虎狼之侧，安能不图存身？",
  ["$congshi1"] = "阁下奉天子以令诸侯，珪自当相从。",
  ["$congshi2"] = "将军率六师以伐不臣，珪何敢相抗？",
  ["~chengui"] = "终日戏虎，竟为虎所噬。",
}

local chenjiao = General(extension, "chenjiao", "wei", 3)
local xieshou = fk.CreateTriggerSkill{
  name = "xieshou",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not target.dead and player:distanceTo(target) <= 2 and player:getMaxCards() > 0 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xieshou-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
    local choices = {"xieshou_draw"}
    if target:isWounded() then
      table.insert(choices, 1, "recover")
    end
    local choice = room:askForChoice(target, choices, self.name, "#xieshou-choice:"..player.id)
    if choice == "recover" then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    else
      if not target.faceup then
        target:turnOver()
      end
      if target.chained then
        target:setChainState(false)
      end
      target:drawCards(2, self.name)
    end
  end,
}
local qingyan = fk.CreateTriggerSkill{
  name = "qingyan",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.firstTarget and data.card.color == Card.Black and data.from ~= player.id and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    if player:getHandcardNum() < math.min(player.hp, player.maxHp) then
      if player.room:askForSkillInvoke(player, self.name, nil, "#qingyan-invoke") then
        self.cost_data = {"draw"}
        return true
      end
    else
      local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#qingyan-card", true)
      if #card > 0 then
        self.cost_data = {"discard", card}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data[1] == "discard" then
      room:throwCard(self.cost_data[2], self.name, player, player)
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    else
      player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    end
  end,
}
local qizi = fk.CreateTriggerSkill{
  name = "qizi",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:distanceTo(target) > 2
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(self.name)
    player.room:notifySkillInvoked(player, self.name)
  end,
}
local qizi_prohibit = fk.CreateProhibitSkill{
  name = "#qizi_prohibit",
  frequency = Skill.Compulsory,
  prohibit_use = function(self, player, card)
    if player:hasSkill("qizi") and card.name == "peach" then
      return table.find(Fk:currentRoom().alive_players, function(p) return p.dying and player:distanceTo(p) > 2 end)
    end
  end,
}
qizi:addRelatedSkill(qizi_prohibit)
chenjiao:addSkill(xieshou)
chenjiao:addSkill(qingyan)
chenjiao:addSkill(qizi)
Fk:loadTranslationTable{
  ["chenjiao"] = "陈矫",
  ["xieshou"] = "协守",
  [":xieshou"] = "每回合限一次，一名角色受到伤害后，若你与其距离不大于2，你可以令你的手牌上限-1，然后其选择一项：1.回复1点体力；2.复原武将牌并摸两张牌。",
  ["qingyan"] = "清严",
  [":qingyan"] = "每回合限两次，当你成为其他角色使用黑色牌的目标后，若你的手牌数：小于体力值，你可将手牌摸至体力上限；"..
  "不小于体力值，你可以弃置一张手牌令手牌上限+1。",
  ["qizi"] = "弃子",
  [":qizi"] = "锁定技，其他角色处于濒死状态时，若你与其距离大于2，你不能对其使用【桃】。",
  ["#xieshou-invoke"] = "协守：你可以手牌上限-1，令 %dest 选择回复体力，或复原武将牌并摸牌",
  ["xieshou_draw"] = "复原武将牌并摸两张牌",
  ["#xieshou-choice"] = "协守：选择 %src 令你执行的一项",
  ["#qingyan-invoke"] = "清严：你可以将手牌摸至体力上限",
  ["#qingyan-card"] = "清严：你可以弃置一张手牌令手牌上限+1",
}

local qinlang = General(extension, "qinlang", "wei", 4)
local haochong = fk.CreateTriggerSkill{
  name = "haochong",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getHandcardNum() ~= player:getMaxCards()
  end,
  on_cost = function(self, event, target, player, data)
    local n = player:getHandcardNum() - player:getMaxCards()
    if n > 0 then
      if #player.room:askForDiscard(player, n, n, false, self.name, true, ".", "#haochong-discard:::"..n) then
        self.cost_data = n
        return true
      end
    else
      if player.room:askForSkillInvoke(player, self.name, nil, "#haochong-draw:::"..player:getMaxCards()) then
        self.cost_data = n
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data > 0 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    else
      player:drawCards(math.min(-self.cost_data, 5), self.name)
      if player:getMaxCards() > 0 then  --不允许减为负数
        room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
      end
    end
  end,
}
local jinjin = fk.CreateTriggerSkill{
  name = "jinjin",
  anim_type = "drawcard",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMaxCards() ~= player.hp and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jinjin-invoke::"..data.from.id..":"..player:getMaxCards())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.abs(player:getMaxCards() - player.hp)
    room:setPlayerMark(player, MarkEnum.AddMaxCards, 0)
    room:setPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 0)
    room:setPlayerMark(player, MarkEnum.MinusMaxCards, 0)
    room:setPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 0)
    if data.from and not data.from.dead then
      local x = #room:askForDiscard(data.from, 1, n, true, self.name, false, ".", "#jinjin-discard:"..player.id.."::"..n)
      if x < n then
        player:drawCards(n - x, self.name)
      end
    end
  end,
}
qinlang:addSkill(haochong)
qinlang:addSkill(jinjin)
Fk:loadTranslationTable{
  ["qinlang"] = "秦朗",
  ["haochong"] = "昊宠",
  [":haochong"] = "当你使用一张牌后，你可以将手牌调整至手牌上限（最多摸五张），然后若你以此法：获得牌，你的手牌上限-1；失去牌，你的手牌上限+1。",
  ["jinjin"] = "矜谨",
  [":jinjin"] = "每回合限一次，当你造成或受到伤害后，你可以将你的手牌上限重置为当前体力值。"..
  "若如此做，伤害来源可以弃置至多X张牌（X为你因此变化的手牌上限数且至少为1），然后其每少弃置一张，你便摸一张牌。",
  ["#haochong-discard"] = "昊宠：你可以将手牌弃至手牌上限（弃置%arg张），然后手牌上限+1",
  ["#haochong-draw"] = "昊宠：你可以将手牌摸至手牌上限（当前手牌上限%arg，最多摸五张），然后手牌上限-1",
  ["#jinjin-invoke"] = "矜谨：你可将手牌上限（当前为%arg）重置为体力值，令 %dest 弃至多等量的牌",
  ["#jinjin-discard"] = "矜谨：弃置1~%arg张牌，每少弃置一张 %src 便摸一张牌",

  ["$haochong1"] = "幸得义父所重，必效死奉曹。",
  ["$haochong2"] = "朗螟蛉之子，幸隆曹氏厚恩。",
  ["$jinjin1"] = "螟蛉终非麒麟，不可气盛自矜。",
  ["$jinjin2"] = "我姓非曹，可敬人，不可欺人。",
  ["~qinlang"] = "二姓之人，死无其所。",
}

local tangzi = General(extension, "ty__tangzi", "wei", 4)
tangzi.subkingdom = "wu"
local ty__xingzhao = fk.CreateTriggerSkill{
  name = "ty__xingzhao",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.HpChanged, fk.MaxHpChanged, fk.CardUsing, fk.EventPhaseChanging, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      local n = #table.filter(player.room.alive_players, function(p) return p:isWounded() end)
      if event == fk.HpChanged or event == fk.MaxHpChanged then
        return (player:hasSkill("xunxun", true) and n == 0) or (not player:hasSkill("xunxun", true) and n > 0)
      elseif event == fk.CardUsing then
        return target == player and data.card.type == Card.TypeEquip and n > 1
      elseif event == fk.EventPhaseChanging then
        return target == player and (data.to == Player.Judge or data.to == Player.Discard) and n > 2
      elseif event == fk.DamageCaused then
        return target == player and data.card and not data.chain and (n == 0 or n > 3)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.HpChanged or event == fk.MaxHpChanged then
      if player:hasSkill("xunxun", true) then
        room:handleAddLoseSkills(player, "-xunxun", self.name, true, false)
      else
        room:handleAddLoseSkills(player, "xunxun", self.name, true, false)
      end
    elseif event == fk.CardUsing then
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    elseif event == fk.EventPhaseChanging then
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "defensive")
      return true
    elseif event == fk.DamageCaused then
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "offensive")
      data.damage = data.damage + 1
    end
  end,
}
tangzi:addSkill(ty__xingzhao)
Fk:loadTranslationTable{
  ["ty__tangzi"] = "唐咨",
  ["ty__xingzhao"] = "兴棹",
  [":ty__xingzhao"] = "锁定技，场上受伤的角色为1个或以上，你拥有技能〖恂恂〗；2个或以上，你使用装备牌时摸一张牌；"..
  "3个或以上，你跳过判定和弃牌阶段；0个、4个或以上，你使用牌对目标角色造成的伤害+1。",
}

--绕庭之鸦：黄皓 孙资刘放 岑昏
Fk:loadTranslationTable{
  ["ty__huanghao"] = "黄皓",
  ["ty__qinqing"] = "寝情",
  [":ty__qinqing"] = "结束阶段，你可以弃置攻击范围内含有一号位的一名其他角色的一张牌。然后若其手牌比一号位多，你摸一张牌。",
  ["ty__huisheng"] = "贿生",
  [":ty__huisheng"] = "当你受到其他角色对你造成的伤害时，你可以令其观看你任意张牌并令其选择一项：1.获得其中一张牌，防止此伤害，"..
  "然后你不能再对其发动〖贿生〗；2.弃置等量的牌。",
  ["cunwei"] = "存畏",
  [":cunwei"] = "锁定技，当你成为锦囊牌的目标后，若你：是此牌唯一目标，你摸一张牌；不是此牌唯一目标，你弃置一张牌。",
}

local sunziliufang = General(extension, "ty__sunziliufang", "wei", 3)
local qinshen = fk.CreateTriggerSkill{
  name = "qinshen",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Discard
  end,
  on_cost = function(self, event, target, player, data)
    self.cost_data = 0
    for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
      if player:getMark("qinshen_"..suit.."-turn") == 0 then
        self.cost_data = self.cost_data + 1
      end
    end
    return self.cost_data > 0 and player.room:askForSkillInvoke(player, self.name, nil, "#qinshen-invoke:::"..self.cost_data)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.cost_data, self.name)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase < Player.Finish
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          player.room:addPlayerMark(player, "qinshen_"..Fk:getCardById(info.cardId):getSuitString().."-turn", 1)
        end
      end
    end
  end,
}
local weidang_active = fk.CreateActiveSkill{
  name = "#weidang_active",
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected, targets)
    if #selected == 0 then
      local n = 0
      for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
        if Self:getMark("weidang_"..suit.."-turn") == 0 then
          n = n + 1
        end
      end
      return #Fk:translate(Fk:getCardById(to_select).trueName) / 3 == n
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      fromArea = Player.Hand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      drawPilePosition = -1,
    })
    local cards = {}
    for i = 1, #room.draw_pile, 1 do
      local card = Fk:getCardById(room.draw_pile[i])
      if #Fk:translate(card.trueName) == #Fk:translate(Fk:getCardById(effect.cards[1]).trueName) then
        table.insertIfNeed(cards, room.draw_pile[i])
      end
    end
    local id = table.random(cards)
    local card = Fk:getCardById(id)
    room:moveCards({
      ids = {id},
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    })
    if card.trueName ~= "jink" and card.trueName ~= "nullification" then
      local use = room:askForUseCard(player, card.name, ".|.|.|.|.|.|"..id, "#weidang-use:::"..card:toLogString(), false)
      if use then
        room:useCard(use)
      end
    end
  end,
}
local weidang = fk.CreateTriggerSkill{
  name = "weidang",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local n = 0
    for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
      if player:getMark("weidang_"..suit.."-turn") == 0 then
        n = n + 1
      end
    end
    if n > 0 then
      player.room:askForUseActiveSkill(player, "#weidang_active", "#weidang-invoke:::"..n, true)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.room.current
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          player.room:addPlayerMark(player, "weidang_"..Fk:getCardById(info.cardId):getSuitString().."-turn", 1)
        end
      end
    end
  end,
}
sunziliufang:addSkill(qinshen)
sunziliufang:addSkill(weidang)
Fk:addSkill(weidang_active)
Fk:loadTranslationTable{
  ["ty__sunziliufang"] = "孙资刘放",
  ["qinshen"] = "勤慎",
  [":qinshen"] = "弃牌阶段结束时，你可摸X张牌（X为本回合没有进入过弃牌堆的花色数量）。",
  ["weidang"] = "伪谠",
  [":weidang"] = "其他角色的结束阶段，你可以将一张字数为X的牌置于牌堆底，然后获得牌堆中一张字数为X的牌（X为本回合没有进入过弃牌堆的花色数量），能使用则使用之。",
  ["#qinshen-invoke"] = "勤慎：你可以摸%arg张牌",
  ["#weidang_active"] = "伪谠",
  ["#weidang-invoke"] = "伪谠：你可以将一张牌名字数为%arg的牌置于牌堆底，然后从牌堆获得一张字数相同的牌并使用之",
  ["#weidang-use"] = "伪谠：请使用%arg",
}

local cenhun = General(extension, "ty__cenhun", "wu", 4)
cenhun:addSkill("jishe")
cenhun:addSkill("lianhuo")
Fk:loadTranslationTable{
  ["ty__cenhun"] = "岑昏",
}

--代汉涂高：马日磾 张勋 雷薄 桥蕤
Fk:loadTranslationTable{
  ["ty__mamidi"] = "马日磾",
  ["bingjie"] = "秉节",
  [":bingjie"] = "出牌阶段开始时，你可以减1点体力上限，然后当你本回合使用【杀】或普通锦囊牌指定目标后，除你以外的目标角色各弃置一张牌，"..
  "若弃置的牌与你使用的牌颜色相同，其无法响应此牌。",
  ["zhengding"] = "正订",
  [":zhengding"] = "锁定技，你的回合外，当你使用或打出牌响应其他角色使用的牌时，若你使用或打出的牌与其使用的牌颜色相同，你加1点体力上限，回复1点体力。",
}

local zhangxun = General(extension, "zhangxun", "qun", 4)
local suizheng = fk.CreateTriggerSkill{
  name = "suizheng",
  anim_type = "support",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish
      else
        return target:getMark("@@suizheng-turn") > 0 and target.phase == Player.Play and player.tag[self.name] and #player.tag[self.name] > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets, prompt
    if player.phase == Player.Finish then
      targets = table.map(room:getAlivePlayers(), function (p) return p.id end)
      prompt = "#suizheng-choose"
    else
      room:setPlayerMark(player, "@@suizheng-turn", 1)
      targets = table.filter(player.tag[self.name], function(id) return not room:getPlayerById(id).dead end)
      player.tag[self.name] = {}
      if #targets == 0 then return end
      prompt = "#suizheng-slash"
    end
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if player.phase == Player.Finish then
      room:setPlayerMark(to, "@@suizheng", 1)
    else
      room:useVirtualCard("slash", nil, player, to, self.name, true)
    end
  end,

  refresh_events = {fk.EventPhaseStart, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return target == player and player:getMark("@@suizheng") > 0 and player.phase == Player.Play
    else
      return player:hasSkill(self.name, true) and data.from and target:getMark("@@suizheng-turn") > 0 and data.to ~= player and not data.to.dead
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      room:setPlayerMark(player, "@@suizheng", 0)
      room:setPlayerMark(player, "@@suizheng-turn", 1)
    else
      player.tag[self.name] = player.tag[self.name] or {}
      table.insert(player.tag[self.name], data.to.id)
    end
  end,
}
local suizheng_targetmod = fk.CreateTargetModSkill{
  name = "#suizheng_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@suizheng-turn") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
  distance_limit_func =  function(self, player, skill)
    if skill.trueName == "slash_skill" and player:getMark("@@suizheng-turn") > 0 then
      return 999
    end
  end,
}
suizheng:addRelatedSkill(suizheng_targetmod)
zhangxun:addSkill(suizheng)
Fk:loadTranslationTable{
  ["zhangxun"] = "张勋",
  ["suizheng"] = "随征",
  [":suizheng"] = "结束阶段，你可以选择一名角色，该角色下个回合的出牌阶段使用【杀】无距离限制且可以多使用一张【杀】。"..
  "然后其出牌阶段结束时，你可以视为对其本阶段造成过伤害的一名其他角色使用一张【杀】。",
  ["@@suizheng"] = "随征",
  ["@@suizheng-turn"] = "随征",
  ["#suizheng-choose"] = "随征：令一名角色下回合出牌阶段使用【杀】无距离限制且次数+1",
  ["#suizheng-slash"] = "随征：你可以视为对其中一名角色使用【杀】",
}

Fk:loadTranslationTable{
  ["leibo"] = "雷薄",
  ["silve"] = "私掠",
  [":silve"] = "游戏开始时，你选择一名其他角色为“私掠”角色。<br>"..
  "“私掠”角色造成伤害后，你可以获得受伤角色一张牌（每回合每名角色限一次）。<br>"..
  "“私掠”角色受到伤害后，你需对伤害来源使用一张【杀】，否则你弃置一张手牌。",
  ["shuaijie"] = "衰劫",
  [":shuaijie"] = "限定技，出牌阶段，若你体力值与装备区里的牌均大于“私掠”角色或“私掠”角色已死亡，你可以减1点体力上限，然后选择一项：<br>"..
  "1.获得“私掠”角色至多3张牌；<br>2.从牌堆获得三张类型不同的牌。<br>然后“私掠”角色改为你。",
}

Fk:loadTranslationTable{
  ["ty__qiaorui"] = "桥蕤",
  ["aishou"] = "隘守",
  [":aishou"] = "结束阶段，你可以摸X张牌（X为你的体力上限），这些牌标记为“隘”。当你于回合外失去最后一张“隘”时，你减1点体力上限。<be>"..
  "准备阶段，弃置你手牌中的所有“隘”，若弃置的“隘”数量大于你的体力值，你加1点体力上限。",
  ["saowei"] = "扫围",
  [":saowei"] = "当一名其他角色使用【杀】结算结束后，若目标角色不为你且目标角色在你的攻击范围内，你可以将一张“隘”当【杀】对该目标角色使用。",
}

return extension
