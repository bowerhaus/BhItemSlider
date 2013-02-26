local listItems={"Aardvark", "Bee", "Cat", "Dog", "Elephant", "Fox", "Giraffe", "Hen", "Iguana", "Jellyfish", "Kangaroo", "Lion", "Monkey", "Newt", "Orangutan", "Pig", "Queen Bee", "Raptor", "Sea Lion", "Turtle", "Viper", "Worker Bee", "Zebra"}
local tahomaFont=TTFont.new("Tahoma.ttf", 20)

local slider=BhItemSlider.new(80, 60, false)

-- This is the position of the "current" item
slider:setPosition(100, application:getContentHeight()/2)

-- These are the options, here set to their default values so you can see what's available
slider:beSlideEnabled(true)
slider:setDisabledAlpha(0.75)
slider:setScaleNotCurrent(1)
slider:setLongTapTime(nil)
slider:beScaleNotCurrentIsotropic(true)
slider:beTouchOnlyOnCurrent(false)
slider:beNoMomentum()
slider:beSnapping(true)
slider:setDragHysteresis(10)
slider:setDragOutOfBoundsStretch(0.4)
slider:setSlideHysteresisFraction(0.25)
slider:beCaptureTouches(true)

-- Let's change some to non-standard values
slider:beStandardMomentum()
slider:setDisabledAlpha(0.75)
slider:setLongTapTime(1)

-- Add event listeners
slider:addEventListener("selectionChanged", 
	function()
		print(string.format("selection changed to %s", slider:getCurrentItem():getText()))
	end)
	
slider:addEventListener("scrollStarted", 
	function()
		print("scroll started")
	end)
	
slider:addEventListener("scrollEnded", 
	function()
		print("scroll ended")
	end)

slider:setDisabledAlpha(1)
slider:setPosition(100, 0)

slider:addEventListener("scrolled", 
	function()
		local currentIndex=slider:getCurrentItemFractionalIndex()
		for _, eachItem in ipairs(slider:getItems()) do
			local eachIndex=slider:getIndexOfItem(eachItem)
			eachItem:setVisible(eachIndex>=currentIndex and eachIndex<currentIndex+5)
		end

	end)
	
slider:addEventListener("longPress",
	-- Enabled with setLongTapTime()
	function(event)
		print(string.format("Long tap on item %s", event.target:getText()))
	end)

-- Allow a touched object to highlight
local function highlight(object, tf)
	if tf then
		-- Alternatively try using setColorTransform()
		object:setTextColor(0xff0000)
	else
		object:setTextColor(0)
	end
end
slider:setHighlightOnTouchFunc(highlight)

-- Populate
for k,v in pairs(listItems) do
	-- Here we just add text fields but we could add sprites
	local text=TextField.new(tahomaFont, v)
	slider:addChild(text)
end

-- Set to first item and add to stage
application:setBackgroundColor(0xBAD45C)
slider:gotoItemAt(1)
stage:addChild(slider)

-- Demo the animated slide to call
Timer.delayedCall(1000, function() slider:slideToItemAt(12, 2) end)

