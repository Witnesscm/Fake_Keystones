local _, ns = ...
local L = ns.L

local locale = GetLocale()
if locale == "zhCN" or locale == "zhTW" then
	L["Keystone Link: "] = "钥石链接："
	L["Fake AngryKeystones"] = "启用伪装"
	L["It will replace AngryKeystones and send keystone info to your party automatically."] = "伪装AngryKeystones自动发送钥石信息"
	L["Level"] = "钥石等级"
	L["Affix"] = "词缀"
	L["Print"] = "打印"
	L["Print keystone link and send keystone info."] = "打印钥石链接到聊天栏, 并发送AngryKeystones信息"
	L["Reset to current affixes"] = "重置词缀为本周词缀"
	L["Challenges Frame"] = "钥石界面"
	L["Modify Challenges Frame"] = "启用钥石界面修改"
	L["Best M+ Level"] = "最佳成绩"
	L["Dungeons :"] = "限时池："
	L["More Dungeons"] = "更多地下城"
	L["Score"] = "分数"
	L["Mythic Keystone"] = "史诗钥石"
	L["Keystone Type"] = "钥石类型"
	L["Timeworn Keystone"] = "弥时钥石"
	L["Time Trial Keystone"] = "计时赛钥石"
end

-- ruRU by Hollicsh
if locale == "ruRU" then
	L["Keystone Link: "] = "Ссылка на ключ: "
	L["Fake AngryKeystones"] = "Фейк AngryKeystones"
	L["It will replace AngryKeystones and send keystone info to your party automatically."] = "Это заменит AngryKeystones и автоматически отправит информацию о ключе в Вашу группу."
	L["Level"] = "Уровень"
	L["Affix"] = "Аффикс"
	L["Print"] = "Отправить"
	L["Print keystone link and send keystone info."] = "Отправить ключ в чат, а также информацию о нём."
	L["Reset to current affixes"] = "Восстановить текущие аффиксы"
	L["Challenges Frame"] = "Рамка испытаний"
	L["Modify Challenges Frame"] = "Изменить рамку испытаний"
	L["Best M+ Level"] = "Лучший уровень M+"
	L["Dungeons: "] = "Подземелья: "
	L["More Dungeons"] = "Больше подземелий"
	L["Score"] = "Счёт"
	L["Mythic Keystone"] = "Мифический ключ"
	L["Keystone Type"] = "Тип ключей"
	L["Timeworn Keystone"] = "Старые ключи"
	L["Time Trial Keystone"] = "Ключ для испытания на время"
end
