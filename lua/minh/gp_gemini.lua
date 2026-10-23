-- =============================================================================
-- minh.gp_gemini — what gp.nvim does not do for Gemini
--
-- 1. System prompt. gp turns it into a plain user message at the start of the
--    chat, so Gemini answers "Understood. I will..." to it (and that reply
--    becomes the chat topic). Send it as systemInstruction instead, like gp
--    already does for Anthropic.
-- 2. Images. In a chat, <leader>p (img-clip) saves the clipboard image under
--    gp_chat_dir/images and inserts ![](path). The images referenced in the
--    LAST question are attached as inline_data parts, so an image is sent once,
--    with its question, not again with every follow-up.
-- =============================================================================

local M = {}

M.image_dir = require("minh.utils").gp_chat_dir .. "/images"

local MIME = { png = "image/png", jpg = "image/jpeg", jpeg = "image/jpeg", webp = "image/webp" }
local MAX_BYTES = 15 * 1024 * 1024 -- Gemini caps a whole inline request at 20 MB

--- inline_data part for the image at `path`, or nil and the reason.
local function image_part(path)
  local mime = MIME[(path:match("%.(%w+)$") or ""):lower()]
  if not mime then
    return nil, "unsupported image type"
  end
  local f = io.open(path, "rb")
  if not f then
    return nil, "file not found"
  end
  local data = f:read("*a")
  f:close()
  if #data > MAX_BYTES then
    return nil, "larger than 15 MB"
  end
  return { inline_data = { mime_type = mime, data = vim.base64.encode(data) } }
end

--- Absolute path of an image reference. Like markdown, a relative path is
--- relative to the chat file (gp asks from the chat buffer), not to the cwd.
local function resolve(path)
  path = vim.fn.expand(path)
  if path:sub(1, 1) == "/" then
    return path
  end
  local base = vim.fn.expand("%:p:h")
  if base == "" then
    base = require("minh.utils").gp_chat_dir
  end
  return vim.fs.normalize(base .. "/" .. path)
end

--- Add the images of the last user turn in a googleai `payload` (in place).
function M.attach(payload)
  local contents = payload and payload.contents
  local last = contents and contents[#contents]
  if not last or last.role ~= "user" then
    return payload
  end

  local images = {}
  for _, part in ipairs(last.parts) do
    for path in (part.text or ""):gmatch("!%[.-%]%((.-)%)") do
      local img, err = image_part(resolve(path))
      if img then
        images[#images + 1] = img
      else
        vim.notify("gp image skipped (" .. err .. "): " .. path, vim.log.levels.WARN)
      end
    end
  end
  vim.list_extend(last.parts, images)
  return payload
end

--- Wrap gp's payload builder. Call after require("gp").setup().
function M.setup()
  local dispatcher = require("gp").dispatcher
  -- Keep gp's own builder so running setup again (:Lazy reload) replaces the
  -- wrapper instead of stacking another one on top.
  dispatcher._prepare_payload = dispatcher._prepare_payload or dispatcher.prepare_payload
  local prepare = dispatcher._prepare_payload
  dispatcher.prepare_payload = function(messages, model, provider)
    if provider ~= "googleai" then
      return prepare(messages, model, provider)
    end
    local system, rest = {}, {}
    for _, message in ipairs(messages) do
      table.insert(message.role == "system" and system or rest, message)
    end
    -- Gemini rejects a request without contents (e.g. responding to a chat
    -- with no question yet): then the system prompt has to stay a message.
    if #rest == 0 then
      return prepare(messages, model, provider)
    end
    local payload = prepare(rest, model, provider)
    if #system > 0 then
      payload.systemInstruction = {
        parts = vim.tbl_map(function(message)
          return { text = message.content }
        end, system),
      }
    end
    return M.attach(payload)
  end
end

return M
