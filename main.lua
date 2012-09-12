local listItems={"Apple", "Banana", "Cabbage", "Dog", "Elephant", "Fox", "Giraffe", "Hen"}

local tahomaFont=TTFont.new("Tahoma.ttf", 30)


local slider=BhItemSlider.new(80, 40, false)
stage:addChild(slider)
for k,v in pairs(listItems) do
	local text=TextField.new(tahomaFont, v)
	slider:addChild(text)
end

slider:setPosition(100, 384)
slider:gotoItemAt(1)

