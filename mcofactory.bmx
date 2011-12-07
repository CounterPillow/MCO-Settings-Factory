SuperStrict

Framework brl.blitz
Import brl.basic
Import brl.retro	' lol hipster
Import brl.Event
Import brl.EventQueue
Import MaxGUI.Drivers
?Win32
	Import "resourceobject.o"	' For awesome look and unnecessary file info. This took me ages.
?

Type TSettingsGUI
	
	'Image format selection GUI items
	Field imageformat:TGadget
	Field imageformat_png:TGadget
	Field imageformat_jpeg:TGadget
	
	'Image quality slider GUI items
	'WILL BE DISABLED IF IMAGEFORMAT != JPEG
	Field imgquality:TGadget
	Field imgquality_slider:TGadget
	Field imgquality_label:TGadget
	
	'Background color selection GUI items
	Field bgcolor:TGadget
	Field bgcolor_select:TGadget
	Field bgcolor_preview:TGadget
	
	Field optimizeimg:TGadget
	Field optimizeimg_usepngcrush:TGadget
	Field optimizeimg_useadvdef:TGadget
	Field optimizeimg_aggressive:TGadget	' Enabled if useadvdef is checked, otherwise disabled
	
	Rem
	Builds the GUI
	EndRem
	Function Create:TSettingsGUI(window:TGadget)
		Local s:TSettingsGUI = New TSettingsGUI
		s.imageformat = CreatePanel(10, 0, 150, 80, window, PANEL_GROUP, "Image Format")
		s.imageformat_png = CreateButton("PNG", 4, 4, 64, 16, s.imageformat, BUTTON_RADIO)
		s.imageformat_jpeg = CreateButton("JPEG", 4, 20, 64, 16, s.imageformat, BUTTON_RADIO)	' Thanks Ion.
		
		s.imgquality = CreatePanel(170, 0, 150, 80, window, PANEL_GROUP, "JPEG Quality")
		s.imgquality_slider = CreateSlider(4, 4, 100, 32, s.imgquality, SLIDER_HORIZONTAL | SLIDER_TRACKBAR)
		SetSliderRange(s.imgquality_slider, 1, 100)
		s.imgquality_label = CreateLabel("1", 105, 5, 25, 16, s.imgquality, LABEL_FRAME | LABEL_RIGHT)
		
		s.bgcolor = CreatePanel(10, 90, 150, 80, window, PANEL_GROUP, "Background Color")
		s.bgcolor_select = CreateButton("Color...", 80, 0, 60, 32, s.bgcolor)
		s.bgcolor_preview = CreateLabel("", 10, 0, 30, 30, s.bgcolor, LABEL_SUNKENFRAME | LABEL_CENTER)
		
		s.optimizeimg = CreatePanel(170, 90, 150, 80, window, PANEL_GROUP, "PNG Optimization")
		s.optimizeimg_usepngcrush = CreateButton("Use pngcrush", 4, 4, 150, 16, s.optimizeimg, BUTTON_CHECKBOX)
		s.optimizeimg_useadvdef = CreateButton("Use advdef", 4, 20, 150, 16, s.optimizeimg, BUTTON_CHECKBOX)
		s.optimizeimg_aggressive = CreateButton("Be aggressive", 4, 36, 150, 16, s.optimizeimg, BUTTON_CHECKBOX)
		Return s
	EndFunction
	
	Rem
	Adjusts the options to the values in the "settings" TMap
	EndRem
	Method ReloadSettings(settings:TMap)
		Select String(settings.ValueForKey("imgformat"))
			Case "png"
				SetButtonState(imageformat_png, True)
				SetButtonState(imageformat_jpeg, False)
			Case "jpg"
				SetButtonState(imageformat_png, False)
				SetButtonState(imageformat_jpeg, True)
			Default
				SetButtonState(imageformat_png, False)
				SetButtonState(imageformat_jpeg, False)
		EndSelect
		
		SetSliderValue(imgquality_slider, Int(String(settings.ValueForKey("imgquality"))))
		SetGadgetText(imgquality_label, Int(String(settings.ValueForKey("imgquality"))))
		
		SetButtonState(optimizeimg_usepngcrush, False)
		SetButtonState(optimizeimg_useadvdef, False)
		SetButtonState(optimizeimg_aggressive, False)	
		
		Local optimize_level:Int = Int(String(settings.ValueForKey("optimize-img")))
		If optimize_level > 0 And optimize_level <= 3
			SetButtonState(optimizeimg_usepngcrush, True)
		EndIf
		If optimize_level > 1 And optimize_level <= 3
			SetButtonState(optimizeimg_useadvdef, True)
		EndIf
		If optimize_level > 2 And optimize_level <= 3
			SetButtonState(optimizeimg_aggressive, True)
		EndIf
		
		Local bgcolor:TRGBColor = TRGBColor(settings.ValueForKey("bg-color"))
		SetGadgetColor(bgcolor_preview, bgcolor.rgb[0], bgcolor.rgb[1], bgcolor.rgb[2])
	EndMethod
	
	Rem
	Does all the event handling for the GUI
	EndRem
	Method HandleEvent(e:TEvent)
		'<lots of awesome stuff here>
	EndMethod
EndType

Type TRGBColor
	Field rgb:Byte[3]
	
	Rem
	Converts the "rgb" byte array to a hex string in the form of '#FFFFFF'
	EndRem
	Method ToHexString:String()
		Return "#" + Right(Hex(ToInt()), 6)
	EndMethod
	
	Rem
	Converts the "rgb" byte array to a 32bit integer
	EndRem
	Method ToInt:Int()
		Return(rgb[0] Shl 16 + rgb[1] Shl 8 + rgb[2])
	EndMethod
	
	Rem
	Converts a hex string in the form of '#FFFFFF' to a one-byte-per-color-component array ("rgb")
	EndRem
	Method FromHexString(color:String)
		color = Replace(color, "#", "")
		color = Upper(color)
		For Local i:Int = 1 To 3
			Local sub:String = "$" + Mid(color, 1 + (i - 1) * 2, 2)	' I fucking hate this 'one-based' BASIC bullshit.
			Self.rgb[i - 1] = Int(sub)
		Next
	EndMethod
	
	Rem
	Currently unimplemented because of flying sandwiches in deep space
	EndRem
	Method FromInt()	' Unimplemented because Pillow is a lazy bastard.
	
	EndMethod
EndType

Local settings:TMap = CreateSettingsMap()

Local mainwindow:TGadget = CreateWindow("MCO Settings Factory", 0, 0, 400, 300, Null, WINDOW_TITLEBAR | WINDOW_MENU | WINDOW_STATUS | WINDOW_CENTER)
BuildGUI(mainwindow)

Local sgui:TSettingsGUI = TSettingsGUI.Create(mainwindow)
sgui.ReloadSettings(settings)

Repeat
	WaitEvent()
	sgui.HandleEvent(CurrentEvent)	'proooobably going to be replaced by a hook. Who knows, stupid event shit.
	'this is just a little hack to play around.
	If EventID() = EVENT_GADGETACTION And EventSource() = sgui.bgcolor_select
		If RequestColor(RequestedRed(), RequestedGreen(), RequestedBlue()) = True Then
			SetGadgetColor(sgui.bgcolor_preview, RequestedRed(), RequestedGreen(), RequestedBlue())
		EndIf
	EndIf
Until EventID() = EVENT_WINDOWCLOSE And EventSource() = mainwindow

Rem
Adds menu items to the main menu
EndRem
Function BuildGUI(window:TGadget)
	Local mainmenu:TGadget = WindowMenu(window)
	Local filemenu:TGadget = CreateMenu("File", 100, mainmenu)
	Local savemenu:TGadget = CreateMenu("Save", 101, filemenu)
	Local saveasmenu:TGadget = CreateMenu("Save as...", 102, filemenu)
	Local loadmenu:TGadget = CreateMenu("Load...", 103, filemenu)
	UpdateWindowMenu(window)
EndFunction

Rem
Clears the settings TMap and creates a new one with default values.
The default values for the settings are taken from http://docs.overviewer.org
EndRem
Function CreateSettingsMap:TMap()
	Local settings:TMap = CreateMap()
	settings.Insert("imgquality", "95")
	settings.Insert("imgformat", "png")
	Local bgcolor:TRGBColor = New TRGBColor
	bgcolor.FromHexString("#A1A1A1")
	settings.Insert("bg-color", bgcolor)
	settings.Insert("optimize-img", "")
	Return settings
EndFunction