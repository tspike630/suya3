--[[
本文件由编辑器自动生成，如需修改请先修改Excel表格后再使用Unity生成本文件

金庸群侠传3D重制版
https://github.com/jynew/jynew

这是本开源项目文件头，所有代码均使用MIT协议。
但游戏内资源和第三方插件、dll等请仔细阅读LICENSE相关授权协议文档。

金庸老先生千古！
]]
local fieldIdx = {}
fieldIdx.Id = 1
fieldIdx.ShopItems = 2
fieldIdx.Trigger = 3
local data = {
{12,{{{120,1000,50},{{121,1000,80}},1},
{4,{{{42,1,200},{{43,1,200},{{44,1,200},{{45,1,200},{{46,1,400},{{47,1,450}},3},
{11,{{{110,100,10}},0},
{17,{{{171,100,10}},0},
}
local helper = jy_utils.prequire('Jyx2Configs/ShopHelper')
local mt = {}
mt.__index = function(a,b)
	if fieldIdx[b] then
		return a[fieldIdx[b]]
	end
	if helper[b] then
		return helper[b]
	end
	return nil
end
mt.__metatable = false
for _,v in pairs(data) do
	setmetatable(v,mt)
end
local fieldIdxShopItems = {}
fieldIdxShopItems.Id = 1
fieldIdxShopItems.Count = 2
fieldIdxShopItems.Price = 3
local mtShopItems = {}
mtShopItems.__index = function(a,b)
	if fieldIdxShopItems[b] then
		return a[fieldIdxShopItems[b]]
	end
	return nil
end
mtShopItems.__metatable = false
for _,v in pairs(data) do
	for _,t in pairs(v.ShopItems) do
		if type(t) == 'table' then
			setmetatable(t,mtShopItems)
		end
	end
end
local configMgr = Jyx2:GetModule('ConfigMgr')
configMgr:AddConfigTable([[Shop]], data)