# Neovim config (LazyVim-based)

Based on [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [LazyVim documentation](https://lazyvim.github.io/installation) to get started.

## Structure

- `init.lua` — bootstraps `lazy.nvim` only; `config.options`, `config.keymaps`,
  and `config.autocmds` are loaded automatically by LazyVim in the correct order.
- `lua/config/options.lua` — spaces, width 4 (matches `stylua.toml`).
- `lua/config/keymaps.lua` — extra maps (`jk` to exit insert/terminal mode).
- `lua/plugins/roslyn.lua` — C# / .NET via `roslyn.nvim`.
- `lua/plugins/dap.lua` — debug adapters: C++ via `codelldb`,
  .NET via `netcoredbg` (kept separate from `lang.dotnet` to avoid
  omnisharp, since C# LSP is `roslyn.nvim`). Also ensures
  `codelldb` / `netcoredbg` / `csharpier` via Mason and `c_sharp`
  treesitter.
- `lua/plugins/neotest.lua` — test runner via `neotest` + `neotest-vstest`
  for .NET (all frameworks, slnx-aware; kept separate from `lang.dotnet`
  to avoid omnisharp). Replaces `Issafalcon/neotest-dotnet`, which crashed
  on neotest 5.20 with empty file specs.

## Formatting

Lua is formatted with `stylua` (spaces, width 4, col 120). Run `stylua --check .`
from this directory. Other languages are handled by `conform.nvim`; install the
backing tools you use (`black`, `prettier`, `clang-format`, `csharpier`).

## Debugging (.NET & C++)

Extras enabled in `lazyvim.json`: `dap.core` (nvim-dap + dap-ui +
virtual-text), `lang.clangd` (codelldb adapter for C/C++) and
`test.core` (neotest + Trouble integration).
Debuggers are installed via Mason: `codelldb`, `netcoredbg`.

Keys (from `dap.core`): `<leader>db` toggle breakpoint,
`<leader>dc` run/continue, `<leader>da` run with args,
`<leader>dO` step over, `<leader>di` step into, `<leader>do` step out,
`<leader>du` toggle UI, `<leader>dt` terminate. `.vscode/launch.json`
is also picked up.

- C++: `g++ -g main.cpp -o main`, open the source, `<leader>db`,
  `<leader>dc`, enter `./main` when prompted.
- .NET: `dotnet build` (Debug), open a `.cs` file, `<leader>db`,
  `<leader>dc`, enter path to the built `bin/Debug/.../*.dll` when prompted.

## Testing (.NET via neotest-vstest)

Keys (from `test.core`): `<leader>tt` run file, `<leader>tr` run nearest,
`<leader>tl` run last, `<leader>ts` toggle summary, `<leader>to` show output,
`<leader>tw` toggle watch. `<leader>td` debugs nearest via `netcoredbg`
(standard DAP strategy).

- Open e.g. `tests/.../AuthTests.cs`, `<leader>tr` runs nearest `[Fact]`,
  `<leader>tt` runs whole file via VSTest discovery (works with `slnx`).
- The summary opens immediately on run (visible progress); the output
  window opens when results arrive. First run is slow (`dotnet` build +
  Testcontainers SQL Server) — watch `<leader>ts` / `<leader>tO` meanwhile.
