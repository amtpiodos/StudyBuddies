local composer = require( "composer" )
local scene = composer.newScene()
local widget = require("widget")
local physics = require( "physics" )
local json = require("json")

physics.start()
physics.setGravity( 0, 0 )
local _W = display.viewableContentWidth
local _H = display.viewableContentHeight

local textAnswerBox
local answer
local i = 1

local uid
local username
local groupname
local gid
local subject
local loadedmessage
local decres
local messageText
local timerperform
local lengthoftext
local UIGroup
UIGroup = display.newGroup()
UIGroup.y = -5

local function fieldHandler( textField )
	return function( event )
		if ( "began" == event.phase ) then
			 -- Transition group upward to y=50
        transition.to( UIGroup, { time=100, y=-250} )
		elseif ( "editing" == event.phase ) then

		elseif ( "submitted" == event.phase or  "ended" == event.phase ) then
            native.setKeyboardFocus( nil )
            -- Transition group back down to y=300
            transition.to( UIGroup, { time = 100, y = -5})
		end
	end
end

local function backtoTimeline(sceneGroup)
	local options = {
		parent = sceneGroup,
		effect = "crossFade",
		time = 300,
		params = {
			uid = uid,
			username = username,
			groupname = groupname,
			gid = gid
		}
	}
	timer.pause(timerperform)
	composer.removeScene("timeline")
    composer.gotoScene( "timeline", options)
end

local myBack = widget.newButton
{
	left = 125,
	top = 50,
	width = 50,
	height = 45,
	defaultFile = "back.png",
	overFile = "back2.png",
	onEvent = backtoTimeline
}

function scene:create (event)
	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen
	physics.pause()

	uid = event.params.uid
	username = event.params.username
	groupname = event.params.groupname
	gid = event.params.gid
	subject = event.params.subject

	backGroup = display.newGroup()  -- Display group for the background image
	sceneGroup:insert( backGroup )

	local background = display.newImageRect(backGroup, "b3.jpg", _W, _H)
	background.x = display.contentCenterX
	background.y = display.contentCenterY

	local minibg = display.newRect(backGroup, display.contentCenterX, display.contentCenterY * 1.09, _W*0.9, _H*0.60)
	minibg:setFillColor(1,0,0)
	minibg.alpha = 0

	function  background:tap(event)
		native.setKeyboardFocus( nil )
	end
	sceneGroup:insert(myBack)
	background:addEventListener("tap", background)
end

function scene:show(event)

	local sceneGroup = self.view
	local phase = event.phase

	local scrollGroup = display.newGroup()
	sceneGroup:insert(scrollGroup)

	local scrollView = widget.newScrollView(
	   {
	        x = display.contentCenterX,
	        y = display.contentCenterY * 0.95,
	        width = display.viewableContentWidth * 0.8,
	        height = display.viewableContentHeight * 0.7,
	        horizontalScrollDisabled = true,
	        listener = scrollListener
	    }
	)
	sceneGroup:insert(scrollView)

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)
		
	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
		textAnswerBox = native.newTextField(_W * 0.43, _H * 0.9, _W * 0.64, _H * 0.065)
		textAnswerBox:addEventListener("userInput", fieldHandler(function() return textAnswerBox end))
		sceneGroup:insert(textAnswerBox)
		textAnswerBox.placeholder = "Answer"
		textAnswerBox.size = 40;

		function textAnswerBox:userInput(event)
			if event.phase == "began" then
				event.target.text =''
			elseif event.phase == "ended" then
				answer = event.target.text
			elseif event.phase == "submitted" then
			end
		end	

		local function handleButtonEvent( event )
			if(event.phase == "ended") then
				local function networkListener( event )
					if ( event.isError ) then
						print( "Network error: ", event.response )
					else
						print( "RESPONSE: ", event.response )
					end
				end

				local params = {}
				params.body = "answersent="..answer.."&subjectsent="..subject.."&usernamesent="..username
				network.request( ("http://192.168.43.114:8080/studybuddies/groupchat/writeanswer"), "POST", networkListener, params)
				-- network.request( ("http://localhost:8080/studybuddies/groupchat/writeanswer"), "POST", networkListener, params)
			end
		end

		local sendanswerButton = widget.newButton(
			{
				x = 600,
				y = 920,
				shape = "rect",
				id = "sendbutton",
				label = "Send",
				fontSize = 25,
				fillColor = { default={ 1, 0.5, 0.5, 0.5 }, over={ 1, 0.2, 0.5, 1 } },
				onEvent = handleButtonEvent
			}
		)
		sceneGroup:insert(sendanswerButton)

		local function loadQuestionAndAnswer(answer)
			local options = {
				parent =sceneGroup,
				text = answer,
				y = display.screenOriginY + 230,
				x = display.viewableContentHeight * 0.3,
				anchorX = display.viewableContentWidth * 0.5,
				anchorY = display.viewableContentHeight * 0.5,
				font =native.systemFont,
				fontSize = 30
			}
			messageText = display.newText(options)
			messageText:setFillColor(1,0,0)

			scrollGroup:insert(messageText)
			scrollView:insert(scrollGroup)
		end


		local function reloadQuestionAndAnswer( event )
			-- body
			local decres2
			local length = 1
			local lddmessage
			local function networkListener1( event )
				if (event.isError) then
					print("Network error: ", event.response)
				else
					decres2 = json.decode(event.response)
					length = decres2.lines
					lddmessage = decres2.answers
					if(length ~= i) then
						display.remove(messageText)
						loadQuestionAndAnswer(lddmessage)
					end
				end
			end
			network.request( ("http://192.168.43.114:8080/studybuddies/groupchat/loadquestion/"..subject), "GET", networkListener1)
			-- network.request( ("http://localhost:8080/studybuddies/groupchat/loadquestion/"..subject), "GET", networkListener1)
		end
		timerperform = timer.performWithDelay(500, reloadQuestionAndAnswer, 0)
		textAnswerBox:addEventListener("userInput", textAnswerBox)
	end
end

-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)
		-- textAnswerBox:removeSelf()
		-- textAnswerBox = nil
	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene