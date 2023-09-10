local qixi_desc = [==[
# 新月杀·七夕模式简介

为了顺应七夕节而设计的活动场模式。由4~8人进行游玩。

## 游戏流程

通过随机方式决出一号位。游戏不分发身份，而是直接进入选将环节。

由于女性武将数量稍有不足，本模式最多只可启用8个选将框，且无法保证选将框武将数量。

系统选择一半的玩家只抽得到男性武将，另外一半玩家只抽得到女性武将。
如果有奇数个玩家的话那么多出的一名玩家选将框性别随机。

选将完成后，所有角色获得模式专属技能“结伴”。然后系统还会对每个角色都随机抽一个技能发放。

> **结伴**：出牌阶段限一次，若你没有伴侣，你可以将一张
【桃】或者防具交给一名未结伴的异性角色并将其设为追求目标；
然后若其的追求目标是你，双方移除追求目标并结为伴侣。
伴侣确定后就无法更改，即使死亡也无法将二人分开。

当无伴侣的角色造成致命的伤害时，若场上已经没有可以被他追求的角色了，则此伤害+1，
否则防止此伤害。

## 胜负与奖惩

获胜条件为击杀除了自己和伴侣之外的所有其他角色。此外有以下几点奖惩规则：

- 击杀伴侣的角色弃置所有牌并失去一点体力。
- 击杀其他角色的话，自己和伴侣各摸1张牌，伴侣已阵亡则摸2张，从未有过伴侣则摸3张。
- 当伴侣阵亡后，剩余的另一方仍视为结伴状态，且胜负条件不变。

因为没有伴侣就无法击杀其他角色，进而无法获胜，所以尽可能先找好伴侣吧。

（然而春哥除外，唯有情字最伤人啊，把你们都杀了.jpg）

## 特殊奖励

结伴双方失去模式赋予的技能和“结伴”，然后根据男方的势力获得如下技能：

- 魏：【舍身》当伴侣不以此法受到伤害时，你可以将伤害转移给自己。
- 蜀：【共斗》每回合限一次，当伴侣使用的非转化【杀】结算完成后，你可以视为对相同的目标使用一张【杀】。
- 吴：【连枝》使用装备牌后可以令伴侣摸一张牌。
- 群：【泣别》伴侣在求桃结束即将死亡时，你可以将所有体力值和武将牌上的技能交给伴侣（伴侣至少会回复至1点体力），然后阵亡。
- 他：无伴侣技，然而也不失去一开始获得的那个随机技能。

当结伴双方为以下已记录的伴侣时，拥有女伴者获得英姿效果，拥有男伴者获得闭月效果，
同时游戏内显示的“伴侣”标注改为彩色字体。

注意，可以是任何同名武将或者相应名字的神势力武将。

魏晋：

- 曹操 & 除sp夏侯氏外所有女性武将
- 曹丕 & 甄姬/郭照/段巧笑/薛灵芸
- 司马懿 & 张春华
- 司马昭 & 王元姬
- 司马师 & 夏侯徽/羊徽瑜
- 庞德 & 李采薇
- 甲虫 & 李婉/郭槐
- 王浑 & 钟琰
- 杜预 & 宣公主
- 钟繇 & 张昌蒲

蜀：

- 刘备 & 甘夫人/糜夫人/孙尚香/张楚/吴苋
- 张飞 & 夏侯氏
- 关羽 & 胡金定（暂无）
- 孟获 & 祝融
- 刘禅 & 星彩/张瑾云
- 诸葛亮/卧龙 & 黄月英
- 黄忠 & 刘赪
- 马超 & 杨婉
- 赵云 & 马云禄/周夷 （绷）
- 关索 & 鲍三娘/王桃/王悦

吴：

- 孙权 & 步练师/袁姬/潘淑/谢灵毓/赵嫣
- 周瑜 & 小乔
- 孙策 & 大乔
- 孙坚 & 吴国太
- 孙皓 & 滕芳兰/张媱/张嫙 （太阴间了）
- 陆逊 & 孙茹
- 孙登 & 芮姬/周妃（孙登暂无）
- 张奋 & 孙翎鸾 （绝望）
- 滕胤 & 滕公主
- 孙翊 & 徐氏
- 全琮 & 孙鲁班

群：

- 吕布 & 严夫人/貂蝉
- 董卓 & 貂蝉 （极其存疑）
- 刘协 & 伏皇后/曹节/曹宪曹华/曹华/董贵人
- 刘宏 & 何太后/王荣
- 刘辩 & 唐姬
- 刘表 & 蔡夫人
- 张济 & 邹氏
- 袁术 & 冯方女
- 牛辅 & 董翓

其他：

- 女士兵 & 男士兵
- 张角 & 黄巾雷使
- 刘焉 & 卢氏

]==]

local couples = {
  -- wei
  caopi = { "zhenji", "guozhao", "duanqiaoxiao", "xuelingyun" },
  simayi = "zhangchunhua",
  simazhao = "wangyuanji",
  simashi = { "xiahouhui", "yanghuiyu" },
  pangde = "licaiwei",
  jiachong = { "liwan", "guohuaij" },
  wanghun = "zhongyan",
  duyu = "xuangongzhu",
  zhongyao = "zhangchangpu",

  -- shu
  liubei = { "ganfuren", "mifuren", "sunshangxiang", "zhangchu", "wuxian" },
  zhangfei = "xiahoushi",
  guanyu = "hujinding",
  menghuo = "zhurong",
  liushan = { "xingcai", "zhangjinyun" },
  zhugeliang = "huangyueying",
  wolong = "huangyueying",
  huangzhong = "liucheng",
  machao = "yangwan",
  zhaoyun = {"mayunlu", "zhouyi"}, -- 绷
  guansuo = { "baosanniang", "wangtao", "wangyues" },

  -- wu
  sunquan = { "bulianshi", "yuanji", "panshu", "xielingyu", "zhaoyanw" },
  zhouyu = "xiaoqiao",
  sunce = "daqiao",
  sunjian = "wuguotai",
  sunhao = { "tengfanglan", "zhangxuan", "zhangyao" },  -- 太哈人了
  luxun = "sunru",
  sundeng = { "ruiji", "zhoufei" },
  zhangfen = "sunlingluan",
  tengyin = "tenggongzhu",
  sunyi = "xushi",
  quancong = "sunluban",

  -- qun
  lvbu = { "diaochan", "yanfuren" },
  dongzhuo = "diaochan",  -- ???
  liuxie = { "fuhuanghou", "caojie", "caoxiancaohua", "caohua", "dongguiren" },
  liubiao = "caifuren",
  liuhong = { "hetaihou", "wangrong" },
  liubian = "tangji",
  zhangji = "zoushi",
  yuanshu = "fengfangnv",
  niufu = "dongxie",

  -- misc
  blank_shibing = "blank_nvshibing",
  zhangjiao = "huangjinleishi",
  liuyan = "lushi",
}

---@param from ServerPlayer
---@param to ServerPlayer
local function isCoupleGeneral(from, to)
  local m, f = from, to
  if from.gender == General.Female then
    m, f = to, from
  end
  local g1 = Fk.generals[m.general].trueName
  local g2 = Fk.generals[f.general].trueName
  if g1:startsWith("god") then g1 = g1:sub(4) end
  if g2:startsWith("god") then g2 = g2:sub(4) end
  if g1 == "caocao" and f.general ~= "sp__xiahoushi" then return true end
  local t = couples[g1] or ""
  return t == g2 or (type(t) == "table" and table.contains(t, g2))
end

---@param from ServerPlayer
---@param to ServerPlayer
local function isCouple(from, to)
  return from:getMark("qixi_couple") == to.id and to:getMark("qixi_couple") == from.id
end

---@param player ServerPlayer
local function attachRandomSkill(player)
  local generals = Fk:getGeneralsRandomly(3, nil, { player.general })
  for _, g in ipairs(generals) do
    for _, s in ipairs(g:getSkillNameList(false)) do
      if not player:hasSkill(s) then
        player.tag['qixi_rand_skill'] = s
        player.room:handleAddLoseSkills(player, s)
        return
      end
    end
  end
end

local sheshen = fk.CreateTriggerSkill{
  name = "qixi_sheshen",
  anim_type = "defensive",
  events = { fk.DamageInflicted },
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.skillName ~= self.name and isCouple(target, player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:damage{
      from = data.from,
      to = player,
      damage = data.damage,
      damageType = data.type,
      skillName = self.name,
    }
    return true
  end,
}
local gongdou = fk.CreateTriggerSkill{
  name = "qixi_gongdou",
  anim_type = "offensive",
  events = { fk.CardUseFinished },
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and isCouple(target, player) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      data.card.trueName == 'slash' and not data.card:isVirtual()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard('slash')
    card.skillName = self.name
    room:useCard{
      from = player.id,
      card = card,
      tos = data.tos,
    }
  end,
}
local lianzhi = fk.CreateTriggerSkill{
  name = 'qixi_lianzhi',
  anim_type = 'drawcard',
  events = { fk.CardUsing },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.type == Card.TypeEquip and
      player.room:getPlayerById(player:getMark('qixi_couple')) ~= nil
  end,
  on_use = function(self, event, target, player, data)
    player.room:getPlayerById(player:getMark('qixi_couple')):drawCards(1, self.name)
  end,
}
local qibie = fk.CreateTriggerSkill{
  name = 'qixi_qibie',
  anim_type = 'big',
  events = { fk.AskForPeachesDone },
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and isCouple(target, player) and
      target.hp < 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = Fk.generals[player.general]:getSkillNameList()
    table.insert(skills, '-qixi_qibie')
    room:handleAddLoseSkills(target, table.concat(skills, '|'))
    room:recover {
      who = target,
      num = math.max(player.hp, 1 - target.hp),
      skillName = self.name,
    }

    local skills2 = table.map(player:getAllSkills(), function(s)
      return "-" .. s.name
    end)
    room:handleAddLoseSkills(player, table.concat(skills2, '|'))
    room:loseHp(player, player.hp, self.name)
  end,
}

Fk:addSkill(sheshen)
Fk:addSkill(gongdou)
Fk:addSkill(lianzhi)
Fk:addSkill(qibie)

Fk:loadTranslationTable{
  ['qixi_sheshen'] = '舍身',
  [':qixi_sheshen'] = '伴侣技，当伴侣不以此法受到伤害时，你可以将伤害转移给自己。',
  ['qixi_gongdou'] = '共斗',
  [':qixi_gongdou'] = '伴侣技，一回合一次，当伴侣使用的非转化杀结算结束后，你可以视为对相同的目标使用了一张【杀】。',
  ['qixi_lianzhi'] = '连枝',
  [':qixi_lianzhi'] = '伴侣技，你使用装备牌时，可以令伴侣摸一张牌。',
  ['qixi_qibie'] = '泣别',
  [':qixi_qibie'] = '伴侣技，当伴侣求桃结束即将阵亡时，你可以令其失去“泣别”，获得你武将牌上所有的技能并回复X点体力' ..
    '（X为你的体力值且至少能令其回复至1点体力），然后你失去所有技能和所有体力。',
}

---@param from ServerPlayer
---@param to ServerPlayer
local function addCoupleSkill(from, to)
  local room = from.room
  local k = from.gender == General.Male and from.kingdom or to.kingdom
  if k == "wei" then
    room:handleAddLoseSkills(from, "qixi_sheshen|-qixi_jieban|-" .. from.tag['qixi_rand_skill'])
    room:handleAddLoseSkills(to, "qixi_sheshen|-qixi_jieban|-" .. to.tag['qixi_rand_skill'])
  elseif k == "shu" then
    room:handleAddLoseSkills(from, "qixi_gongdou|-qixi_jieban|-" .. from.tag['qixi_rand_skill'])
    room:handleAddLoseSkills(to, "qixi_gongdou|-qixi_jieban|-" .. to.tag['qixi_rand_skill'])
  elseif k == "wu" then
    room:handleAddLoseSkills(from, "qixi_lianzhi|-qixi_jieban|-" .. from.tag['qixi_rand_skill'])
    room:handleAddLoseSkills(to, "qixi_lianzhi|-qixi_jieban|-" .. to.tag['qixi_rand_skill'])
  elseif k == "qun" then
    room:handleAddLoseSkills(from, "qixi_qibie|-qixi_jieban|-" .. from.tag['qixi_rand_skill'])
    room:handleAddLoseSkills(to, "qixi_qibie|-qixi_jieban|-" .. to.tag['qixi_rand_skill'])
  else
    room:handleAddLoseSkills(from, "-qixi_jieban")
    room:handleAddLoseSkills(to, "-qixi_jieban")
  end
end

---@param from Player
---@param to Player
local function canPayCourtTo(from, to)
  local room = Fk:currentRoom()
  if from:getMark("qixi_couple") ~= 0 then return false end
  if to:getMark("qixi_couple") ~= 0 then return false end
  if from:getMark("@!qixi_female") == to:getMark("@!qixi_female") then return false end

  return true
end

local qixi_get_logic = function()
  ----@class qixi_logic : GameLogic
  local qixi_logic = GameLogic:subclass("qixi_logic")

  function qixi_logic:assignRoles()
    local room = self.room
    local n = #room.players
    local half = n // 2
    local t = {}
    for _ = 1, half do
      table.insert(t, "@!qixi_male")
      table.insert(t, "@!qixi_female")
    end
    if #t < n then
      table.insert(t, table.random{ "@!qixi_male", "@!qixi_female" })
    end
    table.shuffle(t)

    for i, p in ipairs(room.players) do
      room:addPlayerMark(p, t[i])
      p.role = "hidden"
      p.role_shown = true
      room:broadcastProperty(p, "role")
    end

    -- for adjustSeats
    room.players[1].role = "lord"
  end

  function qixi_logic:chooseGenerals()
    local room = self.room

    local all_generals = Fk:getAllGenerals({ Fk.generals["mouxusheng"], Fk.generals["blank_shibing"], Fk.generals["blank_nvshibing"] })

    local generalNum = math.min(room.settings.generalNum, 8)
    local minGeneralNum = (#room.players * generalNum) // 2
    local male_generals = {}
    local female_generals = {}
    table.shuffle(all_generals)
    for _, g in ipairs(all_generals) do
      local t
      if g.gender == General.Female then
        t = female_generals
      else
        t = male_generals
      end

      if #t >= minGeneralNum then
        if #female_generals >= minGeneralNum and #male_generals >= minGeneralNum then
          break
        end
        goto CONT  -- continue
      end

      if (not g.hidden and not g.total_hidden) and
        not table.find(t, function(_g)
        return _g.trueName == g.trueName
      end) then
        table.insert(t, g)
      end

      ::CONT::
    end

    if #male_generals < minGeneralNum or #female_generals < minGeneralNum then
      local half = math.ceil(#room.players / 2)
      local n = math.min(#male_generals, #female_generals)
      generalNum = n // half
    end

    local n = 1
    local lord = room:getLord()
    room.current = lord
    lord.role = "hidden"

    local nonlord = room.players
    for _, p in ipairs(nonlord) do
      local arg = {}
      local t
      if p:getMark("@!qixi_female") > 0 then
        t = female_generals
      else
        t = male_generals
      end
      for i = 1, generalNum do
        table.insert(arg, table.remove(t).name)
      end
      p.request_data = json.encode({ arg, n })
      p.default_reply = table.random(arg, n)
    end

    room:notifyMoveFocus(nonlord, "AskForGeneral")
    room:doBroadcastRequest("AskForGeneral", nonlord)

    for _, p in ipairs(nonlord) do
      if p.general == "" and p.reply_ready then
        local generals = json.decode(p.client_reply)
        local general = generals[1]
        local deputy = generals[2]
        room:setPlayerGeneral(p, general, true, true)
        room:setDeputyGeneral(p, deputy)
      else
        room:setPlayerGeneral(p, p.default_reply[1], true, true)
        room:setDeputyGeneral(p, p.default_reply[2])
      end
      p.default_reply = ""
    end

    room:askForChooseKingdom(nonlord)
  end

  function qixi_logic:attachSkillToPlayers()
    GameLogic.attachSkillToPlayers(self)
    local room = self.room
    room:setTag("SkipNormalDeathProcess", true)
    for _, p in ipairs(room.players) do
      room:handleAddLoseSkills(p, 'qixi_jieban')
      attachRandomSkill(p)
    end
  end

  return qixi_logic
end

local qixi_jieban = fk.CreateActiveSkill{
  name = "qixi_jieban",
  anim_type = "support",
  can_use = function (self, player, card)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 then return false end
    if player:getMark("qixi_couple") ~= 0 then return false end
    --[[
    local pid = player:getMark("qixi_pay_court")
    local p = Fk:currentRoom():getPlayerById(pid)
    return not p or p.dead or p:getMark("qixi_couple") ~= 0
    --]]
    return true
  end,
  card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected)
    if #selected ~= 0 then return end
    local c = Fk:getCardById(to_select)
    return c.trueName == 'peach' or c.sub_type == Card.SubtypeArmor
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and canPayCourtTo(Self, Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function (self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    room:obtainCard(to, effect.cards[1], true, fk.ReasonGive)

    room:setPlayerMark(from, "qixi_pay_court", to.id)
    room:setPlayerMark(from, "@qixi_pay_court", to.general)
    if to:getMark('qixi_pay_court') == from.id then
      room:setPlayerMark(from, "qixi_pay_court", 0)
      room:setPlayerMark(from, "@qixi_pay_court", 0)
      room:setPlayerMark(to, "qixi_pay_court", 0)
      room:setPlayerMark(to, "@qixi_pay_court", 0)

      room:setPlayerMark(from, "qixi_couple", to.id)
      room:setPlayerMark(to, "qixi_couple", from.id)
      addCoupleSkill(from, to)
      local couple = isCoupleGeneral(from, to)
      if couple then
        room:setPlayerMark(from, to.gender == General.Female and "@qixi_couple_pink" or "@qixi_couple_blue", to.general)
        room:setPlayerMark(to, from.gender == General.Female and "@qixi_couple_pink" or "@qixi_couple_blue", from.general)
      else
        room:setPlayerMark(from, "@qixi_couple", to.general)
        room:setPlayerMark(to, "@qixi_couple", from.general)
      end
    end
  end
}
Fk:addSkill(qixi_jieban)

---@param killer ServerPlayer
---@param victim ServerPlayer
local function rewardAndPunish(killer, victim)
  if killer.dead then return end
  local room = killer.room
  local c = killer:getMark('qixi_couple')
  if victim.id == c then
    killer:throwAllCards("he")
    room:loseHp(killer, 1, '#qixi_rule')
  else
    local couple = room:getPlayerById(c)
    if couple then
      if not couple.dead then
        killer:drawCards(1, "#qixi_rule")
        couple:drawCards(1, "#qixi_rule")
      else
        killer:drawCards(2, "#qixi_rule")
      end
    else
      killer:drawCards(3, "#qixi_rule")
    end
  end
end

local qixi_rule = fk.CreateTriggerSkill{
  name = "#qixi_rule",
  priority = 0.001,
  events = {
    fk.GameOverJudge, fk.BuryVictim, fk.DamageCaused,
    fk.DrawNCards, fk.EventPhaseStart,
  },
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return false end
    if event == fk.DamageCaused then
      return player:getMark('qixi_couple') == 0 and data.damage >= data.to.hp
    elseif event == fk.DrawNCards then
      return player:getMark('@qixi_couple_pink') ~= 0
    elseif event == fk.EventPhaseStart then
      return player.phase == Player.Finish and player:getMark('@qixi_couple_blue') ~= 0
    end
    return true
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameOverJudge then
      room:setTag("SkipGameRule", true)
      local winner = Fk.game_modes[room.settings.gameMode]:getWinner(player)
      if winner ~= "" then
        local alive = table.filter(room.alive_players, function(p)
          return not p.surrendered
        end)
        local p = alive[1]
        room:setPlayerProperty(p, "role", "renegade")
        local c = room:getPlayerById(p:getMark("qixi_couple"))
        if c then
          room:setPlayerProperty(c, "role", "renegade")
        end

        room:gameOver(winner)
        return true
      end
    elseif event == fk.BuryVictim then
      local damage = data.damage
      if damage and damage.from then
        local killer = damage.from
        rewardAndPunish(killer, player);
      end
    elseif event == fk.DamageCaused then
      if table.find(room:getOtherPlayers(player), function(p)
        return canPayCourtTo(player, p)
      end) then

        return true
      else
        data.damage = data.damage + 1
      end
    elseif event == fk.DrawNCards then
      data.n = data.n + 1
    elseif event == fk.EventPhaseStart then
      player:drawCards(1, self.name)
    end
  end,
}
Fk:addSkill(qixi_rule)

local qixi_mode = fk.CreateGameMode{
  name = "qixi_mode",
  minPlayer = 4,
  maxPlayer = 8,
  logic = qixi_get_logic,
  rule = qixi_rule,
  winner_getter = function(self, victim)
    local room = victim.room
    local alive = table.filter(room.alive_players, function(p)
      return not p.surrendered
    end)
    if #alive > 2 then return "" end
    if #alive == 1 then
      return "renegade"
    else
      if alive[1]:getMark("qixi_couple") == alive[2].id then
        return "renegade"
      else
        return ""
      end
    end
  end,
}

Fk:loadTranslationTable{
  ['qixi_mode'] = '七夕模式',
  [':qixi_mode'] = qixi_desc,
  ['qixi_jieban'] = '结伴',
  [':qixi_jieban'] = '出牌阶段限一次，若你没有伴侣，你可以将一张' ..
    '【桃】或者防具牌交给一名未结伴的异性角色并将其设为追求目标；' ..
    '然后若其的追求目标是你，双方移除追求目标并结为伴侣。' ..
    '<br/>伴侣确定后就无法更改，即使死亡也无法将二人分开。',
  ['@qixi_pay_court'] = '追求',
  ['@qixi_couple'] = '伴侣',
  ['@qixi_couple_blue'] = '<font color="#87CEFA">伴侣</font>',
  ['@qixi_couple_pink'] = '<font color="#FFB6C1">伴侣</font>',
}

return qixi_mode
