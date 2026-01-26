-- vim: tabstop=4:shiftwidth=4:expandtab

local json = require('chatterino.json')

function url_encode(str)
    str = string.gsub(str, "([^%w %-%_%.%~])", 
        function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(str, " ", "+")
end

function cmd_translate(ctx)
    -- Syntax: /translate [from:LANG] [to:LANG] [engine:ENGINE] <text>
    ctx.channel:add_system_message("Not implemented lmao" .. ctx.words[2])
end

-- Обязательно приеду к вам снова
function cmd_translate_msg(ctx)
    -- Syntax: /translate-message [from:LANG] [to:LANG] [engine:ENGINE] <message-id>
    -- NOTE: this method is just me testing shit, and doesn't reflect the actual implementation

    local msgId = ctx.words[2]
    local target = ctx.channel:find_message_by_id(msgId)
    if target == nil then
        ctx.channel:add_system_message("Message " .. msgId .. " not found - unable to translate.")
        return
    end

    local request = c2.HTTPRequest.create(
        c2.HTTPMethod.Get, 
        "https://mozhi.pussthecat.org/api/translate?engine=google&from=auto&to=en&text=" .. url_encode(target.message_text)
    )

    request:set_header("Accept", "application/json")
    request:set_header("User-Agent", "curl/8.14.1")

    request:on_success(function(response)
        local data = response:data()
        local parsedResponse = json.parse(data)

        local detectedLang = parsedResponse.detected
        local translatedText = parsedResponse["translated-text"]

        local newMessage = c2.Message.new({
            id = "mohzi-translate-" .. msgId,
            flags = c2.MessageFlag.ElevatedMessage,
            elements = {
                {
                    -- time will default to now
                    type = "timestamp"
                },
                {
                    type = "mention",
                    login_name = target.login_name,
                    display_name = target.display_name,
                    user_color = target.username_color,
                    -- TODO: pull from original element?
                    fallback_color = target.username_color
                },
                {
                    type = "text",
                    text = "said [in " .. detectedLang .. "]: " .. translatedText
                }
            }
        })

        ctx.channel:add_message(newMessage)
    end)
    request:on_error(function(response)
        ctx.channel:add_system_message("Not implemented (error). " .. response:status() .. ": " .. response:error())
    end)

    request:execute()
    -- TODO: on error etc.
end

function cmd_configure()
    -- Syntax:
    --   /translate-config set engine google
    --   /translate-config set lang en
    --   /translate-config set backend https://mozhi.pussthecat.org/api/
    ctx.channel:add_system_message("Not implemented lmao")
end

c2.register_command("/translate", cmd_translate)
c2.register_command("/translate-message", cmd_translate_msg)
c2.register_command("/translate-config", cmd_configure)
