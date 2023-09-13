-- SPDX-License-Identifier: GPL-3.0-or-later

local description = [[
  # 应变模式简介

  ---

  ## 喵喵喵
]]
--什么都没有！
local variation = fk.CreateGameMode{
  name = "variation",
  minPlayer = 2,
  maxPlayer = 8,
  whitelist = {"variation"},
  blacklist = {"standard_cards"},
}

Fk:loadTranslationTable{
  ["variation"] = "应变测试版",
  [":variation"] = description,
}

return variation
