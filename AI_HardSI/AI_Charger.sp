#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

ConVar g_hChargerBhop;
ConVar g_hChargeStartSpeed;
ConVar g_hChargeMaxSpeed;
ConVar g_hChargeProximity;
ConVar g_hHealthThresholdCharger;
ConVar g_hAimOffsetSensitivityCharger;

float g_fChargeStartSpeed;
float g_fChargeMaxSpeed;
float g_fChargeProximity;

int g_iHealthThresholdCharger;
int g_iAimOffsetSensitivityCharger;

bool g_bChargerBhop;
bool g_bShouldCharge[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "AI CHARGER",
	author = "Breezy",
	description = "Improves the AI behaviour of special infected",
	version = "1.0",
	url = "github.com/breezyplease"
};

public void OnPluginStart()
{
	g_hChargerBhop = CreateConVar("ai_charger_bhop", "1", "Flag to enable bhop facsimile on AI chargers");
	g_hChargeProximity = CreateConVar("ai_charge_proximity", "300.0", "How close a client will approach before charging");
	g_hHealthThresholdCharger = CreateConVar("ai_health_threshold_charger", "300", "Charger will charge if its health drops to this level");
	g_hAimOffsetSensitivityCharger = CreateConVar("ai_aim_offset_sensitivity_charger", "20", "If the client has a target, it will not straight pounce if the target's aim on the horizontal axis is within this radius", _, true, 0.0, true, 179.0);
	
	g_hChargeStartSpeed = FindConVar("z_charge_start_speed");
	g_hChargeMaxSpeed = FindConVar("z_charge_max_speed");

	g_hChargerBhop.AddChangeHook(ConVarChanged);
	g_hChargeStartSpeed.AddChangeHook(ConVarChanged);
	g_hChargeMaxSpeed.AddChangeHook(ConVarChanged);
	g_hChargeProximity.AddChangeHook(ConVarChanged);
	g_hHealthThresholdCharger.AddChangeHook(ConVarChanged);
	g_hAimOffsetSensitivityCharger.AddChangeHook(ConVarChanged);

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("charger_charge_start", Event_ChargerChargeStart);
}

public void OnConfigsExecuted()
{
	GetCvars();
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bChargerBhop = g_hChargerBhop.BoolValue;
	g_fChargeStartSpeed = g_hChargeStartSpeed.FloatValue;
	g_fChargeMaxSpeed = g_hChargeMaxSpeed.FloatValue;
	g_fChargeProximity = g_hChargeProximity.FloatValue;
	g_iHealthThresholdCharger = g_hHealthThresholdCharger.IntValue;
	g_iAimOffsetSensitivityCharger = g_hAimOffsetSensitivityCharger.IntValue;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bShouldCharge[client] = false;
}

public void Event_ChargerChargeStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client))
		return;

	int flags = GetEntProp(client, Prop_Send, "m_fFlags");
	SetEntProp(client, Prop_Send, "m_fFlags", flags & ~FL_FROZEN);
	Charger_OnCharge(client);
	SetEntProp(client, Prop_Send, "m_fFlags", flags);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(!IsFakeClient(client) || GetClientTeam(client) != 3 || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != 6 || GetEntProp(client, Prop_Send, "m_isGhost") == 1)
		return Plugin_Continue;

	static float fSurvivorProximity;
	fSurvivorProximity = NearestSurvivorDistance(client);
	if(fSurvivorProximity > g_fChargeProximity && GetEntProp(client, Prop_Send, "m_iHealth") > g_iHealthThresholdCharger)
	{
		if(!g_bShouldCharge[client])
			BlockCharge(client);
	}
	else
		g_bShouldCharge[client] = true;
		
	if(g_bShouldCharge[client] && -1.0 < fSurvivorProximity < 100.0 && ReadyAbility(client) && !IsChargeSurvivor(client))
	{
		static int iTarget;
		iTarget = GetClientAimTarget(client, true);
		if(IsAliveSurvivor(iTarget) && !IsIncapacitated(iTarget) && (buttons & IN_ATTACK2 != 0 || !HitWall(client, iTarget)))
		{
			buttons |= IN_ATTACK;
			buttons |= IN_ATTACK2;
			return Plugin_Changed;
		}
	}

	if(g_bChargerBhop && 200.0 < fSurvivorProximity < 1000.0 && GetEntityFlags(client) & FL_ONGROUND != 0 && GetEntityMoveType(client) != MOVETYPE_LADDER && GetEntProp(client, Prop_Data, "m_nWaterLevel") < 2 && GetEntProp(client, Prop_Send, "m_hasVisibleThreats"))
	{
		static float vVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
		if(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0)) > GetEntPropFloat(client, Prop_Data, "m_flMaxspeed") - 30.0)
		{
			static float vEyeAngles[3];
			GetClientEyeAngles(client, vEyeAngles);
			if(Bhop(client, buttons, vEyeAngles))
				return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}
/*
bool Bhop(int client, int &buttons, float vAng[3])
{
	static bool bJumped;
	bJumped = false;

	if(buttons & IN_FORWARD)
	{
		if(Client_Push(client, buttons, vAng, 180.0))
			bJumped = true;
	}
		
	if(buttons & IN_BACK)
	{
		vAng[1] += 180.0;
		if(Client_Push(client, buttons, vAng, 90.0))
			bJumped = true;
	}
	
	if(buttons & IN_MOVELEFT)
	{
		vAng[1] += 90.0;
		if(Client_Push(client, buttons, vAng, 90.0))
			bJumped = true;
	}

	if(buttons & IN_MOVERIGHT)
	{
		vAng[1] -= 90.0;
		if(Client_Push(client, buttons, vAng, 90.0))
			bJumped = true;
	}
	
	return bJumped;
}

bool Client_Push(int client, int &buttons, const float vAng[3], float fForce)
{
	static float vVec[3];
	GetAngleVectors(vAng, vVec, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vVec, vVec);
	ScaleVector(vVec, fForce);

	static float vVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVel);
	AddVectors(vVel, vVec, vVel);

	if(WontFall(client, vVel))
	{
		buttons |= IN_DUCK;
		buttons |= IN_JUMP;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
		return true;
	}

	return false;
}
*/
bool Bhop(int client, int &buttons, const float vAng[3])
{
	static bool bJumped;
	bJumped = false;

	static float vVec[3];

	if(buttons & IN_FORWARD || buttons & IN_BACK)
	{
		GetAngleVectors(vAng, vVec, NULL_VECTOR, NULL_VECTOR);
		if(Client_Push(client, buttons, vVec, buttons & IN_FORWARD ? 180.0 : -90.0))
			bJumped = true;
	}

	if(buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT)
	{
		GetAngleVectors(vAng, NULL_VECTOR, vVec, NULL_VECTOR);
		if(Client_Push(client, buttons, vVec, buttons & IN_MOVELEFT ? -90.0 : 90.0))
			bJumped = true;
	}

	return bJumped;
}

bool Client_Push(int client, int &buttons, float vVec[3], float fForce)
{
	NormalizeVector(vVec, vVec);
	ScaleVector(vVec, fForce);

	static float vVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVel);
	AddVectors(vVel, vVec, vVel);

	if(WontFall(client, vVel, vVec))
	{
		buttons |= IN_DUCK;
		buttons |= IN_JUMP;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
		return true;
	}

	return false;
}

#define JUMP_HEIGHT 56.0
bool WontFall(int client, const float vVel[3], const float vVec[3])
{
	static float vStart[3];
	static float vEnd[3];
	GetClientAbsOrigin(client, vStart);
	AddVectors(vStart, vVel, vEnd);

	static float vMins[3];
	static float vMaxs[3];
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);

	vStart[2] += 20.0;

	static float fHeight;
	fHeight = vVel[2] > 0.0 ? vVel[2] : JUMP_HEIGHT;

	vEnd[2] += fHeight;
	static Handle hTrace;
	hTrace = TR_TraceHullFilterEx(vStart, vEnd, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, TraceEntityFilter);
	vEnd[2] -= fHeight;

	static bool bDidHit;
	bDidHit = false;

	static float vEndNonCol[3];

	if(hTrace != null)
	{
		if(TR_DidHit(hTrace))
		{
			bDidHit = true;
			TR_GetEndPosition(vEndNonCol, hTrace);
			if(GetVectorDistance(vStart, vEndNonCol) < 64.0)
			{
				delete hTrace;
				return false;
			}

			static float fAngle;
			static float vNormal[3];
			TR_GetPlaneNormal(hTrace, vNormal);
			fAngle = GetAngleBetweenVectors(vVel, vNormal, vVec);
			if(fAngle == 90.0 || fAngle > 135.0)
			{
				delete hTrace;
				return false;
			}
		}
		delete hTrace;
	}
	
	if(!bDidHit)
		vEndNonCol = vEnd;

	static float vDown[3];
	vDown[0] = vEndNonCol[0];
	vDown[1] = vEndNonCol[1];
	vDown[2] = vEndNonCol[2] - 100000.0;

	hTrace = TR_TraceHullFilterEx(vEndNonCol, vDown, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, TraceEntityFilter);
	if(hTrace != null)
	{
		if(TR_DidHit(hTrace))
		{
			TR_GetEndPosition(vEnd, hTrace);
			if(vEndNonCol[2] - vEnd[2] > 120.0)
			{
				delete hTrace;
				return false;
			}

			static int entity;
			static char sClassName[13];
			if((entity = TR_GetEntityIndex(hTrace)) > MaxClients)
			{
				GetEdictClassname(entity, sClassName, sizeof(sClassName));
				if(strcmp(sClassName, "trigger_hurt") == 0)
				{
					delete hTrace;
					return false;
				}
			}
			delete hTrace;
			return true;
		}
		delete hTrace;
	}
	return false;
}

//---------------------------------------------------------
// calculate the angle between 2 vectors
// the direction will be used to determine the sign of angle (right hand rule)
// all of the 3 vectors have to be normalized
//---------------------------------------------------------
float GetAngleBetweenVectors(const float vector1[3], const float vector2[3], const float direction[3])
{
	static float vector1_n[3], vector2_n[3], direction_n[3], cross[3];
	NormalizeVector(direction, direction_n);
	NormalizeVector(vector1, vector1_n);
	NormalizeVector(vector2, vector2_n);
	static float degree;
	degree = ArcCosine(GetVectorDotProduct(vector1_n, vector2_n )) * 57.29577951;   // 180/Pi
	GetVectorCrossProduct(vector1_n, vector2_n, cross);

	if(GetVectorDotProduct(cross, direction_n ) < 0.0)
		degree *= -1.0;

	return degree;
}

public bool TraceEntityFilter(int entity, int contentsMask)
{
	if(entity <= MaxClients)
		return false;
	else
	{
		static char sClassName[9];
		GetEntityClassname(entity, sClassName, sizeof(sClassName));
		if(sClassName[0] == 'i' || sClassName[0] == 'w')
		{
			if(strcmp(sClassName, "infected") == 0 || strcmp(sClassName, "witch") == 0)
				return false;
		}
	}

	return true;
}

float NearestSurvivorDistance(int client)
{
	static int i;
	static int iNum;
	static float vOrigin[3];
	static float vTarget[3];
	static float fDists[MAXPLAYERS + 1];
	
	iNum = 0;

	GetClientAbsOrigin(client, vOrigin);

	for(i = 1; i <= MaxClients; i++)
	{
		if(i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, vTarget);
			fDists[iNum++] = GetVectorDistance(vOrigin, vTarget);
		}
	}

	if(iNum == 0)
		return -1.0;

	SortFloats(fDists, iNum, Sort_Ascending);
	return fDists[0];
}

bool HitWall(int client, int iTarget)
{
	static float vPos[3];
	GetClientAbsOrigin(client, vPos);
	
	static float vTarget[3];
	GetClientAbsOrigin(iTarget, vTarget);

	static float vMins[3];
	static float vMaxs[3];
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);
	
	vMins[0] += 3.0;
	vMins[1] += 3.0;
	vMins[2] += 3.0;
	vMaxs[0] -= 3.0;
	vMaxs[1] -= 3.0;
	vMaxs[2] -= 32.5;

	vPos[2] += 20.0;
	vTarget[2] += 20.0;

	static Handle hTrace;
	hTrace = TR_TraceHullFilterEx(vPos, vTarget, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, TraceEntityFilter);

	static float vEndNonCol[3];

	if(hTrace != null)
	{
		if(TR_DidHit(hTrace))
		{
			TR_GetEndPosition(vEndNonCol, hTrace);
			if(GetVectorDistance(vEndNonCol, vTarget) < 32.0)
			{
				delete hTrace;
				return false;
			}
			delete hTrace;
			return true;
		}
		delete hTrace;
		return false;
	}

	return true;
}

bool IsChargeSurvivor(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_pummelVictim") > 0 || GetEntPropEnt(client, Prop_Send, "m_carryVictim") > 0;
}

bool ReadyAbility(int client)
{
	static int iAbility;
	iAbility = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	return iAbility != -1 && GetEntPropFloat(iAbility, Prop_Send, "m_timestamp") < GetGameTime();
}

void BlockCharge(int client)
{
	static int iAbility;
	iAbility = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if(iAbility != -1)
		SetEntPropFloat(iAbility, Prop_Send, "m_timestamp", GetGameTime() + 0.1);	
}

#define CROUCHING_HEIGHT 56.0
void Charger_OnCharge(int client)
{
	static int iAimTarget;

	iAimTarget = GetClientAimTarget(client, true);
	if(!IsAliveSurvivor(iAimTarget) || IsIncapacitated(iAimTarget) || IsPinned(iAimTarget) || IsTargetWatchingAttacker(client, g_iAimOffsetSensitivityCharger))
	{
		static int iNewTarget;
		iNewTarget = GetClosestSurvivor(client, iAimTarget, g_fChargeProximity > g_fChargeMaxSpeed ? g_fChargeProximity : g_fChargeMaxSpeed);
		if(iNewTarget != -1)
			iAimTarget = iNewTarget;
	}

	static float vAngles[3];
	static float vVectors[3];
	static float vVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVelocity);

	static float vLength;
	vLength = GetVectorLength(vVelocity) + CROUCHING_HEIGHT;
	vLength = vLength < g_fChargeStartSpeed ? g_fChargeStartSpeed : vLength;

	if(IsAliveSurvivor(iAimTarget))
	{
		static float vOrigin[3];
		static float vTarget[3];

		GetClientAbsOrigin(client, vOrigin);
		GetClientAbsOrigin(iAimTarget, vTarget);

		vTarget[2] += CROUCHING_HEIGHT;

		MakeVectorFromPoints(vOrigin, vTarget, vVectors);

		GetVectorAngles(vVectors, vAngles);

		//vLength += GetEntPropFloat(iAimTarget, Prop_Data, "m_flMaxspeed");
	}
	else
	{
		GetClientEyeAngles(client, vAngles);

		vVectors[0] = Cosine(DegToRad(vAngles[1])) * Cosine(DegToRad(vAngles[0]));
		vVectors[1] = Sine(DegToRad(vAngles[1])) * Cosine(DegToRad(vAngles[0]));
		vVectors[2] = Sine(DegToRad(vAngles[0]));

		//vLength += NearestSurvivorDistance(client);
	}
	
	NormalizeVector(vVectors, vVectors);
	ScaleVector(vVectors, vLength);
	TeleportEntity(client, NULL_VECTOR, vAngles, vVectors);
}

bool IsAliveSurvivor(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool IsIncapacitated(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool IsPinned(int client)
{
	if(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	/*if(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
		return true;*/
	return false;
}

bool IsTargetWatchingAttacker(int iAttacker, int iOffsetThreshold)
{
	static int iTarget;
	static bool bIsWatching;

	bIsWatching = true;
	iTarget = GetClientAimTarget(iAttacker);
	if(IsAliveSurvivor(iTarget))
	{
		static int iAimOffset;
		iAimOffset = RoundToNearest(GetPlayerAimOffset(iTarget, iAttacker));
		if(iAimOffset <= iOffsetThreshold)
			bIsWatching = true;
		else 
			bIsWatching = false;
	}
	return bIsWatching;
}

float GetPlayerAimOffset(int iAttacker, int iTarget)
{
	static float vAim[3];
	static float vTarget[3];
	static float vAttacker[3];

	GetClientEyeAngles(iAttacker, vAim);
	vAim[0] = vAim[2] = 0.0;
	GetAngleVectors(vAim, vAim, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAim, vAim);
	
	GetClientAbsOrigin(iTarget, vTarget);
	GetClientAbsOrigin(iAttacker, vAttacker);
	vAttacker[2] = vTarget[2] = 0.0;
	MakeVectorFromPoints(vAttacker, vTarget, vAttacker);
	NormalizeVector(vAttacker, vAttacker);
	
	return RadToDeg(ArcCosine(GetVectorDotProduct(vAim, vAttacker)));
}

int GetClosestSurvivor(int client, int iAimTarget = -1, float fDistance)
{
	static int i;
	static int iNum;
	static float fDist;
	static float vOrigin[3];
	static float vTarget[3];
	static int iTargets[MAXPLAYERS + 1];
	
	iNum = 0;
	GetClientEyePosition(client, vOrigin);
	iNum = GetClientsInRange(vOrigin, RangeType_Visibility, iTargets, MAXPLAYERS);
	
	if(iNum == 0)
		return -1;
			
	static int iTarget;
	static ArrayList aTargets;
	aTargets = new ArrayList(2);
	
	for(i = 0; i < iNum; i++)
	{
		iTarget = iTargets[i];
		if(iTarget && iTarget != iAimTarget && GetClientTeam(iTarget) == 2 && IsPlayerAlive(iTarget) && !IsIncapacitated(iTarget) && !IsPinned(iTarget) && !HitWall(client, iTarget))
		{
			GetClientAbsOrigin(iTarget, vTarget);
			fDist = GetVectorDistance(vOrigin, vTarget);
			if(fDist < fDistance)
				aTargets.Set(aTargets.Push(fDist), iTarget, 1);
		}
	}

	if(aTargets.Length == 0)
	{
		iNum = 0;
		
		GetClientAbsOrigin(client, vOrigin);
		
		for(i = 1; i <= MaxClients; i++)
		{
			if(i != iAimTarget && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsIncapacitated(i) && !IsPinned(i) && !HitWall(client, i))
			{
				GetClientAbsOrigin(i, vTarget);
				fDist = GetVectorDistance(vOrigin, vTarget);
				if(fDist < fDistance)
					aTargets.Set(aTargets.Push(fDist), i, 1);
			}
		}
		
		if(aTargets.Length == 0)
		{
			delete aTargets;
			return -1;
		}
	}

	aTargets.Sort(Sort_Ascending, Sort_Float);
	iAimTarget = aTargets.Get(0, 1);
	delete aTargets;
	return iAimTarget;
}