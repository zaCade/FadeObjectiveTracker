local FadeObjectiveTracker = LibStub("AceAddon-3.0"):NewAddon("FadeObjectiveTracker", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0");

------------------------------------------------------------------------------------------------------
-- Main: Debug Functions
------------------------------------------------------------------------------------------------------
local function DebugPrint(message)
	--@debug@
	FadeObjectiveTracker:Print(message);
	--@end-debug@
end

------------------------------------------------------------------------------------------------------
-- Main: Helper Functions
------------------------------------------------------------------------------------------------------
local function GetTrackerFrame()
	return ObjectiveTrackerFrame or QuestWatchFrame;
end

local function IsObjectiveTracker()
	return ObjectiveTrackerFrame ~= nil or false;
end

local function IsInstancePvP()
	local inInstance, instanceType = IsInInstance();

	return inInstance and instanceType == "pvp" or instanceType == "arena";
end

------------------------------------------------------------------------------------------------------
-- Main: Global Functions
------------------------------------------------------------------------------------------------------
function FadeObjectiveTracker_FadeIn()
	if not FadeObjectiveTracker.Faded then return end

	DebugPrint("FadeObjectiveTracker_FadeIn!");

	FadeObjectiveTracker.Faded = nil;
	FadeObjectiveTracker.Fading = nil;
	FadeObjectiveTracker.Visible = nil;

	UIFrameFadeIn(GetTrackerFrame(), FadeObjectiveTrackerDB.FadeInSpeed or 1, FadeObjectiveTrackerDB.FadeValue or 0, 1);

	if IsObjectiveTracker() then
		ObjectiveTracker_Update();
	else
		QuestWatch_Update();
	end
end

function FadeObjectiveTracker_FadeOut()
	if FadeObjectiveTracker.Faded then return end

	DebugPrint("FadeObjectiveTracker_FadeOut!");

	if FadeObjectiveTrackerDB.OnlyInGroup and IsInGroup() then return end

	FadeObjectiveTracker.Faded = true;
	FadeObjectiveTracker.Fading = nil;
	FadeObjectiveTracker.Visible = FadeObjectiveTrackerDB.FadeValue ~= 0;

	UIFrameFadeOut(GetTrackerFrame(), FadeObjectiveTrackerDB.FadeOutSpeed or 1, 1, FadeObjectiveTrackerDB.FadeValue or 0);
end

function FadeObjectiveTracker_QueueFadeIn()
	if FadeObjectiveTracker.Fading or not FadeObjectiveTracker.Faded then return end

	DebugPrint("FadeObjectiveTracker_QueueFadeIn!");

	FadeObjectiveTracker.Fading = true;
	FadeObjectiveTracker:ScheduleTimer(FadeObjectiveTracker_FadeIn, FadeObjectiveTrackerDB.FadeInDelay or 0);
end

function FadeObjectiveTracker_QueueFadeOut()
	if FadeObjectiveTracker.Fading or FadeObjectiveTracker.Faded then return end

	DebugPrint("FadeObjectiveTracker_QueueFadeOut!");

	if FadeObjectiveTrackerDB.OnlyInGroup and IsInGroup() then return end

	FadeObjectiveTracker.Fading = true;
	FadeObjectiveTracker:ScheduleTimer(FadeObjectiveTracker_FadeOut, FadeObjectiveTrackerDB.FadeOutDelay or 0);
end

------------------------------------------------------------------------------------------------------
-- Main: Internal Event Handlers
------------------------------------------------------------------------------------------------------
function FadeObjectiveTracker:ENCOUNTER_START(_, encounterID, encounterName, difficultyID, groupSize)
	FadeObjectiveTracker.InEncounter = true;

	DebugPrint("ENCOUNTER_START!");

	if not FadeObjectiveTracker.HiddenForPvP and not FadeObjectiveTrackerDB.HideOnCombat or false then
		FadeObjectiveTracker_FadeOut();
	end
end

function FadeObjectiveTracker:ENCOUNTER_END(_, encounterID, encounterName, difficultyID, groupSize, success)
	FadeObjectiveTracker.InEncounter = nil;

	DebugPrint("ENCOUNTER_END!");

	if not FadeObjectiveTracker.HiddenForPvP and not FadeObjectiveTracker.InCombat then
		FadeObjectiveTracker_QueueFadeIn();
	end
end

function FadeObjectiveTracker:PLAYER_REGEN_DISABLED()
	FadeObjectiveTracker.InCombat = true;

	DebugPrint("PLAYER_REGEN_DISABLED!");

	if not FadeObjectiveTracker.HiddenForPvP and FadeObjectiveTrackerDB.HideOnCombat or false then
		FadeObjectiveTracker_FadeOut();
	end
end

function FadeObjectiveTracker:PLAYER_REGEN_ENABLED()
	FadeObjectiveTracker.InCombat = nil;

	DebugPrint("PLAYER_REGEN_ENABLED!");

	if not FadeObjectiveTracker.HiddenForPvP and not FadeObjectiveTracker.InEncounter then
		FadeObjectiveTracker_QueueFadeIn();
	end
end

function FadeObjectiveTracker:PLAYER_ENTERING_WORLD()
	FadeObjectiveTracker.HiddenForPvP = nil;
	FadeObjectiveTracker.InEncounter = nil;
	FadeObjectiveTracker.InCombat = nil;

	FadeObjectiveTracker.InsidePvP = IsInstancePvP();
	FadeObjectiveTracker.IsResting = IsResting();

	DebugPrint("PLAYER_ENTERING_WORLD!\nInsidePvP: " .. tostring(FadeObjectiveTracker.InsidePvP) .. "\nIsResting: " .. tostring(FadeObjectiveTracker.IsResting));

	if FadeObjectiveTracker.InsidePvP and FadeObjectiveTrackerDB.HideInsidePvP or false then
		FadeObjectiveTracker.HiddenForPvP = true;
		FadeObjectiveTracker_FadeOut();
	else
		FadeObjectiveTracker_FadeIn();
	end

	if not FadeObjectiveTracker.HiddenForPvP and not IsObjectiveTracker() then
		if FadeObjectiveTracker.IsResting and FadeObjectiveTrackerDB.HideInsideResting or false then
			FadeObjectiveTracker_FadeOut();
		else
			FadeObjectiveTracker_FadeIn();
		end
	else
		if FadeObjectiveTracker.IsResting and FadeObjectiveTrackerDB.HideInsideResting or false then
			ObjectiveTracker_Collapse();
		else
			ObjectiveTracker_Expand();
			ObjectiveTracker_Update();
		end
	end
end

function FadeObjectiveTracker:PLAYER_UPDATE_RESTING()
	FadeObjectiveTracker.IsResting = IsResting();

	DebugPrint("PLAYER_UPDATE_RESTING!\nIsResting: " .. tostring(FadeObjectiveTracker.IsResting));

	if not FadeObjectiveTracker.HiddenForPvP and not IsObjectiveTracker() then
		if FadeObjectiveTracker.IsResting and FadeObjectiveTrackerDB.HideInsideResting or false then
			FadeObjectiveTracker_FadeOut();
		else
			FadeObjectiveTracker_FadeIn();
		end
	else
		if FadeObjectiveTracker.IsResting and FadeObjectiveTrackerDB.HideInsideResting or false then
			ObjectiveTracker_Collapse();
		else
			ObjectiveTracker_Expand();
			ObjectiveTracker_Update();
		end
	end
end

------------------------------------------------------------------------------------------------------
-- Main: Overwrite Original Functions
------------------------------------------------------------------------------------------------------
if IsObjectiveTracker() then
	local Original_ObjectiveTracker_Update = Original_ObjectiveTracker_Update or ObjectiveTracker_Update;

	function ObjectiveTracker_Update(reason, id)
		if FadeObjectiveTracker.Faded and not FadeObjectiveTracker.Visible then return end

		Original_ObjectiveTracker_Update(reason, id);
	end

	local Original_ObjectiveTracker_Expand = Original_ObjectiveTracker_Expand or ObjectiveTracker_Expand;

	function ObjectiveTracker_Expand()
		if FadeObjectiveTracker.BlockScenarioExpand then FadeObjectiveTracker.BlockScenarioExpand = nil return end

		Original_ObjectiveTracker_Expand();
	end

	local Original_ScenarioTimer_Start = Original_ScenarioTimer_Start or ScenarioTimer_Start;

	function ScenarioTimer_Start(block, updateFunc)
		if FadeObjectiveTrackerDB.BlockScenarioExpand or false then FadeObjectiveTracker.BlockScenarioExpand = true end

		Original_ScenarioTimer_Start(block, updateFunc);
	end
else
	local Original_QuestWatch_Update = Original_QuestWatch_Update or QuestWatch_Update;

	function QuestWatch_Update()
		if FadeObjectiveTracker.Faded and not FadeObjectiveTracker.Visible then return end

		Original_QuestWatch_Update();
	end
end

------------------------------------------------------------------------------------------------------
-- Main: Create Options Table
------------------------------------------------------------------------------------------------------
local FadeObjectiveTrackerOptions = {
	type = "group",
	name = "FadeObjectiveTracker",
	args = {
		FadeInGroup = {
			order = 1,
			type  = "group",
			name  = "Fade settings",
			args  = {
				FadeValue = {
					order = 1,
					type  = "range",
					name  = "Fade percentage",
					desc  = "How much alpha the tracker should fade to.",
					step  = 0.05,
					min   = 0,
					max   = 1,
					set   = function(info, value) FadeObjectiveTrackerDB.FadeValue = value end,
					get   = function(info) return FadeObjectiveTrackerDB.FadeValue or 0 end,
				},
				OnlyInGroup = {
					order = 2,
					type  = "toggle",
					name  = "Only in group",
					desc  = "Only fade the tracker while inside a group.",
					set   = function(info, value) FadeObjectiveTrackerDB.OnlyInGroup = value end,
					get   = function(info) return FadeObjectiveTrackerDB.OnlyInGroup or false end,
				},
				FadeInHeader = {
					order  = 3,
					type   = "header",
					name   = "Fade in settings",
				},
				FadeInSpeed = {
					order = 4,
					type  = "range",
					name  = "Fade in speed",
					desc  = "How long it takes for the tracker to fade in.",
					step  = 0.1,
					min   = 0,
					max   = 10,
					set   = function(info, value) FadeObjectiveTrackerDB.FadeInSpeed = value end,
					get   = function(info) return FadeObjectiveTrackerDB.FadeInSpeed or 1 end,
				},
				FadeInDelay = {
					order = 5,
					type  = "range",
					name  = "Fade in delay",
					desc  = "How long it takes before the tracker actually fades in.",
					step  = 1,
					min   = 0,
					max   = 60,
					set   = function(info, value) FadeObjectiveTrackerDB.FadeInDelay = value end,
					get   = function(info) return FadeObjectiveTrackerDB.FadeInDelay or 0 end,
				},
				FadeOutHeader = {
					order  = 6,
					type   = "header",
					name   = "Fade out settings",
				},
				FadeOutSpeed = {
					order = 7,
					type  = "range",
					name  = "Fade out speed",
					desc  = "How long it takes for the tracker to fade out.",
					step  = 0.1,
					min   = 0,
					max   = 10,
					set   = function(info, value) FadeObjectiveTrackerDB.FadeOutSpeed = value end,
					get   = function(info) return FadeObjectiveTrackerDB.FadeOutSpeed or 1 end,
				},
				FadeOutDelay = {
					order = 8,
					type  = "range",
					name  = "Fade out delay",
					desc  = "How long it takes before the tracker actually fades out.",
					step  = 1,
					min   = 0,
					max   = 60,
					set   = function(info, value) FadeObjectiveTrackerDB.FadeOutDelay = value end,
					get   = function(info) return FadeObjectiveTrackerDB.FadeOutDelay or 0 end,
				},
			},
		},
		ExtraGroup = {
			order = 3,
			type  = "group",
			name  = "Extras",
			args  = {
				BlockScenarioExpand = {
					order  = 1,
					type   = "toggle",
					name   = "Block scenario expand",
					desc   = "Blocks a scenario (Challenge Mode / Proving Grounds) from expanding the tracker.",
					set    = function(info, value) FadeObjectiveTrackerDB.BlockScenarioExpand = value end,
					get    = function(info) return FadeObjectiveTrackerDB.BlockScenarioExpand or false end,
					hidden = not IsObjectiveTracker(),
				},
				HideOnCombat = {
					order = 2,
					type  = "toggle",
					name  = "Fade on combat",
					desc  = "Automatically fades the tracker when entering combat, instead of on encounter start.",
					set   = function(info, value) FadeObjectiveTrackerDB.HideOnCombat = value end,
					get   = function(info) return FadeObjectiveTrackerDB.HideOnCombat or false end,
				},
				HideInsidePvP = {
					order = 3,
					type  = "toggle",
					name  = "Fade inside PvP",
					desc  = "Automatically fades the tracker inside PvP instances. (Battlegrounds/Arenas)",
					set   = function(info, value) FadeObjectiveTrackerDB.HideInsidePvP = value end,
					get   = function(info) return FadeObjectiveTrackerDB.HideInsidePvP or false end,
				},
				HideInsideResting = {
					order = 4,
					type  = "toggle",
					name  = "Collapse while resting",
					desc  = "Automatically hides the tracker when entering resting zones. (Cities/Inns)",
					set   = function(info, value) FadeObjectiveTrackerDB.HideInsideResting = value end,
					get   = function(info) return FadeObjectiveTrackerDB.HideInsideResting or false end,
				},
			},
		},
	},
};

------------------------------------------------------------------------------------------------------
-- Main: Internal Ace3 Handlers
------------------------------------------------------------------------------------------------------
function FadeObjectiveTracker:OnInitialize()
	FadeObjectiveTrackerDB = FadeObjectiveTrackerDB or {};

	FadeObjectiveTrackerDB.FadeValue   = FadeObjectiveTrackerDB.FadeValue   or 0;
	FadeObjectiveTrackerDB.OnlyInGroup = FadeObjectiveTrackerDB.OnlyInGroup or false;

	FadeObjectiveTrackerDB.FadeInSpeed = FadeObjectiveTrackerDB.FadeInSpeed or 1;
	FadeObjectiveTrackerDB.FadeInDelay = FadeObjectiveTrackerDB.FadeInDelay or 0;

	FadeObjectiveTrackerDB.FadeOutSpeed = FadeObjectiveTrackerDB.FadeOutSpeed or 1;
	FadeObjectiveTrackerDB.FadeOutDelay = FadeObjectiveTrackerDB.FadeOutDelay or 0;

	FadeObjectiveTrackerDB.BlockScenarioExpand = FadeObjectiveTrackerDB.BlockScenarioExpand or false;
	FadeObjectiveTrackerDB.HideOnCombat        = FadeObjectiveTrackerDB.HideOnCombat        or false;
	FadeObjectiveTrackerDB.HideInsidePvP       = FadeObjectiveTrackerDB.HideInsidePvP       or false;
	FadeObjectiveTrackerDB.HideInsideResting   = FadeObjectiveTrackerDB.HideInsideResting   or false;

	LibStub("AceConfig-3.0"):RegisterOptionsTable("FadeObjectiveTracker", FadeObjectiveTrackerOptions);

	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FadeObjectiveTracker", nil, nil);
end

function FadeObjectiveTracker:OnEnable()
	self:RegisterEvent("ENCOUNTER_START");
	self:RegisterEvent("ENCOUNTER_END");
	self:RegisterEvent("PLAYER_REGEN_DISABLED");
	self:RegisterEvent("PLAYER_REGEN_ENABLED");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_UPDATE_RESTING");
end
