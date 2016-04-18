
local function pre_process(msg)
  local data = load_data(_config.moderation.data)
  -- SERVICE MESSAGE
  if msg.action and msg.action.type then
    local action = msg.action.type
    -- Check if sicked user joins chat by link
    if action == 'chat_add_user_link' then
      local user_id = msg.from.id
      print('Checking invited user '..user_id)
      local sicked = is_sicked(user_id, msg.to.id)
      if sicked or is_gsicked(user_id) then -- Check it with redis
      print('User is sicked!')
      local print_name = user_print_name(msg.from):gsub("‮", "")
	  local name = print_name:gsub("_", "")
      savelog(msg.to.id, name.." ["..msg.from.id.."] is user siked this gp! ")-- Save to logs
      kick_user(user_id, msg.to.id)
      end
    end
    -- Check if sicked user joins chat
    if action == 'chat_add_user' then
      local user_id = msg.action.user.id
      print('Checking invited user '..user_id)
      local sicked = is_sicked(user_id, msg.to.id)
      if sicked and not is_momod2(msg.from.id, msg.to.id) or is_gsicked(user_id) and not is_admin2(msg.from.id) then -- Check it with redis
        print('User is sicked!')
      local print_name = user_print_name(msg.from):gsub("‮", "")
	  local name = print_name:gsub("_", "")
        savelog(msg.to.id, name.." ["..msg.from.id.."] added a sicked user >"..msg.action.user.id)-- Save to logs
        kick_user(user_id, msg.to.id)
        local sickhash = 'addedbanuser:'..msg.to.id..':'..msg.from.id
        redis:incr(sickhash)
        local sickhash = 'addedsickuser:'..msg.to.id..':'..msg.from.id
        local sickaddredis = redis:get(sickhash)
        if sickaddredis then
          if tonumber(sickaddredis) >= 4 and not is_owner(msg) then
            kick_user(msg.from.id, msg.to.id)-- Kick user who adds ban ppl more than 3 times
          end
          if tonumber(sickaddredis) >=  8 and not is_owner(msg) then
            sick_user(msg.from.id, msg.to.id)-- Kick user who adds ban ppl more than 7 times
            local sickhash = 'addedsickuser:'..msg.to.id..':'..msg.from.id
            redis:set(sickhash, 0)-- Reset the Counter
          end
        end
      end
     if data[tostring(msg.to.id)] then
       if data[tostring(msg.to.id)]['settings'] then
         if data[tostring(msg.to.id)]['settings']['lock_bots'] then
           bots_protection = data[tostring(msg.to.id)]['settings']['lock_bots']
          end
        end
      end
    if msg.action.user.username ~= nil then
      if string.sub(msg.action.user.username:lower(), -3) == 'bot' and not is_momod(msg) and bots_protection == "yes" then --- Will kick bots added by normal users
          local print_name = user_print_name(msg.from):gsub("‮", "")
		  local name = print_name:gsub("_", "")
          savelog(msg.to.id, name.." ["..msg.from.id.."] added a bot > @".. msg.action.user.username)-- Save to logs
          kick_user(msg.action.user.id, msg.to.id)
      end
    end
  end
    -- No further checks
  return msg
  end
  -- sicked user is talking !
  if msg.to.type == 'chat' or msg.to.type == 'channel' then
    local group = msg.to.id
    local texttext = 'groups'
    --if not data[tostring(texttext)][tostring(msg.to.id)] and not is_realm(msg) then -- Check if this group is one of my groups or not
    --chat_del_user('chat#id'..msg.to.id,'user#id'..our_id,ok_cb,false)
    --return
    --end
    local user_id = msg.from.id
    local chat_id = msg.to.id
    local sicked = is_sicked(user_id, chat_id)
    if sicked or is_gsicked(user_id) then -- Check it with redis
      print('sicked user talking!')
      local print_name = user_print_name(msg.from):gsub("‮", "")
	  local name = print_name:gsub("_", "")
      savelog(msg.to.id, name.." ["..msg.from.id.."] sicked user is talking !")-- Save to logs
      kick_user(user_id, chat_id)
      msg.text = ''
    end
  end
  return msg
end

local function kick_sick_res(extra, success, result)
      local chat_id = extra.chat_id
	  local chat_type = extra.chat_type
	  if chat_type == "chat" then
		receiver = 'chat#id'..chat_id
	  else
		receiver = 'channel#id'..chat_id
	  end
	  if success == 0 then
		return send_large_msg(receiver, "Cannot find user by that username!")
	  end
      local member_id = result.peer_id
      local user_id = member_id
      local member = result.username
	  local from_id = extra.from_id
      local get_cmd = extra.get_cmd
       if get_cmd == "kick" then
         if member_id == from_id then
            send_large_msg(receiver, "You can't kick yourself")
			return
         end
         if is_momod2(member_id, chat_id) and not is_admin2(sender) then
            send_large_msg(receiver, "You can't kick mods/owner/admins")
			return
         end
		 kick_user(member_id, chat_id)
      elseif get_cmd == 'sick' then
        if is_momod2(member_id, chat_id) and not is_admin2(sender) then
			send_large_msg(receiver, "You can't sick mods/owner/admins")
			return
        end
        send_large_msg(receiver, 'User @'..member..' ['..member_id..'] sicked')
		sick_user(member_id, chat_id)
      elseif get_cmd == 'unsick' then
        send_large_msg(receiver, 'User @'..member..' ['..member_id..'] unsicked')
        local hash =  'sicked:'..chat_id
        redis:srem(hash, member_id)
        return 'User '..user_id..' unsicked'
      elseif get_cmd == 'sickall' then
        send_large_msg(receiver, 'User @'..member..' ['..member_id..'] globally sicked')
		sickall_user(member_id)
      elseif get_cmd == 'unsickall' then
        send_large_msg(receiver, 'User @'..member..' ['..member_id..'] globally unsicked')
	    unsickall_user(member_id)
    end
end

local function run(msg, matches)
local support_id = msg.from.id
 if matches[1]:lower() == 'id' and msg.to.type == "chat" or msg.to.type == "user" then
    if msg.to.type == "user" then
      return "Bot ID: "..msg.to.id.. "\n\nYour ID: "..msg.from.id
    end
    if type(msg.reply_id) ~= "nil" then
      local print_name = user_print_name(msg.from):gsub("‮", "")
	  local name = print_name:gsub("_", "")
        savelog(msg.to.id, name.." ["..msg.from.id.."] used /id ")
        id = get_message(msg.reply_id,get_message_callback_id, false)
    elseif matches[1]:lower() == 'id' then
      local name = user_print_name(msg.from)
      savelog(msg.to.id, name.." ["..msg.from.id.."] used /id ")
      return "Group ID for " ..string.gsub(msg.to.print_name, "_", " ").. ":\n\n"..msg.to.id
    end
  end
  if matches[1]:lower() == 'kickme' and msg.to.type == "chat" then-- /kickme
  local receiver = get_receiver(msg)
    if msg.to.type == 'chat' then
      local print_name = user_print_name(msg.from):gsub("‮", "")
	  local name = print_name:gsub("_", "")
      savelog(msg.to.id, name.." ["..msg.from.id.."] left using kickme ")-- Save to logs
      chat_del_user("chat#id"..msg.to.id, "user#id"..msg.from.id, ok_cb, false)
    end
  end

  if not is_momod(msg) then -- Ignore normal users
    return
  end

  if matches[1]:lower() == "sicklist" then -- sick list !
    local chat_id = msg.to.id
    if matches[2] and is_admin1(msg) then
      chat_id = matches[2]
    end
    return sick_list(chat_id)
  end
  if matches[1]:lower() == 'sick' then-- /sick
    if type(msg.reply_id)~="nil" and is_momod(msg) then
      if is_admin1(msg) then
		msgr = get_message(msg.reply_id,sick_by_reply_admins, false)
      else
        msgr = get_message(msg.reply_id,sick_by_reply, false)
      end
      local user_id = matches[2]
      local chat_id = msg.to.id
    elseif string.match(matches[2], '^%d+$') then
        if tonumber(matches[2]) == tonumber(our_id) then
         	return
        end
        if not is_admin1(msg) and is_momod2(matches[2], msg.to.id) then
          	return "you can't sick mods/owner/admins"
        end
        if tonumber(matches[2]) == tonumber(msg.from.id) then
          	return "You can't sick your self !"
        end
        local print_name = user_print_name(msg.from):gsub("‮", "")
	    local name = print_name:gsub("_", "")
		local receiver = get_receiver(msg)
        savelog(msg.to.id, name.." ["..msg.from.id.."] sicked user ".. matches[2])
        ban_user(matches[2], msg.to.id)
		send_large_msg(receiver, 'User ['..matches[2]..'] sicked')
      else
		local cbres_extra = {
		chat_id = msg.to.id,
		get_cmd = 'sicked',
		from_id = msg.from.id,
		chat_type = msg.to.type
		}
		local username = string.gsub(matches[2], '@', '')
		resolve_username(username, kick_sick_res, cbres_extra)
    end
  end


  if matches[1]:lower() == 'unsick' then -- /unsick
    if type(msg.reply_id)~="nil" and is_momod(msg) then
      local msgr = get_message(msg.reply_id,unsick_by_reply, false)
    end
      local user_id = matches[2]
      local chat_id = msg.to.id
      local targetuser = matches[2]
      if string.match(targetuser, '^%d+$') then
        	local user_id = targetuser
        	local hash =  'sicked:'..chat_id
        	redis:srem(hash, user_id)
        	local print_name = user_print_name(msg.from):gsub("‮", "")
			local name = print_name:gsub("_", "")
        	savelog(msg.to.id, name.." ["..msg.from.id.."] unsicked user ".. matches[2])
        	return 'User '..user_id..' unsicked'
      else
		local cbres_extra = {
			chat_id = msg.to.id,
			get_cmd = 'unsick',
			from_id = msg.from.id,
			chat_type = msg.to.type
		}
		local username = string.gsub(matches[2], '@', '')
		resolve_username(username, kick_sick_res, cbres_extra)
	end
 end

if matches[1]:lower() == 'kick' then
    if type(msg.reply_id)~="nil" and is_momod(msg) then
      if is_admin1(msg) then
        msgr = get_message(msg.reply_id,Kick_by_reply_admins, false)
      else
        msgr = get_message(msg.reply_id,Kick_by_reply, false)
      end
	elseif string.match(matches[2], '^%d+$') then
		if tonumber(matches[2]) == tonumber(our_id) then
			return
		end
		if not is_admin1(msg) and is_momod2(matches[2], msg.to.id) then
			return "you can't kick mods/owner/admins"
		end
		if tonumber(matches[2]) == tonumber(msg.from.id) then
			return "You can't kick your self !"
		end
    local user_id = matches[2]
    local chat_id = msg.to.id
		local print_name = user_print_name(msg.from):gsub("‮", "")
		local name = print_name:gsub("_", "")
		savelog(msg.to.id, name.." ["..msg.from.id.."] kicked user ".. matches[2])
		kick_user(user_id, chat_id)
	else
		local cbres_extra = {
			chat_id = msg.to.id,
			get_cmd = 'kick',
			from_id = msg.from.id,
			chat_type = msg.to.type
		}
		local username = string.gsub(matches[2], '@', '')
		resolve_username(username, kick_ban_res, cbres_extra)
	end
end


	if not is_admin1(msg) and not is_support(support_id) then
		return
	end

  if matches[1]:lower() == 'sickall' and is_admin1(msg) then -- Global sick
    if type(msg.reply_id) ~="nil" and is_admin1(msg) then
      sickall = get_message(msg.reply_id,sickall_by_reply, false)
    end
    local user_id = matches[2]
    local chat_id = msg.to.id
      local targetuser = matches[2]
      if string.match(targetuser, '^%d+$') then
        if tonumber(matches[2]) == tonumber(our_id) then
         	return false
        end
        	sickall_user(targetuser)
       		return 'User ['..user_id..' ] globally sicked'
     else
	local cbres_extra = {
		chat_id = msg.to.id,
		get_cmd = 'sickall',
		from_id = msg.from.id,
		chat_type = msg.to.type
	}
		local username = string.gsub(matches[2], '@', '')
		resolve_username(username, kick_sick_res, cbres_extra)
      end
  end
  if matches[1]:lower() == 'unsickall' then -- Global unsick
    local user_id = matches[2]
    local chat_id = msg.to.id
      if string.match(matches[2], '^%d+$') then
        if tonumber(matches[2]) == tonumber(our_id) then
          	return false
        end
       		unsickall_user(user_id)
        	return 'User ['..user_id..' ] globally unsicked'
    else
		local cbres_extra = {
			chat_id = msg.to.id,
			get_cmd = 'unsickall',
			from_id = msg.from.id,
			chat_type = msg.to.type
		}
		local username = string.gsub(matches[2], '@', '')
		resolve_username(username, kick_sick_res, cbres_extra)
      end
  end
  if matches[1]:lower() == "gsicklist" then -- Global ban list
    return sickall_list()
  end
end

return {
  patterns = {
    "^[#!/]([Ss]ickall) (.*)$",
    "^[#!/]([Ss]ickall)$",
    "^[#!/]([Bb]anlist) (.*)$",
    "^[#!/]([Bb]anlist)$",
    "^[#!/]([Gg]banlist)$",
	"^[#!/]([Kk]ickme)",
    "^[#!/]([Kk]ick)$",
	"^[#!/]([Ss]ick)$",
    "^[#!/]([Ss]ick) (.*)$",
    "^[#!/]([Uu]nsick) (.*)$",
    "^[#!/]([Uu]nsickall) (.*)$",
    "^[#!/]([Uu]nsickall)$",
    "^[#!/]([Kk]ick) (.*)$",
    "^[#!/]([Uu]nsick)$",
    "^[#!/]([Ii]d)$",
    "^!!tgservice (.+)$"
  },
  run = run,
  pre_process = pre_process
}
