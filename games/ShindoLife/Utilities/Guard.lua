--//Variables
local Guard = {}

--//Source
local function listContainsNumber(list, value)
	local numericValue = tonumber(value)

	if not numericValue then
		return false
	end

	for _, listedValue in ipairs(list or {}) do
		if tonumber(listedValue) == numericValue then
			return true
		end
	end

	return false
end

local function startsWith(text, prefix)
	text = tostring(text or ""):lower()
	prefix = tostring(prefix or ""):lower()

	return text:sub(1, #prefix) == prefix
end

local function getFramework(app)
	return app and app.Framework or Framework
end

local function getGuardConfig(app)
	local config = app and app.Config or {}
	return config.Guard or {}
end

local function getLoaderConfig(app)
	local framework = getFramework(app) or {}
	return framework.Config or {}
end

function Guard.IsLocalUrl(url)
	return startsWith(url, "http://127.0.0.1")
		or startsWith(url, "http://localhost")
		or startsWith(url, "http://0.0.0.0")
end

function Guard.IsDevelopment(app)
	local framework = getFramework(app) or {}
	local loaderConfig = getLoaderConfig(app)

	if loaderConfig.ReleaseGuard == true or tostring(loaderConfig.GuardMode or ""):lower() == "release" then
		return false
	end

	if loaderConfig.DevGuard == true or tostring(loaderConfig.GuardMode or ""):lower() == "dev" then
		return true
	end

	if framework.Bundled == true and tostring((framework.Build or {}).Signature or framework.ReleaseSignature or "") ~= "" then
		return false
	end

	return loaderConfig.SourceMode == true
		or loaderConfig.Dev == true
		or loaderConfig.Development == true
		or Guard.IsLocalUrl(framework.BaseUrl)
end

function Guard.ShouldSilence(app)
	return not Guard.IsDevelopment(app)
end

function Guard.ShouldExport(app)
	local guardConfig = getGuardConfig(app)
	local exportMode = tostring(guardConfig.ExportGlobals or "dev"):lower()

	if exportMode == "always" then
		return true
	end

	if exportMode == "never" then
		return false
	end

	return Guard.IsDevelopment(app)
end

function Guard.FetchUrl(app, url)
	local framework = getFramework(app)

	if framework and type(framework.FetchUrl) == "function" then
		return framework:FetchUrl(url)
	end

	return game:HttpGet(url)
end

function Guard.CheckPlace(app)
	local guardConfig = getGuardConfig(app)
	local allowedPlaceIds = guardConfig.AllowedPlaceIds or {}

	if #allowedPlaceIds <= 0 then
		return true, "place-unrestricted"
	end

	if listContainsNumber(allowedPlaceIds, game.PlaceId) then
		return true, "place-ok"
	end

	return false, "place-blocked"
end

function Guard.CheckBundleOrigin(app)
	local guardConfig = getGuardConfig(app)
	local releaseConfig = guardConfig.Release or {}

	if releaseConfig.RequireBundle == false or Guard.IsDevelopment(app) then
		return true, "bundle-skipped-dev"
	end

	local framework = getFramework(app) or {}
	local build = framework.Build or {}
	local expectedGame = tostring(releaseConfig.Game or "shindolife"):lower()
	local expectedBundle = tostring(releaseConfig.BundleName or "ShindoLife.luau")
	local expectedSignature = tostring(releaseConfig.Signature or "")

	if framework.Bundled ~= true then
		return false, "bundle-required"
	end

	if tostring(build.Game or ""):lower() ~= expectedGame then
		return false, "bundle-game"
	end

	if expectedBundle ~= "" and tostring(build.BundleName or build.BundleFile or "") ~= expectedBundle then
		return false, "bundle-name"
	end

	if expectedSignature ~= "" and tostring(build.Signature or framework.ReleaseSignature or "") ~= expectedSignature then
		return false, "bundle-signature"
	end

	return true, "bundle-ok"
end

function Guard.CheckRemoteBuild(app)
	local guardConfig = getGuardConfig(app)
	local loaderConfig = getLoaderConfig(app)
	local remoteConfig = guardConfig.RemoteBuild or {}

	if loaderConfig.SkipRemoteBuild == true or loaderConfig.CheckRemoteBuild == false then
		return true, "remote-skipped-loader"
	end

	if remoteConfig.Enabled ~= true then
		return true, "remote-disabled"
	end

	if remoteConfig.RequirePublished ~= true then
		return true, "remote-optional"
	end

	if remoteConfig.AllowDevelopment ~= false and Guard.IsDevelopment(app) then
		return true, "remote-skipped-dev"
	end

	local remoteUrl = tostring(remoteConfig.Url or "")
	local signature = tostring(remoteConfig.Signature or "")
	local minLength = math.max(0, tonumber(remoteConfig.MinLength) or 0)

	if remoteUrl == "" then
		return false, "remote-url-missing"
	end

	local fetchSuccess, source = pcall(function()
		return Guard.FetchUrl(app, remoteUrl)
	end)

	if not fetchSuccess or typeof(source) ~= "string" then
		return false, "remote-fetch-failed"
	end

	if #source < minLength then
		return false, "remote-too-short"
	end

	if signature ~= "" and not string.find(source, signature, 1, true) then
		return false, "remote-signature-missing"
	end

	return true, "remote-ok"
end

function Guard.Run(app)
	local guardConfig = getGuardConfig(app)

	if guardConfig.Enabled ~= true then
		return true, "guard-disabled"
	end

	local placeReady, placeReason = Guard.CheckPlace(app)
	if not placeReady then
		return false, placeReason
	end

	local bundleReady, bundleReason = Guard.CheckBundleOrigin(app)
	if not bundleReady then
		return false, bundleReason
	end

	local remoteReady, remoteReason = Guard.CheckRemoteBuild(app)
	if not remoteReady then
		return false, remoteReason
	end

	if app and app.Debug and not Guard.ShouldSilence(app) then
		app.Debug:Log("guard-ok", {
			place = placeReason,
			bundle = bundleReason,
			remote = remoteReason,
			dev = Guard.IsDevelopment(app),
			export = Guard.ShouldExport(app),
		})
	end

	return true, "guard-ok"
end

return Guard
