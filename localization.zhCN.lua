-- Translated by wowui.cn

if( GetLocale() ~= "zhCN" ) then
	return
end

CCTrackerLocals = setmetatable({
	-- Cmd
	["CC Tracker slash commands"] = "CC Tracker命令行",

	["- clear - Clears all running timers."] = "- clear - 清除所有运行的计时器.",
	["- ui - Opens the configuration."] = "- ui - 打开配置窗口.",
	["- test - Shows test timers."] = "- test - 显示测试计时器.",

	-- GUI
	["None"] = "无",
	["General"] = "常规选项",
	
	["Only show trigger name in bars"] = "计时条内仅显示触发名字",
	
	["Bars"] = "计时条",
	["Anchors"] = "锚点",

	["Enable CC Tracker inside"] = "在以下情况启用",

	["Allows you to set what scenario's CC Tracker should be enabled inside."] = "允许你选择在什么情况下启用Party CC Tracker.",
	
	["Enable timer syncing"] = "启用计时器同步",
	["Enables timers syncing with other CC Tracker users, also will send syncs of your own CCs."] = "和其他使用Party CC Tracker插件的用户同步计时器.",
	
	["Silent mode"] = "沉默模式",
	["Disables all timers, all this does is sync your CCs with other players."] = "禁止与其他用户同步计时器.",

	["Syncing"] = "同步",

	["Enemy players"] = "敌对玩家",
	["Friendly players"] = "友方玩家",
	
	["Spells"] = "法术列表",
	["List"] = "列表",

	["Global settings for anchors, any changes made here will modify both the enemy and friendly anchors."] = "锚点的全局设定，任何改动都将影响到敌对和玩家锚点的设置.",

	["Lets you choose which timers should be shown if a party member uses them on an enemy."] = "选择你需要监视的友方玩家使用的法术.",
	["Lets you choose which timers should be shown if an enemy uses them on a party member."] = "选择你需要监视的敌对玩家使用的法术.",

	["Timers"] = "计时条",
	["Enable CC tracking for"] = "启用CC tracking",
	["What player type CC tracking should be used for."] = "选择需要监视的玩家类型.",
	["Friendly CC (Friendly player being CCed)"] = "友方 (友方玩家被法术控制)",
	["Enemy CC (Enemy player being CCed)"] = "敌对 (敌对玩家被法术控制)",
	
	["Enable timers for %s"] = "启用 %s 的计时器",
	
	["Everywhere else"] = "任何地方",
	["Battlegrounds"] = "战场",
	["Arenas"] = "竞技场",
	["Raid instances"] = "团队副本",
	["Party instances"] = "小队副本",

	["Grow display up"] = "向上增长",
	["Instead of adding everything from top to bottom, timers will be shown from bottom to top."] = "计时条向上增长叠加.",

	["Redirect bars to group"] = "重定向计时条到组",
	["Group name to redirect bars to, this lets you show the mods timers under another addons bar group. Requires the bars to be created using GTB."] = "重定向Party CC Tracker计时条到其他插件的计时条组.",

	["Show anchor"] = "显示锚点",
	["Display timer anchors for moving around."] = "显示计时器锚点以拖动.",

	["Display scale"] = "显示缩放",
	["Max timers"] = "计时条上限",
	["Icon position"] = "图标位置",
	["Left"] = "左",
	["Right"] = "右",
	["Bar display"] = "计时条显示",

	["Bar color"] = "计时条颜色",

	["Fade time"] = "渐隐时间",
	
	["Texture"] = "材质",
	["Width"] = "宽",
	["Color"] = "颜色",
	
	["Font"] = "字体",
	["None"] = "无",
	["Text"] = "文字",
	["Size"] = "大小",
}, {__index = CCTrackerLocals})