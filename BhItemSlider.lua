--[[ 
BhItemSlider.lua

A slider picker class
 
MIT License
Copyright (C) 2013. Andy Bower, Bowerhaus LLP

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
local DEFAULT_SLIDE_TIME=0.5
local DEFAULT_SLIDE_SNAP_TIME=0.2
local DEFAULT_DISABLED_ITEM_ALPHA=0.75
local DEFAULT_SCALE_NOT_CURRENT=1

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
	self.isHorizontal=isHorizontal or false
	self.slideSnapTime=DEFAULT_SLIDE_SNAP_TIME
	self.highlightOnTouchFunc=nil
	
	self:beSlideEnabled()
	self:setDisabledAlpha(DEFAULT_DISABLED_ITEM_ALPHA)
	self:setScaleNotCurrent(DEFAULT_SCALE_NOT_CURRENT)
	self:setLongTapTime(nil)
	self:beScaleNotCurrentIsotropic()
	self:beTouchOnlyOnCurrent(false)
	self:beNoMomentum()
	self:beSnapping()
	self:setDragHysteresis(DEFAULT_DRAG_HYSTERESIS)
	self:setDragOutOfBoundsStretch(DEFAULT_DRAG_OUT_OF_BOUNDS_STRETCH)
	self:setSlideHysteresisFraction(DEFAULT_SLIDE_HYSTERESIS_FRACTION)
	self:beCaptureTouches()
	
	self.cancelContext=self
	self.anchorOffset=0.5
	
	self.shield:addEventListener(Event.TOUCHES_BEGIN, self.onTouchesBegin, self)
	self.shield:addEventListener(Event.TOUCHES_MOVE, self.onTouchesMove, self)
    self.shield:addEventListener(Event.TOUCHES_END, self.onTouchesEnd, self)
end

function BhItemSlider:beSlideEnabled(tf)
	self.isSlideEnabled=tf or tf==nil
end

function BhItemSlider:beSnapping(tf)
	self.isSnapping=tf or tf==nil
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

function BhItemSlider:beNoMomentum()
	self:setSlideFriction(math.huge)
end

function BhItemSlider:beLowMomentum()
	self:setSlideFriction(self:getItemSize()*40)
end

function BhItemSlider:beStandardMomentum()
	self:setSlideFriction(self:getItemSize()*20)
end

function BhItemSlider:beHighMomentum()
	self:setSlideFriction(self:getItemSize()*10)
end

function BhItemSlider:setLongTapTime(value)
	self.longTapTime=value
end

function BhItemSlider:setSlideFriction(value)
	self.slideFriction=value
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

function BhItemSlider:setHighlightOnTouchFunc(func)
	self.highlightOnTouchFunc=func
end

function BhItemSlider:updateItemsAlphaAndScale()
	local centerIndex=self:getCurrentItemIndex()
	for i=1,self.contents:getNumChildren() do
		local child=self.contents:getChildAt(i)
		if self.disabledAlpha~=1 then
			child:setAlpha(self:getFractionalValueForItem(child, self.disabledAlpha))	
		end
		if self.scaleNotCurrent ~= 1 then
			-- If a moving scale has been supplied then use it
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
end

function BhItemSlider:getItemSize()
	if self.isHorizontal then
		return self.itemWidth
	else
		return self.itemHeight
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
		BhGridLayout.new(self.contents, self.itemWidth*self.contents:getNumChildren(), 
			self.itemHeight, self.itemWidth, self.itemHeight)
	else
		BhGridLayout.new(self.contents, self.itemWidth, 
			self.itemHeight*self.contents:getNumChildren(), self.itemWidth, self.itemHeight)
	end
end

function BhItemSlider:addItem(item)
	self.contents:addChild(item)
	self:updateLayout()
	self:updateItemsAlphaAndScale()
end 

function BhItemSlider:addItemAt(item, index)
	self.contents:addChildAt(item, index)
	self:updateLayout()
	self:updateItemsAlphaAndScale()
end 

function BhItemSlider:removeItem(item)
	self.contents:removeChild(item)
	self:updateLayout()
	self:updateItemsAlphaAndScale()
end 

function BhItemSlider:removeAllItems()
	for i=self.contents:getNumChildren(),1,-1 do
		self.contents:removeChildAt(i)
	end
	self:updateLayout()
	self:updateItemsAlphaAndScale()	
	self:resetScroll()
end

function BhItemSlider:resetScroll()
	if self.isHorizontal then
		self.contents:setX(0)
	else
		self.contents:setY(0)
	end
end

function BhItemSlider:getNumItems()
	return self.contents:getNumChildren()
end

function BhItemSlider:getHitObject(x, y)
	for i=1, self.contents:getNumChildren() do
		local object=self.contents:getChildAt(i)
		if object:hitTestPoint(x, y) then 
			return object 
		end
	end
	return nil
end

function BhItemSlider:startLongTapTimer()
	self:cancelLongTapTimer()
	self.longTapTimer=Timer.delayedCall(self.longTapTime*1000, function() self:onTouchIsLongTap() end)	
end

function BhItemSlider:cancelLongTapTimer()
	-- Check to see if we have a long tap timer that needs cancelling
	if self.longTapTimer then
		self.longTapTimer:stop()
		self.longTapTimer=nil
	end
end

function BhItemSlider:onTouchIsLongTap()
	self:cancelTouchesFor(self.cancelContext)
	if self.highlightOnTouchFunc then
		self.highlightOnTouchFunc(self.touchObject, false)
	end

	local event=Event.new("longPress")
	event.target=self.touchObject
	self:dispatchEvent(event)
	
	self.hasFocus=nil
	self.dragging=nil
	self.touchObject=nil
end

function BhItemSlider:onTouchesBegin(event)
	if self.hasFocus then 
		return
	end
	
	local hitTestObject=self.contents
	if self.isTouchOnlyOnCurrent then
		hitTestObject=self:getCurrentItem()
	end
	local x, y=event.touch.x, event.touch.y
	if hitTestObject:hitTestPoint(x, y) then
		self.hasFocus=event.touch.id

		if self.isHorizontal then
			self.x0=x
			self.xLast=x
		else
			self.y0=y
			self.yLast=y
		end
		
		self.touchObject=self:getHitObject(x, y)
		if self.touchObject then
			if self.highlightOnTouchFunc then		
				self.highlightOnTouchFunc(self.touchObject, true)
			end
		
			if self.longTapTime then
				-- If we have a long tap time set then start a timer
				self:startLongTapTimer()
			end
		end
		
		-- We don't stop event propagation for the active items because we don't know that
		-- the mouse down will actually be used to do a slide. Instead we wait until a certain
		-- amount of movement has taken place before making this decision. We determine which items
		-- are active by whether a disabledAlpha has been specified.
		if self.captureTouches or (self.disabledAlpha~=1 and not(self:getCurrentItem():hitTestPoint(event.touch.x, event.touch.y))) then
			event:stopPropagation()
		end
	end
end

function BhItemSlider:onTouchesMove(event)
	-- We are tracking a mouse down. Has a move gone beyond our hysteresis limits
	
	if event.touch.id==self.hasFocus then
		local x, y=event.touch.x, event.touch.y
		
		-- Check to see if we have a highlighted object that now needs de-highlighting
		if self.touchObject and self:getHitObject(x, y) ~= self.touchObject then
			if self.highlightOnTouchFunc then		
				self.highlightOnTouchFunc(self.touchObject, false)
			end
			self.touchObject=nil
		end		
	
		if self.isHorizontal then
			-- Horizontal mode
			if self.x0 and not(self.isDragging) and self.isSlideEnabled and math.abs(x-self.x0)>self.dragHysteresis then	
				self:cancelLongTapTimer()
				self:notifyScrollStarted()	
				self.isDragging=true	
				self.lastDragTime=os.timer()
				self.lastDragVelocity=0
				
				-- Enable the following and clicked item buttons will release as soon they are moved.		
				-- Otherwise the release will take place when the move has completed.
				self:cancelTouchesFor(self.cancelContext)
			end
			if self.isDragging then
				local delta=x-self.xLast
				local fIndex=self:getCurrentItemFractionalIndex()
				if fIndex<=1 or fIndex>=self:getNumItems() then
					delta=delta*self.dragOutOfBoundsStretch
				end

				-- If we have a touched object and a highlight function then
				-- ensure the object is now de-highlighted.
				if self.highlightOnTouchFunc and self.touchObject then		
					self.highlightOnTouchFunc(self.touchObject, false)
				end
				self.touchObject=nil
				
				self.contents:setX(self.contents:getX()+delta)	
				self:updateItemsAlphaAndScale()
				self:notifyScroll()
				
				-- Compute the finger drag velocity for momentum movement.
				-- Make sure it doesn't get too high if the timing is out.
				local timeNow=os.timer()
				local maxAbsVelocity=application:getContentWidth()*4
				self.lastDragVelocity=math.max(math.min(delta/(timeNow-self.lastDragTime), maxAbsVelocity), -maxAbsVelocity)
				self.lastDragTime=timeNow
			end
			self.xLast=x
		else
			-- Vertical mode
			if self.y0 and not(self.isDragging) and self.isSlideEnabled and math.abs(y-self.y0)>self.dragHysteresis then
				self:cancelLongTapTimer()
				self:notifyScrollStarted()
				self.isDragging=true
				self.lastDragTime=os.timer()
				self.lastDragVelocity=0
				
				-- Enable the following and clicked item buttons will release as soon they are moved.		
				-- Otherwise the release will take place when the move has completed.
				self:cancelTouchesFor(self.cancelContext)
			end
			if self.isDragging then
				local delta=y-self.yLast
				local fIndex=self:getCurrentItemFractionalIndex()
				if fIndex<=1 or fIndex>=self:getNumItems() then
					delta=delta*self.dragOutOfBoundsStretch
				end
				
				-- If we have a touched object and a highlight function then
				-- ensure the object is now de-highlighted.
				if self.highlightOnTouchFunc and self.touchObject then		
					self.highlightOnTouchFunc(self.touchObject, false)
				end
				self.touchObject=nil
				
				self.contents:setY(self.contents:getY()+delta)	
				self:updateItemsAlphaAndScale()	
				self:notifyScroll()
				
				-- Compute the finger drag velocity for momentum movement.
				-- Make sure it doesn't get too high if the timing is out.
				local timeNow=os.timer()
				local maxAbsVelocity=application:getContentHeight()*4
				self.lastDragVelocity=math.max(math.min(delta/(timeNow-self.lastDragTime), maxAbsVelocity), -maxAbsVelocity)
				self.lastDragTime=timeNow
			end
			self.yLast=y
		end
	end
end

local function sign(x)
	return x>0 and 1 or x<0 and -1 or 0
end

function BhItemSlider:onTouchesEnd(event)
	self:cancelLongTapTimer()

	if event.touch.id==self.hasFocus and self.isDragging then
		local x, y=event.touch.x, event.touch.y
		self:cancelTouchesFor(self.cancelContext)
		local newIndex=self:getCurrentItemFractionalIndex()
		
		if self.isSnapping then
			-- If we are snapping then see if we have moved far
			-- enough to call it a real slide.
			local deltaFraction
			if self.isHorizontal then
				deltaFraction=(x-self.x0)/self.itemWidth
			else
				deltaFraction=(y-self.y0)/self.itemHeight
			end
			if math.abs(deltaFraction)>self.slideHysteresisFraction then
				if deltaFraction>0 and deltaFraction<1 then
					-- Not quite far enough so snap back to original location
					newIndex=math.floor(newIndex)
				end
				if deltaFraction<0 and deltaFraction>-1 then
					-- Not quite far enough so snap back to original location
					newIndex=math.ceil(newIndex)
				end
			end
		end
		
		-- Do some tricky stuff to handle momentum based on the velocity of the last finger movement.
		--
		local u=self.lastDragVelocity
		local v, t, s=u, 0, 0
			if u~=0 then
			v=u/10
			t=(u-v)/(self.slideFriction*sign(u))
			s=(u+v)/2*t
		end
		
		-- bhDebugf("BhItemSlider k=%f, u=%f, t=%f, s=%f?", self.slideFriction, u, t, s)
		
		-- Now we can work out the extra movement required (in items)
		local requestedDelta=s/self:getItemSize()
		local requestedIndex=newIndex-requestedDelta
		local actualIndex=math.min(math.max(requestedIndex, 1), self.contents:getNumChildren())
		
		-- If we hit a limit at either end then let's reduce the amount of slide time to match
		-- so that the movement still looks natural.
		if requestedIndex~=newIndex then
			local timeFraction=math.min(math.abs((actualIndex-newIndex)/(requestedIndex-newIndex)), 1)
			t=t*timeFraction
		end

		-- Perform the slide to the actual index over the given time period
		self:slideToItemAt(actualIndex, math.max(t, self.slideSnapTime))	
		
		self.isDragging=false
		self.x0=nil
		self.y0=nil		
		self:notifyScrollEnded()
	end
	if self.touchObject then	
		local event=Event.new("clicked")
		event.target=self.touchObject
		self:dispatchEvent(event)
		if self.highlightOnTouchFunc then
			self.highlightOnTouchFunc(self.touchObject, false)
		end
		self.touchObject=nil
	end
	self.hasFocus=nil
end

function BhItemSlider:getCurrentItem()
	return self:getItemAt(self:getCurrentItemIndex())
end

function BhItemSlider:getCurrentItemIndex()
	local index=self:getCurrentItemFractionalIndex()
	if self.isSnapping then
		index=math.round(index)
	end
	return index
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
	--index=math.max(1, math.min(self:getNumItems(), index))
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

function BhItemSlider:setCurrentItemIndex(index)
	self:setCurrentItemFractionalIndex(math.round(index))
end

function BhItemSlider:slideToItemAt(index, time)
	-- We have to make sure time is not zero or the tween will never start
	time=math.max(time or self.slideSnapTime, 0.05)

	if self.isSnapping then
		index=math.round(index)
	end
	index=math.min(math.max(1, index), self.contents:getNumChildren())
	local tween=GTween.new(self, time, {itemIndex=index}, {dispatchEvents=true, ease=easing.outQuadratic})
	tween:addEventListener("complete", self.notifySelectionChanged, self)	
	return tween
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
	return self:getItemAt(index)
end

function BhItemSlider:getItems()
	local items={}
	for i=1,self:getItemCount() do
		table.insert(items, self:getItemAt(i))
	end
	return items
end

function BhItemSlider:getItemAt(i)
	return self.contents:getChildAt(math.max(1,i))
end

function BhItemSlider:getItemCount()
	return self.contents:getNumChildren()
end

function BhItemSlider:getItemIndex(item)
	return self.contents:getChildIndex(item)
end

function BhItemSlider:getItemWidth()
	return self.itemWidth
end

function BhItemSlider:setItemWidth(width)
	self.itemWidth=width
	self:updateLayout()
end

function BhItemSlider:getItemHeight()
	return self.itemHeight
end

function BhItemSlider:setItemHeight(height)
	self.itemHeight=height
	self:updateLayout()
end

BhItemSlider.___set=BhItemSlider.set

function BhItemSlider:set(param, value)
	if param=="itemIndex" then
		self:setCurrentItemFractionalIndex(value)
	elseif param=="itemWidth" then
		self:setItemWidth(value)
	elseif param=="itemHeight" then
		self:setItemHeight(value)
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
	if param=="itemWidth" then
		return self:getItemWidth()
	end
		if param=="itemHeight" then
		return self:getItemHeight()
	end
	return BhItemSlider.___get(self, param, value)
end