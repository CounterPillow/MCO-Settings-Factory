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
	
	Field tabber:TGadget
	Field tabs:TGadget[3]
	Field currenttab:TGadget
	
	'Image quality slider GUI items
	'WILL BE DISABLED IF IMAGEFORMAT != JPEG
	Field imgquality:TGadget
	Field imgquality_slider:TGadget
	Field imgquality_label:TGadget
	Field imgquality_value:Int
	
	'Background color selection GUI items
	Field bgcolor:TGadget
	Field bgcolor_select:TGadget
	Field bgcolor_preview:TGadget
	Field bgcolor_color:TRGBColor
	
	Field optimizeimg:TGadget
	Field optimizeimg_usepngcrush:TGadget
	Field optimizeimg_useadvdef:TGadget
	Field optimizeimg_aggressive:TGadget	' Enabled if useadvdef is checked, otherwise disabled
	
	Rem
	Builds the GUI
	EndRem
	Function Create:TSettingsGUI(window:TGadget)
		Local s:TSettingsGUI = New TSettingsGUI
		
		s.tabber = CreateTabber(0, 0, ClientWidth(window), ClientHeight(window), window)
		
		AddGadgetItem(s.tabber, "General Settings")
		AddGadgetItem(s.tabber, "World Setup")
		AddGadgetItem(s.tabber, "Rendermode Setup")
		
		For Local i:Int = 0 To 2
			s.tabs[i] = CreatePanel(0, 0, ClientWidth(s.tabber), ClientHeight(s.tabber), s.tabber)
			HideGadget(s.tabs[i])
		Next
		s.currenttab = s.tabs[0]
		ShowGadget(s.currenttab)
		
		s.imageformat = CreatePanel(10, 0, 150, 80, s.tabs[0], PANEL_GROUP, "Image Format")
		s.imageformat_png = CreateButton("PNG", 4, 4, 64, 16, s.imageformat, BUTTON_RADIO)
		s.imageformat_jpeg = CreateButton("JPEG", 4, 20, 64, 16, s.imageformat, BUTTON_RADIO)	' Thanks Ion.
		
		s.imgquality = CreatePanel(170, 0, 150, 80, s.tabs[0], PANEL_GROUP, "JPEG Quality")
		s.imgquality_slider = CreateSlider(4, 4, 100, 32, s.imgquality, SLIDER_HORIZONTAL | SLIDER_TRACKBAR)
		SetSliderRange(s.imgquality_slider, 1, 100)
		s.imgquality_label = CreateLabel("1", 105, 5, 25, 16, s.imgquality, LABEL_FRAME | LABEL_RIGHT)
		
		s.bgcolor = CreatePanel(10, 90, 150, 80, s.tabs[0], PANEL_GROUP, "Background Color")
		s.bgcolor_select = CreateButton("Color...", 80, 0, 60, 32, s.bgcolor)
		's.bgcolor_preview = CreateLabel("", 10, 0, 30, 30, s.bgcolor, LABEL_SUNKENFRAME | LABEL_CENTER)
		s.bgcolor_preview = CreatePanel(10, 0, 30, 30, s.bgcolor, PANEL_SUNKEN, "")
		s.bgcolor_color:TRGBColor = New TRGBColor
		' Now you may ask: "But Pillow, why didn't you just access the color the _preview gadget has?"
		' To that, I can answer: Because you can't. Yes, for some fucking reason you _CAN_ set a color, but
		' you can't retrieve it easily. There is a _bgcolor var in the windows driver, BUT YOU CAN'T FUCKING
		' ACCESS IT FROM OUTSIDE. I hate you, Sibly. I hate you and your modules.
		
		s.optimizeimg = CreatePanel(170, 90, 150, 80, s.tabs[0], PANEL_GROUP, "PNG Optimization")
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
				DisableGadget(Self.imgquality)
				EnableGadget(Self.optimizeimg)
				SetButtonState(imageformat_png, True)
				SetButtonState(imageformat_jpeg, False)
			Case "jpg"
				DisableGadget(optimizeimg)
				EnableGadget(imgquality)
				SetButtonState(imageformat_png, False)
				SetButtonState(imageformat_jpeg, True)
			Default
				EnableGadget(optimizeimg)
				EnableGadget(imgquality)
				SetButtonState(imageformat_png, False)
				SetButtonState(imageformat_jpeg, False)
		EndSelect
		
		imgquality_value = Int(String(settings.ValueForKey("imgquality")))
		SetSliderValue(imgquality_slider, imgquality_value)
		SetGadgetText(imgquality_label, imgquality_value)
		
		SetButtonState(optimizeimg_usepngcrush, False)
		SetButtonState(optimizeimg_useadvdef, False)
		SetButtonState(optimizeimg_aggressive, False)
		DisableGadget(optimizeimg_aggressive)
		
		Local optimize_level:Int = Int(String(settings.ValueForKey("optimize-img")))
		If optimize_level > 0 And optimize_level <= 3
			SetButtonState(optimizeimg_usepngcrush, True)
		EndIf
		If optimize_level > 1 And optimize_level <= 3
			SetButtonState(optimizeimg_useadvdef, True)
			EnableGadget(optimizeimg_aggressive)
		EndIf
		If optimize_level > 2 And optimize_level <= 3
			SetButtonState(optimizeimg_aggressive, True)
		EndIf
		
		Local bgcolor:TRGBColor = TRGBColor(settings.ValueForKey("bg-color"))
		SetGadgetColor(bgcolor_preview, bgcolor.rgb[0], bgcolor.rgb[1], bgcolor.rgb[2])
	EndMethod
	
	Rem
	Saves the values of the GUI into the Map
	EndRem
	Method SaveIntoMap(settings:TMap)
		'Save Imageformat
		If ButtonState(imageformat_jpeg) = True Then
			settings.Insert("imgformat", "jpg")
			'Image quality
			settings.Insert("imgquality", String(SliderValue(imgquality_slider)))
		Else
			settings.Insert("imgformat", "png")
			'Size optimizations
			settings.Insert("optimize-img", String( ButtonState(optimizeimg_usepngcrush) + ..
													ButtonState(optimizeimg_useadvdef) + ..
													ButtonState(optimizeimg_aggressive)))	' yay!
		EndIf
		settings.Insert("bg-color", bgcolor_color)
	EndMethod
	
	Rem
	Does all the event handling for the GUI
	EndRem
	Method HandleEvent(e:TEvent)
		Select e.id
			Case EVENT_GADGETACTION
				Select e.source
					' Tab switched
					Case tabber
						If currenttab <> tabs[e.data]
							HideGadget(currenttab)
							currenttab = tabs[e.data]
							ShowGadget(currenttab)
						EndIf
					
					' Image Quality and Optimization options
					Case imageformat_jpeg
						DisableGadget(optimizeimg)
						EnableGadget(imgquality)
					Case imageformat_png
						DisableGadget(imgquality)
						EnableGadget(optimizeimg)
					Case optimizeimg_useadvdef
						If ButtonState(optimizeimg_useadvdef) = True
							EnableGadget(optimizeimg_aggressive)
						Else
							DisableGadget(optimizeimg_aggressive)
						EndIf
					' Slider
					Case imgquality_slider
						imgquality_value = SliderValue(imgquality_slider)
						SetGadgetText(imgquality_label, imgquality_value)
					
					' Bg color
					Case bgcolor_select
						If RequestColor(RequestedRed(), RequestedGreen(), RequestedBlue()) = True Then
							SetGadgetColor(bgcolor_preview, RequestedRed(), RequestedGreen(), RequestedBlue())
							bgcolor_color.rgb[0] = RequestedRed()
							bgcolor_color.rgb[1] = RequestedGreen()
							bgcolor_color.rgb[2] = RequestedBlue()
						EndIf
				EndSelect
		EndSelect
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

Type TWorld
	Field path:String
	Field name:String
EndType

Type TRender
	Field name:String
	Field outputdir:String
	Field config:TMap
	
	Rem
		<notetofutureself reason="lazy">
		Okay so here's the thing;
		I'll store TWorld objects for "world" in the config TMap, instead of the world name
		This gives me a bit more flexible access
		</notetofutureself>
	EndRem
	
	Method New()
		Self.config:TMap = New TMap
	EndMethod
EndType

Local settings:TMap = CreateSettingsMap()

Local mainwindow:TGadget = CreateWindow("MCO Settings Factory", 0, 0, 400, 300, Null, WINDOW_TITLEBAR | WINDOW_MENU | WINDOW_STATUS | WINDOW_CENTER)
BuildGUI(mainwindow)

Local sgui:TSettingsGUI = TSettingsGUI.Create(mainwindow)

sgui.ReloadSettings(settings)

Repeat

	WaitEvent()
	sgui.HandleEvent(CurrentEvent) ' "Can't handle this dude" -- Charlie Sheen
	
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

' TODO: Redo this.
Function SaveSettings(path:String, settings:TMap)
	Local stream:TStream = WriteFile(path)
	Local key:Object
	Local val:Object
	For key = EachIn MapKeys(settings)
		val = settings.ValueForKey(key)
		If String(val) = "bg-color" 
			stream.WriteLine("bg-color" + "=" + TRGBColor(val).ToHexString())
		ElseIf val <> Null Then
			stream.WriteLine(String(key) + "=" + String(val))
		EndIf
	Next
	stream.Close()
EndFunction