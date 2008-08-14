-- Translated by wowui.cn

if( GetLocale() ~= "zhCN" ) then
	return
end

PartyCCLocals = {
	-- Cmd
	["Party CC Tracker slash commands"] = "Party CC Tracker命令行",

	["- clear - Clears all running timers."] = "- clear - 清除所有运行的计时器.",
	["- ui - Opens the configuration."] = "- ui - 打开配置窗口.",
	["- test - Shows test timers."] = "- test - 显示测试计时器.",

	-- GUI
	["None"] = "无",
	["General"] = "常规选项",
		
	["Show anchor"] = "显示锚点",
	["Display timer anchors for moving around."] = "显示计时器锚点以拖动.",
	
	["Only show trigger name in bars"] = "计时条内仅显示触发名字",
	
	["Bars"] = "计时条",
	
	["Display scale"] = "显示缩放",
	["How big the actual timers should be."] = "计时器缩放.",
		
	["Bar width"] = "条宽",
	["Bar texture"] = "材质",

	["Redirect bars to group"] = "重定向计时条到组",
	["Group name to redirect bars to, this lets you show Party CC Tracker timers under another addons bar group. Requires the bars to be created using GTB."] = "重定向Party CC Tracker计时条到其他插件的计时条组.",

	["Enable Party CC Tracker inside"] = "在以下情况启用",

	["Allows you to set what scenario's Party CC Tracker should be enabled inside."] = "允许你选择在什么情况下启用Party CC Tracker.",
	
	["Enable timer syncing"] = "启用计时器同步",
	["Enables timers syncing with other Party CC Tracker users, also will send syncs of your own CCs."] = "和其他使用Party CC Tracker插件的用户同步计时器.",
	
	["Spells which should be enabled and shown as timers."] = "启用和显示计时器的法术.",
	
	["Silent mode"] = "沉默模式",
	["Disables all timers, all this does is sync your CCs with other players."] = "禁止与其他用户同步计时器.",
	
	["Syncing"] = "同步",
	
	["Spells"] = "法术列表",
	["List"] = "列表",
	["Lets you choose which spells should be shown if a party member uses them."] = "选择你需要监视的团队成员使用的法术.",
	
	["Enable timers for %s"] = "启用 %s 的计时器",
	
	["Everywhere else"] = "任何地方",
	["Battlegrounds"] = "战场",
	["Arenas"] = "竞技场",
	["Raid instances"] = "团队副本",
	["Party instances"] = "小队副本",
}
PartyCCLocals = setmetatable({

}, {__index = PartyCCLocals})