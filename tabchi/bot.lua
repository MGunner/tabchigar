redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)

function dl_cb(arg, data)
end
function get_admin ()
	if redis:get('botBOT-IDadminset') then
		return true
	else
   		print("\n\27[32m  لازمه کارکرد صحیح ، فرامین و امورات مدیریتی ربات تبلیغ گر <<\n                    تعریف کاربری به عنوان مدیر است\n\27[34m                   ایدی خود را به عنوان مدیر وارد کنید\n\27[32m    شما می توانید از ربات زیر شناسه عددی خود را بدست اورید\n\27[34m        ربات:       @id_ProBot")
    	print("\n\27[32m >> Tabchi Bot need a fullaccess user (ADMIN)\n\27[34m Imput Your ID as the ADMIN\n\27[32m You can get your ID of this bot\n\27[34m                 @id_ProBot")
    	print("\n\27[36m                      : شناسه عددی ادمین را وارد کنید << \n >> Imput the Admin ID :\n\27[31m                 ")
    	local admin=io.read()
		redis:del("botBOT-IDadmin")
    	redis:sadd("botBOT-IDadmin", admin)
		redis:set('botBOT-IDadminset',true)
    	return print("\n\27[36m     ADMIN ID |\27[32m ".. admin .." \27[36m| شناسه ادمین")
	end
end
function get_bot (i, naji)
	function bot_info (i, naji)
		redis:set("botBOT-IDid",naji.id_)
		if naji.first_name_ then
			redis:set("botBOT-IDfname",naji.first_name_)
		end
		if naji.last_name_ then
			redis:set("botBOT-IDlanme",naji.last_name_)
		end
		redis:set("botBOT-IDnum",naji.phone_number_)
		return naji.id_
	end
	tdcli_function ({ID = "GetMe",}, bot_info, nil)
end
function reload(chat_id,msg_id)
	loadfile("./bot-BOT-ID.lua")()
	send(chat_id, msg_id, "<i>با موفقیت انجام شد.✅</i>")
end
function is_naji(msg)
    local var = false
	local hash = 'botBOT-IDadmin'
	local user = msg.sender_user_id_
    local Naji = redis:sismember(hash, user)
	if Naji then
		var = true
	end
	return var
end
function writefile(filename, input)
	local file = io.open(filename, "w")
	file:write(input)
	file:flush()
	file:close()
	return true
end
function process_join(i, naji)
	if naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("botBOT-IDmaxjoin", tonumber(Time), true)
	else
		redis:srem("botBOT-IDgoodlinks", i.link)
		redis:sadd("botBOT-IDsavedlinks", i.link)
	end
end
function process_link(i, naji)
	if (naji.is_group_ or naji.is_supergroup_channel_) then
		redis:srem("botBOT-IDwaitelinks", i.link)
		redis:sadd("botBOT-IDgoodlinks", i.link)
	elseif naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("botBOT-IDmaxlink", tonumber(Time), true)
	else
		redis:srem("botBOT-IDwaitelinks", i.link)
	end
end
function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("botBOT-IDalllinks", link) then
				redis:sadd("botBOT-IDwaitelinks", link)
				redis:sadd("botBOT-IDalllinks", link)
			end
		end
	end
end
function add(id)
	local Id = tostring(id)
	if not redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:sadd("botBOT-IDusers", id)
			redis:sadd("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:sadd("botBOT-IDsupergroups", id)
			redis:sadd("botBOT-IDall", id)
		else
			redis:sadd("botBOT-IDgroups", id)
			redis:sadd("botBOT-IDall", id)
		end
	end
	return true
end
function rem(id)
	local Id = tostring(id)
	if redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:srem("botBOT-IDusers", id)
			redis:srem("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:srem("botBOT-IDsupergroups", id)
			redis:srem("botBOT-IDall", id)
		else
			redis:srem("botBOT-IDgroups", id)
			redis:srem("botBOT-IDall", id)
		end
	end
	return true
end
function send(chat_id, msg_id, text)
	 tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessageTypingAction",
      progress_ = 100
    }
  }, cb or dl_cb, cmd)
	tdcli_function ({
		ID = "SendMessage",
		chat_id_ = chat_id,
		reply_to_message_id_ = msg_id,
		disable_notification_ = 1,
		from_background_ = 1,
		reply_markup_ = nil,
		input_message_content_ = {
			ID = "InputMessageText",
			text_ = text,
			disable_web_page_preview_ = 1,
			clear_draft_ = 0,
			entities_ = {},
			parse_mode_ = {ID = "TextParseModeHTML"},
		},
	}, dl_cb, nil)
end
get_admin()
redis:set("botBOT-IDstart", true)
function tdcli_update_callback(data)
	if data.ID == "UpdateNewMessage" then
		if not redis:get("botBOT-IDmaxlink") then
			if redis:scard("botBOT-IDwaitelinks") ~= 0 then
				local links = redis:smembers("botBOT-IDwaitelinks")
				for x,y in ipairs(links) do
					if x == 6 then redis:setex("botBOT-IDmaxlink", 65, true) return end
					tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
				end
			end
		end
		if not redis:get("botBOT-IDmaxjoin") then
			if redis:scard("botBOT-IDgoodlinks") ~= 0 then
				local links = redis:smembers("botBOT-IDgoodlinks")
				for x,y in ipairs(links) do
					tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
					if x == 2 then redis:setex("botBOT-IDmaxjoin", 65, true) return end
				end
			end
		end
		local msg = data.message_
		local bot_id = redis:get("botBOT-IDid") or get_bot()
		if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 178220800) then
			local c = (msg.content_.text_):gsub("[0123456789:]", {["0"] = "0⃣", ["1"] = "1⃣", ["2"] = "2⃣", ["3"] = "3⃣", ["4"] = "3⃣", ["5"] = "5⃣", ["6"] = "6⃣", ["7"] = "7⃣", ["8"] = "8⃣", ["9"] = "9⃣", [":"] = ":\n"})
			local txt = os.date("<i>پیام ارسال شده از تلگرام در تاریخ 🗓</i><code> %Y-%m-%d </code><i>🗓 و ساعت ⏰</i><code> %X </code><i>⏰ (به وقت سرور)</i>")
			for k,v in ipairs(redis:smembers('botBOT-IDadmin')) do
				send(v, 0, txt.."\n\n"..c)
			end
		end
		if tostring(msg.chat_id_):match("^(%d+)") then
			if not redis:sismember("botBOT-IDall", msg.chat_id_) then
				redis:sadd("botBOT-IDusers", msg.chat_id_)
				redis:sadd("botBOT-IDall", msg.chat_id_)
			end
		end
		add(msg.chat_id_)
		if msg.date_ < os.time() - 150 then
			return false
		end
		if msg.content_.ID == "MessageText" then
			local text = msg.content_.text_
			local matches
			if redis:get("botBOT-IDlink") then
				find_link(text)
			end
			if is_naji(msg) then
				find_link(text)
				if text:match("^(del link) (.*)$") then
					local matches = text:match("^del link (.*)$")
					if matches == "join" then
						redis:del("botBOT-IDgoodlinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار عضویت گروه با موفقیت پاکسازی شد✅")
					elseif matches == "confirm" then
						redis:del("botBOT-IDwaitelinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار تایید گروه با موفقیت پاکسازی شد✅")
					elseif matches == "saved" then
						redis:del("botBOT-IDsavedlinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های ذخیره شده گروه ها با موفقیت پاکسازی شد✅")
					end
				elseif text:match("^(delall link) (.*)$") then
					local matches = text:match("^delall link (.*)$")
					if matches == "join" then
						local list = redis:smembers("botBOT-IDgoodlinks")
						for i, v in ipairs(list) do
							redis:srem("botBOT-IDalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار عضویت بطورکلی با موفقیت پاکسازی شد✅")
						redis:del("botBOT-IDgoodlinks")
					elseif matches == "confirm" then
						local list = redis:smembers("botBOT-IDwaitelinks")
						for i, v in ipairs(list) do
							redis:srem("botBOT-IDalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار تایید بطورکلی با موفقیت پاکسازی شد✅")
						redis:del("botBOT-IDwaitelinks")
					elseif matches == "saved" then
						local list = redis:smembers("botBOT-IDsavedlinks")
						for i, v in ipairs(list) do
							redis:srem("botBOT-IDalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های ذخیره شده بطورکلی با موفقیت پاکسازی شد✅")
						redis:del("botBOT-IDsavedlinks")
					end
				elseif text:match("^(off) (.*)$") then
					local matches = text:match("^off (.*)$")
					if matches == "j" then	
						redis:set("bot1maxjoin", true)
						redis:set("bot1offjoin", true)
						return send(msg.chat_id_, msg.id_, "فرایند عضویت خودکار با موفقیت متوقف شد✅")
					elseif matches == "t" then	
						redis:set("bot1maxlink", true)
						redis:set("bot1offlink", true)
						return send(msg.chat_id_, msg.id_, "فرایند تایید لینک در های در انتظار با موفقیت متوقف شد✅")
					elseif matches == "s" then	
						redis:del("bot1link")
						return send(msg.chat_id_, msg.id_, "فرایند شناسایی لینک با موفقیت متوقف شد✅")
					elseif matches == "a" then	
						redis:del("bot1savecontacts")
						return send(msg.chat_id_, msg.id_, "فرایند افزودن خودکار مخاطبین به اشتراک گذاشته شده با موفقیت متوقف شد✅")
					end
				elseif text:match("^(on) (.*)$") then
					local matches = text:match("^on (.*)$")
					if matches == "j" then	
						redis:del("bot1maxjoin")
						redis:del("bot1offjoin")
						return send(msg.chat_id_, msg.id_, "فرایند عضویت خودکار با موفقیت فعال شد✅")
					elseif matches == "t" then	
						redis:del("bot1maxlink")
						redis:del("bot1offlink")
						return send(msg.chat_id_, msg.id_, "فرایند تایید لینک های در انتظار با موفقیت فعال شد✅")
					elseif matches == "s" then	
						redis:set("bot1link", true)
						return send(msg.chat_id_, msg.id_, "فرایند شناسایی لینک با موفقیت فعال شد✅")
					elseif matches == "a" then	
						redis:set("bot1savecontacts", true)
						return send(msg.chat_id_, msg.id_, "فرایند افزودن خودکار مخاطبین به اشتراک  گذاشته شده با موفقیت فعال شد✅")
					end
				elseif text:match("^(promote) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDadmin', matches) then
						return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر در حال حاضر مدیر میباشد♻️</i>")
					elseif redis:sismember('botBOT-IDmod', msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "شما دسترسی به تبچی ندارید‼️")
					else
						redis:sadd('botBOT-IDadmin', matches)
						redis:sadd('botBOT-IDmod', matches)
						return send(msg.chat_id_, msg.id_, "<i>مقام کاربر به مدیر ارتقا پیدا کرد✅</i>")
					end
				elseif text:match("^(setowner) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDmod',msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "شما دسترسی به تبچی را ندارید‼️")
					end
					if redis:sismember('botBOT-IDmod', matches) then
						redis:srem("botBOT-IDmod",matches)
						redis:sadd('botBOT-IDadmin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "مقام کاربر به مدیریت کل ربات ارتقا پیدا کرد✅")
					elseif redis:sismember('botBOT-IDadmin',matches) then
						return send(msg.chat_id_, msg.id_, 'درحال حاضر مدیر میباشد♻️')
					else
						redis:sadd('botBOT-IDadmin', matches)
						redis:sadd('botBOT-IDadmin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "کاربر به مقام مدیرکل ربات ارتقا پیدا کرد✅")
					end
				elseif text:match("^(demote) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDmod', msg.sender_user_id_) then
						if tonumber(matches) == msg.sender_user_id_ then
								redis:srem('botBOT-IDadmin', msg.sender_user_id_)
								redis:srem('botBOT-IDmod', msg.sender_user_id_)
							return send(msg.chat_id_, msg.id_, "شما دیگر مدیر ربات نیستید‼️")
						end
						return send(msg.chat_id_, msg.id_, "شما دسترسی به تبچی را ندارید‼️")
					end
					if redis:sismember('botBOT-IDadmin', matches) then
						if  redis:sismember('botBOT-IDadmin'..msg.sender_user_id_ ,matches) then
							return send(msg.chat_id_, msg.id_, "شما نمی توانید مدیری که به شما مقام داده را عزل مقام نمایید‼️")
						end
						redis:srem('botBOT-IDadmin', matches)
						redis:srem('botBOT-IDmod', matches)
						return send(msg.chat_id_, msg.id_, "کاربر از مقام مدیریت عزل شد✅")
					end
					return send(msg.chat_id_, msg.id_, "کاربر مورد نظر مدیر نمی باشد‼️")
				elseif text:match("^(refresh)$") then
					get_bot()
					return send(msg.chat_id_, msg.id_, "<i>مشخصات فردی ربات با موفقیت بروز رسانی شد✅</i>")
				elseif text:match("ریپورت") then
					tdcli_function ({
						ID = "SendBotStartMessage",
						bot_user_id_ = 178220800,
						chat_id_ = 178220800,
						parameter_ = 'start'
					}, dl_cb, nil)
				elseif text:match("^(update)$") then
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^update$") then
					io.popen("git fetch --all && git reset --hard origin/persian && git pull origin persian && chmod +x bot"):read("*all")
					local text,ok = io.open("bot.lua",'r'):read('*a'):gsub("BOT%-ID",BOT-ID)
					io.open("bot-BOT-ID.lua",'w'):write(text):close()
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^Reload$") then
					local botid = BOT-ID - 1
					redis:sunionstore("botBOT-IDall","tabchi:"..tostring(botid)..":all")
					redis:sunionstore("botBOT-IDusers","tabchi:"..tostring(botid)..":pvis")
					redis:sunionstore("botBOT-IDgroups","tabchi:"..tostring(botid)..":groups")
					redis:sunionstore("botBOT-IDsupergroups","tabchi:"..tostring(botid)..":channels")
					redis:sunionstore("botBOT-IDsavedlinks","tabchi:"..tostring(botid)..":savedlinks")
					return send(msg.chat_id_, msg.id_, "<b>همگام سازی اطلاعات با تبچی شماره</b><code> "..tostring(botid).." </code><b>با موفقیت انجام شد✅</b>")
				elseif text:match("^(list) (.*)$") then
					local matches = text:match("^list (.*)$")
					local naji
					if matches == "contact" then
						return tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},
						function (I, Naji)
							local count = Naji.total_count_
							local text = "مخاطبین : \n"
							for i =0 , tonumber(count) - 1 do
								local user = Naji.users_[i]
								local firstname = user.first_name_ or ""
								local lastname = user.last_name_ or ""
								local fullname = firstname .. " " .. lastname
								text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id_) .. "] = " .. tostring(user.phone_number_) .. "  \n"
							end
							writefile("botBOT-ID_contacts.txt", text)
							tdcli_function ({
								ID = "SendMessage",
								chat_id_ = I.chat_id,
								reply_to_message_id_ = 0,
								disable_notification_ = 0,
								from_background_ = 1,
								reply_markup_ = nil,
								input_message_content_ = {ID = "InputMessageDocument",
								document_ = {ID = "InputFileLocal",
								path_ = "botBOT-ID_contacts.txt"},
								caption_ = "🌐مخاطبین تبچی شماره BOT-ID"}
							}, dl_cb, nil)
							return io.popen("rm -rf botBOT-ID_contacts.txt"):read("*all")
						end, {chat_id = msg.chat_id_})
					elseif matches == "پاسخ های خودکار تبچی" then
						local text = "<i>🌐لیست پاسخ های خودکار :</i>\n\n"
						local answers = redis:smembers("botBOT-IDanswerslist")
						for k,v in pairs(answers) do
							text = tostring(text) .. "<i>l" .. tostring(k) .. "l</i>  " .. tostring(v) .. " : " .. tostring(redis:hget("botBOT-IDanswers", v)) .. "\n"
						end
						if redis:scard('botBOT-IDanswerslist') == 0  then text = "<code>       EMPTY</code>" end
						return send(msg.chat_id_, msg.id_, text)
					elseif matches == "block" then
						naji = "botBOT-IDblockedusers"
					elseif matches == "pv" then
						naji = "botBOT-IDusers"
					elseif matches == "gp" then
						naji = "botBOT-IDgroups"
					elseif matches == "sgp" then
						naji = "botBOT-IDsupergroups"
					elseif matches == "link" then
						naji = "botBOT-IDsavedlinks"
					elseif matches == "owner" then
						naji = "botBOT-IDadmin"
					else
						return true
					end
					local list =  redis:smembers(naji)
					local text = tostring(matches).." : \n"
					for i, v in pairs(list) do
						text = tostring(text) .. tostring(i) .. "-  " .. tostring(v).."\n"
					end
					writefile(tostring(naji)..".txt", text)
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = 0,
						disable_notification_ = 0,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {ID = "InputMessageDocument",
							document_ = {ID = "InputFileLocal",
							path_ = tostring(naji)..".txt"},
						caption_ = "لیست "..tostring(matches).." های تبلیغ گر شماره BOT-ID"}
					}, dl_cb, nil)
					return io.popen("rm -rf "..tostring(naji)..".txt"):read("*all")
				elseif text:match("^(markread) (.*)$") then
					local matches = text:match("^markread (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDmarkread", true)
						return send(msg.chat_id_, msg.id_, "<i>وضعیت پیام ها  >>  خوانده شده ✔️✔️\n</i><code>(تیک دوم فعال)</code>")
					elseif matches == "off" then
						redis:del("botBOT-IDmarkread")
						return send(msg.chat_id_, msg.id_, "<i>وضعیت پیام ها  >>  خوانده نشده ✔️\n</i><code>(بدون تیک دوم)</code>")
					end 
				elseif text:match("^(addedmsg) (.*)$") then
					local matches = text:match("^addedmsg (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDaddmsg", true)
						return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاطب با موفقیت فعال شد✅</i>")
					elseif matches == "off" then
						redis:del("botBOT-IDaddmsg")
						return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاطب با موفقیت غیرفعال شد✅</i>")
					end
				elseif text:match("^(addednumber) (.*)$") then
					local matches = text:match("addednumber (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDaddcontact", true)
						return send(msg.chat_id_, msg.id_, "<i>ارسال شماره هنگام افزودن مخاطب با موفقیت فعال شد✅</i>")
					elseif matches == "off" then
						redis:del("botBOT-IDaddcontact")
						return send(msg.chat_id_, msg.id_, "<i>ارسال شماره هنگام افزودن مخاطب باموفقیت غیرفعال شد✅</i>")
					end
				elseif text:match("^(setaddedmsg) (.*)") then
					local matches = text:match("^setaddedmsg (.*)")
					redis:set("botBOT-IDaddmsgtext", matches)
					return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاطب با موفقیت ثبت شد✅</i>:\n🔰 "..matches.." 🔰")
				elseif text:match('^(setanswer) "(.*)" (.*)') then
					local txt, answer = text:match('^setanswer "(.*)" (.*)')
					redis:hset("botBOT-IDanswers", txt, answer)
					redis:sadd("botBOT-IDanswerslist", txt)
					return send(msg.chat_id_, msg.id_, "<i>جواب برای | </i>" .. tostring(txt) .. "<i> | تنظیم شد به :</i>\n" .. tostring(answer))
				elseif text:match("^(delanswer) (.*)") then
					local matches = text:match("^delanswer (.*)")
					redis:hdel("botBOT-IDanswers", matches)
					redis:srem("botBOT-IDanswerslist", matches)
					return send(msg.chat_id_, msg.id_, "<i>جواب برای | </i>" .. tostring(matches) .. "<i> | از لیست جواب های خودکار پاک شد✅</i>")
				elseif text:match("^(autoanswer) (.*)$") then
					local matches = text:match("^autoanswer (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDautoanswer", true)
						return send(msg.chat_id_, 0, "<i>پاسخگویی خودکار تبچی با موفقیت فعال شد✅</i>")
					elseif matches == "off" then
						redis:del("botBOT-IDautoanswer")
						return send(msg.chat_id_, 0, "<i>حالت پاسخگویی خودکار تبچی با موفقیت غیرفعال شد✅</i>")
					end
				elseif text:match("^(refresh)$")then
					local list = {redis:smembers("botBOT-IDsupergroups"),redis:smembers("botBOT-IDgroups")}
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
						redis:set("botBOT-IDcontacts", naji.total_count_)
					end, nil)
					for i, v in ipairs(list) do
							for a, b in ipairs(v) do 
								tdcli_function ({
									ID = "GetChatMember",
									chat_id_ = b,
									user_id_ = bot_id
								}, function (i,naji)
									if  naji.ID == "Error" then rem(i.id) 
									end
								end, {id=b})
							end
					end
					return send(msg.chat_id_,msg.id_,"<i>تازه‌سازی آمار تبچی شماره </i><code> BOT-ID </code> با موفقیت انجام شد✅")
				elseif text:match("^(settings)$") then
					local s =  redis:get("botBOT-IDoffjoin") and 0 or redis:get("botBOT-IDmaxjoin") and redis:ttl("botBOT-IDmaxjoin") or 0
					local ss = redis:get("botBOT-IDofflink") and 0 or redis:get("botBOT-IDmaxlink") and redis:ttl("botBOT-IDmaxlink") or 0
					local msgadd = redis:get("botBOT-IDaddmsg") and "✅️" or "⛔️"
					local numadd = redis:get("botBOT-IDaddcontact") and "✅️" or "⛔️"
					local txtadd = redis:get("botBOT-IDaddmsgtext") or  "اد‌دی گلم خصوصی پیام بده"
					local autoanswer = redis:get("botBOT-IDautoanswer") and "✅️" or "⛔️"
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local links = redis:scard("botBOT-IDsavedlinks")
					local offjoin = redis:get("botBOT-IDoffjoin") and "⛔️" or "✅️"
					local offlink = redis:get("botBOT-IDofflink") and "⛔️" or "✅️"
					local nlink = redis:get("botBOT-IDlink") and "✅️" or "⛔️"
					local contacts = redis:get("botBOT-IDsavecontacts") and "✅️" or "⛔️"
					local txt = "⚙️  <i> settings</i><code> BOT-ID</code>  ⛓\n\n"..tostring(offjoin).."<code> Auto join </code>🚀\n"..tostring(offlink).."<code> Auto link confirmation </code>🚦\n"..tostring(nlink).."<code> Detect membership links</code>🎯\n"..tostring(contacts).."<code> Automatically add contacts </code>➕\n" .. tostring(autoanswer) .."<code> Auto Answer Mode 🗣 </code>\n" .. tostring(numadd) .. "<code> Add contact with number 📞 </code>\n" .. tostring(msgadd) .. "<code> Add contact with message 🗞</code>\n〰〰〰ا〰〰〰\n📄<code> Add contact message :</code>\n📍 " .. tostring(txtadd) .. " 📍\n〰〰〰ا〰〰〰\n\n<code>📁 Saved Links: </code><b>" .. tostring(links) .. "</b>\n<code>⏲ Pending membership links: </code><b>" .. tostring(glinks) .. "</b>\n🕖   <b>" .. tostring(s) .. " </b><code>Seconds to re-join</code>\n<code>❄️ Links waiting to be confirmed : </code><b>" .. tostring(wlinks) .. "</b>\n🕑   <b>" .. tostring(ss) .. " </b><code>Seconds to confirm re-linking</code>\n\n 💠 creator : @DevMF"
					return send(msg.chat_id_, 0, txt)
				elseif text:match("^(s)$") or text:match("^(p)$") then
					local gps = redis:scard("botBOT-IDgroups")
					local sgps = redis:scard("botBOT-IDsupergroups")
					local usrs = redis:scard("botBOT-IDusers")
					local links = redis:scard("botBOT-IDsavedlinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
					redis:set("botBOT-IDcontacts", naji.total_count_)
					end, nil)
					local contacts = redis:get("botBOT-IDcontacts")
					local text = [[
♣️🌝♠️
					
<code>🃏P: </code> ]] .. tostring(usrs) ..  [[
					
<code>🀄️S: </code> ]] .. tostring(sgps) .. [[
					
<code>♥️L: </code> ]] .. tostring(links).. [[


🃏 Creator: @DevMF]]
				    return send(msg.chat_id_, 0, text)
				elseif (text:match("^(fwd) (.*)$") and msg.reply_to_message_id_ ~= 0) then
					local matches = text:match("^fwd (.*)$")
					local naji
					if matches:match("^(pv)") then
						naji = "botBOT-IDusers"
					elseif matches:match("^(gp)$") then
						naji = "botBOT-IDgroups"
					elseif matches:match("^(sgp)$") then
						naji = "botBOT-IDsupergroups"
					else
						return true
					end
					local list = redis:smembers(naji)
					local id = msg.reply_to_message_id_
					for i, v in pairs(list) do
						tdcli_function({
							ID = "ForwardMessages",
							chat_id_ = v,
							from_chat_id_ = msg.chat_id_,
							message_ids_ = {[0] = id},
							disable_notification_ = 1,
							from_background_ = 1
						}, dl_cb, nil)
					end
					return send(msg.chat_id_, msg.id_, "<i>با موفقیت ارسال شد✅</i>")
				elseif text:match("^(send sgp) (.*)") then
					local matches = text:match("^send sgp (.*)")
					local dir = redis:smembers("botBOT-IDsupergroups")
					for i, v in pairs(dir) do
						tdcli_function ({
							ID = "SendMessage",
							chat_id_ = v,
							reply_to_message_id_ = 0,
							disable_notification_ = 0,
							from_background_ = 1,
							reply_markup_ = nil,
							input_message_content_ = {
								ID = "InputMessageText",
								text_ = matches,
								disable_web_page_preview_ = 1,
								clear_draft_ = 0,
								entities_ = {},
							parse_mode_ = nil
							},
						}, dl_cb, nil)
					end
                    			return send(msg.chat_id_, msg.id_, "<i>با موفقیت ارسال شد✅</i>")
				elseif text:match("^(block) (%d+)$") then
					local matches = text:match("%d+")
					rem(tonumber(matches))
					redis:sadd("botBOT-IDblockedusers",matches)
					tdcli_function ({
						ID = "BlockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>شخص مورد نظر با موفقیت بلاک شد✅</i>")
				elseif text:match("^(unblock) (%d+)$") then
					local matches = text:match("%d+")
					add(tonumber(matches))
					redis:srem("botBOT-IDblockedusers",matches)
					tdcli_function ({
						ID = "UnblockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>شخص مورد نظر با موفقیت از بلاک در اورده شد✅</i>")	
				elseif text:match('^(setname) "(.*)" (.*)') then
					local fname, lname = text:match('^setname "(.*)" (.*)')
					tdcli_function ({
						ID = "ChangeName",
						first_name_ = fname,
						last_name_ = lname
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>نام جدید با موفقیت تنظیم شد✅</i>")
				elseif text:match("^(setusername) (.*)") then
					local matches = text:match("^setusername (.*)")
						tdcli_function ({
						ID = "ChangeUsername",
						username_ = tostring(matches)
						}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>تلاش برای تنظیم نام کاربری♻️</i>')
				elseif text:match("^(delusername)$") then
					tdcli_function ({
						ID = "ChangeUsername",
						username_ = ""
					}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>نام کاربری با موفقیت حذف گردید✅</i>')
				elseif text:match('^(send pm) "(.*)" (.*)') then
					local id, txt = text:match('^Send pm "(.*)" (.*)')
					send(id, 0, txt)
					return send(msg.chat_id_, msg.id_, "<i>ارسال شد</i>")
				elseif text:match("^(echo) (.*)") then
					local matches = text:match("^Echo (.*)")
					return send(msg.chat_id_, 0, matches)
				elseif text:match("^(my id)$") then
					return send(msg.chat_id_, msg.id_, "<i>" .. msg.sender_user_id_ .."</i>")
				elseif text:match("^(leave) (.*)$") then
					local matches = text:match("^Leave (.*)$") 	
					send(msg.chat_id_, msg.id_, 'تبچی با موفقیت گروه مورد نظر خارج شد✅')
					tdcli_function ({
						ID = "ChangeChatMemberStatus",
						chat_id_ = matches,
						user_id_ = bot_id,
						status_ = {ID = "ChatMemberStatusLeft"},
					}, dl_cb, nil)
					return rem(matches)
				elseif text:match("^(addtoall) (%d+)$") then
					local matches = text:match("%d+")
					local list = {redis:smembers("botBOT-IDgroups"),redis:smembers("botBOT-IDsupergroups")}
					for a, b in pairs(list) do
						for i, v in pairs(b) do 
							tdcli_function ({
								ID = "AddChatMember",
								chat_id_ = v,
								user_id_ = matches,
								forward_limit_ =  50
							}, dl_cb, nil)
						end	
					end
					return send(msg.chat_id_, msg.id_, "<i>شخص مورد نظر به تمام گروه های من با موفقیت ادد شد✅</i>")
				elseif (text:match("^(ping)$") and not msg.forward_info_)then
					return tdcli_function({
						ID = "ForwardMessages",
						chat_id_ = msg.chat_id_,
						from_chat_id_ = msg.chat_id_,
						message_ids_ = {[0] = msg.id_},
						disable_notification_ = 0,
						from_background_ = 1
					}, dl_cb, nil)
				elseif text:match("^(help)$") then
					local txt = '📍راهنمای دستورات تبلیغ‌گر📍\n\n🔹ping\n<i>اعلام وضعیت تبلیغ‌گر ✔️</i>\n<code>❤️ حتی اگر تبلیغ‌گر شما دچار محدودیت ارسال پیام شده باشد بایستی به این پیام پاسخ دهد❤️</code>\n/reload\n<i>l🔄 بارگذاری مجدد ربات 🔄l</i>\n<code>I⛔️عدم استفاده بی جهت⛔️I</code>\n🔹update\n<i>بروزرسانی ربات به آخرین نسخه و بارگذاری مجدد 🆕</i>\n\n🔹promote [iD]\n<i>افزودن مدیر جدید با شناسه عددی داده شده 🛂</i>\n\n🔹setowner [iD]\n<i>افزودن مدیرکل جدید با شناسه عددی داده شده 🛂</i>\n\n<code>(⚠️ تفاوت مدیر و مدیر‌کل دسترسی به اعطا و یا گرفتن مقام مدیریت است⚠️)</code>\n\n🔹demote [iD]\n<i>حذف مدیر یا مدیرکل با شناسه عددی داده شده ✖️</i>\n\n🔹leave\n<i>خارج شدن از گروه و حذف آن از اطلاعات گروه ها 🏃</i>\n\n🔹addmembers\n<i>افزودن حداکثر مخاطبین و افراد در گفت و گوهای شخصی به گروه ➕</i>\n\n🔹my id\n<i>دریافت شناسه خود 🆔</i>\n\n🔹echo [text]\n<i>دریافت متن 🗣</i>\n\n🔹sendpm [iD] [text]\n<i>ارسال متن به شناسه گروه یا کاربر داده شده 📤</i>\n\n🔹setname [name]\n<i>تنظیم نام ربات ✏️</i>\n\n🔹ref\n<i>تازه‌سازی اطلاعات فردی ربات🎈</i>\n<code>(مورد استفاده در مواردی همچون پس از تنظیم نام📍جهت بروزکردن نام مخاطب اشتراکی تبلیغ‌گر📍)</code>\n\n🔹setusername [name]\n<i>جایگزینی اسم با نام کاربری فعلی(محدود در بازه زمانی کوتاه) 🔄</i>\n\n🔹delusername\n<i>حذف کردن نام کاربری ❎</i>\n\n🔹off j|t|+|a|s\n<i>غیر‌فعال کردن فرایند خواسته شده</i> ◼️\n\n🔹on j |t|+|a|s\n<i>فعال‌سازی فرایند خواسته شده</i> ◻️\n\n🔹addednumber on|off\n<i>تغییر وضعیت اشتراک شماره تبلیغ‌گر در جواب شماره به اشتراک گذاشته شده 🔖</i>\n\naddedmsg on|off\n<i>تغییر وضعیت ارسال پیام در جواب شماره به اشتراک گذاشته شده ℹ️</i>\n\n🔹setaddedmsg [text]\n<i>تنظیم متن داده شده به عنوان جواب شماره به اشتراک گذاشته شده 📨</i>\n\n🔹list contact|block|gp|sgp|autoanswer|link|owner|\n<i>دریافت لیستی از مورد خواسته شده در قالب پرونده متنی یا پیام 📄</i>\n\n🔹block [iD]\n<i>مسدود‌کردن(بلاک) کاربر با شناسه داده شده از گفت و گوی خصوصی 🚫</i>\n\n🔹Unblock [iD]\n<i>رفع مسدودیت کاربر با شناسه داده شده 💢</i>\n\n🔹markread on|off\n<i>تغییر وضعیت مشاهده پیام‌ها توسط تبلیغ‌گر (فعال و غیر‌فعال‌کردن تیک دوم)</i>\n\n🔹s | p\n<i>دریافت آمار و وضعیت تبلیغ‌گر 📊</i>\n\nوضعیت\n<i>دریافت وضعیت اجرایی تبلیغ‌گر⚙️</i>\n\n🔹ref\n<i>تازه‌سازی آمار تبلیغ‌گر🚀</i>\n<code>🎃مورد استفاده حداکثر یک بار در روز🎃</code>\n\n🔹fwd all|pv|gp|sgp\n<i>ارسال پیام جواب داده شده به مورد خواسته شده 📩</i>\n<code>(😄توصیه ما عدم استفاده از همه و خصوصی😄)</code>\n\n🔹send sgp [text]\n<i>ارسال متن داده شده به همه سوپرگروه ها ✉️</i>\n<code>(😜توصیه ما استفاده و ادغام دستورات بگو و ارسال به سوپرگروه😜)</code>\n\n🔹setanswer [text]\n<i>تنظیم جوابی به عنوان پاسخ خودکار به پیام وارد شده مطابق با متن باشد 📝</i>\n\n🔹delanswer\n<i>حذف جواب مربوط به متن ✖️</i>\n\n🔹autoanswer on|off\n<i>تغییر وضعیت پاسخگویی خودکار تبلیغ‌گر به متن های تنظیم شده 📯</i>\n\nحذف لینک عضویت|تایید|ذخیره شده\n<i>حذف لیست لینک‌های مورد نظر </i>❌\n\n🔹delall link|join|confirm|saved|\n<i>حذف کلی لیست لینک‌های مورد نظر </i>💢\n🔺<code>پذیرفتن مجدد لینک در صورت حذف کلی</code>🔻\n\n🔹addtoall [iD]\n<i>افزودن کابر با شناسه وارد شده به همه گروه و سوپرگروه ها ➕➕</i>\n\n🔹leave [iD]\n<i>عملیات ترک کردن با استفاده از شناسه گروه 🏃</i>\n\n🔹help\n<i>دریافت همین پیام 🆘</i>\n〰〰〰ا〰〰〰\n🔹reload\n<code>همگام سازی اطلاعات تبلیغ‌گر با اطلاعات تبچی از قبل نصب شده 🔃 (جهت این امر حتما به ویدیو آموزشی کانال مراجعه کنید)</code>\n〰〰〰ا〰〰〰\nسازنده : @DevMF \nکانال : @MaxFlyTM\n<i> داداچ تبچیم😐❤️</i>\n\n<code>آخرین اخبار و رویداد های تبلیغ‌گر را در کانال ما پیگیری کنید.</code>'
					return send(msg.chat_id_,msg.id_, txt)
				elseif tostring(msg.chat_id_):match("^-") then
					if text:match("^(leave)$") then
						rem(msg.chat_id_)
						return tdcli_function ({
							ID = "ChangeChatMemberStatus",
							chat_id_ = msg.chat_id_,
							user_id_ = bot_id,
							status_ = {ID = "ChatMemberStatusLeft"},
						}, dl_cb, nil)
					elseif text:match("^(addmembers)$") then
						tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},function(i, naji)
							local users, count = redis:smembers("botBOT-IDusers"), naji.total_count_
							for n=0, tonumber(count) - 1 do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = naji.users_[n].id_,
									forward_limit_ = 50
								},  dl_cb, nil)
							end
							for n=1, #users do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = users[n],
									forward_limit_ = 50
								},  dl_cb, nil)
							end
						end, {chat_id=msg.chat_id_})
						return send(msg.chat_id_, msg.id_, "<i>در حال افزودن همه مخاطبین به گروه...😐</i>")
					end
				end
			end
			if redis:sismember("botBOT-IDanswerslist", text) then
				if redis:get("botBOT-IDautoanswer") then
					if msg.sender_user_id_ ~= bot_id then
						local answer = redis:hget("botBOT-IDanswers", text)
						send(msg.chat_id_, 0, answer)
					end
				end
			end
		elseif (msg.content_.ID == "MessageContact" and redis:get("botBOT-IDsavecontacts")) then
			local id = msg.content_.contact_.user_id_
			if not redis:sismember("botBOT-IDaddedcontacts",id) then
				redis:sadd("botBOT-IDaddedcontacts",id)
				local first = msg.content_.contact_.first_name_ or "-"
				local last = msg.content_.contact_.last_name_ or "-"
				local phone = msg.content_.contact_.phone_number_
				local id = msg.content_.contact_.user_id_
				tdcli_function ({
					ID = "ImportContacts",
					contacts_ = {[0] = {
							phone_number_ = tostring(phone),
							first_name_ = tostring(first),
							last_name_ = tostring(last),
							user_id_ = id
						},
					},
				}, dl_cb, nil)
				if redis:get("botBOT-IDaddcontact") and msg.sender_user_id_ ~= bot_id then
					local fname = redis:get("botBOT-IDfname")
					local lnasme = redis:get("botBOT-IDlname") or ""
					local num = redis:get("botBOT-IDnum")
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = msg.id_,
						disable_notification_ = 1,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {
							ID = "InputMessageContact",
							contact_ = {
								ID = "Contact",
								phone_number_ = num,
								first_name_ = fname,
								last_name_ = lname,
								user_id_ = bot_id
							},
						},
					}, dl_cb, nil)
				end
			end
			if redis:get("botBOT-IDaddmsg") then
				local answer = redis:get("botBOT-IDaddmsgtext") or "اددی گلم خصوصی پیام بده"
				send(msg.chat_id_, msg.id_, answer)
			end
		elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
			return rem(msg.chat_id_)
		elseif (msg.content_.caption_ and redis:get("botBOT-IDlink"))then
			find_link(msg.content_.caption_)
		end
		if redis:get("botBOT-IDmarkread") then
			tdcli_function ({
				ID = "ViewMessages",
				chat_id_ = msg.chat_id_,
				message_ids_ = {[0] = msg.id_} 
			}, dl_cb, nil)
		end
	elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
		tdcli_function ({
			ID = "GetChats",
			offset_order_ = 9223372036854775807,
			offset_chat_id_ = 0,
			limit_ = 1000
		}, dl_cb, nil)
	end
end
