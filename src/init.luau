--!strict

local RunService = game:GetService("RunService")

local Budget = require(script.Budget)
local Constants = require(script.Constants)
local DataStore = require(script.DataStore)
local SimulatedErrors = require(script.SimulatedErrors)
local SimulatedYield = require(script.SimulatedYield)
local validateString = require(script.validateString)

local function assertServer()
	if not RunService:IsServer() then
		error("DataStore can't be accessed from the client")
	end
end

local DataStoreServiceMock = {}
DataStoreServiceMock.__index = DataStoreServiceMock

export type DataStoreServiceMock = typeof(setmetatable(
	{} :: {
		dataStores: { [string]: { [string]: DataStore.DataStore<any> } },
		errors: SimulatedErrors.SimulatedErrors,
		yield: SimulatedYield.SimulatedYield,
		budget: Budget.Budget,
	},
	DataStoreServiceMock
))

function DataStoreServiceMock.new(): DataStoreServiceMock
	return setmetatable({
		dataStores = {},
		errors = SimulatedErrors.new(),
		yield = SimulatedYield.new(),
		budget = Budget.new(),
	}, DataStoreServiceMock)
end

function DataStoreServiceMock.manual(): DataStoreServiceMock
	return setmetatable({
		dataStores = {},
		errors = SimulatedErrors.new(),
		yield = SimulatedYield.new(),
		budget = Budget.manual(),
	}, DataStoreServiceMock)
end

function DataStoreServiceMock.GetDataStore<T>(
	self: DataStoreServiceMock,
	name: string,
	scope: string?
): DataStore.DataStore<T>
	assertServer()

	scope = scope or "global"

	validateString("name", name, Constants.MAX_NAME_LENGTH)
	validateString("scope", scope :: string, Constants.MAX_SCOPE_LENGTH)

	if self.dataStores[name] :: any == nil then
		self.dataStores[name] = {}
	end

	if self.dataStores[name][scope :: string] :: any == nil then
		self.dataStores[name][scope :: string] = DataStore.new(self.budget, self.errors, self.yield)
	end

	return self.dataStores[name][scope :: string]
end

function DataStoreServiceMock.GetRequestBudgetForRequestType(
	self: DataStoreServiceMock,
	requestType: Enum.DataStoreRequestType
): number
	local budget = self.budget.budgets[requestType]

	if budget == nil then
		error("`requestType` must be an Enum.DataStoreRequestType")
	end

	return budget
end

return DataStoreServiceMock
