script_name('Telegram Control')
script_author('nist1')
script_version('1.1')
script_properties('work-in-pause')

local imgui_check, imgui			= pcall(require, 'mimgui')
local samp_check, samp				= pcall(require, 'samp.events')
local effil_check, effil			= pcall(require, 'effil')
local requests_check, requests	= pcall(require, 'requests')
local inicfg                  = require('inicfg')
local ffi							= require('ffi')
local dlstatus						= require('moonloader').download_status
local encoding						= require('encoding')
encoding.default					= 'CP1251'
u8 = encoding.UTF8

-->> Main Check Libs
if not imgui_check or not samp_check or not effil_check or not requests_check then 
	function main()
		if not isSampfuncsLoaded() or not isSampLoaded() then return end
		while not isSampAvailable() do wait(100) end
		local libs = {
			['Mimgui'] = imgui_check,
			['SAMP.Lua'] = samp_check,
			['Effil'] = effil_check,
         ['Requests'] = requests_check,
		}
		local libs_no_found = {}
		for k, v in pairs(libs) do
			if not v then sampAddChatMessage('[Telegram Control]{FFFFFF} Ó Âàñ îòñóòñòâóåò áèáëèîòåêà {308ad9}' .. k .. '{FFFFFF}. Áåç íå¸ ñêðèïò {308ad9}íå áóäåò {FFFFFF}ðàáîòàòü!', 0x308ad9); table.insert(libs_no_found, k) end
		end
		sampShowDialog(18364, '{308ad9}Telegram Control', string.format('{FFFFFF}Â Âàøåé ñáîðêå {308ad9}íåòó íåîáõîäèìûõ áèáëèîòåê{FFFFFF} äëÿ ðàáîòû ñêðèïòà.\nÁåç íèõ îí {308ad9}íå áóäåò{FFFFFF} ðàáîòàòü!\n\nÁèáëèîòåêè, êîòîðûå Âàì íóæíû:\n{FFFFFF}- {308ad9}%s\n\n{FFFFFF}Âñå áèáëèîòåêè ìîæíî ñêà÷àòü íà BlastHack: {308ad9}https://www.blast.hk\n{FFFFFF}Òàì æå Âû {308ad9}íàéäåòå èíñòðóêöèþ {FFFFFF}äëÿ èõ óñòàíîâêè.', table.concat(libs_no_found, '\n{FFFFFF}- {7172ee}')), 'Ïðèíÿòü', '', 0)
		thisScript():unload()
	end
	return
end

-->> Load Files
if not doesDirectoryExist(getWorkingDirectory()..'\\Telegram Control') then
   createDirectory(getWorkingDirectory()..'\\Telegram Control')
end
if not doesDirectoryExist(getWorkingDirectory()..'\\Telegram Control\\logo.png') then
   downloadUrlToFile('https://i.imgur.com/XSdx9Wm.png', getWorkingDirectory()..'\\Telegram Control\\logo.png', function (id, status, p1, p2)
   end)
end
if not doesDirectoryExist(getWorkingDirectory()..'\\Telegram Control\\EagleSans-Regular.ttf') then
   downloadUrlToFile('https://github.com/nist1-scripter/Telegram-Control/raw/main/EagleSans-Regular.ttf', getWorkingDirectory()..'\\Telegram Control\\EagleSans-Regular.ttf', function (id, status, p1, p2)
   end)
end

-->> JSON
function table.assign(target, def, deep)
   for k, v in pairs(def) do
       if target[k] == nil then
           if type(v) == 'table' then
               target[k] = {}
               table.assign(target[k], v)
           else  
               target[k] = v
           end
       elseif deep and type(v) == 'table' and type(target[k]) == 'table' then 
           table.assign(target[k], v, deep)
       end
   end 
   return target
end

function json(path)
	createDirectory(getWorkingDirectory() .. '/Telegram Control')
	local path = getWorkingDirectory() .. '/Telegram Control/' .. path
	local class = {}

	function class:save(array)
		if array and type(array) == 'table' and encodeJson(array) then
			local file = io.open(path, 'w')
			file:write(encodeJson(array))
			file:close()
		else
			msg('Îøèáêà ïðè ñîõðàíåíèè ôàéëà êîíôèãà!')
		end
	end

	function class:load(array)
		local result = {}
		local file = io.open(path)
		if file then
			result = decodeJson(file:read()) or {}
		end

		return table.assign(result, array, true)
	end

	return class
end

-->> Local Settings
local new = imgui.new
local WinState = new.bool()
local tab = 1
local updateid
local lastHealth = 0

local jsonConfig = json('Config.json'):load({ 
   ['notifications'] = {
		inputToken = '',
		inputUser = '',
      join = false,
      damage = false,
      die = false,
      logChat = false,
   },
   ['settings'] = {
      autoQ = false,
      autoOff = false,
      statsCmd = false,
      offCmd = false,
      qCmd = false,
   }
})

-->> Autoupdate Settings
local update_url = 'https://raw.githubusercontent.com/nist1-scripter/Telegram-Control/main/update.ini'
local update_path = getWorkingDirectory()..'\\Telegram Control\\update.ini'
local script_url = 'https://raw.githubusercontent.com/nist1-scripter/Telegram-Control/main/Telegram%20Control.lua'
local script_path = thisScript().path
local update_state = false

-->> Notifications Settings
local inputToken, inputUser = imgui.new.char[128](jsonConfig['notifications'].inputToken), imgui.new.char[128](jsonConfig['notifications'].inputUser)
local join = new.bool(jsonConfig['notifications'].join)
local damage = new.bool(jsonConfig['notifications'].damage)
local die = new.bool(jsonConfig['notifications'].die)
local autoQ = new.bool(jsonConfig['settings'].autoQ)
local logChat = new.bool(jsonConfig['notifications'].logChat)
local autoOff = new.bool(jsonConfig['settings'].autoOff)
local statsCmd = new.bool(jsonConfig['settings'].statsCmd)
local qCmd = new.bool(jsonConfig['settings'].qCmd)
local offCmd = new.bool(jsonConfig['settings'].offCmd)

-->> Main
function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
   getLastUpdate()
   lua_thread.create(get_telegram_updates)
   while not sampIsLocalPlayerSpawned() do wait(0) end
	msg('Çàãðóæåí! Àêòèâàöèÿ: {308ad9}/tgc')
	sampRegisterChatCommand('tgc', function() WinState[0] = not WinState[0] end)
   checkUpdates()
	while true do wait(1000)
      if update_state then
         downloadUrlToFile(script_url, script_path, function(id, status)
            if status == dlstatus.STATUS_ENDDOWNLOADDATA then
               msg('Îáíîâëåíèå óñïåøíî óñòàíîâëåíî!')
               thisScript():reload()
            end
         end)
         break
      end
	end
end

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	getTheme()

   fonts = {}
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()

   -->> Default Font
	imgui.GetIO().Fonts:Clear()
	imgui.GetIO().Fonts:AddFontFromFileTTF(u8(getWorkingDirectory() .. '/Telegram Control/EagleSans-Regular.ttf'), 20, nil, glyph_ranges)

   -->> Other Fonts
	for k, v in ipairs({15, 18, 25, 30}) do
		fonts[v] = imgui.GetIO().Fonts:AddFontFromFileTTF(u8(getWorkingDirectory() .. '/Telegram Control/EagleSans-Regular.ttf'), v, nil, glyph_ranges)
	end

   -->> Logo
	logo = imgui.CreateTextureFromFile(u8(getWorkingDirectory() .. '/Telegram Control/logo.png'))
end)

imgui.OnFrame(function() return WinState[0] end,
    function(player)
      imgui.SetNextWindowPos(imgui.ImVec2(select(1, getScreenResolution()) / 2, select(2, getScreenResolution()) / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  	imgui.SetNextWindowSize(imgui.ImVec2(1000, 475), imgui.Cond.FirstUseEver)
      imgui.Begin(thisScript().name, window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysUseWindowPadding)
      imgui.BeginGroup()
         imgui.SetCursorPosY(30 / 2)
         imgui.Image(logo, imgui.ImVec2(200, 130))
         imgui.SetCursorPosY(160)
         if imgui.Button(u8'Óâåäîìëåíèÿ', imgui.ImVec2(200,40)) then
            tab = 1
         end
         if imgui.Button(u8'Îáíîâëåíèÿ', imgui.ImVec2(200,40)) then
            tab = 2
         end
         if imgui.Button(u8'Íàñòðîéêè', imgui.ImVec2(200,40)) then
            tab = 3
         end
         if imgui.Button(u8'Àâòîð', imgui.ImVec2(200,40)) then
            tab = 4
         end
      imgui.EndGroup()

      imgui.SameLine()

      imgui.BeginChild('##right', imgui.ImVec2(-1, -1), true, imgui.WindowFlags.NoScrollbar)
      if tab == 1 then
         imgui.PushFont(fonts[15])
			imgui.Text(u8('1 Øàã: Îòêðûâàåì Telegram è çàõîäèì â áîòà «@BotFather»')); imgui.SameLine(); imgui.Link('(https://t.me/BotFather)', 'https://t.me/BotFather')
			imgui.Text(u8('2 Øàã: Ââîäèì êîìàíäó «/newbot» è ñëåäóåì èíñòðóêöèÿì'))
			imgui.Text(u8('3 Øàã: Ïîñëå óñïåøíîãî ñîçäàíèÿ áîòà Âû ïîëó÷èòå òîêåí')); imgui.NewLine(); imgui.SameLine(20); imgui.Text(u8('· Ïðèìåð ñîîáùåíèÿ ñ òîêåíîì:')); imgui.SameLine(); imgui.TextDisabled('Use this token to access the HTTP API: 6123464634:AAHgee28hWg5yCFICHfeew231pmKhh19c')
			imgui.Text(u8('4 Øàã: Âàì íóæíî óçíàòü ID ñâîåãî þçåðà. Äëÿ ýòîãî ÿ èñïîëüçîâàë áîòà «@getmyid_bot»')); imgui.SameLine(); imgui.Link('(https://t.me/getmyid_bot)', 'https://t.me/getmyid_bot')
			imgui.Text(u8('5 Øàã: Ïèøåì áîòó «@getmyid_bot» â ëè÷êó è Âàì îòïðàâèòñÿ ID Âàøåãî þçåðà â ïîëå «Your user ID»')); imgui.NewLine(); imgui.SameLine(20); imgui.Text(u8('· Ïðèìåð ñîîáùåíèÿ ñ ID þçåðà:')); imgui.SameLine(); imgui.TextDisabled('Your user ID: 1950130')
			imgui.Text(u8('6 Øàã: Òåïåðü íàì íóæíî ââåñòè òîêåí è ID þçåðà â ïîëÿ íèæå. Ïîñëå íàæìèòå íà êíîïêó «Òåñòîâîå ñîîáùåíèå» â ñêðèïòå')); imgui.NewLine(); imgui.SameLine(20); imgui.Text(u8('· Åñëè Âàì â ëè÷êó îòïðàâèòñÿ ñîîáùåíèå, òî Âû âñ¸ ñäåëàëè ïðàâèëüíî'))
			imgui.PopFont()

			imgui.NewLine()

			imgui.SetCursorPosY(255)
			imgui.CenterText(u8(' Äàííûå äëÿ áîòà:'))
         imgui.SetCursorPosX((imgui.GetWindowWidth() - 300) / 2)
			imgui.BeginGroup()
				imgui.PushItemWidth(300)
					if imgui.InputTextWithHint('##inputToken', u8('Ââåäèòå òîêåí'), inputToken, ffi.sizeof(inputToken), imgui.InputTextFlags.Password) then
						jsonConfig['notifications'].inputToken = ffi.string(inputToken)
						json('Config.json'):save(jsonConfig)
					end
					if imgui.InputTextWithHint('##inputUser', u8('Ââåäèòå ID þçåðà'), inputUser, ffi.sizeof(inputUser), imgui.InputTextFlags.Password) then
						jsonConfig['notifications'].inputUser = ffi.string(inputUser)
						json('Config.json'):save(jsonConfig)
					end
				imgui.PopItemWidth()
				if imgui.Button(u8('Òåñòîâîå ñîîáùåíèå'), imgui.ImVec2(300)) then
					sendTelegramNotification('Òåñòîâîå ñîîáùåíèå!')
				end
			imgui.EndGroup()
      elseif tab == 2 then
         imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Ñïèñîê Îáíîâëåíèé:'), 30).x) / 2 )
			imgui.FText(u8('Ñïèñîê Îáíîâëåíèé:'), 30)
         imgui.BeginChild('news', imgui.ImVec2(-1, -1), false)
            imgui.BeginChild('##update2', imgui.ImVec2(-1, 63), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Îáíîâëåíèå #1.1'), 30).x) / 2 )
			   imgui.FText(u8('Îáíîâëåíèå #1.1'), 30)
            imgui.FText(u8'- Àâòîîáíîâëåíèå ñêðèïòà', 18)
            date_text = u8('Îò ') .. '27.09.2023'
				imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
				imgui.FText('{TextDisabled}' .. date_text, 18)
			   imgui.EndChild()
            imgui.BeginChild('##update1', imgui.ImVec2(-1, 110), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Release'), 30).x) / 2 )
			   imgui.FText(u8('Release'), 30)
            imgui.FText(u8'- Âûõîä èç èãðû/Âûêëþ÷åíèå ÏÊ ïðè îòêëþ÷åíèè îò ñåðâåðà', 18)
            imgui.FText(u8'- Ìíîæåñòâî ñîáûòèé äëÿ îïîâåùåíèÿ â Telegram', 18)
            imgui.FText(u8'{Text}- Êîìàíäû {TextDisabled}/off{Text}, {TextDisabled}/q{Text}, {TextDisabled}/stats{Text}, {TextDisabled}/help {Text}äëÿ èñïîëüçîâàíèÿ â Telegram', 18)
            date_text = u8('Îò ') .. '22.09.2023'
				imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
				imgui.FText('{TextDisabled}' .. date_text, 18)
			   imgui.EndChild()
         imgui.EndChild()
      elseif tab == 4 then
         imgui.PushFont(fonts[30])
				imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8('Àâòîð ñêðèïòà: nist1')).x) / 2)
				imgui.Text(u8('Àâòîð ñêðèïòà:'))
				imgui.SameLine()
				imgui.TextColoredRGB('{209ac9}nist1')
			imgui.PopFont()
			imgui.SameLine()
         imgui.SetCursorPos(imgui.ImVec2((imgui.GetWindowWidth() * 1.5 - 700) / 2, (imgui.GetWindowHeight() - 250) / 2))
			imgui.BeginChild('Other', imgui.ImVec2(300, 195), true)
				imgui.CenterText(u8('Íåáîëüøàÿ èíôîðìàöèÿ:'))
				if imgui.Button(u8('Blasthack àêêàóíò'), imgui.ImVec2(-1, 77.5)) then os.execute('explorer https://www.blast.hk/members/465668/') end
				if imgui.Button(u8('Òåìà íà BlastHack'), imgui.ImVec2(-1, 77.5))then os.execute('explorer https://www.blast.hk/threads/190315/') end
            if imgui.IsItemHovered() then
               imgui.BeginTooltip()
               imgui.Text(u8'Âðåìåííî íå äîñòóïíî.')
               imgui.EndTooltip()
            end
			imgui.EndChild()
		   imgui.SetCursorPosY(imgui.GetWindowHeight() * 0.875)
		   imgui.CenterText(u8('Íàøëè áàã/íåäîðàáîòêó, ëèáî õîòèòå ïðåäëîæèòü èäåþ äëÿ ñêðèïòà?'))
		   imgui.CenterText(u8('Ñâÿæèòåñü ñ Àâòîðîì ñ ïîìîùüþ Blasthack.'))
      elseif tab == 3 then
         imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Íàñòðîéêè ñêðèïòà:'), 30).x) / 2 )
         imgui.FText(u8('Íàñòðîéêè ñêðèïòà:'), 30)
         imgui.PushFont(fonts[18])
			imgui.SetCursorPosX((imgui.GetWindowWidth() * 1.5 - 1150) / 2 - 5)
         imgui.BeginChild('settingsNotf', imgui.ImVec2(365, 419), false)
            imgui.StripChild()
            imgui.BeginChild('settingsNotfUnder', imgui.ImVec2(-1, -1), false)
			      imgui.CenterText(u8('Íàñòðîéêè óâåäîìëåíèé:'))
               if imgui.Checkbox(u8' Ëîãèðîâàíèå âõîäà/âûõîäà èç èãðû', join) then
                  jsonConfig['notifications'].join = join[0]
                  json('Config.json'):save(jsonConfig)
               end
               if imgui.IsItemHovered() then
                  imgui.BeginTooltip()
                  imgui.Text(u8'Ïðè âõîäå/âûõîäå â èãðó ïîëó÷èòå ñîîáùåíèå â Telegram.')
                  imgui.EndTooltip()
               end
               if imgui.Checkbox(u8' Ëîãèðîâàíèå óðîíà ïî ïåðñîíàæó', damage) then
                  jsonConfig['notifications'].damage = damage[0]
                  json('Config.json'):save(jsonConfig)
               end
               if imgui.IsItemHovered() then
                  imgui.BeginTooltip()
                  imgui.Text(u8'Åñëè Âû ïîëó÷èòå óðîí, òî ïîëó÷èòå ñîîáùåíèå â Telegram.')
                  imgui.EndTooltip()
               end
               if imgui.Checkbox(u8' Ëîãèðîâàíèå ñìåðòè ïåðñîíàæà', die) then
                  jsonConfig['notifications'].die = die[0]
                  json('Config.json'):save(jsonConfig)
               end
               if imgui.IsItemHovered() then
                  imgui.BeginTooltip()
                  imgui.Text(u8'Åñëè Âû óìð¸òå, òî ïîëó÷èòå ñîîáùåíèå â Telegram.')
                  imgui.EndTooltip()
               end
               if imgui.Checkbox(u8' Ëîãèðîâàíèå RP/NRP ÷àòà', logChat) then
                  jsonConfig['notifications'].logChat = logChat[0]
                  json('Config.json'):save(jsonConfig)
               end
               if imgui.IsItemHovered() then
                  imgui.BeginTooltip()
                  imgui.Text(u8'Îòïðàâëÿåò â Telegram ñîîáùåíèÿ èç ÷àòà.')
                  imgui.EndTooltip()
               end
            imgui.EndChild()
         imgui.EndChild()

         imgui.SameLine()

         imgui.SetCursorPosX((imgui.GetWindowWidth() * 1.5 - 365) / 2 - 5)
         imgui.BeginChild('settings', imgui.ImVec2(365, 419), false)
            imgui.StripChild()
            imgui.BeginChild('settingsUnder', imgui.ImVec2(-1, -1), false)
               imgui.CenterText(u8('Íàñòðîéêè ïðî÷åãî:'))
               if imgui.Checkbox(u8' Âûõîä èç èãðû ïðè îòêëþ÷åíèè îò ñåðâåðà', autoQ) then
                  if not jsonConfig['settings'].autoOff then
                     jsonConfig['settings'].autoQ = autoQ[0]
                     json('Config.json'):save(jsonConfig)
                  elseif jsonConfig['settings'].autoOff then
                     msg('Èñïîëüçóéòå ëèáî âûõîä èç èãðû, ëèáî âûêëþ÷åíèå ÏÊ.')
                     autoQ[0] = false
                  end
               end
               if imgui.IsItemHovered() then
                  imgui.BeginTooltip()
                  imgui.Text(u8'Åñëè Âàñ êèêíóò/çàáàíÿò, òî âàøà èãðà àâòîìàòè÷åñêè çàêðîåòñÿ.')
                  imgui.EndTooltip()
               end
               if imgui.Checkbox(u8' Âûêëþ÷åíèå ÏÊ ïðè îòêëþ÷åíèè îò ñåðâåðà', autoOff) then
                  if not jsonConfig['settings'].autoQ then
                     jsonConfig['settings'].autoOff = autoOff[0]
                     json('Config.json'):save(jsonConfig)
                  elseif jsonConfig['settings'].autoQ then
                     msg('Èñïîëüçóéòå ëèáî âûõîä èç èãðû, ëèáî âûêëþ÷åíèå ÏÊ.')
                     autoOff[0] = false
                  end
               end
               if imgui.IsItemHovered() then
                  imgui.BeginTooltip()
                  imgui.Text(u8'Åñëè Âàñ êèêíóò/çàáàíÿò, òî âàø ÏÊ àâòîìàòè÷åñêè âûêëþ÷èòñÿ.')
                  imgui.EndTooltip()
               end
               if imgui.Checkbox(u8' Ïîëó÷àòü ñòàòèñòèêó ïî êîìàíäå â Telegram', statsCmd) then
                  jsonConfig['settings'].statsCmd = statsCmd[0]
                  json('Config.json'):save(jsonConfig)
               end
               if imgui.IsItemHovered() then
                  imgui.BeginTooltip()
                  imgui.Text(u8'Îòïðàâëÿåò âàøó ñòàòèñòèêó.')
                  imgui.Text(u8'Êîìàíäà â Telegram: /stats')
                  imgui.EndTooltip()
               end
               if imgui.Checkbox(u8' Çàêðûâàòü èãðó ïî êîìàíäå â Telegram', qCmd) then
                  jsonConfig['settings'].qCmd = qCmd[0]
                  json('Config.json'):save(jsonConfig)
               end
               if imgui.IsItemHovered() then
                  imgui.BeginTooltip()
                  imgui.Text(u8'Âûõîäèò èç èãðû.')
                  imgui.Text(u8'Êîìàíäà â Telegram: /q')
                  imgui.EndTooltip()
               end
               if imgui.Checkbox(u8' Âûêëþ÷àòü ÏÊ ïî êîìàíäå â Telegram', offCmd) then
                  jsonConfig['settings'].offCmd = offCmd[0]
                  json('Config.json'):save(jsonConfig)
               end
               if imgui.IsItemHovered() then
                  imgui.BeginTooltip()
                  imgui.Text(u8'Âûêëþ÷àåò ÏÊ.')
                  imgui.Text(u8'Êîìàíäà â Telegram: /off')
                  imgui.EndTooltip()
               end
            imgui.EndChild()
         imgui.EndChild()
         imgui.PopFont()
      end
      imgui.PushFont(fonts[40])
		imgui.SetCursorPosX(imgui.GetWindowWidth() - 55)
		imgui.SetCursorPosY(5)
		if imgui.Button('X', imgui.ImVec2(50)) then WinState[0] = false end
		imgui.PopFont()
      imgui.EndChild()
      imgui.End()
   end
)

-->> Mimgui Snippets
function imgui.StripChild()
	local dl = imgui.GetWindowDrawList()
	local p = imgui.GetCursorScreenPos()
	dl:AddRectFilled(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + 10, p.y + imgui.GetWindowHeight()), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col['ButtonActive']]), 3, 5)
	imgui.Dummy(imgui.ImVec2(10, imgui.GetWindowHeight()))
	imgui.SameLine()
end

function imgui.ColorConvertHexToFloat4(hex)
	local s = hex:sub(5, 6) .. hex:sub(3, 4) .. hex:sub(1, 2)
	return imgui.ColorConvertU32ToFloat4(tonumber('0xFF' .. s))
end

function imgui.CenterText(text, size)
	local size = size or imgui.GetWindowWidth()
	imgui.SetCursorPosX((size - imgui.CalcTextSize(tostring(text)).x) / 2)
	imgui.Text(tostring(text))
end

function imgui.FText(text, font)
	assert(text)
	local render_text = function(stext)
		local text, colors, m = {}, {}, 1
		while stext:find('{%u%l-%u-%l-}') do
			local n, k = stext:find('{.-}')
			local color = imgui.GetStyle().Colors[imgui.Col[stext:sub(n + 1, k - 1)]]
			if color then
				text[#text], text[#text + 1] = stext:sub(m, n - 1), stext:sub(k + 1, #stext)
				colors[#colors + 1] = color
				m = n
			end
			stext = stext:sub(1, n - 1) .. stext:sub(k + 1, #stext)
		end
		if text[0] then
			for i = 0, #text do
				imgui.TextColored(colors[i] or colors[1], text[i])
				imgui.SameLine(nil, 0)
			end
			imgui.NewLine()
		else imgui.Text(stext) end
	end
	imgui.PushFont(fonts[font])
	render_text(text)
	imgui.PopFont()
end

function getSize(text, font)
	assert(text)
	imgui.PushFont(fonts[font])
	local size = imgui.CalcTextSize(text)
	imgui.PopFont()
	return size
end

function imgui.CenterText(text, size)
	local size = size or imgui.GetWindowWidth()
	imgui.SetCursorPosX((size - imgui.CalcTextSize(tostring(text)).x) / 2)
	imgui.Text(tostring(text))
end

function imgui.Link(name, link, size)
	local size = size or imgui.CalcTextSize(name)
	local p = imgui.GetCursorScreenPos()
	local p2 = imgui.GetCursorPos()
	local resultBtn = imgui.InvisibleButton('##'..link..name, size)
	if resultBtn then os.execute('explorer '..link) end
	imgui.SetCursorPos(p2)
	if imgui.IsItemHovered() then
		imgui.TextColored(imgui.GetStyle().Colors[imgui.Col['ButtonHovered']], name)
		imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y + size.y), imgui.ImVec2(p.x + size.x, p.y + size.y), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col['ButtonHovered']]))
	else
		imgui.TextColored(imgui.GetStyle().Colors[imgui.Col['ButtonActive']], name)
	end
	return resultBtn
end

function imgui.TextColoredRGB(text)
   local style = imgui.GetStyle()
   local colors = style.Colors
   local ImVec4 = imgui.ImVec4
   local explode_argb = function(argb)
       local a = bit.band(bit.rshift(argb, 24), 0xFF)
       local r = bit.band(bit.rshift(argb, 16), 0xFF)
       local g = bit.band(bit.rshift(argb, 8), 0xFF)
       local b = bit.band(argb, 0xFF)
       return a, r, g, b
   end
   local getcolor = function(color)
       if color:sub(1, 6):upper() == 'SSSSSS' then
           local r, g, b = colors[1].x, colors[1].y, colors[1].z
           local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
           return ImVec4(r, g, b, a / 255)
       end
       local color = type(color) == 'string' and tonumber(color, 16) or color
       if type(color) ~= 'number' then return end
       local r, g, b, a = explode_argb(color)
       return imgui.ImVec4(r/255, g/255, b/255, a/255)
   end
   local render_text = function(text_)
       for w in text_:gmatch('[^\r\n]+') do
           local text, colors_, m = {}, {}, 1
           w = w:gsub('{(......)}', '{%1FF}')
           while w:find('{........}') do
               local n, k = w:find('{........}')
               local color = getcolor(w:sub(n + 1, k - 1))
               if color then
                   text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                   colors_[#colors_ + 1] = color
                   m = n
               end
               w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
           end
           if text[0] then
               for i = 0, #text do
                   imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                   imgui.SameLine(nil, 0)
               end
               imgui.NewLine()
           else imgui.Text(u8(w)) end
       end
   end
   render_text(text)
end

-->> Other Function
function msg(text)
	sampAddChatMessage(string.format('[%s] {FFFFFF}%s', thisScript().name, text), 0x308ad9)
end

function checkUpdates()
   downloadUrlToFile(update_url, update_path, function(id, status)
      if status == dlstatus.STATUS_ENDDOWNLOADDATA then
         updateIni = inicfg.load(nil, update_path)
         if tonumber(updateIni.main.version) > tonumber(thisScript().version) then
            msg('Âíèìàíèå! Áûëî íàéäåíî îáíîâëåíèå, îáíîâëÿþñü..') 
            update_state = true
         end
         os.remove(update_path)
      end
   end)
end

function samp.onSetPlayerHealth(health)
	if health ~= lastHealth and jsonConfig['notifications'].damage and sampGetGamestate() == 3 then
		sendTelegramNotification('Âàøå çäîðîâüå èçìåíåíî!\nÒåêóùåå ÕÏ: ' .. health)
	end
	lastHealth = health
end

function samp.onServerMessage(color, text)
   if text:find('^%s*%(%( ×åðåç 30 ñåêóíä âû ñìîæåòå ñðàçó îòïðàâèòüñÿ â áîëüíèöó èëè ïîäîæäàòü âðà÷åé %)%)%s*$') then
      if jsonConfig['notifications'].die then
         sendTelegramNotification('Âàø ïåðñîíàæ óìåð!')
      end
   end
   if text:find(".*%[%d+%] ãîâîðèò:") then 
      if jsonConfig['notifications'].logChat then
         sendTelegramNotification(text)
      end
   end
   if text:find("%(%( %S+%[%d+%]: {B7AFAF}.-{FFFFFF} %)%)") then
      local nameNrp, famNrp, idNrp, tNrp = text:match("%(%( (%w+)_(%w+)%[(%d+)%]: {B7AFAF}(.-){FFFFFF} %)%)")
		local idNrpInGame = sampGetCharHandleBySampPlayerId(idNrp)
      if idNrpInGame and jsonConfig['notifications'].logChat then
         sendTelegramNotification('(( '..nameNrp..'_'..famNrp..'['..idNrp..']: '..tNrp..' ))')
      end
   end
end

function onReceivePacket(id)
	local notificationsJoinLeave = {
		[34] = {'Âû ïîäêëþ÷èëèñü ê ñåðâåðó!', 'ID_CONNECTION_REQUEST_ACCEPTED', jsonConfig['notifications'].join},
		[35] = {'Ïîïûòêà ïîäêëþ÷åíèÿ íå óäàëàñü!', 'ID_CONNECTION_ATTEMPT_FAILED', jsonConfig['notifications'].join},
		[37] = {'Íåïðàâèëüíûé ïàðîëü îò ñåðâåðà!', 'ID_INVALID_PASSWORD', jsonConfig['notifications'].join}
	}
	if notificationsJoinLeave[id] and notificationsJoinLeave[id][3] then
		sendTelegramNotification(notificationsJoinLeave[id][1])
	end
   local notificationsJoinLeaveIfAuto = {
		[32] = {'Ñåðâåð çàêðûë ñîåäèíåíèå!', 'ID_DISCONNECTION_NOTIFICATION', jsonConfig['notifications'].join},
		[33] = {'Ñîåäèíåíèå ïîòåðÿíî!', 'ID_CONNECTION_LOST', jsonConfig['notifications'].join},
	}
	if notificationsJoinLeaveIfAuto[id] and notificationsJoinLeaveIfAuto[id][3] and not jsonConfig['settings'].autoQ and not jsonConfig['settings'].autoOff then
		sendTelegramNotification(notificationsJoinLeaveIfAuto[id][1])
	end
   local LocalAutoQ = {
		[32] = {'Ñåðâåð çàêðûë ñîåäèíåíèå!', 'ID_DISCONNECTION_NOTIFICATION', jsonConfig['settings'].autoQ},
		[33] = {'Ñîåäèíåíèå ïîòåðÿíî!', 'ID_CONNECTION_LOST', jsonConfig['settings'].autoQ},
	}
	if LocalAutoQ[id] and LocalAutoQ[id][3] then
		sendTelegramNotification(list_packet[id][1]..'\nÂàøà èãðà âûêëþ÷åíà.')
      ffi.C.ExitProcess(0)
	end
   local LocalAutoOff = {
		[32] = {'Ñåðâåð çàêðûë ñîåäèíåíèå!', 'ID_DISCONNECTION_NOTIFICATION', jsonConfig['settings'].autoOff},
		[33] = {'Ñîåäèíåíèå ïîòåðÿíî!', 'ID_CONNECTION_LOST', jsonConfig['settings'].autoOff},
	}
	if LocalAutoOff[id] and LocalAutoOff[id][3] then
		sendTelegramNotification(LocalAutoOff[id][1]..'\nÂàø êîìïüþòåð âûêëþ÷åí.')
      os.execute('shutdown /s /t 5')
	end
end

function threadHandle(runner, url, args, resolve, reject)
   local t = runner(url, args)
   local r = t:get(0)
   while not r do
      r = t:get(0)
      wait(0)
   end
   local status = t:status()
   if status == 'completed' then
      local ok, result = r[1], r[2]
      if ok then resolve(result) else reject(result) end
   elseif err then
      reject(err)
   elseif status == 'canceled' then
      reject(status)
   end
   t:cancel(0)
end

function requestRunner()
   return effil.thread(function(u, a)
      local https = require 'ssl.https'
      local ok, result = pcall(https.request, u, a)
      if ok then
         return {true, result}
      else
         return {false, result}
      end
   end)
end

function async_http_request(url, args, resolve, reject)
   local runner = requestRunner()
   if not reject then reject = function() end end
   lua_thread.create(function()
      threadHandle(runner, url, args, resolve, reject)
   end)
end

function encodeUrl(str)
   str = str:gsub(' ', '%+')
   str = str:gsub('\n', '%%0A')
   return u8:encode(str, 'CP1251')
end

function sendTelegramNotification(msg) -- ôóíêöèÿ äëÿ îòïðàâêè ñîîáùåíèÿ þçåðó
   msg = msg:gsub('{......}', '') --òóò òèïî óáèðàåì öâåò
   msg = encodeUrl(msg) -- íó òóò ìû çàêîäèðóåì ñòðîêó
   async_http_request('https://api.telegram.org/bot' .. jsonConfig['notifications'].inputToken .. '/sendMessage?chat_id=' .. jsonConfig['notifications'].inputUser .. '&text='..msg,'', function(result) end) -- à òóò óæå îòïðàâêà
end

function get_telegram_updates() -- ôóíêöèÿ ïîëó÷åíèÿ ñîîáùåíèé îò þçåðà
   while not updateid do wait(1) end -- æäåì ïîêà íå óçíàåì ïîñëåäíèé ID
   local runner = requestRunner()
   local reject = function() end
   local args = ''
   while true do
      url = 'https://api.telegram.org/bot'..jsonConfig['notifications'].inputToken..'/getUpdates?chat_id='..jsonConfig['notifications'].inputUser..'&offset=-1' -- ñîçäàåì ññûëêó
      threadHandle(runner, url, args, processing_telegram_messages, reject)
      wait(0)
   end
end

function processing_telegram_messages(result) -- ôóíêöèÿ ïðîâåðÎ÷êè òîãî ÷òî îòïðàâèë ÷åë
   if result then
      -- òóòà ìû ïðîâåðÿåì âñå ëè âåðíî
      local proc_table = decodeJson(result)
      if proc_table.ok then
         if #proc_table.result > 0 then
            local res_table = proc_table.result[1]
            if res_table then
               if res_table.update_id ~= updateid then
                  updateid = res_table.update_id
                  local message_from_user = res_table.message.text
                  if message_from_user then
                     -- è òóò åñëè ÷åë îòïðàâèë òåêñò ìû ñâåðÿåì
                     local textTg = u8:decode(message_from_user) .. ' ' --äîáàâëÿåì â êîíåö ïðîáåë äàáû íå ïðîèçîøëè òåõ. øîêîëàäêè ñ êîìàíäàìè(òèïî ÷òîá !q íå ñ÷èòàëîñü êàê !qq)
                     if textTg:match('^/q') then
                        if jsonConfig['settings'].qCmd then
                           sendTelegramNotification('Èãðà óñïåøíî çàêðûòà.')
                           ffi.C.ExitProcess(0)
                        elseif not jsonConfig['settings'].qCmd then
                           sendTelegramNotification('Äàííàÿ ôóíêöèÿ îòêëþ÷åíà!\nÂêëþ÷èòü ìîæíî â íàñòðîéêàõ ñêðèïòà.')
                        end
                     elseif textTg:match('^/off') then
                        if jsonConfig['settings'].offCmd then
                           sendTelegramNotification('Âàø ÏÊ âûêëþ÷èòñÿ ÷åðåç 5 ñåêóíä.')
                           os.execute('shutdown /s /t 5')
                        elseif not jsonConfig['settings'].offCmd then
                           sendTelegramNotification('Äàííàÿ ôóíêöèÿ îòêëþ÷åíà!\nÂêëþ÷èòü ìîæíî â íàñòðîéêàõ ñêðèïòà.')
                        end
                     elseif textTg:match('^/stats') then
                        if jsonConfig['settings'].statsCmd then
                           sendTelegramNotification('Âîò âàøà ñòàòèñòèêà:')
                           stats = true
                           sampSendChat('/stats')
                        elseif not jsonConfig['settings'].statsCmd then
                           sendTelegramNotification('Äàííàÿ ôóíêöèÿ îòêëþ÷åíà!\nÂêëþ÷èòü ìîæíî â íàñòðîéêàõ ñêðèïòà.')
                        end
                     elseif textTg:match('^/help') then
                        sendTelegramNotification('Ñïèñîê äîñòóïíûõ êîìàíä:\n\n/off - Âûêëþ÷àåò Âàø êîìïüþòåð.\n/q - Âûõîäèò èç èãðû.\n/stats - Îòïðàâëÿåò Âàøó ñòàòèñòèêó èç èãðû.')
                     else -- åñëè æå íå íàéäåòñÿ íè îäíà èç êîìàíä âûøå, âûâåäåì ñîîáùåíèå
                        sendTelegramNotification('Òàêîé êîìàíäû íå ñóùåñòâóåò!\nÑïèñîê êîìàíä â /help')
                     end
                  end
               end
            end
         end
      end
   end
end

function getLastUpdate()
   async_http_request('https://api.telegram.org/bot'..jsonConfig['notifications'].inputToken..'/getUpdates?chat_id='..jsonConfig['notifications'].inputUser..'&offset=-1','',function(result)
       if result then
           local proc_table = decodeJson(result)
           if proc_table.ok then
               if #proc_table.result > 0 then
                   local res_table = proc_table.result[1]
                   if res_table then
                       updateid = res_table.update_id
                   end
               else
                   updateid = 1
               end
           end
       end
   end)
end

samp.onShowDialog = function(dialogId, style, title, button1, button2, text)
   if stats and dialogId==235 then
      sendTelegramNotification(text)
      stats = false
      setVirtualKeyDown(0x1B, true)
      setVirtualKeyDown(0x1B, false)
   end
end

-->> Theme
function getTheme()
   imgui.SwitchContext()
   --==[ CONFIG ]==--
   local style  = imgui.GetStyle()
   local colors = style.Colors
   local clr    = imgui.Col
   local ImVec4 = imgui.ImVec4
   local ImVec2 = imgui.ImVec2

   --==[ STYLE ]==--
   imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
   imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
   imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
   imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
   imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
   imgui.GetStyle().IndentSpacing = 0
   imgui.GetStyle().ScrollbarSize = 10
   imgui.GetStyle().GrabMinSize = 10

   --==[ BORDER ]==--
   imgui.GetStyle().WindowBorderSize = 1
   imgui.GetStyle().ChildBorderSize = 1
   imgui.GetStyle().PopupBorderSize = 1
   imgui.GetStyle().FrameBorderSize = 1
   imgui.GetStyle().TabBorderSize = 1

   --==[ ROUNDING ]==--
   imgui.GetStyle().WindowRounding = 5
   imgui.GetStyle().ChildRounding = 5
   imgui.GetStyle().FrameRounding = 5
   imgui.GetStyle().PopupRounding = 5
   imgui.GetStyle().ScrollbarRounding = 5
   imgui.GetStyle().GrabRounding = 5
   imgui.GetStyle().TabRounding = 5

   --==[ ALIGN ]==--
   imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
   imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
   imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
   
   --==[ COLORS ]==--
   colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
   colors[clr.TextDisabled]         = ImVec4(0.73, 0.75, 0.74, 1.00)
   colors[clr.WindowBg]             = ImVec4(0.09, 0.09, 0.09, 0.94)
   colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
   colors[clr.Border]               = ImVec4(0.20, 0.20, 0.20, 0.50)
   colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
   colors[clr.FrameBg]              = ImVec4(0.00, 0.39, 1.00, 0.65)
   colors[clr.FrameBgHovered]       = ImVec4(0.11, 0.40, 0.69, 1.00)
   colors[clr.FrameBgActive]        = ImVec4(0.11, 0.40, 0.69, 1.00)
   colors[clr.TitleBg]              = ImVec4(0.00, 0.00, 0.00, 1.00)
   colors[clr.TitleBgActive]        = ImVec4(0.00, 0.24, 0.54, 1.00)
   colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.22, 1.00, 0.67)
   colors[clr.MenuBarBg]            = ImVec4(0.08, 0.44, 1.00, 1.00)
   colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.53)
   colors[clr.ScrollbarGrab]        = ImVec4(0.31, 0.31, 0.31, 1.00)
   colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1.00)
   colors[clr.ScrollbarGrabActive]  = ImVec4(0.51, 0.51, 0.51, 1.00)
   colors[clr.CheckMark]            = ImVec4(1.00, 1.00, 1.00, 1.00)
   colors[clr.SliderGrab]           = ImVec4(0.34, 0.67, 1.00, 1.00)
   colors[clr.SliderGrabActive]     = ImVec4(0.84, 0.66, 0.66, 1.00)
   colors[clr.Button]               = ImVec4(0.00, 0.39, 1.00, 0.65)
   colors[clr.ButtonHovered]        = ImVec4(0.00, 0.64, 1.00, 0.65)
   colors[clr.ButtonActive]         = ImVec4(0.00, 0.53, 1.00, 0.50)
   colors[clr.Header]               = ImVec4(0.00, 0.62, 1.00, 0.54)
   colors[clr.HeaderHovered]        = ImVec4(0.00, 0.36, 1.00, 0.65)
   colors[clr.HeaderActive]         = ImVec4(0.00, 0.53, 1.00, 0.00)
   colors[clr.Separator]            = ImVec4(0.43, 0.43, 0.50, 0.50)
   colors[clr.SeparatorHovered]     = ImVec4(0.71, 0.39, 0.39, 0.54)
   colors[clr.SeparatorActive]      = ImVec4(0.71, 0.39, 0.39, 0.54)
   colors[clr.ResizeGrip]           = ImVec4(0.71, 0.39, 0.39, 0.54)
   colors[clr.ResizeGripHovered]    = ImVec4(0.84, 0.66, 0.66, 0.66)
   colors[clr.ResizeGripActive]     = ImVec4(0.84, 0.66, 0.66, 0.66)
   colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
   colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
   colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
   colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
   colors[clr.TextSelectedBg]       = ImVec4(0.26, 0.59, 0.98, 0.35)
end
