#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <dhooks>

#define PLUGIN_NAME				"bots(coop)"
#define PLUGIN_AUTHOR			"DDRKhat, Marcus101RR, Merudo, Lux, Shadowysn, sorallll"
#define PLUGIN_DESCRIPTION		"coop"
#define PLUGIN_VERSION			"1.10.8"
#define PLUGIN_URL				"https://forums.alliedmods.net/showthread.php?p=2405322#post2405322"

#define GAMEDATA 		"bots"
#define CVAR_FLAGS 		FCVAR_NOTIFY
#define MAX_SLOTS		5
#define TEAM_NOTEAM		0
#define TEAM_SPECTATOR	1
#define TEAM_SURVIVOR	2
#define TEAM_INFECTED   3
#define JOIN_MANUAL		(1 << 0)
#define JOIN_AUTOMATIC	(1 << 1)
#define SOUND_SPECMENU	"ui/helpful_event_1.wav"

Handle
	g_hBotsTimer,
	g_hSDK_NextBotCreatePlayerBot_SurvivorBot,
	g_hSDK_CTerrorPlayer_RoundRespawn,
	g_hSDK_CCSPlayer_State_Transition,
	g_hSDK_SurvivorBot_SetHumanSpectator,
	g_hSDK_CTerrorPlayer_TakeOverBot,
	//g_hSDK_CTerrorPlayer_GoAwayFromKeyboard,
	g_hSDK_CDirector_IsInTransition;

StringMap
	g_smSteamIDs;

ArrayList
	g_aMeleeScripts;

Address
	g_pDirector,
	g_pStatsCondition;

ConVar
	g_cvBotsLimit,
	g_cvJoinFlags,
	g_cvRespawnJoin,
	g_cvSpecLimit,
	g_cvSpecNotify,
	g_cvGiveType,
	g_cvGiveTime,
	g_cvSurvivorLimit;

int
	g_iRoundStart,
	g_iSurvivorBot,
	g_iBotsLimit,
	g_iJoinFlags,
	g_iSpecLimit,
	g_iSpecNotify,
	g_iOff_m_restoreCSWeaponID1,
	g_iOff_m_iRestoreAmmoCount,
	g_iOff_m_restoreCSWeaponID2,
	g_iOff_m_hHiddenWeapon;

bool
	g_bRespawnJoin,
	g_bGiveType,
	g_bGiveTime,
	g_bInSpawnTime,
	g_bShouldFixAFK,
	g_bShouldIgnore,
	g_bHideNameChange;

enum struct esWeapon {
	ConVar cvFlags;

	int iCount;
	int iAllowed[20];
}

esWeapon
	g_esWeapon[MAX_SLOTS];

enum struct esPlayer {
	int iPlayerBot;
	int iBotPlayer;

	bool bSpecNotify;

	char sModel[PLATFORM_MAX_PATH];
	char sSteamID[32];
}

esPlayer
	g_esPlayer[MAXPLAYERS + 1];

static const char
	g_sSurvivorNames[][] = {
		"Nick",
		"Rochelle",
		"Coach",
		"Ellis",
		"Bill",
		"Zoey",
		"Francis",
		"Louis"
	},
	g_sSurvivorModels[][] = {
		"models/survivors/survivor_gambler.mdl",
		"models/survivors/survivor_producer.mdl",
		"models/survivors/survivor_coach.mdl",
		"models/survivors/survivor_mechanic.mdl",
		"models/survivors/survivor_namvet.mdl",
		"models/survivors/survivor_teenangst.mdl",
		"models/survivors/survivor_biker.mdl",
		"models/survivors/survivor_manager.mdl"
	},
	g_sWeaponName[MAX_SLOTS][][] = {
		{//slot 0(主武器)
			"weapon_smg",						//1 UZI微冲
			"weapon_smg_mp5",					//2 MP5
			"weapon_smg_silenced",				//4 MAC微冲
			"weapon_pumpshotgun",				//8 木喷
			"weapon_shotgun_chrome",			//16 铁喷
			"weapon_rifle",						//32 M16步枪
			"weapon_rifle_desert",				//64 三连步枪
			"weapon_rifle_ak47",				//128 AK47
			"weapon_rifle_sg552",				//256 SG552
			"weapon_autoshotgun",				//512 一代连喷
			"weapon_shotgun_spas",				//1024 二代连喷
			"weapon_hunting_rifle",				//2048 木狙
			"weapon_sniper_military",			//4096 军狙
			"weapon_sniper_scout",				//8192 鸟狙
			"weapon_sniper_awp",				//16384 AWP
			"weapon_rifle_m60",					//32768 M60
			"weapon_grenade_launcher"			//65536 榴弹发射器
		},
		{//slot 1(副武器)
			"weapon_pistol",					//1 小手枪
			"weapon_pistol_magnum",				//2 马格南
			"weapon_chainsaw",					//4 电锯
			"fireaxe",							//8 斧头
			"frying_pan",						//16 平底锅
			"machete",							//32 砍刀
			"baseball_bat",						//64 棒球棒
			"crowbar",							//128 撬棍
			"cricket_bat",						//256 球拍
			"tonfa",							//512 警棍
			"katana",							//1024 武士刀
			"electric_guitar",					//2048 电吉他
			"knife",							//4096 小刀
			"golfclub",							//8192 高尔夫球棍
			"shovel",							//16384 铁铲
			"pitchfork",						//32768 草叉
			"riotshield",						//65536 盾牌
		},
		{//slot 2(投掷物)
			"weapon_molotov",					//1 燃烧瓶
			"weapon_pipe_bomb",					//2 管制炸弹
			"weapon_vomitjar",					//4 胆汁瓶
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			""
		},
		{//slot 3
			"weapon_first_aid_kit",				//1 医疗包
			"weapon_defibrillator",				//2 电击器
			"weapon_upgradepack_incendiary",	//4 燃烧弹药包
			"weapon_upgradepack_explosive",		//8 高爆弹药包
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			""
		},
		{//slot 4
			"weapon_pain_pills",				//1 止痛药
			"weapon_adrenaline",				//2 肾上腺素
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			""
		}
	},
	g_sWeaponModels[][] = {
		"models/w_models/weapons/w_smg_uzi.mdl",
		"models/w_models/weapons/w_smg_mp5.mdl",
		"models/w_models/weapons/w_smg_a.mdl",
		"models/w_models/weapons/w_pumpshotgun_A.mdl",
		"models/w_models/weapons/w_shotgun.mdl",
		"models/w_models/weapons/w_rifle_m16a2.mdl",
		"models/w_models/weapons/w_desert_rifle.mdl",
		"models/w_models/weapons/w_rifle_ak47.mdl",
		"models/w_models/weapons/w_rifle_sg552.mdl",
		"models/w_models/weapons/w_autoshot_m4super.mdl",
		"models/w_models/weapons/w_shotgun_spas.mdl",
		"models/w_models/weapons/w_sniper_mini14.mdl",
		"models/w_models/weapons/w_sniper_military.mdl",
		"models/w_models/weapons/w_sniper_scout.mdl",
		"models/w_models/weapons/w_sniper_awp.mdl",
		"models/w_models/weapons/w_m60.mdl",
		"models/w_models/weapons/w_grenade_launcher.mdl",
	
		"models/w_models/weapons/w_pistol_a.mdl",
		"models/w_models/weapons/w_desert_eagle.mdl",
		"models/weapons/melee/w_chainsaw.mdl",
		"models/weapons/melee/v_fireaxe.mdl",
		"models/weapons/melee/w_fireaxe.mdl",
		"models/weapons/melee/v_frying_pan.mdl",
		"models/weapons/melee/w_frying_pan.mdl",
		"models/weapons/melee/v_machete.mdl",
		"models/weapons/melee/w_machete.mdl",
		"models/weapons/melee/v_bat.mdl",
		"models/weapons/melee/w_bat.mdl",
		"models/weapons/melee/v_crowbar.mdl",
		"models/weapons/melee/w_crowbar.mdl",
		"models/weapons/melee/v_cricket_bat.mdl",
		"models/weapons/melee/w_cricket_bat.mdl",
		"models/weapons/melee/v_tonfa.mdl",
		"models/weapons/melee/w_tonfa.mdl",
		"models/weapons/melee/v_katana.mdl",
		"models/weapons/melee/w_katana.mdl",
		"models/weapons/melee/v_electric_guitar.mdl",
		"models/weapons/melee/w_electric_guitar.mdl",
		"models/v_models/v_knife_t.mdl",
		"models/w_models/weapons/w_knife_t.mdl",
		"models/weapons/melee/v_golfclub.mdl",
		"models/weapons/melee/w_golfclub.mdl",
		"models/weapons/melee/v_shovel.mdl",
		"models/weapons/melee/w_shovel.mdl",
		"models/weapons/melee/v_pitchfork.mdl",
		"models/weapons/melee/w_pitchfork.mdl",
		"models/weapons/melee/v_riotshield.mdl",
		"models/weapons/melee/w_riotshield.mdl",

		"models/w_models/weapons/w_eq_molotov.mdl",
		"models/w_models/weapons/w_eq_pipebomb.mdl",
		"models/w_models/weapons/w_eq_bile_flask.mdl",

		"models/w_models/weapons/w_eq_medkit.mdl",
		"models/w_models/weapons/w_eq_defibrillator.mdl",
		"models/w_models/weapons/w_eq_incendiary_ammopack.mdl",
		"models/w_models/weapons/w_eq_explosive_ammopack.mdl",

		"models/w_models/weapons/w_eq_adrenaline.mdl",
		"models/w_models/weapons/w_eq_painpills.mdl"
	};

// 如果签名失效，请到此处更新 (https://github.com/Psykotikism/L4D1-2_Signatures)
public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() {
	vInitData();
	g_smSteamIDs = new StringMap();
	g_aMeleeScripts = new ArrayList(64);

	AddCommandListener(spec_next_Listener, "spec_next");
	HookUserMessage(GetUserMessageId("SayText2"), umSayText2, true);

	CreateConVar("bots_version", PLUGIN_VERSION, "bots(coop) plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_cvBotsLimit = 			CreateConVar("bots_limit", 				"4", 		"开局Bot的数量", CVAR_FLAGS, true, 1.0, true, 31.0);
	g_cvJoinFlags = 			CreateConVar("bots_join_flags", 		"3", 		"加入生还者的方法. \n0=插件不进行处理, 1=输入!join手动加入, 2=进服后插件自动加入, 3=手动+自动", CVAR_FLAGS);
	g_cvRespawnJoin = 			CreateConVar("bots_respawn_join", 		"1", 		"玩家第一次进服时如果没有存活的Bot可以接管是否复活. \n0=否, 1=是.", CVAR_FLAGS);
	g_cvSpecLimit = 			CreateConVar("bots_spec_limit", 		"1", 		"当完全旁观玩家达到多少个时禁止使用sm_spec命令.", CVAR_FLAGS);
	g_cvSpecNotify = 			CreateConVar("bots_spec_notify", 		"3", 		"完全旁观玩家点击鼠标左键时, 提示加入生还者的方式 \n0=不提示, 1=聊天栏, 2=屏幕中央, 3=弹出菜单.", CVAR_FLAGS);
	g_esWeapon[0].cvFlags = 	CreateConVar("bots_give_slot0", 		"131071", 	"主武器给什么. \n0=不给, 131071=所有, 7=微冲, 1560=霰弹, 30720=狙击, 31=Tier1, 32736=Tier2, 98304=Tier0.", CVAR_FLAGS);
	g_esWeapon[1].cvFlags = 	CreateConVar("bots_give_slot1", 		"1064", 	"副武器给什么. \n0=不给, 131071=所有.(如果选中了近战且该近战在当前地图上未解锁,则会随机给一把).", CVAR_FLAGS);
	g_esWeapon[2].cvFlags = 	CreateConVar("bots_give_slot2", 		"0", 		"投掷物给什么. \n0=不给, 7=所有.", CVAR_FLAGS);
	g_esWeapon[3].cvFlags =		CreateConVar("bots_give_slot3", 		"1", 		"医疗品给什么. \n0=不给, 15=所有.", CVAR_FLAGS);
	g_esWeapon[4].cvFlags =		CreateConVar("bots_give_slot4", 		"3", 		"药品给什么. \n0=不给, 3=所有.", CVAR_FLAGS);
	g_cvGiveType = 				CreateConVar("bots_give_type", 			"2", 		"根据什么来给玩家装备. \n0=不给, 1=每个槽位的设置, 2=当前存活生还者的平均装备质量(仅主副武器).", CVAR_FLAGS);
	g_cvGiveTime = 				CreateConVar("bots_give_time", 			"0", 		"什么时候给玩家装备. \n0=每次出生时, 1=只在本插件创建Bot和复活玩家时.", CVAR_FLAGS);

	g_cvSurvivorLimit = FindConVar("survivor_limit");
	g_cvSurvivorLimit.Flags &= ~FCVAR_NOTIFY; // 移除ConVar变动提示
	g_cvSurvivorLimit.SetBounds(ConVarBound_Upper, true, 31.0);

	g_cvBotsLimit.AddChangeHook(vCvarChanged_Limit);

	g_cvJoinFlags.AddChangeHook(vCvarChanged_General);
	g_cvRespawnJoin.AddChangeHook(vCvarChanged_General);
	g_cvSpecLimit.AddChangeHook(vCvarChanged_General);
	g_cvSpecNotify.AddChangeHook(vCvarChanged_General);

	g_esWeapon[0].cvFlags.AddChangeHook(vCvarChanged_Weapon);
	g_esWeapon[1].cvFlags.AddChangeHook(vCvarChanged_Weapon);
	g_esWeapon[2].cvFlags.AddChangeHook(vCvarChanged_Weapon);
	g_esWeapon[3].cvFlags.AddChangeHook(vCvarChanged_Weapon);
	g_esWeapon[4].cvFlags.AddChangeHook(vCvarChanged_Weapon);

	g_cvGiveType.AddChangeHook(vCvarChanged_Weapon);
	g_cvGiveTime.AddChangeHook(vCvarChanged_Weapon);
	
	AutoExecConfig(true, "bots");

	RegConsoleCmd("sm_teams", 	cmdTeamPanel, 	"团队菜单");
	RegConsoleCmd("sm_spec", 	cmdJoinTeam1, 	"加入旁观者");
	RegConsoleCmd("sm_join", 	cmdJoinTeam2, 	"加入生还者");
	RegConsoleCmd("sm_tkbot", 	cmdTakeOverBot, "接管指定BOT");

	RegAdminCmd("sm_afk", 		cmdGoAFK,	ADMFLAG_RCON,	"闲置");
	RegAdminCmd("sm_botset",	cmdBotSet,	ADMFLAG_RCON,	"设置开局Bot的数量");

	HookEvent("round_end", 				Event_RoundEnd, 	EventHookMode_PostNoCopy);
	HookEvent("round_start", 			Event_RoundStart, 	EventHookMode_PostNoCopy);
	HookEvent("player_spawn", 			Event_PlayerSpawn);
	HookEvent("player_death", 			Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", 			Event_PlayerTeam);
	HookEvent("player_bot_replace", 	Event_PlayerBotReplace);
	HookEvent("bot_player_replace", 	Event_BotPlayerReplace);
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
}

public void OnPluginEnd() {
	vStatsConditionPatch(false);
}

Action cmdTeamPanel(int client, int args) {
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	vDisplayTeamPanel(client);
	return Plugin_Handled;
}

Action cmdJoinTeam1(int client, int args) {
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	bool bIdle = !!iGetBotOfIdlePlayer(client);
	if (!bIdle && GetClientTeam(client) == TEAM_SPECTATOR) {
		PrintToChat(client, "你当前已在旁观者队伍.");
		return Plugin_Handled;
	}
	
	if (iGetSpectatorCount() >= g_iSpecLimit) {
		PrintToChat(client, "\x05当前旁观者数量已达到限制\x01-> \x04%d\x01.", g_iSpecLimit);
		return Plugin_Handled;
	}

	if (bIdle)
		SDKCall(g_hSDK_CTerrorPlayer_TakeOverBot, client, true);

	ChangeClientTeam(client, TEAM_SPECTATOR);
	return Plugin_Handled;
}

int iGetSpectatorCount() {
	int iCount;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SPECTATOR && !iGetBotOfIdlePlayer(i))
			iCount++;
	}
	return iCount;
}

Action cmdJoinTeam2(int client, int args) {
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;
	/*
	if (bIsInTransition())
		return Plugin_Handled;*/

	if (!(g_iJoinFlags & JOIN_MANUAL)) {
		PrintToChat(client, "手动加入已禁用.");
		return Plugin_Handled;
	}

	if (!g_iRoundStart) {
		PrintToChat(client, "回合尚未开始.");
		return Plugin_Handled;
	}

	switch (GetClientTeam(client)) {
		case TEAM_SPECTATOR: {
			if (iGetBotOfIdlePlayer(client))
				return Plugin_Handled;
		}

		case TEAM_SURVIVOR: {
			PrintToChat(client, "你当前已在生还者队伍.");
			return Plugin_Handled;
		}

		default:
			ChangeClientTeam(client, TEAM_SPECTATOR);
	}

	return aJoinTeam2(client);
}

Action aJoinTeam2(int client) {
	bool bCanRespawn = g_bRespawnJoin && bIsFirstTime(client);
	int iBot = GetClientOfUserId(g_esPlayer[client].iPlayerBot);
	if (!iBot || !bIsValidSurBot(iBot))
		iBot = iFindUselessSurBot(true);

	if (!iBot) {
		if ((iBot = iAddSurBot()) == -1) {
			ChangeClientTeam(client, TEAM_SURVIVOR);
			if (!IsPlayerAlive(client)) {
				if (bCanRespawn)
					vRoundRespawn(client);
				else
					PrintToChat(client, "\x05重复加入默认为\x01-> \x04死亡状态\x01.");
			}
	
			if (IsPlayerAlive(client))
				vTeleportToSurvivor(client);

			return Plugin_Handled;
		}
		else if (IsPlayerAlive(iBot)) {
			if (bCanRespawn)
				vTeleportToSurvivor(iBot);
			else
				SDKCall(g_hSDK_CCSPlayer_State_Transition, iBot, 6);
		}
	}

	if (bCanRespawn) {
		if (!IsPlayerAlive(iBot)) {
			vRoundRespawn(iBot);
			vTeleportToSurvivor(iBot);
		}

		vSetHumanSpectator(iBot, client);
	}
	else {
		if (IsPlayerAlive(iBot))
			vSetHumanSpectator(iBot, client);
		else {
			SDKCall(g_hSDK_SurvivorBot_SetHumanSpectator, iBot, client);
			SDKCall(g_hSDK_CTerrorPlayer_TakeOverBot, client, true);
			PrintToChat(client, "\x05重复加入默认为\x01-> \x04死亡状态\x01.");
		}		
	}

	return Plugin_Handled;
}

Action cmdTakeOverBot(int client, int args) {
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	if (!iClientTeamTakeOver(client)) {
		PrintToChat(client, "不符合接管条件.");
		return Plugin_Handled;
	}

	if (!iFindUselessSurBot(true)) {
		PrintToChat(client, "\x01没有 \x05空闲的电脑BOT \x01可以接管\x01.");
		return Plugin_Handled;
	}

	vTakeOverBotMenu(client);
	return Plugin_Handled;
}

int iClientTeamTakeOver(int client) {
	int iTeam = GetClientTeam(client);
	switch (iTeam) {
		case TEAM_SPECTATOR: {
			if (iGetBotOfIdlePlayer(client))
				iTeam = 0;
		}

		case TEAM_SURVIVOR: {
			if (IsPlayerAlive(client))
				iTeam = 0;
		}
	}
	return iTeam;
}

void vTakeOverBotMenu(int client) {
	char item[12];
	char info[64];
	Menu menu = new Menu(iTakeOverBot_MenuHandler);
	menu.SetTitle("- 请选择接管目标 - [!tkbot]");
	menu.AddItem("o", "当前旁观目标");

	for (int i = 1; i <= MaxClients; i++) {
		if (!bIsValidSurBot(i))
			continue;

		FormatEx(item, sizeof item, "%d", GetClientUserId(i));
		FormatEx(info, sizeof info, "%s - %s", IsPlayerAlive(i) ? "存活" : "死亡", sGetModelName(i));
		menu.AddItem(item, info);
	}

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// L4D2_Adrenaline_Recovery (https://github.com/LuxLuma/L4D2_Adrenaline_Recovery)
char[] sGetModelName(int client) {
	int iChar;
	char sModel[31];
	GetClientModel(client, sModel, sizeof sModel);
	switch (sModel[29]) {
		case 'b'://nick
			iChar = 0;
		case 'd'://rochelle
			iChar = 1;
		case 'c'://coach
			iChar = 2;
		case 'h'://ellis
			iChar = 3;
		case 'v'://bill
			iChar = 4;
		case 'n'://zoey
			iChar = 5;
		case 'e'://francis
			iChar = 6;
		case 'a'://louis
			iChar = 7;
		default:
			iChar = 8;
	}

	strcopy(sModel, sizeof sModel, iChar == 8 ? "未知" : g_sSurvivorNames[iChar]);
	return sModel;
}

int iTakeOverBot_MenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_Select: {
			int iBot;
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			if (item[0] == 'o') {
				iBot = GetEntPropEnt(param1, Prop_Send, "m_hObserverTarget");
				if (iBot > 0 && bIsValidSurBot(iBot))
					vTakeOverBot(param1, iBot);
				else
					PrintToChat(param1, "当前旁观目标非可接管BOT.");
			}
			else {
				iBot = GetClientOfUserId(StringToInt(item));
				if (!iBot || !bIsValidSurBot(iBot))
					PrintToChat(param1, "选定的目标BOT已失效.");
				else {
					int iTeam = iClientTeamTakeOver(param1);
					if (!iTeam)
						PrintToChat(param1, "不符合接管条件.");
					else {
						if (iTeam != 1)
							ChangeClientTeam(param1, TEAM_SPECTATOR);

						vTakeOverBot(param1, iBot);
					}
				}
			}
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

Action cmdGoAFK(int client, int args) {
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	if (GetClientTeam(client) != TEAM_SURVIVOR || !IsPlayerAlive(client))
		return Plugin_Handled;

	vGoAFKTimer(client, 0.5);//SDKCall(g_hSDK_CTerrorPlayer_GoAwayFromKeyboard, client);
	return Plugin_Handled;
}

void vGoAFKTimer(int client, float flDuration)
{
	static int m_GoAFKTimer = -1;
	if (m_GoAFKTimer == -1)
		m_GoAFKTimer = FindSendPropInfo("CTerrorPlayer", "m_lookatPlayer") - 12;

	SetEntDataFloat(client, m_GoAFKTimer + 4, flDuration);
	SetEntDataFloat(client, m_GoAFKTimer + 8, GetGameTime() + flDuration);
}

Action cmdBotSet(int client, int args) {
	if (!IsServerProcessing()) {
		ReplyToCommand(client, "服务器尚未进行帧处理.");
		return Plugin_Handled;
	}

	if (args != 1) {
		ReplyToCommand(client, "\x01!botset/sm_botset <\x05数量\x01>.");
		return Plugin_Handled;
	}

	int iArg = GetCmdArgInt(1);
	if (iArg < 1 || iArg > MaxClients - 1) {
		ReplyToCommand(client, "\x01参数范围 \x051\x01~\x05%d\x01.", MaxClients - 1);
		return Plugin_Handled;
	}

	delete g_hBotsTimer;
	g_cvBotsLimit.SetInt(iArg);
	g_hBotsTimer = CreateTimer(1.0, tmrBotsUpdate);
	ReplyToCommand(client, "\x05开局BOT数量已设置为\x01-> \x04%d\x01.", iArg);
	return Plugin_Handled;
}

Action spec_next_Listener(int client, char[] command, int argc) {
	if (!g_esPlayer[client].bSpecNotify || !(g_iJoinFlags & JOIN_MANUAL))
		return Plugin_Continue;

	if (bIsInTransition())
		return Plugin_Continue;

	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != TEAM_SPECTATOR || iGetBotOfIdlePlayer(client))
		return Plugin_Continue;

	g_esPlayer[client].bSpecNotify = false;

	switch (g_iSpecNotify) {
		case 1:
			PrintToChat(client, "\x01聊天栏输入 \x05!join \x01加入游戏.");

		case 2:
			PrintHintText(client, "聊天栏输入 !join 加入游戏");

		case 3:
			vJoinSurvivorMenu(client);
	}

	return Plugin_Continue;
}

void vJoinSurvivorMenu(int client) {
	EmitSoundToClient(client, SOUND_SPECMENU, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

	Menu menu = new Menu(iJoinSurvivor_MenuHandler);
	menu.SetTitle("加入生还者?");
	menu.AddItem("y", "是");
	menu.AddItem("n", "否");

	if (iFindUselessSurBot(true))
		menu.AddItem("t", "接管指定BOT");

	menu.ExitButton = false;
	menu.ExitBackButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

int iJoinSurvivor_MenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_Select: {
			switch (param2) {
				case 0:
					cmdJoinTeam2(param1, 0);

				case 2: {
					if (iFindUselessSurBot(true))
						vTakeOverBotMenu(param1);
					else
						PrintToChat(param1, "\x01没有 \x05空闲的电脑BOT \x01可以接管\x01.");
				}
			}
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

Action umSayText2(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init) {
	if (!g_bHideNameChange)
		return Plugin_Continue;

	msg.ReadByte();
	msg.ReadByte();

	char sMsg[254];
	msg.ReadString(sMsg, sizeof sMsg, true);
	if (strcmp(sMsg, "#Cstrike_Name_Change") == 0)
		return Plugin_Handled;

	return Plugin_Continue;
}

public void OnConfigsExecuted() {
	vGeCvars_Limit();
	vGeCvars_Weapon();
	vGeCvars_General();
}

void vCvarChanged_Limit(ConVar convar, const char[] oldValue, const char[] newValue) {
	vGeCvars_Limit();
}

void vGeCvars_Limit() {
	g_cvSurvivorLimit.SetInt((g_iBotsLimit = g_cvBotsLimit.IntValue));
}

void vCvarChanged_General(ConVar convar, const char[] oldValue, const char[] newValue) {
	vGeCvars_General();
}

void vGeCvars_General() {
	g_iJoinFlags = 		g_cvJoinFlags.IntValue;
	g_bRespawnJoin = 	g_cvRespawnJoin.BoolValue;
	g_iSpecLimit = 	g_cvSpecLimit.IntValue;
	g_iSpecNotify = g_cvSpecNotify.IntValue;
}

void vCvarChanged_Weapon(ConVar convar, const char[] oldValue, const char[] newValue) {
	vGeCvars_Weapon();
}

void vGeCvars_Weapon() {
	int iCount;
	for (int i; i < MAX_SLOTS; i++) {
		g_esWeapon[i].iCount = 0;
		if (!g_esWeapon[i].cvFlags.BoolValue || !iGetSlotAllowed(i))
			iCount++;
	}

	g_bGiveType = iCount < MAX_SLOTS ? g_cvGiveType.BoolValue : false;
	g_bGiveTime = g_cvGiveTime.BoolValue;
}

int iGetSlotAllowed(int iSlot) {
	for (int i; i < 17; i++) {
		if (!g_sWeaponName[iSlot][i][0])
			break;

		if ((1 << i) & g_esWeapon[iSlot].cvFlags.IntValue)
			g_esWeapon[iSlot].iAllowed[g_esWeapon[iSlot].iCount++] = i;
	}
	return g_esWeapon[iSlot].iCount;
}

public void OnClientDisconnect(int client) {
	if (IsFakeClient(client))
		return;

	g_esPlayer[client].sSteamID[0] = '\0';

	if (g_iRoundStart) {
		delete g_hBotsTimer;
		g_hBotsTimer = CreateTimer(1.0, tmrBotsUpdate);
	}
}

Action tmrBotsUpdate(Handle timer) {
	g_hBotsTimer = null;

	if (!bIsInTransition())
		vSpawnCheck();
	else
		g_hBotsTimer = CreateTimer(1.0, tmrBotsUpdate);

	return Plugin_Continue;
}

void vSpawnCheck() {
	if (!g_iRoundStart)
		return;

	int iSurvivor		= iGetTeamCount(TEAM_SURVIVOR, true);
	int iHumanSurvivor	= iGetTeamCount(TEAM_SURVIVOR, false);
	int iSurvivorLimit	= g_iBotsLimit;
	int iSurvivorMax	= iHumanSurvivor > iSurvivorLimit ? iHumanSurvivor : iSurvivorLimit;

	if (iSurvivor > iSurvivorMax)
		PrintToConsoleAll("Kicking %d bot(s)", iSurvivor - iSurvivorMax);

	if (iSurvivor < iSurvivorLimit)
		PrintToConsoleAll("Spawning %d bot(s)", iSurvivorLimit - iSurvivor);

	for (; iSurvivorMax < iSurvivor; iSurvivorMax++)
		vKickUnusedSurBot();
	
	for (; iSurvivor < iSurvivorLimit; iSurvivor++)
		vSpawnFakeSurClient();
}

void vKickUnusedSurBot() {
	int iBot = iFindUnusedSurBot(); // 优先踢出没有对应真实玩家且后生成的Bot
	if (iBot) {
		vRemovePlayerWeapons(iBot);
		KickClient(iBot, "Kicking Useless Client.");
	}
}

void vSpawnFakeSurClient() {
	int iBot = iAddSurBot();
	if (iBot != -1) {
		if (!IsPlayerAlive(iBot))
			vRoundRespawn(iBot);

		vTeleportToSurvivor(iBot);
	}
}

public void OnMapEnd() {
	vResetPlugin();
}

void vResetPlugin() {
	g_iRoundStart = 0;

	g_smSteamIDs.Clear();
	delete g_hBotsTimer;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	vResetPlugin();

	int iIdlePlayer;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR)
			continue;

		iIdlePlayer = iGetIdlePlayerOfBot(i);
		if (iIdlePlayer && IsClientInGame(iIdlePlayer) && !IsFakeClient(iIdlePlayer) && GetClientTeam(iIdlePlayer) == TEAM_SPECTATOR)
			vTakeOverBot(iIdlePlayer, i);
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR)
		return;

	delete g_hBotsTimer;
	g_hBotsTimer = CreateTimer(2.0, tmrBotsUpdate);
		
	if (!IsFakeClient(client) && bIsFirstTime(client))
		vRecordSteamID(client);

	SetEntProp(client, Prop_Send, "m_isGhost", 0);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVOR)
		return;

	int iIdlePlayer = iGetIdlePlayerOfBot(client);
	if (iIdlePlayer && IsClientInGame(iIdlePlayer) && !IsFakeClient(iIdlePlayer) && GetClientTeam(iIdlePlayer) == TEAM_SPECTATOR)
		vTakeOverBot(iIdlePlayer, client);
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return;

	switch (event.GetInt("team")) {
		case TEAM_SPECTATOR: {
			g_esPlayer[client].bSpecNotify = true;

			if (g_iJoinFlags & JOIN_AUTOMATIC && event.GetInt("oldteam") == TEAM_NOTEAM)
				CreateTimer(1.0, tmrJoinSurvivorTeam, event.GetInt("userid"), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}

		case TEAM_SURVIVOR:
			SetEntProp(client, Prop_Send, "m_isGhost", 0);
	}
}

Action tmrJoinSurvivorTeam(Handle timer, int client) {
	if (!(g_iJoinFlags & JOIN_AUTOMATIC) || !(client = GetClientOfUserId(client)) || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) > TEAM_SPECTATOR || iGetBotOfIdlePlayer(client)) 
		return Plugin_Stop;

	if (!g_iRoundStart || bIsInTransition() || GetClientTeam(client) <= TEAM_NOTEAM)
		return Plugin_Continue;

	aJoinTeam2(client);
	return Plugin_Stop;
}

void Event_PlayerBotReplace(Event event, char[] name, bool dontBroadcast) {
	int playerId = event.GetInt("player");
	int player = GetClientOfUserId(playerId);
	if (!player || !IsClientInGame(player) || IsFakeClient(player) || GetClientTeam(player) != TEAM_SURVIVOR)
		return;

	int botId = event.GetInt("bot");
	int bot = GetClientOfUserId(botId);

	g_esPlayer[bot].iBotPlayer = playerId;
	g_esPlayer[player].iPlayerBot = botId;

	if (!g_esPlayer[player].sModel[0])
		return;

	SetEntProp(bot, Prop_Send, "m_survivorCharacter", GetEntProp(player, Prop_Send, "m_survivorCharacter"));
	SetEntityModel(bot, g_esPlayer[player].sModel);
	for (int i; i < 8; i++) {
		if (strcmp(g_esPlayer[player].sModel, g_sSurvivorModels[i], false) == 0) {
			g_bHideNameChange = true;
			SetClientInfo(bot, "name", g_sSurvivorNames[i]);
			g_bHideNameChange = false;
			break;
		}
	}
}

void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast) {
	int player = GetClientOfUserId(event.GetInt("player"));
	if (!player || !IsClientInGame(player) || IsFakeClient(player) || GetClientTeam(player) != TEAM_SURVIVOR)
		return;

	int bot = GetClientOfUserId(event.GetInt("bot"));
	SetEntProp(player, Prop_Send, "m_survivorCharacter", GetEntProp(bot, Prop_Send, "m_survivorCharacter"));

	char sModel[PLATFORM_MAX_PATH];
	GetClientModel(bot, sModel, sizeof sModel);
	SetEntityModel(player, sModel);
}

void Event_FinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast) {
	int entity = FindEntityByClassname(MaxClients + 1, "info_survivor_position");
	if (entity == -1)
		return;

	float vOrigin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);

	int iSurvivor;
	static const char sOrder[][] = {"1", "2", "3", "4"};
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR)
			continue;

		if (++iSurvivor < 4)
			continue;
			
		entity = CreateEntityByName("info_survivor_position");
		if (entity != -1) {
			DispatchKeyValue(entity, "Order", sOrder[iSurvivor - RoundToFloor(iSurvivor / 4.0) * 4]);
			TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(entity);
		}
	}
}

bool bIsFirstTime(int client) {
	if (!bCacheSteamID(client))
		return false;

	bool bAllowed = true;
	g_smSteamIDs.GetValue(g_esPlayer[client].sSteamID, bAllowed);
	return bAllowed;
}

void vRecordSteamID(int client) {
	if (bCacheSteamID(client))
		g_smSteamIDs.SetValue(g_esPlayer[client].sSteamID, false, true);
}

bool bCacheSteamID(int client) {
	if (g_esPlayer[client].sSteamID[0])
		return true;

	if (GetClientAuthId(client, AuthId_Steam2, g_esPlayer[client].sSteamID, sizeof esPlayer::sSteamID))
		return true;

	g_esPlayer[client].sSteamID[0] = '\0';
	return false;
}

int iGetBotOfIdlePlayer(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && iGetIdlePlayerOfBot(i) == client)
			return i;
	}
	return 0;
}

int iGetIdlePlayerOfBot(int client) {
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}

int iGetTeamCount(int iTeam, bool bIncludeBots) {
	int iCount;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != iTeam)
			continue;

		if (!bIncludeBots && IsFakeClient(i) && !iGetIdlePlayerOfBot(i))
			continue;

		iCount++;
	}
	return iCount;
}

int iFindUnusedSurBot() {
	int client = MaxClients;
	ArrayList aClients = new ArrayList(2);

	for (; client >= 1; client--) {
		if (!bIsValidSurBot(client))
			continue;

		aClients.Set(aClients.Push(bIsSpecInvalid(GetClientOfUserId(g_esPlayer[client].iBotPlayer)) ? 0 : 1), client, 1);
	}

	if (!aClients.Length)
		client = 0;
	else {
		aClients.Sort(Sort_Ascending, Sort_Integer);
		client = aClients.Get(0, 1);
	}

	delete aClients;
	return client;
}

int iFindUselessSurBot(bool bAlive) {
	int client;
	ArrayList aClients = new ArrayList(2);

	for (int i = MaxClients; i >= 1; i--) {
		if (!bIsValidSurBot(i))
			continue;

		client = GetClientOfUserId(g_esPlayer[i].iBotPlayer);
		aClients.Set(aClients.Push(IsPlayerAlive(i) == bAlive ? (bIsSpecInvalid(client) ? 0 : 1) : (bIsSpecInvalid(client) ? 2 : 3)), i, 1);
	}

	if (!aClients.Length)
		client = 0;
	else {
		aClients.Sort(Sort_Descending, Sort_Integer);

		client = aClients.Length - 1;
		client = aClients.Get(GetRandomInt(aClients.FindValue(aClients.Get(client, 0)), client), 1);
	}

	delete aClients;
	return client;
}

bool bIsValidSurBot(int client) {
	return IsClientInGame(client) && !IsClientInKickQueue(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_SURVIVOR && !iGetIdlePlayerOfBot(client);
}

bool bIsSpecInvalid(int client) {
	return !client || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) == TEAM_SURVIVOR;
}

void vTeleportToSurvivor(int client, bool bRandom = true) {
	int iSurvivor = 1;
	ArrayList aClients = new ArrayList(2);

	for (; iSurvivor <= MaxClients; iSurvivor++) {
		if (iSurvivor == client || !IsClientInGame(iSurvivor) || GetClientTeam(iSurvivor) != TEAM_SURVIVOR || !IsPlayerAlive(iSurvivor))
			continue;
	
		aClients.Set(aClients.Push(!GetEntProp(iSurvivor, Prop_Send, "m_isIncapacitated") ? 0 : !GetEntProp(iSurvivor, Prop_Send, "m_isHangingFromLedge") ? 1 : 2), iSurvivor, 1);
	}

	if (!aClients.Length)
		iSurvivor = 0;
	else {
		aClients.Sort(Sort_Descending, Sort_Integer);

		if (!bRandom)
			iSurvivor = aClients.Get(aClients.Length - 1, 1);
		else {
			iSurvivor = aClients.Length - 1;
			iSurvivor = aClients.Get(GetRandomInt(aClients.FindValue(aClients.Get(iSurvivor, 0)), iSurvivor), 1);
		}
	}

	delete aClients;

	if (iSurvivor) {
		vSetInvincibilityTime(client, 1.5);
		SetEntProp(client, Prop_Send, "m_bDucked", 1);
		SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags")|FL_DUCKING);

		float vPos[3];
		GetClientAbsOrigin(iSurvivor, vPos);
		TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
	}
}

void vSetInvincibilityTime(int client, float flDuration) {
	static int m_invulnerabilityTimer = -1;
	if (m_invulnerabilityTimer == -1)
		m_invulnerabilityTimer = FindSendPropInfo("CTerrorPlayer", "m_noAvoidanceTimer") - 12;

	SetEntDataFloat(client, m_invulnerabilityTimer + 4, flDuration);
	SetEntDataFloat(client, m_invulnerabilityTimer + 8, GetGameTime() + flDuration);
}

// 给玩家近战
// L4D2- Melee In The Saferoom (https://forums.alliedmods.net/showpost.php?p=2611529&postcount=484)
public void OnMapStart() {
	int i;
	for (; i < sizeof g_sWeaponModels; i++) {
		if (!IsModelPrecached(g_sWeaponModels[i]))
			PrecacheModel(g_sWeaponModels[i], true);
	}

	char buffer[64];
	for (i = 3; i < 17; i++) {
		FormatEx(buffer, sizeof buffer, "scripts/melee/%s.txt", g_sWeaponName[1][i]);
		if (!IsGenericPrecached(buffer))
			PrecacheGeneric(buffer, true);
	}

	PrecacheSound(SOUND_SPECMENU);
	vGetMeleeWeaponsStringTable();
}

void vGetMeleeWeaponsStringTable() {
	g_aMeleeScripts.Clear();

	int iTable = FindStringTable("meleeweapons");
	if (iTable != INVALID_STRING_TABLE) {
		int iNum = GetStringTableNumStrings(iTable);
		char sMeleeName[64];
		for (int i; i < iNum; i++) {
			ReadStringTable(iTable, i, sMeleeName, sizeof sMeleeName);
			g_aMeleeScripts.PushString(sMeleeName);
		}
	}
}

void vGiveMelee(int client, const char[] sMeleeName) {
	char sScriptName[64];
	if (g_aMeleeScripts.FindString(sMeleeName) != -1)
		strcopy(sScriptName, sizeof sScriptName, sMeleeName);
	else
		g_aMeleeScripts.GetString(GetRandomInt(0, g_aMeleeScripts.Length - 1), sScriptName, sizeof sScriptName);
	
	GivePlayerItem(client, sScriptName);
}

void vDisplayTeamPanel(int client) {
	static const char sZombieClass[][] = {
		"None",
		"Smoker",
		"Boomer",
		"Hunter",
		"Spitter",
		"Jockey",
		"Charger",
		"Witch",
		"Tank",
		"Survivor"
	};

	Panel panel = new Panel();
	panel.SetTitle("---团队信息---");

	char text[254];
	FormatEx(text, sizeof text, "旁观者 (%d)", iGetTeamCount(TEAM_SPECTATOR, false));
	panel.DrawItem(text);

	int i = 1;
	for (; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SPECTATOR)
			continue;

		FormatEx(text, sizeof text, "%N", i);
		ReplaceString(text, sizeof text, "[", "");
		Format(text, sizeof text, "%s - %s", iGetBotOfIdlePlayer(i) ? "闲置" : "观众", text);
		panel.DrawText(text);
	}

	FormatEx(text, sizeof text, "生还者 (%d/%d) - %d Bot(s)", iGetTeamCount(TEAM_SURVIVOR, false), g_iBotsLimit, iGetSurBotsCount());
	panel.DrawItem(text);

	static ConVar cvSurvivorMaxInc;
	if (!cvSurvivorMaxInc)
		cvSurvivorMaxInc = FindConVar("survivor_max_incapacitated_count");

	int iSurvivorMaxInc = cvSurvivorMaxInc.IntValue;
	for (i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR)
			continue;
		
		FormatEx(text, sizeof text, "%N", i);
		ReplaceString(text, sizeof text, "[", "");
	
		if (!IsPlayerAlive(i))
			Format(text, sizeof text, "死亡 - %s", text);
		else
		 {
			if (GetEntProp(i, Prop_Send, "m_isIncapacitated"))
				Format(text, sizeof text, "倒地 - %d HP - %s", GetClientHealth(i) + iGetTempHealth(i), text);
			else if (GetEntProp(i, Prop_Send, "m_currentReviveCount") >= iSurvivorMaxInc)
				Format(text, sizeof text, "黑白 - %d HP - %s", GetClientHealth(i) + iGetTempHealth(i), text);
			else
				Format(text, sizeof text, "%dHP - %s", GetClientHealth(i) + iGetTempHealth(i), text);
	
		}

		panel.DrawText(text);
	}

	FormatEx(text, sizeof text, "感染者 (%d)", iGetTeamCount(TEAM_INFECTED, false));
	panel.DrawItem(text);

	int iClass;
	for (i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_INFECTED)
			continue;

		if ((iClass = GetEntProp(i, Prop_Send, "m_zombieClass")) != 8 && IsFakeClient(i))
			continue;

		FormatEx(text, sizeof text, "%N", i);
		ReplaceString(text, sizeof text, "[", "");

		if (IsPlayerAlive(i)) {
			if (GetEntProp(i, Prop_Send, "m_isGhost"))
				Format(text, sizeof text, "(%s)鬼魂 - %s", sZombieClass[iClass], text);
			else
				Format(text, sizeof text, "(%s)%d HP - %s", sZombieClass[iClass], GetEntProp(i, Prop_Data, "m_iHealth"), text);
		}
		else
			Format(text, sizeof text, "(%s)死亡 - %s", sZombieClass[iClass], text);

		panel.DrawText(text);
	}

	panel.DrawItem("刷新");
	panel.Send(client, iTeamPanelHandler, 30);
	delete panel;
}

int iTeamPanelHandler(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_Select: {
			if (param2 == 4)
				vDisplayTeamPanel(param1);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

int iGetSurBotsCount() {
	int iCount;
	for (int i = 1; i <= MaxClients; i++) {
		if (bIsValidSurBot(i))
			iCount++;
	}
	return iCount;
}

int iGetTempHealth(int client) {
	static ConVar cvPainPillsDecay;
	if (!cvPainPillsDecay)
		cvPainPillsDecay = FindConVar("pain_pills_decay_rate");

	int iHealth = RoundToFloor(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * cvPainPillsDecay.FloatValue);
	return iHealth < 0 ? 0 : iHealth;
}

void vInitData() {
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(sPath))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if (!hGameData)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_pDirector = hGameData.GetAddress("CDirector");
	if (!g_pDirector)
		SetFailState("Failed to find address: \"CDirector\" (%s)", PLUGIN_VERSION);

	g_iOff_m_restoreCSWeaponID1 = hGameData.GetOffset("CTerrorPlayer::RestoreWeapons::m_restoreCSWeaponID1");
	if (g_iOff_m_restoreCSWeaponID1 == -1)
		SetFailState("Failed to find offset: \"CTerrorPlayer::RestoreWeapons::m_restoreCSWeaponID1\" (%s)", PLUGIN_VERSION);
	
	g_iOff_m_iRestoreAmmoCount = hGameData.GetOffset("CTerrorPlayer::RestoreWeapons::m_iRestoreAmmoCount");
	if (g_iOff_m_iRestoreAmmoCount == -1)
		SetFailState("Failed to find offset: \"CTerrorPlayer::RestoreWeapons::m_iRestoreAmmoCount\" (%s)", PLUGIN_VERSION);

	g_iOff_m_restoreCSWeaponID2 = hGameData.GetOffset("CTerrorPlayer::RestoreWeapons::m_restoreCSWeaponID2");
	if (g_iOff_m_restoreCSWeaponID2 == -1)
		SetFailState("Failed to find offset: \"CTerrorPlayer::RestoreWeapons::m_restoreCSWeaponID2\" (%s)", PLUGIN_VERSION);

	g_iOff_m_hHiddenWeapon = hGameData.GetOffset("CTerrorPlayer::OnIncapacitatedAsSurvivor::m_hHiddenWeapon");
	if (g_iOff_m_hHiddenWeapon == -1)
		SetFailState("Failed to find offset: \"CTerrorPlayer::OnIncapacitatedAsSurvivor::m_hHiddenWeapon\" (%s)", PLUGIN_VERSION);

	StartPrepSDKCall(SDKCall_Static);
	Address pAddr = hGameData.GetMemSig("NextBotCreatePlayerBot<SurvivorBot>");
	if (!pAddr)
		SetFailState("Failed to find address: \"NextBotCreatePlayerBot<SurvivorBot>\" in \"CDirector::AddSurvivorBot\" (%s)", PLUGIN_VERSION);
	if (!hGameData.GetOffset("OS")) {
		Address offset = view_as<Address>(LoadFromAddress(pAddr + view_as<Address>(1), NumberType_Int32));	// (addr+5) + *(addr+1) = call function addr
		if (!offset)
			SetFailState("Failed to find address: \"NextBotCreatePlayerBot<SurvivorBot>\" (%s)", PLUGIN_VERSION);

		pAddr += offset + view_as<Address>(5); // sizeof(instruction)
	}
	if (!PrepSDKCall_SetAddress(pAddr))
		SetFailState("Failed to find address: \"NextBotCreatePlayerBot<SurvivorBot>\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	if (!(g_hSDK_NextBotCreatePlayerBot_SurvivorBot = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"NextBotCreatePlayerBot<SurvivorBot>\" (%s)", PLUGIN_VERSION);

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::RoundRespawn"))
		SetFailState("Failed to find signature: \"CTerrorPlayer::RoundRespawn\" (%s)", PLUGIN_VERSION);
	if (!(g_hSDK_CTerrorPlayer_RoundRespawn = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"CTerrorPlayer::RoundRespawn\" (%s)", PLUGIN_VERSION);

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCSPlayer::State_Transition"))
		SetFailState("Failed to find signature: \"CCSPlayer::State_Transition\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	if (!(g_hSDK_CCSPlayer_State_Transition = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"CCSPlayer::State_Transition\" (%s)", PLUGIN_VERSION);

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::SetHumanSpectator"))
		SetFailState("Failed to find signature: \"SurvivorBot::SetHumanSpectator\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	if (!(g_hSDK_SurvivorBot_SetHumanSpectator = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"SurvivorBot::SetHumanSpectator\" (%s)", PLUGIN_VERSION);
	
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::TakeOverBot"))
		SetFailState("Failed to find signature: \"CTerrorPlayer::TakeOverBot\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	if (!(g_hSDK_CTerrorPlayer_TakeOverBot = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"CTerrorPlayer::TakeOverBot\" (%s)", PLUGIN_VERSION);
	/*
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::GoAwayFromKeyboard"))
		SetFailState("Failed to find signature: \"CTerrorPlayer::GoAwayFromKeyboard\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	if (!(g_hSDK_CTerrorPlayer_GoAwayFromKeyboard = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"CTerrorPlayer::GoAwayFromKeyboard\" (%s)", PLUGIN_VERSION);*/

	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsInTransition"))
		SetFailState("Failed to find signature: \"CDirector::IsInTransition\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	if (!(g_hSDK_CDirector_IsInTransition = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"CDirector::IsInTransition\" (%s)", PLUGIN_VERSION);

	vInitPatchs(hGameData);
	vSetupDetours(hGameData);

	delete hGameData;
}

void vInitPatchs(GameData hGameData = null) {
	int iOffset = hGameData.GetOffset("RoundRespawn_Offset");
	if (iOffset == -1)
		SetFailState("Failed to find offset: \"RoundRespawn_Offset\" (%s)", PLUGIN_VERSION);

	int iByteMatch = hGameData.GetOffset("RoundRespawn_Byte");
	if (iByteMatch == -1)
		SetFailState("Failed to find byte: \"RoundRespawn_Byte\" (%s)", PLUGIN_VERSION);

	g_pStatsCondition = hGameData.GetMemSig("CTerrorPlayer::RoundRespawn");
	if (!g_pStatsCondition)
		SetFailState("Failed to find address: \"CTerrorPlayer::RoundRespawn\" (%s)", PLUGIN_VERSION);
	
	g_pStatsCondition += view_as<Address>(iOffset);
	int iByteOrigin = LoadFromAddress(g_pStatsCondition, NumberType_Int8);
	if (iByteOrigin != iByteMatch)
		SetFailState("Failed to load \"CTerrorPlayer::RoundRespawn\", byte mis-match @ %d (0x%02X != 0x%02X) (%s)", iOffset, iByteOrigin, iByteMatch, PLUGIN_VERSION);
}

// [L4D1 & L4D2] SM Respawn Improved (https://forums.alliedmods.net/showthread.php?t=323220)
void vStatsConditionPatch(bool bPatch) {
	static bool bPatched;
	if (!bPatched && bPatch) {
		bPatched = true;
		StoreToAddress(g_pStatsCondition, 0xEB, NumberType_Int8);
	}
	else if (bPatched && !bPatch) {
		bPatched = false;
		StoreToAddress(g_pStatsCondition, 0x75, NumberType_Int8);
	}
}

// Left 4 Dead 2 - CreateSurvivorBot (https://forums.alliedmods.net/showpost.php?p=2729883&postcount=16)
int iAddSurBot() {
	g_bInSpawnTime = true;
	int iBot = SDKCall(g_hSDK_NextBotCreatePlayerBot_SurvivorBot, NULL_STRING);
	if (iBot != -1)
		ChangeClientTeam(iBot, TEAM_SURVIVOR);

	g_bInSpawnTime = false;
	return iBot;
}

void vRoundRespawn(int client) {			
	vStatsConditionPatch(true);
	g_bInSpawnTime = true;
	SDKCall(g_hSDK_CTerrorPlayer_RoundRespawn, client);
	g_bInSpawnTime = false;
	vStatsConditionPatch(false);
}

/**
// https://github.com/bcserv/smlib/blob/transitional_syntax/scripting/include/smlib/clients.inc#:~:text=Spectator%20Movement%20modes-,enum%20Obs_Mode,-%7B
// Spectator Movement modes
enum Obs_Mode
{
	OBS_MODE_NONE = 0,	// not in spectator mode
	OBS_MODE_DEATHCAM,	// special mode for death cam animation
	OBS_MODE_FREEZECAM,	// zooms to a target, and freeze-frames on them
	OBS_MODE_FIXED,		// view from a fixed camera position
	OBS_MODE_IN_EYE,	// follow a player in first person view
	OBS_MODE_CHASE,		// follow a player in third person view
	OBS_MODE_ROAMING,	// free roaming

	NUM_OBSERVER_MODES
};
**/
void vSetHumanSpectator(int iBot, int client) {
	SDKCall(g_hSDK_SurvivorBot_SetHumanSpectator, iBot, client);
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", iBot);
	if (GetEntProp(client, Prop_Send, "m_iObserverMode") == 6)
		SetEntProp(client, Prop_Send, "m_iObserverMode", 5);
}

void vTakeOverBot(int client, int iBot) {
	SDKCall(g_hSDK_SurvivorBot_SetHumanSpectator, iBot, client);
	SDKCall(g_hSDK_CTerrorPlayer_TakeOverBot, client, true);
}

bool bIsInTransition() {
	return SDKCall(g_hSDK_CDirector_IsInTransition, g_pDirector);
}

void vSetupDetours(GameData hGameData = null) {
	DynamicDetour dDetour = DynamicDetour.FromConf(hGameData, "DD::CTerrorPlayer::GoAwayFromKeyboard");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: \"DD::CTerrorPlayer::GoAwayFromKeyboard\" (%s)", PLUGIN_VERSION);

	if (!dDetour.Enable(Hook_Pre, DD_CTerrorPlayer_GoAwayFromKeyboard_Pre))
		SetFailState("Failed to detour pre: \"DD::CTerrorPlayer::GoAwayFromKeyboard\" (%s)", PLUGIN_VERSION);

	if (!dDetour.Enable(Hook_Post, DD_CTerrorPlayer_GoAwayFromKeyboard_Post))
		SetFailState("Failed to detour post: \"DD::CTerrorPlayer::GoAwayFromKeyboard\" (%s)", PLUGIN_VERSION);

	dDetour = DynamicDetour.FromConf(hGameData, "DD::SurvivorBot::SetHumanSpectator");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: \"DD::SurvivorBot::SetHumanSpectator\" (%s)", PLUGIN_VERSION);
		
	if (!dDetour.Enable(Hook_Pre, DD_SurvivorBot_SetHumanSpectator_Pre))
		SetFailState("Failed to detour pre: \"DD::SurvivorBot::SetHumanSpectator\" (%s)", PLUGIN_VERSION);

	dDetour = DynamicDetour.FromConf(hGameData, "DD::CBasePlayer::SetModel");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: \"DD::CBasePlayer::SetModel\" (%s)", PLUGIN_VERSION);
		
	if (!dDetour.Enable(Hook_Post, DD_CBasePlayer_SetModel_Post))
		SetFailState("Failed to detour post: \"DD::CBasePlayer::SetModel\" (%s)", PLUGIN_VERSION);

	dDetour = DynamicDetour.FromConf(hGameData, "DD::CTerrorPlayer::GiveDefaultItems");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: \"DD::CTerrorPlayer::GiveDefaultItems\" (%s)", PLUGIN_VERSION);

	if (!dDetour.Enable(Hook_Pre, DD_CTerrorPlayer_GiveDefaultItems_Pre))
		SetFailState("Failed to detour pre: \"DD::CTerrorPlayer::GiveDefaultItems\" (%s)", PLUGIN_VERSION);
}

// [L4D1 & L4D2]Survivor_AFK_Fix[Left 4 Fix] (https://forums.alliedmods.net/showthread.php?p=2714236)
public void OnEntityCreated(int entity, const char[] classname) {
	if (!g_bShouldFixAFK)
		return;

	if (entity < 1 || entity > MaxClients)
		return;
	
	if (classname[0] != 's' || strcmp(classname[1], "urvivor_bot", false) != 0)
		return;

	g_iSurvivorBot = entity;
}

MRESReturn DD_CTerrorPlayer_GoAwayFromKeyboard_Pre(int pThis, DHookReturn hReturn) {
	g_bShouldFixAFK = true;
	return MRES_Ignored;
}

MRESReturn DD_CTerrorPlayer_GoAwayFromKeyboard_Post(int pThis, DHookReturn hReturn) {
	if (g_bShouldFixAFK && g_iSurvivorBot > 0 && IsFakeClient(g_iSurvivorBot)) {
		g_bShouldIgnore = true;
		vSetHumanSpectator(g_iSurvivorBot, pThis);
		vWriteTakeoverPanel(pThis, g_iSurvivorBot);
		g_bShouldIgnore = false;
	}

	g_iSurvivorBot = 0;
	g_bShouldFixAFK = false;
	return MRES_Ignored;
}

MRESReturn DD_SurvivorBot_SetHumanSpectator_Pre(int pThis, DHookParam hParams) {
	if (!g_bShouldFixAFK)
		return MRES_Ignored;

	if (g_bShouldIgnore)
		return MRES_Ignored;

	if (g_iSurvivorBot < 1)
		return MRES_Ignored;

	return MRES_Supercede;
}

// [L4D(2)] Survivor Identity Fix for 5+ Survivors (https://forums.alliedmods.net/showpost.php?p=2718792&postcount=36)
MRESReturn DD_CBasePlayer_SetModel_Post(int pThis, DHookParam hParams) {
	if (pThis < 1 || pThis > MaxClients || !IsClientInGame(pThis) || IsFakeClient(pThis))
		return MRES_Ignored;

	if (GetClientTeam(pThis) != TEAM_SURVIVOR) {
		g_esPlayer[pThis].sModel[0] = '\0';
		return MRES_Ignored;
	}
	
	char sModel[PLATFORM_MAX_PATH];
	hParams.GetString(1, sModel, sizeof sModel);
	if (StrContains(sModel, "models/survivors/survivor_", false) == 0)
		strcopy(g_esPlayer[pThis].sModel, sizeof esPlayer::sModel, sModel);

	return MRES_Ignored;
}

MRESReturn DD_CTerrorPlayer_GiveDefaultItems_Pre(int pThis) {
	if (!g_bGiveType)
		return MRES_Ignored;

	if (g_bShouldFixAFK || g_bGiveTime && !g_bInSpawnTime)
		return MRES_Ignored;

	if (pThis < 1 || pThis > MaxClients || !IsClientInGame(pThis))
		return MRES_Ignored;

	if (GetClientTeam(pThis) != TEAM_SURVIVOR || !IsPlayerAlive(pThis) || bShouldIgnore(pThis))
		return MRES_Ignored;

	vGiveDefaultItems(pThis);
	vResetRestoreWeapons(pThis);
	return MRES_Supercede;
}

void vWriteTakeoverPanel(int client, int iBot) {
	char sChar[2];
	IntToString(GetEntProp(iBot, Prop_Send, "m_survivorCharacter"), sChar, sizeof sChar);
	BfWrite bf = view_as<BfWrite>(StartMessageOne("VGUIMenu", client));
	bf.WriteString("takeover_survivor_bar");
	bf.WriteByte(true);
	bf.WriteByte(IN_ATTACK);
	bf.WriteString("character");
	bf.WriteString(sChar);
	EndMessage();
}

bool bShouldIgnore(int client) {
	if (IsFakeClient(client)) {
		if (iGetIdlePlayerOfBot(client))
			return true;

		return false;
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_SPECTATOR && iGetIdlePlayerOfBot(i) == client)
			return true;
	}

	return false;
}

void vResetRestoreWeapons(int client) {
	SetEntData(client, g_iOff_m_restoreCSWeaponID1, 0);
	SetEntData(client, g_iOff_m_iRestoreAmmoCount, 0);
	SetEntData(client, g_iOff_m_restoreCSWeaponID2, 0);
}

void vGiveDefaultItems(int client) {
	vRemovePlayerWeapons(client);

	for (int i = 4; i >= 2; i--) {
		if (!g_esWeapon[i].iCount)
			continue;

		GivePlayerItem(client, g_sWeaponName[i][g_esWeapon[i].iAllowed[GetRandomInt(0, g_esWeapon[i].iCount - 1)]]);
	}

	vGiveSecondary(client);

	switch (g_cvGiveType.IntValue) {
		case 1:
			vGivePresetPrimary(client);
		
		case 2:
			vGiveAveragePrimary(client);
	}
}

void vGiveSecondary(int client) {
	if (g_esWeapon[1].iCount) {
		int iRandom = g_esWeapon[1].iAllowed[GetRandomInt(0, g_esWeapon[1].iCount - 1)];
		if (iRandom > 2)
			vGiveMelee(client, g_sWeaponName[1][iRandom]);
		else
			GivePlayerItem(client, g_sWeaponName[1][iRandom]);
	}
}

void vGivePresetPrimary(int client) {
	if (g_esWeapon[0].iCount)
		GivePlayerItem(client, g_sWeaponName[0][g_esWeapon[0].iAllowed[GetRandomInt(0, g_esWeapon[0].iCount - 1)]]);
}

bool bIsWeaponTier1(int iWeapon) {
	char sWeapon[32];
	GetEntityClassname(iWeapon, sWeapon, sizeof sWeapon);
	for (int i; i < 5; i++) {
		if (strcmp(sWeapon, g_sWeaponName[0][i], false) == 0)
			return true;
	}
	return false;
}

void vGiveAveragePrimary(int client) {
	int i = 1, iTier, iTotal, iWeapon;
	for (; i <= MaxClients; i++) {
		if (i == client || !IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i))
			continue;

		iTotal += 1;
		iWeapon = GetPlayerWeaponSlot(i, 0);
		if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;

		iTier += bIsWeaponTier1(iWeapon) ? 1 : 2;
	}

	switch (iTotal > 0 ? RoundToNearest(float(iTier) / float(iTotal)) : 0) {
		case 1:
			GivePlayerItem(client, g_sWeaponName[0][GetRandomInt(0, 4)]);

		case 2:
			GivePlayerItem(client, g_sWeaponName[0][GetRandomInt(5, 14)]);
	}
}

void vRemovePlayerWeapons(int client) {
	int iWeapon;
	for (int i; i < MAX_SLOTS; i++) {
		if ((iWeapon = GetPlayerWeaponSlot(client, i)) <= MaxClients)
			continue;

		RemovePlayerItem(client, iWeapon);
		RemoveEntity(iWeapon);
	}

	iWeapon = GetEntDataEnt2(client, g_iOff_m_hHiddenWeapon);
	SetEntData(client, g_iOff_m_hHiddenWeapon, -1);
	if (iWeapon > MaxClients && IsValidEntity(iWeapon) && GetEntPropEnt(iWeapon, Prop_Data, "m_hOwnerEntity") == client) {
		RemovePlayerItem(client, iWeapon);
		RemoveEntity(iWeapon);
	}
}
