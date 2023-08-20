local curl = require("plenary.curl")

local provider_urls = {
	etherscan = "https://api.etherscan.io/api",
	bscscan = "https://api.bscscan.com/api",
	polygonscan = "https://api.polygonscan.com/api",
}

local config = {
	api_key_script = "~/secrets/blockchain_api_key.sh",
	default_chain = "ethereum",
	default_provider = "etherscan",
}

local M = {}

M.get_api_key = function()
	local api_key =
		vim.fn.system(config.api_key_script .. " " .. config.default_chain .. " " .. config.default_provider)
	api_key = string.gsub(api_key, "\n", "")
	return api_key
end

print(M.get_api_key())

return M
