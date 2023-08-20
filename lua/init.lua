local curl = require("plenary.curl")
local popup = require("plenary.popup")

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
local ERC20_TOPIC0 = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef" -- This can also be for ERC721 though

local config = {
	api_key_script = "~/secrets/blockchain_api_key.sh",
	default_blockchain = "ethereum",
	width = nil,
	height = nil,
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

local to_eth_address = function(hex_str)
	return "0x" .. string.sub(hex_str, 27)
end

M.eth_getTransactionReceipt = function(tx_hash, blockchain)
	if tx_hash == nil then
		error("tx_hash is required")
	end
	local res = fetch_get_alchemy("eth_getTransactionReceipt", { tx_hash }, blockchain)
	local data = res.result

	local tx_headers = {
		tx_hash = data.transactionHash,
		from_address = data.from,
		to_address = data.to,
		block_number = tonumber(data.blockNumber),
	}
	local erc20_logs = {}
	local other_logs = {}

	for _, log in pairs(data.logs) do
		if log.topics[1] == ERC20_TOPIC0 then
			table.insert(erc20_logs, {
				log_index = tonumber(log.logIndex),
				token_address = log.address,
				token_from = to_eth_address(log.topics[2]),
				token_to = to_eth_address(log.topics[3]),
				amount = tonumber(log.data),
			})
		else
			table.insert(other_logs, {
				log_index = tonumber(log.logIndex),
				topics = log.topics,
				data = log.data,
			})
		end
	end

	local tx_data = {
		tx_headers = tx_headers,
		erc20_logs = erc20_logs,
		other_logs = other_logs,
	}
	local window = M._create_window()
	local lines = {
		"tx_hash: " .. tx_data.tx_headers.tx_hash,
		"from: " .. tx_data.tx_headers.from_address .. " to: " .. tx_data.tx_headers.to_address,
	}
	for _, log in pairs(tx_data.erc20_logs) do
		-- TODO group logs by token address
		table.insert(lines, "token: " .. log.token_address)
		table.insert(
			lines,
			"[" .. log.log_index .. "] " .. "erc20: " .. log.token_from .. " -> " .. log.token_to .. " " .. log.amount
		)
	end
	for _, log in pairs(tx_data.other_logs) do
		table.insert(lines, "other: " .. log.data)
	end
	vim.api.nvim_buf_set_lines(window.bufnr, 0, -1, false, lines)
end

M._create_window = function()
	local width = config.width or 100
	local height = config.height or 10
	local borderchars = config.borderchars or { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
	local bufnr = vim.api.nvim_create_buf(false, false)

	local Eth_win_it, win = popup.create(bufnr, {
		title = "eth",
		highlight = "EthWindow",
		col = math.floor((vim.o.columns - width) / 2),
		line = math.floor(((vim.o.lines - height) / 2) - 1),
		minwidth = width,
		minheight = height,
		borderchars = borderchars,
	})

	vim.api.nvim_win_set_option(win.border.win_id, "winhl", "Normal:EthWindowBorder")

	return {
		bufnr = bufnr,
		win_id = Eth_win_it,
	}
end

return M
