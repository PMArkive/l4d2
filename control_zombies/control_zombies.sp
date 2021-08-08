"Games"
{
	"left4dead2" 
	{
		"Functions"
		{
			"CTerrorPlayer::OnEnterGhostState"
			{
				"signature"	"CTerrorPlayer::OnEnterGhostState"
				"callconv"	"thiscall"
				"return"	"void"
				"this"		"entity"
			}
			"CTerrorPlayer::MaterializeFromGhost"
			{
				"signature"		"CTerrorPlayer::MaterializeFromGhost"
				"callconv"		"thiscall"
				"return"		"void"
				"this"			"entity"
			}
			"CTerrorPlayer::PlayerZombieAbortControl"
			{
				"signature"		"CTerrorPlayer::PlayerZombieAbortControl"
				"callconv"		"thiscall"
				"return"		"void"
				"this"			"entity"
			}
			"ForEachTerrorPlayer<SpawnablePZScan>"
			{
				"signature"		"ForEachTerrorPlayer<SpawnablePZScan>"
				"callconv"		"thiscall"
				"return"		"void"
				"this"			"ignore"
			}
		}

		"Addresses"
		{
			"CTerrorPlayer::RoundRespawn"
			{
				"linux"
				{
					"signature"	"CTerrorPlayer::RoundRespawn"
				}
				"windows"
				{
					"signature"	"CTerrorPlayer::RoundRespawn"			
				}
			}
		}

		"Offsets"
		{
			/* CBaseEntity::IsInStasis(CBaseEntity *__hidden this) */
			"CBaseEntity::IsInStasis"
			{
				"windows"	"39"
				"linux"		"40"
			}
			"RoundRespawn_Offset"
			{
				"linux"		"25" // 0x19
				"windows"	"15" // 0xF
			}
			"RoundRespawn_Byte" // JNZ => JNS
			{
				"linux"		"117" // 0x75
				"windows"	"117" // 0x75
			}
		}

		"Signatures" //大部分windows签名来自https://github.com/Psykotikism/L4D1-2_Signatures
		{
			/* CTerrorPlayer::OnEnterGhostState(void) */
			"CTerrorPlayer::OnEnterGhostState"
			{
				"library"	"server"
				"linux"		"@_ZN13CTerrorPlayer17OnEnterGhostStateEv"
				"windows"	"\x2A\x2A\x2A\x2A\x2A\x2A\x53\x56\x8B\x2A\x8B\x86\x2A\x2A\x2A\x2A\x8B\x2A\x2A\x8D\x8E\x2A\x2A\x2A\x2A\x57"
				/* ? ? ? ? ? ? 53 56 8B ? 8B 86 ? ? ? ? 8B ? ? 8D 8E ? ? ? ? 57 */
			}
			/* Tank::LeaveStasis(void) */
			"Tank::LeaveStasis"
			{
				"library"	"server"
				"linux"		"@_ZN4Tank11LeaveStasisEv"
				"windows"	"\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x8D\xB7\x2A\x2A\x2A\x2A\x74\x2A\x8B\x86\x2A\x2A\x2A\x2A\x8B\x90\x2A\x2A\x2A\x2A\x8D\x8E\x2A\x2A\x2A\x2A\x56\xFF\x2A\xC6\x2A\x2A\x8B\x2A\x8B\x90\x2A\x2A\x2A\x2A\x8B"
				/* ? ? ? ? ? ? ? ? ? ? ? 8D B7 ? ? ? ? 74 ? 8B 86 ? ? ? ? 8B 90 ? ? ? ? 8D 8E ? ? ? ? 56 FF ? C6 ? ? 8B ? 8B 90 ? ? ? ? 8B */
			}
			/* CCSPlayer::State_Transition(CSPlayerState) */
			"CCSPlayer::State_Transition"
			{
				"library"	"server"
				"linux"		"@_ZN9CCSPlayer16State_TransitionE13CSPlayerState"
				"windows"	"\x2A\x2A\x2A\x2A\x2A\x2A\x8B\x86\x2A\x2A\x2A\x2A\x57\x8B\x2A\x2A\x85\x2A\x74\x2A\x83"
				/* ? ? ? ? ? ? 8B 86 ? ? ? ? 57 8B ? ? 85 ? 74 ? 83 */
			}
			/* CTerrorPlayer::MaterializeFromGhost(void) */
			"CTerrorPlayer::MaterializeFromGhost"
			{
				"library"	"server"
				"linux"		"@_ZN13CTerrorPlayer20MaterializeFromGhostEv"
				"windows"	"\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\xFF\x2A\x50\xE8\x2A\x2A\x2A\x2A\x83\x2A\x2A\x50\x8B\x2A\x8B\x90\x2A\x2A\x2A\x2A\x8B\x2A\xFF\x2A\x50\x68\x2A\x2A\x2A\x2A\xE8"
				/* ? ? ? ? ? ? ? ? ? ? ? FF ? 50 E8 ? ? ? ? 83 ? ? 50 8B ? 8B 90 ? ? ? ? 8B ? FF ? 50 68 ? ? ? ? E8 */
				/* Search "%s materialized from spawn mode as a %s" */
			}
			/* CTerrorPlayer::PlayerZombieAbortControl(void) */
			"CTerrorPlayer::PlayerZombieAbortControl"
			{
				"library"	"server"
				"linux"		"@_ZN13CTerrorPlayer24PlayerZombieAbortControlEv"
				"windows"	"\x2A\x2A\x2A\x2A\x2A\x2A\x56\x8B\x2A\xE8\x2A\x2A\x2A\x2A\x83\x2A\x2A\x0F\x85\x2A\x2A\x2A\x2A\x8B\x2A\x8B\x90\x2A\x2A\x2A\x2A\x8B\x2A\xFF\x2A\x84\x2A\x0F\x84\x2A\x2A\x2A\x2A\xE8"
				/* ? ? ? ? ? ? 56 8B ? E8 ? ? ? ? 83 ? ? 0F 85 ? ? ? ? 8B ? 8B 90 ? ? ? ? 8B ? FF ? 84 ? 0F 84 ? ? ? ? E8 */
			}
			/* ForEachTerrorPlayer<SpawnablePZScan>(SpawnablePZScan &) */
			"ForEachTerrorPlayer<SpawnablePZScan>"
			{
				"library"	"server"
				"linux"		"@_Z19ForEachTerrorPlayerI15SpawnablePZScanEbRT_"
				"windows"	"\x55\x8B\xEC\x83\xEC\x2C\x8B\x0D\x2A\x2A\x2A\x2A\x53\x8B\x5D\x08\x56"
				/* 55 8B EC 83 EC 2C 8B 0D ? ? ? ? 53 8B 5D 08 56 */
			}
			/* CTerrorPlayer::SetClass(ZombieClassType) */
			"CTerrorPlayer::SetClass"
			{
				"library"	"server"
				"linux"		"@_ZN13CTerrorPlayer8SetClassE15ZombieClassType"
				"windows"	"\x2A\x2A\x2A\x2A\x2A\x2A\xE8\x2A\x2A\x2A\x2A\x83\x2A\x2A\x0F\x85\x2A\x2A\x2A\x2A\xA1\x2A\x2A\x2A\x2A\x40"
				/* ? ? ? ? ? ? E8 ? ? ? ? 83 ? ? 0F 85 ? ? ? ? A1 ? ? ? ? 40 */
			}
			/* CBaseAbility::CreateForPlayer(CTerrorPlayer *) */
			"CBaseAbility::CreateForPlayer"
			{
				"library"	"server"
				"linux"		"@_ZN12CBaseAbility15CreateForPlayerEP13CTerrorPlayer"
				"windows"	"\x2A\x2A\x2A\x2A\x2A\x2A\x56\x8B\x2A\x2A\x85\x2A\x0F\x84\x2A\x2A\x2A\x2A\x8B\x2A\xE8\x2A\x2A\x2A\x2A\x83"
				/* ? ? ? ? ? ? 56 8B ? ? 85 ? 0F 84 ? ? ? ? 8B ? E8 ? ? ? ? 83 */
			}
			/* CTerrorPlayer::CleanupPlayerState(void) */
			"CTerrorPlayer::CleanupPlayerState"
			{
				"library"	"server"
				"linux"		"@_ZN13CTerrorPlayer18CleanupPlayerStateEv"
				"windows"	"\x53\x8B\xDC\x83\xEC\x08\x83\xE4\xF0\x83\xC4\x04\x55\x8B\x6B\x04\x89\x6C\x24\x04\x8B\xEC\x0F\x57\xC0"
				/* 53 8B DC 83 EC 08 83 E4 F0 83 C4 04 55 8B 6B 04 89 6C 24 04 8B EC 0F 57 C0 */
			}
			/* CTerrorPlayer::OnCarryEnded(CTerrorPlayer *__hidden this, bool, bool, bool) */
			"CTerrorPlayer::OnCarryEnded"
			{
				"library"	"server"
				"linux"		"@_ZN13CTerrorPlayer12OnCarryEndedEbbb"
				"windows"	"\x55\x8B\xEC\x53\x56\x8B\x35\x2A\x2A\x2A\x2A\x57\x8B\xF9"
				/* 55 8B EC 53 56 8B 35 ? ? ? ? 57 8B F9 */
			}
			/* CTerrorPlayer::OnPummelEnded(bool, CTerrorPlayer*) */
			"CTerrorPlayer::OnPummelEnded"
			{
				"library"	"server"
				"linux"		"@_ZN13CTerrorPlayer13OnPummelEndedEbPS_"
				"windows"	"\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x53\x56\x8B\x2A\x8B\x86\x2A\x2A\x2A\x2A\x57\x83\x2A\x2A\x0F"
				/* ? ? ? ? ? ? ? ? ? 53 56 8B ? 8B 86 ? ? ? ? 57 83 ? ? 0F */
			}
			/* CTerrorPlayer::TakeOverZombieBot(CTerrorPlayer*) */
			"CTerrorPlayer::TakeOverZombieBot"
			{
				"library"	"server"
				"linux"		"@_ZN13CTerrorPlayer17TakeOverZombieBotEPS_"
				"windows"	"\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\xA1\x2A\x2A\x2A\x2A\x33\x2A\x89\x2A\x2A\x53\x8B\x2A\x2A\x80\xBB"
				/* ? ? ? ? ? ? ? ? ? A1 ? ? ? ? 33 ? 89 ? ? 53 8B ? ? 80 BB */
			}
			/* CTerrorPlayer::RoundRespawn(void) */
			"CTerrorPlayer::RoundRespawn"
			{
				"library"	"server"
				"linux"		"@_ZN13CTerrorPlayer12RoundRespawnEv"
				"windows"	"\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\xE8\x2A\x2A\x2A\x2A\x84\x2A\x75\x2A\x8B\x2A\xE8\x2A\x2A\x2A\x2A\xC6\x86"
				/* ? ? ? ? ? ? ? ? E8 ? ? ? ? 84 ? 75 ? 8B ? E8 ? ? ? ? C6 86 */
			}
			/* SurvivorBot::SetHumanSpectator(SurvivorBot *__hidden this, CTerrorPlayer *) */
			"SurvivorBot::SetHumanSpectator"
			{
				"library"	"server"
				"linux"		"@_ZN11SurvivorBot17SetHumanSpectatorEP13CTerrorPlayer"
				"windows"	"\x2A\x2A\x2A\x2A\x2A\x2A\x83\xBE\x2A\x2A\x2A\x2A\x2A\x7E\x2A\x32\x2A\x5E\x5D\xC2\x2A\x2A\x8B\x0D"
                /* ? ? ? ? ? ? 83 BE ? ? ? ? ? 7E ? 32 ? 5E 5D C2 ? ? 8B 0D */
			}
			/* CTerrorPlayer::TakeOverBot(bool) */
			"CTerrorPlayer::TakeOverBot"
			{
				"library"  "server"
				"linux"    "@_ZN13CTerrorPlayer11TakeOverBotEb"
				"windows"  "\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\xA1\x2A\x2A\x2A\x2A\x33\x2A\x89\x2A\x2A\x53\x56\x8D"
				/* ? ? ? ? ? ? ? ? ? A1 ? ? ? ? 33 ? 89 ? ? 53 56 8D */
			}
			/* CTerrorGameRules::"CTerrorGameRules::HasPlayerControlledZombies"() */
			"CTerrorGameRules::HasPlayerControlledZombies"
			{
				"library"	"server"
				"linux"		"@_ZN16CTerrorGameRules26HasPlayerControlledZombiesEv"
				"windows"	"\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x74\x2A\xB8\x2A\x2A\x2A\x2A\xEB\x2A\xA1\x2A\x2A\x2A\x2A\x8B\x2A\x2A\x85\x2A\x75\x2A\xB8\x2A\x2A\x2A\x2A\x8B\x0D\x2A\x2A\x2A\x2A\x8B\x2A\x50\x8B\x2A\x2A\xFF\x2A\x85\x2A\x74\x2A\x6A\x2A\x68\x2A\x2A\x2A\x2A\x8B\x2A\xE8\x2A\x2A\x2A\x2A\x85\x2A\x7E"
				/* ? ? ? ? ? ? ? ? ? ? 74 ? B8 ? ? ? ? EB ? A1 ? ? ? ? 8B ? ? 85 ? 75 ? B8 ? ? ? ? 8B 0D ? ? ? ? 8B ? 50 8B ? ? FF ? 85 ? 74 ? 6A ? 68 ? ? ? ? 8B ? E8 ? ? ? ? 85 ? 7E */
				/* Search "playercontrolledzombies". */
			}
		}
    }
}
