local CONFIG = {}
local EXTENSION_NAME = "TRAK"

local function map(t, predicate)
    local new = {}
    for key, value in pairs(t) do
        table.insert(new, predicate(key, value))
    end
    return new
end

local function sanitize_name(text)
    return text:lower():gsub("[ -_]", "")
end

local function get_config_path()
    local sep = package.config:sub(1, 1)
    return vlc.config.userdatadir() .. sep .. EXTENSION_NAME:lower() .. ".xml"
end

local function get_debug_config(config)
    return table.concat(
        map(config, function(key, _)
            return key
        end),
        ", "
    )
end

local function load_config_attr(value)
    return tonumber(value, 10) or value
end

local function load_config_item(item, config)
    if not item then
        return
    elseif item.name == "media" then
        config[item.value] = {
            audio = load_config_attr(item.attributes.audio),
            subtitle = load_config_attr(item.attributes.subtitle),
        }
    else
        vlc.msg.warn(
            ("[%s] Unexpected item in configuration: %q"):format(
                EXTENSION_NAME,
                item.name
            )
        )
    end
end

local function load_xml_attr(xml_reader)
    local attributes = {}
    local attr_name, attr_value = xml_reader:next_attr()

    while attr_name do
        attributes[attr_name] = attr_value
        attr_name, attr_value = xml_reader:next_attr()
    end
    return attributes
end

local function load_xml_node(xml_reader, parent, config)
    local status, value = xml_reader:next_node()
    -- New node
    if status == 1 then
        status = load_xml_node(
            xml_reader,
            { name = value, attributes = load_xml_attr(xml_reader) },
            config
        )
    -- Close node
    elseif status == 2 then
        load_config_item(parent, config)
        status = load_xml_node(xml_reader, nil, config)
    -- Value from node
    elseif status == 3 then
        parent.value = value
        status = load_xml_node(xml_reader, parent, config)
    end
    return status
end

local function load_config(config_path)
    local config = {}
    local file = vlc.io.open(config_path, "r")

    if not file then
        vlc.msg.info(
            ("[%s] No configuration file at %q"):format(
                EXTENSION_NAME,
                config_path
            )
        )
        return {}
    end
    local stream = vlc.memory_stream(file:read("*a"))
    local xml_reader = vlc.xml():create_reader(stream)
    if load_xml_node(xml_reader, nil, config) == -1 then
        vlc.msg.error(
            ("[%s] Could not load configuration at %q. XML is invalid"):format(
                EXTENSION_NAME,
                config_path
            )
        )
        return {}
    end
    vlc.msg.info(
        ("[%s] Loaded configuration at %q: Available medias: %s"):format(
            EXTENSION_NAME,
            config_path,
            get_debug_config(config)
        )
    )
    return config
end

local function get_media_identifier()
    local item = vlc.player.item()

    if not item then
        return nil
    end
    return vlc.strings.url_parse(item:uri())["path"]
end

local function get_media_config(config, item_name)
    item_name = sanitize_name(item_name)
    for key, _ in pairs(config) do
        local name = sanitize_name(key)
        if item_name:find(name) then
            return key
        end
    end
    return nil
end

local function should_toggle_track(index, track, value)
    if value == -1 then
        -- toggle if track is selected
        return track.selected
    elseif type(value) == "number" then
        return value == index and not track.selected
    elseif type(value) == "string" then
        return sanitize_name(track.name):find(sanitize_name(value))
            and not track.selected
    end
    return false
end

local function use_track(tracks, config_value, toggle_func)
    if config_value == nil then
        return
    end
    for i, track in ipairs(tracks) do
        if should_toggle_track(i - 1, track, config_value) then
            vlc.msg.info(
                ("[%s] Toggle track %q per config (%s)"):format(
                    EXTENSION_NAME,
                    track.name,
                    config_value
                )
            )
            toggle_func(track.id)
        end
    end
end

local function update_language(global_config, item_name)
    local config_name = get_media_config(global_config, item_name)
    if config_name then
        vlc.msg.info(
            ("[%s] Configuration = %q found for %q"):format(
                EXTENSION_NAME,
                config_name,
                item_name
            )
        )
        local config = CONFIG[config_name]
        use_track(
            vlc.player.get_audio_tracks(),
            config.audio,
            vlc.player.toggle_audio_track
        )
        use_track(
            vlc.player.get_spu_tracks(),
            config.subtitle,
            vlc.player.toggle_spu_track
        )
    else
        vlc.msg.info(
            ("[%s] Configuration not found for %q"):format(
                EXTENSION_NAME,
                item_name
            )
        )
    end
end

function descriptor()
    return {
        title = EXTENSION_NAME,
        version = "0.0.1",
        author = "theo-ardouin",
        url = "https://github.com/theo-ardouin/vlc-trak",
        description = "Allows to select a preferred language per configuration",
        capabilities = { "playing-listener", "input-listener" },
    }
end

function activate()
    CONFIG = load_config(get_config_path())
    local media_identifier = get_media_identifier()
    if media_identifier then
        update_language(CONFIG, media_identifier)
    end
end

-- Using playing_changed as input_changed is not working
-- https://code.videolan.org/videolan/vlc/-/issues/27558
function playing_changed()
    update_language(CONFIG, get_media_identifier())
end

function input_changed()
    update_language(CONFIG, get_media_identifier())
end
