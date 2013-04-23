--[[ 
BhGridLayout.lua
 
MIT License
Copyright (C) 2012. Andy Bower, Bowerhaus LLP

Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

BhGridLayout=Core.class()

function BhGridLayout:init(target, width, height, itemWidth, itemHeight)
	self.target=target
	self.width=width
	self.height=height
	self.itemWidth=itemWidth
	self.itemHeight=itemHeight
	self:layout()
end

local function calclayout(self)
	local ncols=math.ceil((self.width) / self.itemWidth)
	local nrows=math.ceil((self.height) / self.itemHeight)
	
	-- How many rows do we actually need
	local actRows=math.ceil(self.target:getNumChildren()/ncols)
	local xorigin=0-(ncols*self.itemWidth)/2
	local yorigin=0-(actRows*self.itemHeight)/2
	
	local y=yorigin	
	local itemIndex=1
	self.itemRects={}
	for i=1,nrows do
		local x=xorigin
		for j=1,ncols do
			if itemIndex<=self.target:getNumChildren() then 
				self.itemRects[itemIndex]={left=x, top=y, right=x+self.itemWidth, bottom=y+self.itemHeight}
				x=x+self.itemWidth
			end
			itemIndex=itemIndex+1
		end
		y=y+self.itemHeight
	end
	
end

function BhGridLayout:getItemRectAt(index)
	return self.itemRects[index]
end

function BhGridLayout:layout()
	calclayout(self)
	for i=1,self.target:getNumChildren() do
		local itemRect=self:getItemRectAt(i)
		local item=self.target:getChildAt(i)
		item:setPosition(itemRect.left+self.itemWidth/2, itemRect.top+self.itemHeight/2)
	end
end