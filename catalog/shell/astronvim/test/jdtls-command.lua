local setup = dofile(vim.env.LMX_INIT)
local base = vim.env.TMPDIR
vim.fn.mkdir(base .. "/parsers/parser", "p")
vim.fn.mkdir(base .. "/parsers/queries", "p")
local options
package.preload.lazy = function()
  return { setup = function(specs)
    for _, spec in ipairs(specs) do
      if spec[1] == "AstroNvim/astrolsp" then
        options = {}
        spec.opts(nil, options)
      end
    end
  end }
end
local function configure(configuration)
  local other = { "/test/gopls", "--stdio" }
  setup({
    lazy = base .. "/lazy", astro = base .. "/astro", catppuccin = base .. "/catppuccin",
    parsers = base .. "/parsers", plugins = {},
    servers = { jdtls = configuration, gopls = { cmd = other } },
  }, "system")
  assert(vim.deep_equal(options.config.gopls.cmd, other), "non-Java server command changed")
  return options.config.jdtls
end

for _, configuration in ipairs({
  {}, { cmd = function() end }, { cmd = "jdtls" },
  { cmd = {} }, { cmd = { "/test/jdtls", 42 } }, { cmd = { executable = "/test/jdtls" } },
}) do
  assert(vim.deep_equal(configure(configuration), configuration), "non-argv command changed")
end

local original = { "/test/jdtls", "--jvm-arg=-javaagent:/test/lombok.jar" }
local cwd = vim.fn.getcwd()
local dispatchers, environment = {}, { JDTLS_PROBE = "retained" }
local captured, capturedOptions
local start = vim.lsp.rpc.start
vim.lsp.rpc.start = function(cmd, handlers, options)
  assert(handlers == dispatchers, "jdtls dispatchers changed")
  assert(options.cwd == cwd and options.detached == false, "jdtls RPC options changed")
  captured, capturedOptions = cmd, options
  return {}
end

local ok, failure = pcall(function()
  for _, arguments in ipairs({ {}, { "-data", "/chosen/workspace" }, { "-data=/chosen/workspace" } }) do
    local declared = vim.list_extend(vim.deepcopy(original), arguments)
    local saved = vim.deepcopy(declared)
    local command = configure({ cmd = declared }).cmd
    assert(type(command) == "function", "jdtls command does not pass project context")
    for _, root in ipairs({ "/projects/one/service", "/projects/two/service" }) do
      command(dispatchers, { root_dir = root, cmd_cwd = cwd, cmd_env = environment, detached = false })
      assert(vim.deep_equal(captured, saved), "jdtls executable or supplied arguments changed")
      assert(capturedOptions.env.LMX_JDTLS_ROOT == root, "jdtls received the wrong project root")
      assert(capturedOptions.env.JDTLS_PROBE == "retained", "jdtls environment was lost")
      assert(environment.LMX_JDTLS_ROOT == nil, "jdtls mutated the configured environment")
      assert(vim.fn.getcwd() == cwd, "jdtls command changed the editor working directory")
    end
    command(dispatchers, { cmd_cwd = cwd, cmd_env = environment, detached = false })
    assert(vim.deep_equal(capturedOptions.env, environment), "rootless command changed the environment")
    assert(vim.deep_equal(declared, saved), "starting jdtls mutated the provider declaration")
  end
end)
vim.lsp.rpc.start = start
assert(ok, failure)

local root = base .. "/project"
vim.fn.mkdir(root, "p")
local initialized, stopped = false, false
vim.lsp.rpc.start = function(cmd, handlers, options)
  assert(vim.deep_equal(cmd, original), "vim.lsp.start changed the jdtls command")
  assert(options.env.LMX_JDTLS_ROOT == root, "vim.lsp.start did not pass the resolved project root")
  return {
    request = function(method, _, callback)
      assert(method == "initialize", "unexpected request to the test client")
      initialized = true
      callback(nil, { capabilities = {} })
      return true, 1
    end,
    notify = function() return true end,
    is_closing = function() return stopped end,
    terminate = function() stopped = true; handlers.on_exit(0, 0) end,
  }
end
ok, failure = pcall(function()
  local id = vim.lsp.start({
    name = "jdtls-context-probe",
    cmd = configure({ cmd = original }).cmd,
    root_dir = root,
    cmd_cwd = cwd,
  }, { attach = false })
  assert(id and initialized, "vim.lsp.start did not initialize the test client")
  local client = assert(vim.lsp.get_client_by_id(id))
  client:stop(true)
  assert(stopped, "test client did not stop")
end)
vim.lsp.rpc.start = start
assert(ok, failure)
