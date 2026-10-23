-- =============================================================================
-- minh.gp_images — send images pasted in a gp.nvim chat to Gemini
--
-- gp only sends text. In a chat, <leader>p (img-clip) saves the clipboard image
-- under gp_chat_dir/images and inserts ![](/abs/path.png). Before gp sends the
-- request, the images referenced in the LAST question are attached as
-- inline_data parts. Older questions keep only the text, so an image is sent
-- once, with the question it belongs to, not again with every follow-up.
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
      local img, err = image_part(vim.fn.expand(path))
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
  local prepare = dispatcher.prepare_payload
  dispatcher.prepare_payload = function(messages, model, provider)
    local payload = prepare(messages, model, provider)
    if provider == "googleai" then
      M.attach(payload)
    end
    return payload
  end
end

return M
