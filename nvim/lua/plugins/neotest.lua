-- Test runner via neotest (.NET only).
-- LazyVim's `test.core` extra provides nvim-neotest/neotest + deps
-- (plenary, treesitter, nvim-nio) and the default <leader>t keymaps.
-- This file adds the VSTest adapter (kept separate from `lang.dotnet`
-- to avoid pulling in omnisharp, since this config uses roslyn.nvim).
-- NOTE: replaces Issafalcon/neotest-dotnet (unmaintained, crashes on
-- neotest 5.20: empty file spec -> spec.context nil at results:164,
-- specs[1] nil at build_spec:150). neotest-vstest is maintained,
-- slnx-aware, and supports all frameworks + standard DAP strategy.
return {
    {
        "nvim-neotest/neotest",
        optional = true,
        dependencies = {
            "Nsidorenco/neotest-vstest",
        },
        opts = {
            adapters = {
                ["neotest-vstest"] = {},
            },
            -- `output.open_on_run` (from test.core) only shows once
            -- results arrive, and `dotnet test` takes minutes on first
            -- run (build + Testcontainers). Open the summary immediately
            -- so there is visible progress feedback.
            consumers = {
                auto_summary = function(client)
                    client.listeners.starting = function()
                        vim.schedule(function()
                            require("neotest").summary.open()
                        end)
                    end
                    return {}
                end,
            },
        },
    },
}
