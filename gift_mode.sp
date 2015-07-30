#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <gift>

#define PLUGIN_VERSION "2.0"

new Handle:cVars[2];
new Handle:cGiftChance;
new Handle:cDropChance;
new Handle:cGiftDuration;
new Handle:cGiftCooldown;

new Handle:hCoolTimer[MAXPLAYERS+1];

new Handle:EntityArray;

new isEnabled;
new isRoundActive;
new isCooldown[MAXPLAYERS+1];
//new Float:g_CountTimer[MAXPLAYERS+1];

new Float:g_GiftChance;
new Float:g_DropChance;
new Float:g_GiftDuration;
new Float:g_GiftCooldown;


public Plugin:myinfo = {
	name = "[GiftMod] Gift Mode",
	author = "Tak (chaosxk)",
	description = "Spawns random gift and abilities.",
	version = PLUGIN_VERSION,
};

public OnPluginStart() {
	cVars[0] = CreateConVar("gift_mode_version", PLUGIN_VERSION, "Gift Mode Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cVars[1] = CreateConVar("gift_mode_enabled", "1", "Should this plugin be enabled?");
	cGiftChance = CreateConVar("gift_mode_chance", "0.50", "Chance for a good effect.");
	cDropChance = CreateConVar("gift_mode_dropchance", "0.65", "Chance for a gift to drop.");
	cGiftDuration = CreateConVar("gift_mode_duration", "120.0", "How long before gifts disappears?")
	cGiftCooldown = CreateConVar("gift_mode_cooldown", "60.0", "How long before players can see and pickup gifts.")
	
	HookEvent("teamplay_waiting_ends", OnRoundStart, EventHookMode_Post);
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Post);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Pre);
	HookEvent("teamplay_round_stalemate", OnRoundEnd, EventHookMode_Pre)
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	
	HookConVarChange(cVars[0], cVarChange);
	HookConVarChange(cVars[1], cVarChange);
	HookConVarChange(cGiftChance, cVarChange);
	HookConVarChange(cDropChance, cVarChange);
	HookConVarChange(cGiftDuration, cVarChange);
	HookConVarChange(cGiftCooldown, cVarChange);
	
	EntityArray = CreateArray();
}

public OnPluginEnd() {
	RemoveGift();
	for(new i = 0; i < MaxClients+1; i++) {
		ClearTimer(hCoolTimer[i]);
		isCooldown[i] = 0;
	}
}

public OnLibraryRemoved(const String:name[]) {
	if(StrEqual(name, "gift_abilities")) {
		RemoveGift();
		for(new i = 0; i < MaxClients+1; i++) {
			ClearTimer(hCoolTimer[i]);
			isCooldown[i] = 0;
		}
	}
}

public OnMapEnd() {
	RemoveGift();
	for(new i = 0; i < MaxClients+1; i++) {
		ClearTimer(hCoolTimer[i]);
		isCooldown[i] = 0;
	}
}

public OnClientPutInServer(client) {
	isCooldown[client] = 0;
}

public OnClientDisconnect(client) {
	ClearTimer(hCoolTimer[client]);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	CreateNative("Gift_Spawn", Native_Spawn);
	RegPluginLibrary("gift_mode");
	return APLRes_Success; 
}

public OnConfigsExecuted() {
	isEnabled = GetConVarInt(cVars[1]);
	g_GiftChance = GetConVarFloat(cGiftChance);
	g_DropChance = GetConVarFloat(cDropChance);
	g_GiftDuration = GetConVarFloat(cGiftDuration);
	g_GiftCooldown = GetConVarFloat(cGiftCooldown);
	isRoundActive = 1;
}

public cVarChange(Handle:convar, String:oldValue[], String:newValue[]) {
	if(StrEqual(oldValue, newValue, true)) {
		return;
	}
	new Float:iNewValue = StringToFloat(newValue);
	if(convar == cVars[0]) {
		SetConVarString(cVars[0], PLUGIN_VERSION);
	}
	else if(convar == cVars[1]) {
		isEnabled = RoundFloat(iNewValue);
	}
	else if(convar == cGiftChance) {
		g_GiftChance = iNewValue;
	}
	else if(convar == cDropChance) {
		g_DropChance = iNewValue;
	}
	else if(convar == cGiftDuration) {
		g_GiftDuration = iNewValue;
	}
	else if(convar == cGiftCooldown) {
		g_GiftCooldown = iNewValue;
	}
}

public Action:OnRoundStart(Handle:event, String:name[], bool:dontBroadcast) {
	isRoundActive = 1;
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:event, String:name[], bool:dontBroadcast) {
	isRoundActive = 0;
	for(new i = 0; i < MaxClients+1; i++) {
		ClearTimer(hCoolTimer[i]);
		isCooldown[i] = 0;
	}
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	if(!isEnabled) return Plugin_Continue;
	if(!isRoundActive) return Plugin_Continue;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsValidClient(victim) && IsValidClient(attacker)) {
		if(GetRandomFloat(0.0, 1.0) <= g_DropChance) {
			if(victim != attacker) {
				decl Float:pos[3];
				GetClientAbsOrigin(victim, pos);
				SpawnGift(pos);
			}
		}
	}
	return Plugin_Continue;
}

public Native_Spawn(Handle:plugin, numparams) {
	decl Float:pos[3];
	pos[0] = Float:GetNativeCell(1);
	pos[1] = Float:GetNativeCell(2);
	pos[2] = Float:GetNativeCell(3);
	new bool:success = SpawnGift(pos);
	if(success) return false;
	else return true;
}

bool:SpawnGift(Float:pos[3]) {
	new ent = CreateEntityByName("item_ammopack_small");
	if(IsValidEntity(ent)) {
		DispatchKeyValue(ent, "powerup_model", "models/items/tf_gift.mdl");
		SetEntPropFloat(ent, Prop_Send, "m_flModelScale", 1.0);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR); 
		DispatchSpawn(ent); 
		ActivateEntity(ent);
		SetEntProp(ent, Prop_Send, "m_iTeamNum", 1, 4);
		if(TE_SetupTFParticle("bday_confetti", pos, _, _, ent, 3, 0, false)) {
			TE_SendToAll(0.0);
		}
		EmitAmbientSound("misc/happy_birthday.wav", pos);
		SDKHook(ent, SDKHook_StartTouch, StartTouch);
		SDKHook(ent, SDKHook_SetTransmit, SetTransmit);
		PushArrayCell(EntityArray, EntIndexToEntRef(ent));
		CreateTimer(g_GiftDuration, RemoveGiftTimer, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
		return true;
	}
	return false;
}

public Action:RemoveGiftTimer(Handle:timer, any:entref) { 
	new ent = EntRefToEntIndex(entref); 
	if(IsValidEntity(ent)) {
		AcceptEntityInput(ent, "kill"); 
		new arrayIndex = FindValueInArray(EntityArray, entref);
		if(arrayIndex != -1) {
			RemoveFromArray(EntityArray, arrayIndex);
		}
	}
}

RemoveGift() {
	for(new i = 0; i < GetArraySize(EntityArray); i++) {
		new ent = EntRefToEntIndex(GetArrayCell(EntityArray, i));
		if(IsValidEntity(ent)) {
			AcceptEntityInput(ent, "kill");
		}
	}
}

public Action:StartTouch(entity, client) {
	if(!IsValidClient(client)) return Plugin_Continue;
	if(isCooldown[client]) return Plugin_Continue;
	if(Gift_Active(client) == false) {
		new bool:iGoodEffect;
		AcceptEntityInput(entity, "Kill");
		if(GetRandomFloat(0.0, 1.0) <= g_GiftChance) {
			iGoodEffect = true;
		}
		else iGoodEffect = false;
		if(iGoodEffect == true) {
			new iEffectNum = GetRandomInt(1, Gift_Total());
			/*if(iEffectNum == 1) {
				Gift_Godmode(client);
			}
			else if(iEffectNum == 2) {
				Gift_Toxic(client);
			}
			else if(iEffectNum == 3) {
				Gift_Gravity(client);
			}
			else if(iEffectNum == 4) {
				Gift_Swimming(client);
			}
			else if(iEffectNum == 5) {
				Gift_Bumper(client);
			}*/
			Gift_Incendiary(client);
		}
		else {
			PrintToChat(client, "You got a bad effect.");
		}
		isCooldown[client] = 1;
		hCoolTimer[client] = CreateTimer(g_GiftCooldown+Gift_Duration(), CooldownTimer, GetClientUserId(client));
	}
	return Plugin_Continue;
}

public Action:SetTransmit(entity, client) {
	if(!IsValidClient(client)) return Plugin_Continue;
	if(isCooldown[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:CooldownTimer(Handle:timer, any:userId) {
	new client = GetClientOfUserId(userId);
	isCooldown[client] = 0;
	hCoolTimer[client] = INVALID_HANDLE;
}

bool:IsValidClient( client ) {
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client)) {
		return false; 
	}
	return true; 
}

public ClearTimer(&Handle:timer) {  
	if(timer != INVALID_HANDLE) {  
		KillTimer(timer);  
	}  
	timer = INVALID_HANDLE;  
}

stock bool:TE_SetupTFParticle(String:Name[],
            Float:origin[3] = NULL_VECTOR,
            Float:start[3] = NULL_VECTOR,
            Float:angles[3] = NULL_VECTOR,
            entindex = -1,
            attachtype = -1,
            attachpoint = -1,
            bool:resetParticles = true) {
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx == INVALID_STRING_TABLE) {
        LogError("Could not find string table: ParticleEffectNames");
        return false;
    }
    // find particle index
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    for (new i = 0; i < count; i++) {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false)) {
            stridx = i;
            break;
        }
    }
    if(stridx == INVALID_STRING_INDEX) {
        LogError("Could not find particle: %s", Name);
        return false;
    }
    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if(entindex != -1) TE_WriteNum("entindex", entindex);
    if(attachtype != -1) TE_WriteNum("m_iAttachType", attachtype);
    if(attachpoint != -1) TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
    return true;
}