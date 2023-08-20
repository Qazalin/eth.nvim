local curl = require("plenary.curl")

local provider_urls = {
	etherscan = {
		ethereum = "https://api.etherscan.io/api",
		bsc = "https://api.bscscan.com/api",
		polygon = "https://api.polygonscan.com/api",
	},
	alchemy = {
		ethereum = "https://eth-mainnet.g.alchemy.com/v2",
	},
}

local config = {
	api_key_script = "~/secrets/blockchain_api_key.sh",
	default_blockchain = "ethereum",
}

local M = {}

M._get_api_key = function(blockchain, provider)
	local api_key = vim.fn.system(config.api_key_script .. " " .. blockchain .. " " .. provider)
	api_key = string.gsub(api_key, "\n", "")
	return api_key
end

local fetch_get_alchemy = function(method, params, blockchain, jsonrpc, id)
	if method == nil then
		error("method is required")
	end
	if params == nil then
		error("params is required")
	end

	local provider = "alchemy"
	blockchain = blockchain or config.default_blockchain

	local query = {
		id = id or 1,
		jsonrpc = jsonrpc or "2.0",
		params = params,
		method = method,
	}
	local api_key = M._get_api_key(blockchain, provider)
	local url = provider_urls[provider][blockchain]
	local response = curl.post(url, {
		body = vim.fn.json_encode(query),
		headers = {
			accept = "application/json",
			["content-type"] = "application/json",
			["Authorization"] = "Bearer " .. api_key,
		},
	})

	local data = vim.fn.json_decode(response.body)
	return data
end

M.eth_getTransactionReceipt = function(blockchain)
	local response = fetch_get_alchemy(
		"eth_getTransactionReceipt",
		{ "0x8fc90a6c3ee3001cdcbbb685b4fbe67b1fa2bec575b15b0395fea5540d0901ae" },
		blockchain
	)
	print(vim.inspect(response))
end

M.eth_getTransactionReceipt()

return M
