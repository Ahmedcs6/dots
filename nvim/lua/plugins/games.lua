local minimal = false

return {
  -- Games
  --------------------------------------------------------------------------------
  { 'ThePrimeagen/vim-be-good', cmd = 'VimBeGood', cond = not minimal },
  {
    'NStefan002/speedtyper.nvim',
    cmd = 'Speedtyper',
    cond = not minimal,
    opts = {},
  },
 }
