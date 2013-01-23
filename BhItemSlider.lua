--[[ 
BhItemSlider.lua

A slider picker class
 
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

BhItemSlider=Core.class(Sprite)

local DEFAULT_DRAG_HYSTERESIS=10
local DEFAULT_DRAG_OUT_OF_BOUNDS_STRETCH=0.4
local DEFAULT_SLIDE_HYSTERESIS_FRACTION=0.25
local DEFAULT_SLIDE_TIME=0.2
local DEFAULT_DISABLED_ITEM_ALPHA=0.75
local DEFAULT_SCALE_NOT_CURRENT=0.75
local DEFAULT_ITEM_PADDING=2

local function recursiveDispatchEvent(sprite, event)
	for i=sprite:getNumChildren(),1,-1 do
		recursiveDispatchEvent(sprite:getChildAt(i), event)
	end
	sprite:dispatchEvent(event)
end

function BhItemSlider:init(itemWidth, itemHeight, isHorizontal)
	-- We keep our "children" in a separate contents group and cover them with
	-- a shield sprite that we can use to get mouse events before they do. This allows us
	-- to have (e.g.) child buttons that can be receive down events at the same time we do
	-- but that we can cancel when we detect that the event is really a slide drag of ourselves.
	--
	
	self.contents=Sprite.new()
	Sprite.addChild(self, self.contents)
	self.shield=Sprite.new()
	Sprite.addChild(self, self.shield)
	
	self.itemWidth=itemWidth
	self.itemHeight=itemHeight
	self.itemPadding=DEFAULT_ITEM_PADDING
	self.isHorizontal=isHorizontal or false
	
	self:setDisabledAlpha(DEFAULT_DISABLED_ITEM_ALPHA)
	self:setScaleNotCurrent(DEFAULT_SCALE_NOT_CURRENT)
	self:beScaleNotCurrentIsotropic()
	self:beTouchOnlyOnCurrent(false)
	self:setDragHysteresis(DEFAULT_DRAG_HYSTERESIS)
	self:setDragOutOfBoundsStretch(DEFAULT_DRAG_OUT_OF_BOUNDS_STRETCH)
	self:setSlideHysteresisFraction(DEFAULT_SLIDE_HYSTERESIS_FRACTION)
	self:setSlideTime(DEFAULT_SLIDE_TIME)
	self:beCaptureTouches()
	
	self.cancelContext=self
	self.anchorOffset=0.5
	
	self.shield:addEventListener(Event.MOUSE_DOWN, self.onMouseDown, self)
	self.shield:addEventListener(Event.MOUSE_MOVE, self.onMouseMove, self)
    self.shield:addEventListener(Event.MOUSE_UP, self.onMouseUp, self)
end

function BhItemSlider:beScaleNotCurrentIsotropic(tf)
	self.scaleNotCurrentIsotropic=tf or tf==nil
end

function BhItemSlider:beTouchOnlyOnCurrent(tf)
	self.isTouchOnlyOnCurrent=tf or  tf==nil
end

function BhItemSlider:beCaptureTouches(tf)
	self.captureTouches=tf or tf==nil
end

function BhItemSlider:setDisabledAlpha(value)
	self.disabledAlpha=value
end

function BhItemSlider:setScaleNotCurrent(value)
	self.scaleNotCurrent=value
end

function BhItemSlider:setDragHysteresis(value)
	self.dragHysteresis=value
end

function BhItemSlider:setDragOutOfBoundsStretch(value)
	self.dragOutOfBoundsStretch=value
end

function BhItemSlider:setSlideHysteresisFraction(value)
	self.slideHysteresisFraction=value
end

function BhItemSlider:setSlideTime(value)
	self.slideTime=value
end

function BhItemSlider:setItemPadding(value)
	self.itemPadding=value
	self:updateLayout()
end

function BhItemSlider:updateItemsAlphaAndScale()
	local centerIndex=self:getCurrentItemIndex()
	for i=1,self.contents:getNumChildren() do
		local child=self.contents:getChildAt(i)
		child:setAlpha(self:getFractionalValueForItem(child, self.disabledAlpha))
		local itemScale=self:getFractionalValueForItem(child, self.scaleNotCurrent)
		if self.scaleNotCurrentIsotropic then
			child:setScale(itemScale)
		else
			if self.isHorizontal then
				child:setScaleX(itemScale)
			else
				child:setScaleY(itemScale)
			end
		end
	end
end

function BhItemSlider:getIndexOfItem(item)
	return self.contents:getChildIndex(item)
end

function BhItemSlider:getFractionalValueForItem(item, value)
	local currentFractionalIndex=self:getCurrentItemFractionalIndex()
	local index=self:getIndexOfItem(item)
	return 1-math.min(1, math.abs(index-currentFractionalIndex)*(1-value))
end

function BhItemSlider:notifyScrollStarted()	
	local e=Event.new("scrollStarted")
	self:dispatchEvent(e)
end

function BhItemSlider:notifyScroll()	
	local e=Event.new("scrolled")
	self:dispatchEvent(e)
end

function BhItemSlider:notifyScrollEnded()	
	local e=Event.new("scrollEnded")
	self:dispatchEvent(e)
end

function BhItemSlider:notifySelectionChanged()
	local event=Event.new("selectionChanged")
	self:dispatchEvent(event)
end

function BhItemSlider:cancelTouchesFor(sprite)
	local event=Event.new(Event.TOUCHES_CANCEL)
	event.touch={id=0}
	recursiveDispatchEvent(sprite, event)
end

function BhItemSlider:updateLayout()
	if self.isHorizontal then
		self.layoutManager=BhGridLayout.new(self.contents, (self.itemWidth+self.itemPadding*2)*self.contents:getNumChildren(), 
			self.itemHeight+self.itemPadding*2, self.itemWidth, self.itemHeight, self.itemPadding)
	else
		self.layoutManager=BhGridLayout.new(self.contents, self.itemWidth, 
			(self.itemHeight+self.itemPadding*2)*self.contents:getNumChildren(), (self.itemWidth+self.itemPadding*2), self.itemHeight, self.itemPadding)
	end
end

function BhItemSlider:addChild(item)
	self.contents:addChild(item)
	self:updateLayout()
	self:updateItemsAlphaAndScale()
end 

function BhItemSlider:removeChild(item)
	item:removeFromParent()
	self:updateLayout()
	self:updateItemsAlphaAndScale()
end 

function BhItemSlider:getNumItems()
	return self.contents:getNumChildren()
end

function BhItemSlider:onMouseDown(event)
	local hitTestObject=self.contents
	if self.isTouchOnlyOnCurrent then
		hitTestObject=self:getCurrentItem()
	end
	if hitTestObject:hitTestPoint(event.x, event.y) then
		self.hasFocus=true
		if self.isHorizontal then
			self.x0=event.x
			self.xLast=event.x
		else
			self.y0=event.y
			self.yLast=event.y
		end
		
		-- We don't stop event propagation for the active items because we don't know that
		-- the mouse down will actually be used to do a slide. Instead we wait until a certain
		-- amount of movement has taken place before making this decision. We determine which items
		-- are active by whether a disabledAlpha has been specified.
		if self.captureTouches or (self.disabledAlpha~=1 and not(self:getCurrentItem():hitTestPoint(event.x, event.y))) then
			event:stopPropagation()
		end
	end
end

function BhItemSlider:onMouseMove(event)
	-- We are trackimng a mouse down. Has a move gone beyond our hysteresis limits
	if self.hasFocus then
		if self.isHorizontal then
			-- Horizontal mode
			if self.x0 and not(self.isDragging) and math.abs(event.x-self.x0)>self.dragHysteresis then	
				self:notifyScrollStarted()	
				self.isDragging=true			
				-- Enable the following and clicked item buttons will release as soon they are moved.		
				-- Otherwise the release will take place when the move has completed.
				self:cancelTouchesFor(self.cancelContext)
			end
			if self.isDragging then
				local delta=event.x-self.xLast
				local fIndex=self:getCurrentItemFractionalIndex()
				if fIndex<=1 or fIndex>=self:getNumItems() then
					delta=delta*self.dragOutOfBoundsStretch
				end
				self.contents:setX(self.contents:getX()+delta)	
				self:updateItemsAlphaAndScale()
				self:notifyScroll()
			end
			self.xLast=event.x
		else
			-- Vertical mode
			if self.y0 and not(self.isDragging) and math.abs(event.y-self.y0)>self.dragHysteresis then
				self:notifyScrollStarted()
				self.isDragging=true
				-- Enable the following and clicked item buttons will release as soon they are moved.		
				-- Otherwise the release will take place when the move has completed.
				self:cancelTouchesFor(self.cancelContext)
			end
			if self.isDragging then
				local delta=event.y-self.yLast
				local fIndex=self:getCurrentItemFractionalIndex()
				if fIndex<=1 or fIndex>=self:getNumItems() then
					delta=delta*self.dragOutOfBoundsStretch
				end
				self.contents:setY(self.contents:getY()+delta)	
				self:updateItemsAlphaAndScale()	
				self:notifyScroll()
			end
			self.yLast=event.y
		end
	end
end

function BhItemSlider:onMouseUp(event)
	if self.isDragging then
		self:cancelTouchesFor(self.cancelContext)
		local newIndex=self:getCurrentItemFractionalIndex()
		local deltaFraction
		if self.isHorizontal then
			deltaFraction=(event.x-self.x0)/self.itemWidth
		else
			deltaFraction=(event.y-self.y0)/self.itemHeight
		end
		if math.abs(deltaFraction)>self.slideHysteresisFraction then
			-- We have moved far enough to call it a slide
			if deltaFraction>0 and deltaFraction<1 then
				newIndex=math.floor(newIndex)
			end
			if deltaFraction<0 and deltaFraction>-1 then
				newIndex=math.ceil(newIndex)
			end
		end
		newIndex=math.round(newIndex)
		self:slideToItemAt(math.min(math.max(1, newIndex), self.contents:getNumChildren()))		
		self.isDragging=false
		self.x0=nil
		self.y0=nil		
		self:notifyScrollEnded()
	end
	self.hasFocus=false
end

function BhItemSlider:getCurrentItem()
	return self:getItemAt(self:getCurrentItemIndex())
end

function BhItemSlider:getCurrentItemIndex()
		return math.round(self:getCurrentItemFractionalIndex())
end

function BhItemSlider:getCurrentItemFractionalIndex()
	local nItems=self.contents:getNumChildren()
	local index
	if self.isHorizontal then
		local origin=(nItems-1)*self.itemWidth/2
		index=(origin-self.contents:getX())/self.itemWidth+1
	else
		local origin=(nItems-1)*self.itemHeight/2
		index=(origin-self.contents:getY())/self.itemHeight+1
	end
	index=math.max(1, math.min(self:getNumItems(), index))
	return index
end

function BhItemSlider:setCurrentItemFractionalIndex(fIndex)
	local nItems=self.contents:getNumChildren()
	local index
	if self.isHorizontal then
		local origin=(nItems-1)*self.itemWidth/2
		local x=origin-(fIndex-1)*self.itemWidth
		self.contents:setX(x)
	else
		local origin=(nItems-1)*self.itemHeight/2
		local y=origin-(fIndex-1)*self.itemHeight
		self.contents:setY(y)
	end
	self:updateItemsAlphaAndScale()
	self:notifyScroll()
end

function BhItemSlider:slideToItemAt(index)
	local tween=GTween.new(self, self.slideTime, {itemIndex=index}, {dispatchEvents=true})
	tween:addEventListener("complete", self.notifySelectionChanged, self)
	
end

function BhItemSlider:getItemScrollPosition(item)
	if self.isHorizontal then
		return -item:getX(), self.contents:getY()
	else
		return self.contents:getX(), -item:getY()
	end
end

function BhItemSlider:gotoItemAt(index, isSilent)
	self:set("itemIndex", index)
	if not(isSilent) then
		self:notifySelectionChanged()
	end
end

function BhItemSlider:getItemAt(i)
	return self.contents:getChildAt(math.max(1,i))
end

function BhItemSlider:getItemCount()
	return self.contents:getNumChildren()
end

BhItemSlider.___set=BhItemSlider.set

function BhItemSlider:set(param, value)
	if param=="itemIndex" then
		self:setCurrentItemFractionalIndex(value)
	else
		BhItemSlider.___set(self, param, value)
	end
	return self
end
 
BhItemSlider.___get=BhItemSlider.get

function BhItemSlider:get(param, value)
	if param=="itemIndex" then
		return self:getCurrentItemFractionalIndex()
	end
	return BhItemSlider.___get(self, param, value)
end