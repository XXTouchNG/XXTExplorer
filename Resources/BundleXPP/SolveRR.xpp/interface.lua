function xui_interface()
	return {
		["subheader"] = "Elegant App UI provided by XXTouchApp.",
		["header"] = "Example",
		["title"] = "Demo",
		["items"] = {
			{
				["cell"] = "XUIGroupCell",
				["label"] = "Switch"
			},{
				["defaults"] = "com.yourcompany.yourscript",
				["default"] = true,
				["label"] = "Enabled",
				["cell"] = "XUISwitchCell",
				["key"] = "enabled",
				["icon"] = "res/16.png"
			},{
				["cell"] = "XUIGroupCell",
				["label"] = "Button"
			},{
				["url"] = "https://www.xxtouch.com",
				["cell"] = "XUILinkCell",
				["label"] = "Open XXTouch.com"
			},{
				["cell"] = "XUIButtonCell",
				["action"] = "OpenURL:",
				["label"] = "Contact i.82@me.com",
				["kwargs"] = {
					"mailto://i.82@me.com"
				}
			},{
				["cell"] = "XUIGroupCell",
				["label"] = "Menu"
			},{
				["url"] = "sub/xui-sub.json",
				["cell"] = "XUILinkCell",
				["label"] = "Load another pane"
			},{
				["url"] = "appicon.png",
				["cell"] = "XUILinkCell",
				["label"] = "Open an image"
			},{
				["validValues"] = {
					1,2,3
				},
				["defaults"] = "com.yourcompany.yourscript",
				["default"] = {
					
				},
				["validTitles"] = {
					"Red","Green","Blue"
				},
				["label"] = "List of Options",
				["cell"] = "XUIOptionCell",
				["key"] = "list-1",
				["shortTitles"] = {
					"Red","Green","Blue"
				}
			},{
				["validValues"] = {
					1,2,3
				},
				["defaults"] = "com.yourcompany.yourscript",
				["default"] = {
					1,2
				},
				["validTitles"] = {
					"Red","Green","Blue"
				},
				["label"] = "List of Multiple Options",
				["cell"] = "XUIMultipleOptionCell",
				["key"] = "list-2",
				["maxCount"] = 2
			},{
				["validValues"] = {
					1,2,3
				},
				["defaults"] = "com.yourcompany.yourscript",
				["default"] = {
					1
				},
				["validTitles"] = {
					"Red","Green","Blue"
				},
				["label"] = "List of Ordered Options",
				["cell"] = "XUIOrderedOptionCell",
				["key"] = "list-3",
				["maxCount"] = 2,
				["minCount"] = 1
			},{
				["cell"] = "XUIGroupCell",
				["label"] = "Segment"
			},{
				["validValues"] = {
					1,2,3
				},
				["defaults"] = "com.yourcompany.yourscript",
				["default"] = "",
				["validTitles"] = {
					"Red","Green","Blue"
				},
				["label"] = "List of Options",
				["cell"] = "XUISegmentCell",
				["key"] = "list-segment",
				["shortTitles"] = {
					"Red","Green","Blue"
				}
			},{
				["validValues"] = {
					1,2,3,4,5,6,7
				},
				["defaults"] = "com.yourcompany.yourscript",
				["default"] = {
					1,2
				},
				["validTitles"] = {
					"Red","Green","Blue","Yellow","Purple","Black","White"
				},
				["cell"] = "XUICheckboxCell",
				["key"] = "checkbox",
				["maxCount"] = 4
			},{
				["validValues"] = {
					"first","second","third","fourth","fifth","sixth"
				},
				["defaults"] = "com.yourcompany.yourscript",
				["default"] = "fifth",
				["validTitles"] = {
					"First","Second","Third","Fourth","Fifth, please!","Zero"
				},
				["cell"] = "XUIRadioCell",
				["key"] = "radio"
			},{
				["cell"] = "XUIGroupCell",
				["label"] = "Number"
			},{
				["showValue"] = true,
				["defaults"] = "com.yourcompany.yourscript",
				["min"] = 1,
				["default"] = 5,
				["max"] = 10,
				["label"] = "Slider",
				["cell"] = "XUISliderCell",
				["key"] = "slider",
				["isSegmented"] = true
			},{
				["defaults"] = "com.yourcompany.yourscript",
				["min"] = 1,
				["default"] = 5,
				["max"] = 10,
				["autoRepeat"] = true,
				["label"] = "Stepper",
				["cell"] = "XUIStepperCell",
				["key"] = "stepper",
				["isInteger"] = true
			},{
				["cell"] = "XUIGroupCell",
				["footerText"] = "This is the footer text of this section.",
				["label"] = "TextField"
			},{
				["noAutoCorrect"] = true,
				["defaults"] = "com.yourcompany.yourscript",
				["default"] = "",
				["label"] = "Username",
				["cell"] = "XUITextFieldCell",
				["key"] = "username",
				["keyboard"] = "default",
				["placeholder"] = "Enter the username"
			},{
				["noAutoCorrect"] = true,
				["defaults"] = "com.yourcompany.yourscript",
				["default"] = "",
				["label"] = "Password",
				["cell"] = "XUISecureTextFieldCell",
				["key"] = "password",
				["keyboard"] = "ascii",
				["placeholder"] = "Enter the password"
			},{
				["cell"] = "XUIGroupCell",
				["label"] = "StaticText"
			},{
				["cell"] = "XUIStaticTextCell",
				["label"] = "This specifier uses the label key as text content. Dynamic height of this cell is enabled."
			}
		}
	}
end

return {
	name = "Example",
	arguments = {},
	generator = xui_interface,
}
