--[=[
	A wrapper for [MemoryStoreService](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreService). Its main purpose is to provide
	an easy way to catch and handle errors from MemoryStoreService by using Promises and to incorporate automatic retry functionality if a request were to fail.

	@class SafeMemoryStore
]=]
-- < Services > --
local MemoryStoreService = game:GetService("MemoryStoreService")

-- < Imports > --
local Promise = require(script.Parent.Promise)

-- < Types > --
local SafeSortedMap: SafeSortedMap = {}
local SafeMemoryQueue: SafeMemoryQueue = {}
local SafeMemoryStore = {}
SafeSortedMap.__index = SafeSortedMap
SafeMemoryQueue.__index = SafeMemoryQueue

export type SafeMemoryQueue = typeof(setmetatable({} :: {
	_queue: MemoryStoreQueue,
	maxRetries: number,
}, SafeMemoryQueue))

export type SafeSortedMap = typeof(setmetatable({} :: {
	_map: MemoryStoreSortedMap,
	maxRetries: number,
}, SafeSortedMap))

--[=[
	A wrapper for [MemoryStoreQueue](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreQueue). This object can be retrieved by calling [SafeMemoryStore:GetQueue()]

	:::tip
	Unlike the original `MemoryStoreQueue`, none of the function calls for `SafeMemoryQueue` are yielding. Instead the functions
	return [Promises](https://eryn.io/roblox-lua-promise/api/Promise) that will resolve when the function is completed
	:::

	@class SafeMemoryQueue
]=]
function SafeMemoryQueue.new(name: string, maxRetries: number?, invisibilityTimeout: number?): SafeMemoryQueue
	local self: SafeMemoryQueue = setmetatable({}, SafeMemoryQueue)

	self._queue = MemoryStoreService:GetQueue(name, invisibilityTimeout)
	self.maxRetries = maxRetries or 3

	return self
end

--[=[
	Performs [AddAsync](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreQueue#AddAsync) on the queue. The call will be retried upon failure.
	Returns a Promise that resolves to nil

	@param value any -- The value of the item to add to the queue.
	@param expiration number -- Item expiration time, in seconds, after which the item will be automatically removed from the queue.
	@param priority? number -- Item priority. Items with higher priority are retrieved from the queue before items with lower priority. Default Value: 0
	@return Promise<>
]=]
function SafeMemoryQueue:AddAsync(value: any, expiration: number, priority: number?)
	local function promiseAddAsync()
		return Promise.new(function(resolve)
			self._queue:AddAsync(value, expiration, priority)
			resolve()
		end)
	end

	return Promise.retry(promiseAddAsync, self.maxRetries)
end

--[=[
	Performs [ReadAsync](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreQueue#ReadAsync) on the queue. The call will be retried upon failure.

	Returns a Promise that passes a tuple of two elements. The first element is an array
	of item values read from the queue. The second element is a string identifier that should be passed to
	[RemoveAsync] to permanently remove these items from the queue.

	@return Promise<{ any }, string>
]=]
function SafeMemoryQueue:ReadAsync(count: number, allOrNothing: boolean?, waitTimeout: number?)
	local function promiseReadAsync()
		return Promise.new(function(resolve)
			local items: { any }, id: string = self._queue:ReadAsync(count, allOrNothing, waitTimeout)
			resolve(items, id)
		end)
	end

	return Promise.retry(promiseReadAsync, self.maxRetries)
end

--[=[
	Performs [RemoveAsync](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreQueue#RemoveAsync) on the queue. The call will be retried upon failure.
	Returns a Promise that resolves to nil

	@param id string -- Identifies the items to delete. Use the value returned by [ReadAsync](/api/SafeMemoryQueue#ReadAsync).
	@return Promise<>
]=]
function SafeMemoryQueue:RemoveAsync(id: string)
	local function promiseRemoveAsync()
		return Promise.new(function(resolve)
			self._queue:RemoveAsync(id)
			resolve()
		end)
	end

	return Promise.retry(promiseRemoveAsync, self.maxRetries)
end

--[=[
	A wrapper for a [MemoryStoreSortedMap](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreSortedMap).This object can be retrieved by calling [SafeMemoryStore:GetSortedMap()]

	:::tip
	Unlike the original `MemoryStoreSortedMap` none of the function calls for `SafeSortedMap` are yielding. Instead the functions
	return Promises that will resolve when the function is completed
	:::

	@class SafeSortedMap
]=]
function SafeSortedMap.new(name: string, maxRetries: number?): SafeSortedMap
	local self = {
		_map = MemoryStoreService:GetSortedMap(name),
		maxRetries = maxRetries or 3,
	}

	return setmetatable(self, SafeSortedMap)
end

--[=[
	Performs [GetAsync](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreSortedMap#GetAsync) on the sorted map. The call will be retried upon failure.
	Returns a Promise that resolves to the value of the entry in the sorted map

	@param key string -- Key whose value to retrieve
	@return Promise<any>
]=]
function SafeSortedMap:GetAsync(key: string)
	local function promiseGetAsync()
		return Promise.new(function(resolve)
			local value: any = self._map:GetAsync(key)
			resolve(value)
		end)
	end

	return Promise.retry(promiseGetAsync, self.maxRetries)
end

--[=[
	Performs [GetRangeAsync](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreSortedMap#GetRangeAsync) on the sorted map. The call does not yield and will be retried upon failure.
	Returns a Promise that resolves to a dictionary of keys and their values in the requested range

	@param direction Enum.SortDirection -- Sort direction, ascending or descending
	@param count number -- The number of items to retrieve; the maximum allowed value for this parameter is 200
	@param exclusiveLowerBound string? -- Lower bound, exclusive, for the returned keys
	@param exclusiveUpperBound string? -- Upper bound, exclusive, for the returned keys
	@return Promise<{ [string]: any }>
]=]
function SafeSortedMap:GetRangeAsync(direction: Enum.SortDirection, count: number, exclusiveLowerBound: string?, exclusiveUpperBound: string?)
	local function promiseGetRangeAsync()
		return Promise.new(function(resolve)
			local range: { [string]: any } = self._map:GetRangeAsync(direction, count, exclusiveLowerBound, exclusiveUpperBound)
			resolve(range)
		end)
	end

	return Promise.retry(promiseGetRangeAsync, self.maxRetries)
end

--[=[
	Performs [RemoveAsync](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreSortedMap#RemoveAsync) on the sorted map. The call does not yield and will be retried upon failure.
	Returns a Promise that resolves to nil

	@param key string -- Key to remove
	@return Promise<>
]=]
function SafeSortedMap:RemoveAsync(key: string)
	local function promiseRemoveAsync()
		return Promise.new(function(resolve)
			self._map:RemoveAsync(key)
			resolve()
		end)
	end

	return Promise.retry(promiseRemoveAsync, self.maxRetries)
end

--[=[
	Performs [SetAsync](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreSortedMap#SetAsync) on the sorted map. The call does not yield and will be retried upon failure.
	Returns a Promise that resolves to a boolean. The boolean will be true if a new item was added, false if an existing item was overwritten.

	@param key string -- Key whose value to set
	@param value any -- Key value to set
	@param expiration number -- Item expiration, in seconds. The item is automatically removed from the sorted map once the expiration duration is reached. The maximum expiration time is 45 days (3,888,000 seconds).
	@return Promise<boolean>
]=]
function SafeSortedMap:SetAsync(key: string, value: any, expiration: number)
	local function promiseSetAsync()
		return Promise.new(function(resolve)
			local isNewItem: boolean = self._map:SetAsync(key, value, expiration)
			resolve(isNewItem)
		end)
	end

	return Promise.retry(promiseSetAsync, self.maxRetries)
end

--[=[
	Performs [UpdateAsync](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreSortedMap#UpdateAsync) on the sorted map. The call does not yield and will be retried upon failure.
	Returns a Promise that resolves the last value returned by the `transformFunction` parameter.

	@param key string -- Key whose value to update
	@param transformFunction (any) -> (any) -- Takes the key's old value as input and returns the new value.
	@param expiration number -- Item expiration time, in seconds, after which the item will be automatically removed from the sorted map. The maximum expiration time is 45 days (3,888,000 seconds).
	@return Promise<any>
]=]
function SafeSortedMap:UpdateAsync(key: string, transformFunction: (any) -> any, expiration: number)
	local function promiseUpdateAsync()
		return Promise.new(function(resolve)
			local newValue: any = self._map:UpdateAsync(key, transformFunction, expiration)
			resolve(newValue)
		end)
	end

	return Promise.retry(promiseUpdateAsync, self.maxRetries)
end

--[=[
	@param name string -- Name of the queue
	@param maxRetries number? -- How many times to retry any of the functions of [SafeMemoryQueue], should they fail. Default Value: 3
	@param invisibilityTimeout number? -- Invisibility timeout, in seconds, for read operations through this queue instance. If not provided, defaults to 30 seconds. Default Value: 30
	@return SafeMemoryQueue
]=]
function SafeMemoryStore.GetQueue(name: string, maxRetries: number?, invisibilityTimeout: number?): SafeMemoryQueue
	return SafeMemoryQueue.new(name, maxRetries, invisibilityTimeout)
end

--[=[
	@param name string -- Name of the sorted map
	@param maxRetries number? -- How many times to retry any of the functions of [SafeSortedMap], should they fail. Default Value: 3
	@return SafeSortedMap
]=]
function SafeMemoryStore.GetSortedMap(name: string, maxRetries: number?): SafeSortedMap
	return SafeSortedMap.new(name, maxRetries)
end

return SafeMemoryStore
