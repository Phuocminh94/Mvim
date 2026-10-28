-- basedpyright defaults to "recommended", which turns on dozens of strict rules
-- (reportUnknown*, reportMissingParameterType, ...) and makes the server do much more work
-- on every keystroke. "standard" keeps completion, hover and the usual type errors.
return {
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "standard",
      },
    },
  },
}
