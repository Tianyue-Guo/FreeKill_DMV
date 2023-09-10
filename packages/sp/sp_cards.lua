-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package("sp_cards", Package.CardPack)
extension.extensionName = "sp"

Fk:loadTranslationTable{
  ["sp_cards"] = "SP卡牌",
}

local yanxiao_trick = fk.CreateDelayedTrickCard{
  name = "&yanxiao_trick",
}
extension:addCard(yanxiao_trick)

Fk:loadTranslationTable{
  ["yanxiao_trick"] = "言笑",
  [":yanxiao_trick"] = "这张牌视为延时锦囊<br/><b>效果：</b>判定区内有“言笑”牌的角色判定阶段开始时，获得其判定区里的所有牌。",
}

return extension
