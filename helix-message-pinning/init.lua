-- vim: tabstop=4:shiftwidth=4:expandtab

-- Put your chatterino token between the quotes below (i.e. "abcdefghijklmnopqrstuvwzyx1234")
local chatterinoOauthTokenFromSettings = ""

local json = require('chatterino.json')

pinByIdCommand = "/pin-msg-id-plugin"
pinByIdUsage = "Usage: /pin-msg-id-plugin <message-id>"
function cmd_pin_message_by_id(ctx)
    if (#ctx.words < 2) then
        ctx.channel:add_system_message(pinByIdUsage)
        return
    end

    local msgId = ctx.words[2]
    local target = ctx.channel:find_message_by_id(msgId)
    if target == nil then
        ctx.channel:add_system_message("Message " .. msgId .. " not found, unable to pin it.")
        return
    end

    local currentUserId = c2.current_account():id()
    local channelId = ctx.channel:get_twitch_id()

    local request = c2.HTTPRequest.create(
        c2.HTTPMethod.Put, 
        -- No sanatization, wide hardo!
        -- TODO: pass in duration_seconds, not specifying = indefinite pin
        "https://api.twitch.tv/helix/chat/pins?broadcaster_id=" .. channelId .. "&moderator_id=" .. currentUserId .. "&message_id=" .. msgId
    )

    request:set_header("Accept", "application/json")
    request:set_header("Content-Type", "application/json")
    request:set_header("Client-Id", "g5zg0400k4vhrx2g6xi4hgveruamlv")
    request:set_header("Authorization", "Bearer " .. chatterinoOauthTokenFromSettings)

    request:on_success(function(response)
        local status = response:status()
        if (status ~= 204) then
            ctx.channel:add_system_message("Failed to pin, HTTP status " .. status)
            return
        end

        ctx.channel:add_system_message("Message from '" .. target.display_name .. "' pinned!")
    end)
    request:on_error(function(response)
        ctx.channel:add_system_message("Message pin failed with status " .. response:status() .. ": " .. response:error())
    end)

    request:execute()
end


unpinByIdCommand = "/unpin-msg-plugin"
function cmd_unpin(ctx)
    local currentUserId = c2.current_account():id();
    local channelId = ctx.channel:get_twitch_id()

    local request = c2.HTTPRequest.create(
        c2.HTTPMethod.Get, 
        "https://api.twitch.tv/helix/chat/pins?broadcaster_id=" .. channelId .. "&moderator_id=" .. currentUserId
    )

    request:set_header("Accept", "application/json")
    request:set_header("Content-Type", "application/json")
    request:set_header("Client-Id", "g5zg0400k4vhrx2g6xi4hgveruamlv")
    request:set_header("Authorization", "Bearer " .. chatterinoOauthTokenFromSettings)

    request:on_success(function(response)
        local status = response:status()
        if (status ~= 200) then
            ctx.channel:add_system_message("Failed to get current pinned message, HTTP status " .. status)
            return
        end

        unpin(ctx, response, currentUserId, channelId)
    end)
    request:on_error(function(response)
        ctx.channel:add_system_message("Unpin message (get) failed with status " .. response:status() .. ": " .. response:error())
    end)

    request:execute()
end

function unpin(ctx, get_response, currentUserId, channelId)
    local parsedResponse = json.parse(get_response:data())
    local messages = parsedResponse.data
    if (#messages == 0) then
        ctx.channel:add_system_message("No message is currently pinned.")
        return
    end

    local messageId = messages[1].message_id
    local request = c2.HTTPRequest.create(
        c2.HTTPMethod.Delete, 
        "https://api.twitch.tv/helix/chat/pins?broadcaster_id=" .. channelId .. "&moderator_id=" .. currentUserId .. "&message_id=" .. messageId
    )
    request:set_header("Client-Id", "g5zg0400k4vhrx2g6xi4hgveruamlv")
    request:set_header("Authorization", "Bearer " .. chatterinoOauthTokenFromSettings)

    request:on_success(function(response)
        local status = response:status()
        if (status ~= 204) then
            ctx.channel:add_system_message("Failed to unpin message, HTTP status " .. status)
            return
        end

        ctx.channel:add_system_message("Message unpinned :)")
    end)
    request:on_error(function(response)
        ctx.channel:add_system_message("Unpin message (delete) failed with status " .. response:status() .. ": " .. response:error())
    end)

    request:execute()
end

c2.register_command(pinByIdCommand, cmd_pin_message_by_id)
c2.register_command(unpinByIdCommand, cmd_unpin)
