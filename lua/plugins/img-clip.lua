return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  cmd = { "PasteImage" },
  opts = {
    custom = {
      -- In a gp.nvim chat: absolute path under the chat dir, so minh.gp_images
      -- can find the image whatever the cwd is, and no file name prompt.
      {
        trigger = function()
          return require("minh.utils").is_gp_chat(0)
        end,
        dir_path = function()
          return require("minh.gp_images").image_dir
        end,
        use_absolute_path = true,
        relative_template_path = false,
        prompt_for_file_name = false,
        template = "![]($FILE_PATH)",
      },
    },
  },
}
