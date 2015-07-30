#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <gift>

#define PLUGIN_VERSION "2.0"
#define TotalAbilities 8

new Handle:cVersion = INVALID_HANDLE;
new Handle:cDuration = INVALID_HANDLE;
new Handle:gTimer[TotalAbilities][MAXPLAYERS+1];

new Handle:cToxicRadius = INVALID_HANDLE;
new Handle:cToxicDamage = INVALID_HANDLE;
new Handle:cGravity = INVALID_HANDLE;

new Float:g_Duration;
new Float:g_ToxicRadius;
new Float:g_ToxicDamage;
new Float:g_Gravity;

new g_Active[MAXPLAYERS+1];
new Float:g_CountTimer[MAXPLAYERS+1];

enum {
	Disabled = 0,
	Godmode,
	Toxic,
	Gravity,
	Swimming,
	Bumper,
	Scary,
	Knockers,
	Incendiary
};

public Plugin:myinfo = {
	name = "[GiftMod] Gift Abilities",
	author = "Tak (chaosxk)",
	description = "Core function of GiftMod abilities.",
	version = PLUGIN_VERSION,
};

public OnPluginStart() {
	cVersion = CreateConVar("gift_abilities_version", PLUGIN_VERSION, "Gift Abilities Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cDuration = CreateConVar("gift_duration", "15.0", "How many seconds should godmode last?");
	
	cToxicRadius = CreateConVar("gift_toxic_radius", "275.0", "How big of a radius should toxic affect other players?");
	cToxicDamage = CreateConVar("gift_toxic_damage", "900.0", "How much damage should toxic do?");
	cGravity = CreateConVar("gift_gravity_multiplier", "0.1", "How much gravity?");
	
	HookConVarChange(cVersion, cVarChange);
	HookConVarChange(cDuration, cVarChange);
	HookConVarChange(cToxicRadius, cVarChange);
	HookConVarChange(cToxicDamage, cVarChange);
	
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
}

public OnPluginEnd() {
	for(new client = 0; client < MaxClients+1; client++) {
		RemoveEffects(client);
	}
}

public OnMapStart() {
	PrecacheKart();
}

public OnMapEnd() {
	for(new client = 0; client < MaxClients+1; client++) {
		RemoveEffects(client);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	CreateNative("Gift_Total", Native_Total);
	CreateNative("Gift_Duration", Native_Duration)
	CreateNative("Gift_Active", Native_Active);
	CreateNative("Gift_Godmode", Native_Godmode);
	CreateNative("Gift_Toxic", Native_Toxic);
	CreateNative("Gift_Gravity", Native_Gravity);
	CreateNative("Gift_Swimming", Native_Swimming);
	CreateNative("Gift_Bumper", Native_Bumper);
	CreateNative("Gift_Scary", Native_Scary);
	CreateNative("Gift_Knockers", Native_Knockers);
	CreateNative("Gift_Incendiary", Native_Incendiary);
	RegPluginLibrary("gift_abilities");
	return APLRes_Success; 
}

public OnConfigsExecuted() {
	g_Duration = GetConVarFloat(cDuration);
	g_ToxicRadius = GetConVarFloat(cToxicRadius);
	g_ToxicDamage = GetConVarFloat(cToxicDamage);
	g_Gravity = GetConVarFloat(cGravity);
	for(new client = 1; client <= MaxClients; client++) {
		if(IsValidClient(client)) {
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnClientPutInSever(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client) {
	RemoveEffects(client);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public cVarChange(Handle:convar, String:oldValue[], String:newValue[]) {
	if(StrEqual(oldValue, newValue, true)) {
		return;
	}
	new Float:iNewValue = StringToFloat(newValue);
	if(convar == cVersion) {
		SetConVarString(cVersion, PLUGIN_VERSION);
	}
	else if(convar == cDuration) {
		g_Duration = iNewValue;
	}
	else if(convar == cToxicRadius) {
		g_ToxicRadius = iNewValue;
	}
	else if(convar == cToxicDamage) {
		g_ToxicDamage = iNewValue;
	}
	else if(convar == cGravity) {
		g_Gravity = iNewValue;
	}
}

public Action:OnRoundEnd(Handle:event, String:name[], bool:dontBroadcast) {
	for(new client = 0; client < MaxClients+1; client++) {
		RemoveEffects(client);
	}
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(victim)) return Plugin_Continue;
	RemoveEffects(victim);
	return Plugin_Continue;
}

public Native_Total(Handle:plugin, numparams) {
	return TotalAbilities;
}

public Native_Active(Handle:plugin, numparams) {
	new client = GetNativeCell(1);
	if(!IsValidClient(client)) return true;
	if(g_Active[client] != Disabled) return true;
	return false;
}

public Native_Duration(Handle:plugin, numparams) {
	return _:g_Duration;
}

public Native_Godmode(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	if(IsValidClient(client)) {
		g_Active[client] = Godmode;
		TF2_AddCondition(client, TFCond:5, g_Duration);
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		gTimer[0][client] = CreateTimer(g_Duration, Godmode_Timer, GetClientUserId(client));
		PrintToChat(client, "You got a god mode.");
		return true;
	}
	return false;
}

public Action:Godmode_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	g_Active[client] = Disabled;
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	TF2_RemoveCondition(client, TFCond:5);
	gTimer[0][client] = INVALID_HANDLE;
	PrintToChat(client, "Godmode has ended.")
}

public Native_Toxic(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	if(IsValidClient(client)) {
		g_Active[client] = Toxic;
		SetEntityRenderColor(client, 0, 255, 0, _);
		g_CountTimer[client] = g_Duration;
		gTimer[1][client] = CreateTimer(1.0, Toxic_Timer, GetClientUserId(client), TIMER_REPEAT);
		PrintToChat(client, "You got a Toxic.");
		return true;
	}
	return false;
}

public Action:Toxic_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(g_CountTimer[client] == 0) {
		g_Active[client] = Disabled;
		SetEntityRenderColor(client, 255, 255, 255, _);
		gTimer[1][client] = INVALID_HANDLE;
		PrintToChat(client, "Toxic has ended.")
		return Plugin_Stop;
	}
	new clientTeam = GetClientTeam(client);
	for(new victim = 1; victim <= MaxClients; victim++) {
		if(IsValidClient(victim) && client != victim && clientTeam != GetClientTeam(victim)) {
			if(!TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) && g_Active[victim] != Godmode) {
				decl Float:cpos[3], Float:vpos[3];
				GetClientAbsOrigin(client, cpos);
				GetClientAbsOrigin(victim, vpos);
				new Float:Distance = GetVectorDistance(cpos, vpos);
				if(Distance <= g_ToxicRadius) {
					SDKHooks_TakeDamage(victim, 0, client, g_ToxicDamage, DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH|DMG_ALWAYSGIB);
				}
			}
		}
	}
	g_CountTimer[client]--;
	return Plugin_Continue;
}

public Native_Gravity(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	if(IsValidClient(client)) {
		g_Active[client] = Gravity;
		SetEntityGravity(client, g_Gravity);
		gTimer[2][client] = CreateTimer(g_Duration, Gravity_Timer, GetClientUserId(client));
		PrintToChat(client, "You got a Gravity.");
		return true;
	}
	return false;
}

public Action:Gravity_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	g_Active[client] = Disabled;
	SetEntityGravity(client, 1.0);
	gTimer[2][client] = INVALID_HANDLE;
	PrintToChat(client, "Gravity has ended.")
}

public Native_Swimming(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	if(IsValidClient(client)) {
		g_Active[client] = Swimming;
		TF2_AddCondition(client, TFCond:86, g_Duration);
		gTimer[3][client] = CreateTimer(g_Duration, Swimming_Timer, GetClientUserId(client));
		PrintToChat(client, "You can Swimming.");
	}
}

public Action:Swimming_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	g_Active[client] = Disabled;
	TF2_RemoveCondition(client, TFCond:86);
	gTimer[3][client] = INVALID_HANDLE;
	PrintToChat(client, "Swimming has ended.")
}

public Native_Bumper(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	if(IsValidClient(client)) {
		g_Active[client] = Bumper;
		TF2_AddCondition(client, TFCond:82, g_Duration);
		gTimer[4][client] = CreateTimer(g_Duration, Bumper_Timer, GetClientUserId(client));
		PrintToChat(client, "Bumper time.");
	}
}

public Action:Bumper_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	g_Active[client] = Disabled;
	TF2_RemoveCondition(client, TFCond:82);
	gTimer[4][client] = INVALID_HANDLE;
	PrintToChat(client, "Bumper has ended.")
}

public Native_Scary(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	if(IsValidClient(client)) {
		g_Active[client] = Scary;
		gTimer[5][client] = CreateTimer(g_Duration, Scary_Timer, GetClientUserId(client));
		PrintToChat(client, "Scary time");
	}
}

public Action:Scary_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	g_Active[client] = Disabled;
	gTimer[5][client] = INVALID_HANDLE;
	PrintToChat(client, "Scary has ended.")
}

public Native_Knockers(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	if(IsValidClient(client)) {
		g_Active[client] = Knockers;
		gTimer[6][client] = CreateTimer(g_Duration, Knockers_Timer, GetClientUserId(client));
		PrintToChat(client, "Knocker time");
	}
}

public Action:Knockers_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	g_Active[client] = Disabled;
	gTimer[6][client] = INVALID_HANDLE;
	PrintToChat(client, "Knockers has ended.")
}

public Native_Incendiary(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	if(IsValidClient(client)) {
		g_Active[client] = Incendiary;
		gTimer[7][client] = CreateTimer(g_Duration, Incendiary_Timer, GetClientUserId(client));
		PrintToChat(client, "Incendiary time");
	}
}

public Action:Incendiary_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	g_Active[client] = Disabled;
	gTimer[7][client] = INVALID_HANDLE;
	PrintToChat(client, "Incendiary has ended.")
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if(IsValidClient(attacker) && IsValidClient(victim)) {
		if(g_Active[attacker] == Scary) {
			if(attacker != victim) {
				TF2_StunPlayer(victim, 1.0, 0.0, TF_STUNFLAGS_GHOSTSCARE, 0);
			}
		}
		else if(g_Active[attacker] == Knockers) {
			new Float:aang[3], Float:vvel[3], Float:pvec[3];
			GetClientAbsAngles(attacker, aang);
			GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vvel);
			
			if (attacker == victim) {
				vvel[2] += 1000.0;
			} 
			else {
				GetAngleVectors(aang, pvec, NULL_VECTOR, NULL_VECTOR);
				vvel[0] += pvec[0] * 300.0;
				vvel[1] += pvec[1] * 300.0;
				vvel[2] = 500.0;
			}
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vvel);
		}
		else if(g_Active[attacker] == Incendiary) {
			if(attacker != victim) {
				TF2_IgnitePlayer(victim, attacker);
			}
		}
	}
}

public RemoveEffects(client) {
	if(g_Active[client] != Disabled) {
		switch(g_Active[client]) {
			case Godmode: {
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				TF2_RemoveCondition(client, TFCond:5);
				ClearTimer(gTimer[0][client]);
			}
			case Toxic: {
				SetEntityRenderColor(client, 255, 255, 255, _);
				ClearTimer(gTimer[1][client]);
			}
			case Gravity: {
				SetEntityGravity(client, 1.0);
				ClearTimer(gTimer[2][client]);
			}
			case Swimming: {
				TF2_RemoveCondition(client, TFCond:86);
				ClearTimer(gTimer[3][client]);
			}
			case Bumper: {
				TF2_RemoveCondition(client, TFCond:82);
				ClearTimer(gTimer[4][client]);
			}
			case Scary: {
				ClearTimer(gTimer[5][client]);
			}
			case Knockers: {
				ClearTimer(gTimer[6][client]);
			}
			case Incendiary: {
				ClearTimer(gTimer[7][client]);
			}
		}
		g_Active[client] = Disabled;
	}
}

public ClearTimer(&Handle:timer) {  
	if(timer != INVALID_HANDLE) {  
		KillTimer(timer);  
	}  
	timer = INVALID_HANDLE;  
} 

bool:IsValidClient( client ) {
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client)) {
		return false; 
	}
	return true; 
}  

stock PrecacheKart() {
	PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar.mdl", true);
	PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar_nolights.mdl", true);
	PrecacheModel("models/props_halloween/bumpercar_cage.mdl", true);

	PrecacheSound(")weapons/bumper_car_accelerate.wav");
	PrecacheSound(")weapons/bumper_car_decelerate.wav");
	PrecacheSound(")weapons/bumper_car_decelerate_quick.wav");
	PrecacheSound(")weapons/bumper_car_go_loop.wav");
	PrecacheSound(")weapons/bumper_car_hit_ball.wav");
	PrecacheSound(")weapons/bumper_car_hit_ghost.wav");
	PrecacheSound(")weapons/bumper_car_hit_hard.wav");
	PrecacheSound(")weapons/bumper_car_hit_into_air.wav");
	PrecacheSound(")weapons/bumper_car_jump.wav");
	PrecacheSound(")weapons/bumper_car_jump_land.wav");
	PrecacheSound(")weapons/bumper_car_screech.wav");
	PrecacheSound(")weapons/bumper_car_spawn.wav");
	PrecacheSound(")weapons/bumper_car_spawn_from_lava.wav");
	PrecacheSound(")weapons/bumper_car_speed_boost_start.wav");
	PrecacheSound(")weapons/bumper_car_speed_boost_stop.wav");

	decl String:szSnd[64];
	for(new i = 1; i <= 8; i++) {
		FormatEx(szSnd, sizeof(szSnd), "weapons/bumper_car_hit%i.wav", i);
		PrecacheSound(szSnd);
	}
}