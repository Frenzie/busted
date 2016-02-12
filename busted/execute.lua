
return function(busted)
  local block = require 'busted.block'(busted)

  local function execute(runs, options)
    local function suite_reset()
      local oldctx = busted.context.get()
      local children = busted.context.children(oldctx)

      busted.context.clear()
      local ctx = busted.context.get()
      for k, v in pairs(oldctx) do
        ctx[k] = v
      end

      for _, child in ipairs(children) do
        for descriptor, _ in pairs(busted.executors) do
          child[descriptor] = nil
        end
        busted.context.attach(child)
      end

      busted.randomseed = tonumber(options.seed) or os.time()
    end

    for i = 1, runs do
      local root = busted.context.get()
      local seed = (busted.randomize and busted.randomseed or nil)

      if i > 1 then
        suite_reset()
        root = busted.context.get()
        busted.safe_publish('suite', { 'suite', 'reset' }, root, i, runs)
      end

      if busted.safe_publish('suite', { 'suite', 'start' }, root, i, runs, seed) then
        if block.setup(root) then
          busted.execute()
        end
        block.lazyTeardown(root)
        block.teardown(root)
      end
      busted.safe_publish('suite', { 'suite', 'end' }, root, i, runs)

      if busted.skipAll then
        break
      end
    end
  end

  return execute
end
