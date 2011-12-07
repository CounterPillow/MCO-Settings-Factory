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
	
	Field pngcrush:TGadget
	
	Rem
	Constructor, builds the GUI
	EndRem
	Method New()
		imageformat = CreatePanel(10, 0, 128, 64, mainwindow, PANEL_GROUP, "Image Format")
		imageformat_png = CreateButton("PNG", 4, 4, 64, 16, imageformat, BUTTON_RADIO)
		imageformat_jpeg = CreateButton("JPEG", 4, 20, 64, 16, imageformat, BUTTON_RADIO)	' Thanks Ion.
		
		imgquality = CreatePanel(150, 0, 150, 64, mainwindow, PANEL_GROUP, "JPEG Quality")
		imgquality_slider = CreateSlider(4, 4, 100, 32, imgquality, SLIDER_HORIZONTAL | SLIDER_TRACKBAR)
		SetSliderRange(imgquality_slider, 1, 100)
		imgquality_label = CreateLabel("1", 105, 5, 25, 16, imgquality, LABEL_FRAME | LABEL_RIGHT)
		
		bgcolor = CreatePanel(10, 80, 150, 64, mainwindow, PANEL_GROUP, "Background Color")
		bgcolor_select = CreateButton("Color...", 80, 0, 60, 32, bgcolor)
		bgcolor_preview = CreateLabel("", 10, 0, 30, 30, bgcolor, LABEL_SUNKENFRAME | LABEL_CENTER)
	EndMethod
	
	Rem
	Adjusts the options to the values in the "settings" TMap
	EndRem
	Method ReloadSettings()
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

Global settings:TMap
Global guigadgets:TList = New TList

Global mainwindow:TGadget = CreateWindow("MCO Settings Factory", 0, 0, 400, 300, Null, WINDOW_TITLEBAR | WINDOW_MENU | WINDOW_STATUS | WINDOW_CENTER)
BuildGUI()

Local sgui:TSettingsGUI = New TSettingsGUI

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
Adds menu items to the main menu, and adds them to a list for... I dunno. Probably going to be changed.
EndRem
Function BuildGUI()
	Local mainmenu:TGadget = WindowMenu(mainwindow)
	Local filemenu:TGadget = CreateMenu("File", 100, mainmenu)
	guigadgets.AddLast(filemenu)
	Local savemenu:TGadget = CreateMenu("Save", 101, filemenu)
	guigadgets.AddLast(savemenu)
	Local saveasmenu:TGadget = CreateMenu("Save as...", 102, filemenu)
	guigadgets.AddLast(saveasmenu)
	Local loadmenu:TGadget = CreateMenu("Load...", 103, filemenu)
	guigadgets.AddLast(loadmenu)
	UpdateWindowMenu(mainwindow)
EndFunction

Rem
Clears the settings TMap and creates a new one with default values.
The default values for the settings are taken from http://docs.overviewer.org
EndRem
Function ResetSettingsMap()
	settings = CreateMap()
	settings.Insert("imgquality", "95")
	settings.Insert("imgformat", "png")
	Local bgcolor:TRGBColor = New TRGBColor
	bgcolor.FromHexString("#A1A1A1")
	settings.Insert("bg-color", bgcolor)
EndFunction