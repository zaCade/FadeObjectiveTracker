local FadeObjectiveTracker = LibStub("AceAddon-3.0"):NewAddon("FadeObjectiveTracker", "AceEvent-3.0", "AceTimer-3.0");

------------------------------------------------------------------------------------------------------
-- Main: Global Functions
------------------------------------------------------------------------------------------------------
function FadeObjectiveTracker_FadeIn()
	if not FadeObjectiveTracker.Faded then return end

	FadeObjectiveTracker.Faded = nil;
	FadeObjectiveTracker.Fading = nil;

	UIFrameFadeIn(ObjectiveTrackerFrame, FadeObjectiveTrackerDB.FadeInSpeed or 1, 0, 1);

	for _, childFrame in pairs({ObjectiveTrackerFrame:GetChildren()}) do
		if childFrame.wasMouseEnabled then
			childFrame.wasMouseEnabled = nil;
			childFrame:EnableMouse(true);
		end
	end
end

function FadeObjectiveTracker_FadeOut()
	if FadeObjectiveTracker.Faded then return end

	FadeObjectiveTracker.Faded = true;
	FadeObjectiveTracker.Fading = nil;

	UIFrameFadeOut(ObjectiveTrackerFrame, FadeObjectiveTrackerDB.FadeOutSpeed or 1, 1, 0);

	for _, childFrame in pairs({ObjectiveTrackerFrame:GetChildren()}) do
		if childFrame:IsMouseEnabled() then
			childFrame.wasMouseEnabled = true;
			childFrame:EnableMouse(false);
		end
	end
end

function FadeObjectiveTracker_QueueFadeIn()
	if FadeObjectiveTracker.Fading or not FadeObjectiveTracker.Faded then return end

	FadeObjectiveTracker.Fading = true;
	FadeObjectiveTracker:ScheduleTimer(FadeObjectiveTracker_FadeIn, FadeObjectiveTrackerDB.FadeInDelay or 0);
end

function FadeObjectiveTracker_QueueFadeOut()
	if FadeObjectiveTracker.Fading or FadeObjectiveTracker.Faded then return end

	FadeObjectiveTracker.Fading = true;
	FadeObjectiveTracker:ScheduleTimer(FadeObjectiveTracker_FadeOut, FadeObjectiveTrackerDB.FadeOutDelay or 0);
end

function FadeObjectiveTracker_IsInstancePvP()
	local inInstance, instanceType = IsInInstance();

	return inInstance and instanceType == "pvp" or instanceType == "arena";
end

------------------------------------------------------------------------------------------------------
-- Main: Internal Event Handlers
------------------------------------------------------------------------------------------------------
function FadeObjectiveTracker:ENCOUNTER_START(encounterID, encounterName, difficultyID, groupSize)
	FadeObjectiveTracker.InEncounter = true;

	if not FadeObjectiveTracker.HiddenForPvP and not FadeObjectiveTrackerDB.HideOnCombat or false then
		FadeObjectiveTracker_FadeOut();
	end
end

function FadeObjectiveTracker:ENCOUNTER_END(encounterID, encounterName, difficultyID, groupSize, success)
	FadeObjectiveTracker.InEncounter = nil;

	if not FadeObjectiveTracker.HiddenForPvP and not FadeObjectiveTracker.InCombat then
		FadeObjectiveTracker_QueueFadeIn();
	end
end

function FadeObjectiveTracker:PLAYER_REGEN_DISABLED()
	FadeObjectiveTracker.InCombat = true;

	if not FadeObjectiveTracker.HiddenForPvP and FadeObjectiveTrackerDB.HideOnCombat or false then
		FadeObjectiveTracker_FadeOut();
	end
end

function FadeObjectiveTracker:PLAYER_REGEN_ENABLED()
	FadeObjectiveTracker.InCombat = nil;

	if not FadeObjectiveTracker.HiddenForPvP and not FadeObjectiveTracker.InEncounter then
		FadeObjectiveTracker_QueueFadeIn();
	end
end

function FadeObjectiveTracker:PLAYER_ENTERING_WORLD()
	FadeObjectiveTracker.InEncounter = nil;
	FadeObjectiveTracker.InCombat = nil;

	FadeObjectiveTracker.InsidePvP = FadeObjectiveTracker_IsInstancePvP();
	FadeObjectiveTracker.IsResting = IsResting();

	if FadeObjectiveTracker.InsidePvP and FadeObjectiveTrackerDB.HideInsidePvP or false then
		FadeObjectiveTracker.HiddenForPvP = true;
		FadeObjectiveTracker_FadeOut();
	else
		FadeObjectiveTracker.HiddenForPvP = nil;
		FadeObjectiveTracker_FadeIn();
	end

	if FadeObjectiveTracker.IsResting and FadeObjectiveTrackerDB.HideInsideResting or false then
		ObjectiveTracker_Collapse();
	else
		ObjectiveTracker_Expand();
		ObjectiveTracker_Update();
	end
end

function FadeObjectiveTracker:PLAYER_UPDATE_RESTING()
	FadeObjectiveTracker.IsResting = IsResting();

	if FadeObjectiveTracker.IsResting and FadeObjectiveTrackerDB.HideInsideResting or false then
		ObjectiveTracker_Collapse();
	else
		ObjectiveTracker_Expand();
		ObjectiveTracker_Update();
	end
end

------------------------------------------------------------------------------------------------------
-- Main: Overwrite Original Functions
------------------------------------------------------------------------------------------------------
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
			name  = "Fade in settings",
			args  = {
				FadeInSpeed = {
					order = 1,
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
					order = 2,
					type  = "range",
					name  = "Fade in delay",
					desc  = "How long it takes before the tracker actually fades in.",
					step  = 1,
					min   = 0,
					max   = 60,
					set   = function(info, value) FadeObjectiveTrackerDB.FadeInDelay = value end,
					get   = function(info) return FadeObjectiveTrackerDB.FadeInDelay or 0 end,
				},
			},
		},
		FadeOutGroup = {
			order = 2,
			type  = "group",
			name  = "Fade out settings",
			args  = {
				FadeOutSpeed = {
					order = 1,
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
					order = 2,
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
			name  = "Extra tweaks",
			args  = {
				BlockScenarioExpand = {
					order = 1,
					type  = "toggle",
					name  = "Block scenario expand",
					desc  = "Blocks a scenario (Challenge Mode / Proving Grounds) from expanding the tracker.",
					set   = function(info, value) FadeObjectiveTrackerDB.BlockScenarioExpand = value end,
					get   = function(info) return FadeObjectiveTrackerDB.BlockScenarioExpand or false end,
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
