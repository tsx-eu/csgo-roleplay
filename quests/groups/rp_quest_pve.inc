/*
 * Cette oeuvre, création, site ou texte est sous licence Creative Commons Attribution
 * - Pas d’Utilisation Commerciale
 * - Partage dans les Mêmes Conditions 4.0 International. 
 * Pour accéder à une copie de cette licence, merci de vous rendre à l'adresse suivante
 * http://creativecommons.org/licenses/by-nc-sa/4.0/ .
 *
 * Merci de respecter le travail fourni par le ou les auteurs 
 * https://www.ts-x.eu/ - kossolax@ts-x.eu
 */


#define		TEAM_NONE		0
#define		TEAM_PLAYERS	1
#define		TEAM_INVITATION	2
#define		TEAM_NPC		3
#define		QUEST_TEAMS		4

ArrayList g_hQueue;
int g_iQuest;
int g_iPlayerTeam[2049], g_stkTeam[QUEST_TEAMS + 1][MAXPLAYERS + 1], g_stkTeamCount[QUEST_TEAMS];
Handle g_hKillTimer[MAXPLAYERS + 1];
bool g_bCanMakeQuest;
int g_iPlayerObjective[MAXPLAYERS + 1];
int g_cBeam;
int g_iPort;

enum soundList {
	snd_YouHaveTheFlag,
	snd_YouAreOnBlue, snd_YouAreOnRed,
	snd_1MinuteRemain, snd_5MinutesRemain,
	snd_EndOfRound,
	snd_Congratulations, snd_YouHaveLostTheMatch, snd_FlawlessVictory, snd_HumiliatingDefeat,
	snd_YouAreLeavingTheBattlefield,
	snd_FirstBlood,
	snd_DoubleKill, snd_MultiKill, snd_MegaKill, snd_UltraKill, snd_MonsterKill,
	snd_KillingSpree, snd_Unstopppable, snd_Dominating, snd_Godlike
};
enum announcerData {
	ann_Client,
	ann_SoundID,
	ann_Time,
	ann_max
};
char g_szSoundList[soundList][] = {
	"DeadlyDesire/announce/YouHaveTheFlag.mp3",
	"DeadlyDesire/announce/YouAreOnBlue.mp3",
	"DeadlyDesire/announce/YouAreOnRed.mp3",

	"DeadlyDesire/announce/1MinutesRemain.mp3",
	"DeadlyDesire/announce/5MinutesRemain.mp3",
	
	"DeadlyDesire/announce/EndOfRound.mp3",
	"DeadlyDesire/announce/Congratulations.mp3",
	"DeadlyDesire/announce/YouHaveLostTheMatch.mp3",
	"DeadlyDesire/announce/FlawlessVictory.mp3",
	"DeadlyDesire/announce/HumiliatingDefeat.mp3",
	
	"DeadlyDesire/announce/YouAreLeavingTheBattlefield.mp3",
	
	"DeadlyDesire/announce/FristBlood.mp3",
	
	"DeadlyDesire/announce/DoubleKill.mp3",
	"DeadlyDesire/announce/MultiKill.mp3",
	"DeadlyDesire/announce/MegaKill.mp3",
	"DeadlyDesire/announce/UltraKill.mp3",
	"DeadlyDesire/announce/MonsterKill.mp3",
	
	"DeadlyDesire/announce/KillingSpree.mp3",
	"DeadlyDesire/announce/Unstopppable.mp3",
	"DeadlyDesire/announce/Dominating.mp3",
	"DeadlyDesire/announce/Godlike.mp3"
};
enum QuestConfig {
	QC_Killed = 0,
	QC_Remainning,
	QC_Alive,
	QC_Health,
	QC_Difficulty,
	QC_Time,
	QC_DeadTime,
	QC_Bonus,
	QC_Light,
	QC_Alert,
	QC_FirstBlood,
	QC_Reset,
	QC_Max
};
int g_iQuestConfig[QC_Max];
int g_CyclAnnouncer[MAX_ANNOUNCES][announcerData], g_CyclAnnouncer_start, g_CyclAnnouncer_end;
int g_iKillingSpree[65], g_iKilling[65];

public bool fwdCanStart(int client) {
	
	if( g_bCanMakeQuest == false )
		return false;
	if ( g_iPort == 27015) {
		if( rp_GetClientInt(client, i_PlayerLVL) < 100 )
			return false;
		if( rp_GetClientFloat(client, fl_MonthTime) < 21.0 )
			return false;
	}
	
	static char banned[][32] = { "STEAM_1:1:47247649" };
	char szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	
	for (int i = 0; i < sizeof(banned); i++) {
		if( StrEqual(banned[i], szSteamID) )
			return false;
	}
	
	
	return true;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_PluginReloadSelf);
	g_iPort = GetConVarInt(FindConVar("hostport"));
}
public void OnAllPluginsLoaded() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if (g_iQuest == -1)
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
		
	int i;
	rp_QuestAddStep(g_iQuest, i++, Q0_Start,	Q01_Frame,	Q0_Abort, 	QUEST_NULL);
	
	if ( g_iPort == 27015) {
		rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q02_Frame,	Q0_Abort, 	QUEST_NULL);
		rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q03_Frame,	Q0_Abort, 	QUEST_NULL);
		rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q04_Frame,	Q0_Abort, 	QUEST_NULL);
		rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q05_Frame,	Q0_Abort, 	QUEST_NULL);
		rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q06_Frame,	Q0_Abort, 	QUEST_NULL);
	}
	
	int count = REQUIRED_PLAYER; // petit hack pour le compilo qui refuse d'écrire REQUIRED_PLAYER > 1
	if( count > 1 )
		rp_QuestAddStep(g_iQuest, i++, QI_Start,	QI_Frame,	Q0_Abort, 	QUEST_NULL);
	
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q1_Frame,	Q0_Abort, 	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, Q2_Start,	Q2_Frame,	Q_Abort, 	Q_Abort);
	rp_QuestAddStep(g_iQuest, i++, Q3_Start,	Q3_Frame,	QUEST_NULL, QUEST_NULL);
	
	g_hQueue = new ArrayList(1, 1024);
	g_bCanMakeQuest = true;
}
public void OnClientDisconnect(int client) {
	removeClientTeam(client);
}
// ----------------------------------------------------------------------------
public void OnMapStart() {
	AddFileToDownloadsTable("models/DeadlyDesire/props/udamage.mdl");
	AddFileToDownloadsTable("models/DeadlyDesire/props/udamage.dx90.vtx");
	AddFileToDownloadsTable("models/DeadlyDesire/props/udamage.phy");
	AddFileToDownloadsTable("models/DeadlyDesire/props/udamage.vvd");
	AddFileToDownloadsTable("materials/DeadlyDesire/props/studmap.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/props/studmap.vtf");
	PrecacheModel("models/DeadlyDesire/props/udamage.mdl", true);
	
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	PrecacheSound("player/heartbeatloop.wav");
	
	char tmp[PLATFORM_MAX_PATH];
	for (int i = 0; i < sizeof(g_szSoundList); i++) {
		PrecacheSoundAny(g_szSoundList[i]);
		Format(tmp, sizeof(tmp), "sound/%s", g_szSoundList[i]);
		AddFileToDownloadsTable(tmp);
	}
}
// -----------------------------------------------------------------------------------------------------------------
public void Q0_Start(int objectiveID, int client) {
	g_bCanMakeQuest = false;
}
public void Q0_Abort(int objectiveID, int client) {
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Désolé, vous ne pouvez pas essayer la PVE pour le moment.");
	CreateTimer(10.0, newAttempt);
}
public void Q01_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q0_MenuComplete);
	menu.SetTitle("Cette quête est toujours en développement.\nNous avons besoin de vous, pour l'améliorer.\nÉtant donné qu'il ne s'agit encore que d'un\nbref aperçu de la version final, la quête\nest réservée aux joueurs sachant à quoi\ns'attendre.\n \nRépondez correctement aux questions suivantes\npour tenter l'expérience.\n ");
	menu.AddItem("0", "J'ai bien compris, mais j'y participe pas.");
	menu.AddItem("0", "J'ai besoin de plus d'info.");
	menu.AddItem("1", "Lancez le questionnaire!");
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public void Q02_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q0_MenuComplete);
	menu.SetTitle(QUEST_NAME ... " - BETA\n \nLe projet PVE sur le roleplay c'est...");
	
	menu.AddItem("0", "Un nouveau système de PVP beaucoup plus équilibré");
	menu.AddItem("1", "Des combats en équipe contres des monstres dans une arène");
	menu.AddItem("0", "Une nouvelle quête qui fait gagner plein de thune");
	menu.AddItem("0", "Une nouvelle quête qui fait gagner plein d'expérience");
	menu.AddItem("0", "Un défis pour devenir admin");
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public void Q03_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q0_MenuComplete);
	menu.SetTitle(QUEST_NAME ... " - BETA\n \nOù se situe l'affrontement de la PVE?");
	
	menu.AddItem("0", "Dans la mairie dans des locaux aménagés");
	menu.AddItem("1", "Dans une arène, hors map");
	menu.AddItem("0", "Dans le BUNKER en face de la villa immo");
	menu.AddItem("0", "Dans le cimetière de Princeton");
	
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public void Q04_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q0_MenuComplete);
	menu.SetTitle(QUEST_NAME ... " - BETA\n \nQuelle aptitude les mobs PVE ne sont t-ils pas capable\nde réaliser, pour le moment?");
	
	menu.AddItem("0", "Monter une échelle");
	menu.AddItem("1", "Contourner un props posé par un joueur");
	menu.AddItem("0", "Envoyer des projectiles (ex: flèche)");
	menu.AddItem("0", "Monter ou descendre une pente");
	menu.AddItem("0", "Trouver leur chemin dans Princeton");	
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public void Q05_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q0_MenuComplete);
	menu.SetTitle(QUEST_NAME ... " - BETA\n \nQuand a été annoncé le projet PVE?");
	
	menu.AddItem("0", "Janvier 2016");
	menu.AddItem("1", "Mars 2017");
	menu.AddItem("0", "Mai 2017");
	menu.AddItem("0", "Juillet 2017");	
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public void Q06_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q0_MenuComplete);
	menu.SetTitle(QUEST_NAME ... " - BETA\n \nQuel mob n'existe pas dans la PVE?");
	
	menu.AddItem("0", "Squelette armé d'une épée et d'un bouclier");
	menu.AddItem("0", "Squelette armé d'un arc");
	menu.AddItem("1", "Squelette armé d'une lance");
	menu.AddItem("0", "Squelette armé d'une hache");
	
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public int Q0_MenuComplete(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ne donnez pas les réponses aux autres ;-)");
		
		if( StringToInt(options) == 1 )
			rp_QuestStepComplete(client, g_iPlayerObjective[client]);
		else
			rp_QuestStepFail(client, g_iPlayerObjective[client]);

	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return 0;
}
// ----------------------------------------------------------------------------
public void Q_Abort(int objectiveID, int client) {
	
	CreateTimer(5.0 * 60.0, newAttempt);
	
	for (int i = 0; i < g_stkTeamCount[TEAM_PLAYERS]; i++) {
		int target = g_stkTeam[TEAM_PLAYERS][i];
		rp_UnhookEvent(target, RP_OnPlayerDead, fwdDead);
		rp_UnhookEvent(target, RP_OnPlayerZoneChange, fwdZone);
		rp_UnhookEvent(target, RP_PlayerCanUseItem, fwdItem);
		rp_UnhookEvent(target, RP_PrePlayerPhysic, fwdPhysics);
		
		CPrintToChat(target, "{lightblue}[TSX-RP]{default} Merci pour votre test! Donnez vos suggestions sur pve.ts-x.eu <3");
		
		removeClientTeam(target);
	}
	
	for (int i = 0; i < g_stkTeamCount[TEAM_NPC]; i++) {
		int entity = g_stkTeam[TEAM_NPC][i];
		
		rp_ScheduleEntityInput(entity, 0.1, "Kill");
	}
	
	char classname[64];
	for (int i = MaxClients; i < MAX_ENTITIES; i++) {
		if( !IsValidEdict(i) || !IsValidEntity(i) )
			continue;
		if( !HasEntProp(i, Prop_Send, "m_vecOrigin") )
			continue;
		if( rp_GetPlayerZone(i) != QUEST_ARENA )
			continue;
			
		if( IsMonster(i) )
			AcceptEntityInput(i, "Kill");
		if( rp_IsValidVehicle(i) )
			rp_SetVehicleInt(i, car_health, -1);
		if( rp_GetBuildingData(i, BD_owner) > 0 && Entity_GetHealth(i) > 0 )
			Entity_Hurt(i, Entity_GetHealth(i));
		
		GetEdictClassname(i, classname, sizeof(classname));
		if( StrContains(classname, "weapon_") == 0 )
			AcceptEntityInput(i, "Kill");
	}
	
	int parent;
	parent = EntRefToEntIndex(g_iQuestConfig[QC_Bonus]);
	if( parent != INVALID_ENT_REFERENCE )
		AcceptEntityInput(parent, "KillHierarchy");
	parent = EntRefToEntIndex(g_iQuestConfig[QC_Light]);
	if( parent != INVALID_ENT_REFERENCE )
		AcceptEntityInput(parent, "KillHierarchy");
}
public int Q1_MenuComplete(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		g_iQuestConfig[QC_Difficulty] = StringToInt(options);
		rp_QuestStepComplete(client, g_iPlayerObjective[client]);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return 0;
}
public void Q1_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q1_MenuComplete);
	menu.SetTitle(QUEST_NAME ... " - BETA\n \nQuel doit être votre niveau de difficulté?\n ");
	
	menu.AddItem("0", "Je suis trop jeune pour mourir\n- Les pillules sont désactivées\n ");
	menu.AddItem("1", "Hey, pas si fort\n- Les boosts sont désactivés\n- Les items de regénération sont désactivés\n- Les fusées, propulseurs et pillules sont désactivés\n ");
	menu.AddItem("2", "Fais-moi mal\n- Les boosts sont désactivés\n- Tous les items sont désactivés");
	
	
	menu.Display(client, MENU_TIME_FOREVER);
}
// ----------------------------------------------------------------------------
public void Q2_Start(int objectiveID, int client) {
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Bonne chance pour ce test!");
	
	addClientToTeam(client, TEAM_PLAYERS);
	
	for (int i = 0; i < g_stkTeamCount[TEAM_PLAYERS]; i++) {
		int target = g_stkTeam[TEAM_PLAYERS][i];
		rp_HookEvent(target, RP_OnPlayerDead, fwdDead);
		rp_HookEvent(target, RP_OnPlayerZoneChange, fwdZone);
		rp_HookEvent(target, RP_PlayerCanUseItem, fwdItem);
		rp_HookEvent(target, RP_PrePlayerPhysic, fwdPhysics);
		
		g_iKillingSpree[target] = 0;
		g_iKilling[target] = 0;
	}
	
	g_hQueue.Clear();
	for (int i = 0; i < sizeof(g_szSpawnQueue); i++) {
		int cpt = StringToInt(g_szSpawnQueue[i][0]);
		int id = PVE_GetId(g_szSpawnQueue[i][1]);
		
		if( id >= 0 ) {
			for (int j = 0; j < cpt; j++)
				g_hQueue.Push(id);
		}
	}
	
	int bonus = SQ_SpawnBonus();
	int light = SQ_SpawnLight();
	
	g_iQuestConfig[QC_Time] = g_iQuestConfig[QC_Killed] = g_iQuestConfig[QC_Alive] = 0;
	g_iQuestConfig[QC_Health] = 5;
	g_iQuestConfig[QC_DeadTime] = 60;
	g_iQuestConfig[QC_FirstBlood] = 0;
	g_iQuestConfig[QC_Remainning] = g_hQueue.Length;
	g_iQuestConfig[QC_Bonus] = EntIndexToEntRef(bonus);
	g_iQuestConfig[QC_Light] = EntIndexToEntRef(light);

}
public void Q2_Frame(int objectiveID, int client) {
	float pos[3];
	
	if( g_iQuestConfig[QC_Remainning] <= 0 ) {
		rp_QuestStepComplete(client, objectiveID);
		for (int i = 0; i < g_stkTeamCount[TEAM_PLAYERS]; i++) {
			int target = g_stkTeam[TEAM_PLAYERS][i];
			if( target != client )
				rp_QuestComplete(target, QUEST_UNIQID, true);
		}
	}
	else if( g_iQuestConfig[QC_Health] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
		for (int i = 0; i < g_stkTeamCount[TEAM_PLAYERS]; i++) {
			int target = g_stkTeam[TEAM_PLAYERS][i];
			if( target != client )
				rp_QuestComplete(target, QUEST_UNIQID, false);
		}
	}
	
	CyclAnnouncer_Frame();
	
	bool allSafe = true;
	bool allOut = true;
	
	for (int i = 0; i < g_stkTeamCount[TEAM_PLAYERS]; i++) {
		int target = g_stkTeam[TEAM_PLAYERS][i];
	
		if( rp_GetPlayerZone(target) == QUEST_ARENA ) {
			allOut = false;
			g_iQuestConfig[QC_Reset] = 0;
			
			PrintHintText(target, "Arène SOLO\nZombie restant: %d\nPV restant: %d - Temps: %d secondes", 
				g_iQuestConfig[QC_Remainning], g_iQuestConfig[QC_Health], g_iQuestConfig[QC_Time]
			);
			
			int health = GetClientHealth(target);
			
			
			if( health < 200 )
				allSafe = false;
			
			if( GetClientTeam(target) == CS_TEAM_CT )
				ForcePlayerSuicide(target);
		}
		else if( g_iQuestConfig[QC_Health] > 0 ) {
			PrintHintText(target, "Retournez dans un métro avec du stuff pour reprendre la partie.\nIl vous reste %d vie - Temps: %d secondes", g_iQuestConfig[QC_Health], g_iQuestConfig[QC_Time]);
		}
	}
	
	if( allOut ) {
		if( g_iQuestConfig[QC_Reset] == 0 ) {
			g_iQuestConfig[QC_Reset] = 1;
			for (int i = 0; i < g_stkTeamCount[TEAM_NPC]; i++) {
				int entity = g_stkTeam[TEAM_NPC][i];
				int id = PVE_GetEntityInt(entity, ESI_Identifier);
				
				if( id >=  0 ) {
					g_hQueue.ShiftUp(0);
					g_hQueue.Set(0, id);
					AcceptEntityInput(entity, "Kill");
					g_iQuestConfig[QC_Remainning]++;
					g_iQuestConfig[QC_Killed]--;
				}
			}
		}
		
		if( g_iQuestConfig[QC_DeadTime] > 0 )
			g_iQuestConfig[QC_DeadTime]--;
		else
			g_iQuestConfig[QC_Time]++;
	}
	else {
		if( g_hQueue.Length > 0  && g_iQuestConfig[QC_Alive] < (5+g_iQuestConfig[QC_Difficulty]) ) {
			if( SQ_Pop(pos) ) {
				int id = g_hQueue.Get(0);
				g_hQueue.Erase(0);
				
				int entity = PVE_Spawn(id, pos, NULL_VECTOR);
				addClientToTeam(entity, TEAM_NPC);
					
				g_iQuestConfig[QC_Alive]++;
					
				PVE_RegEvent(entity, ESE_Dead, OnDead);
				PVE_RegEvent(entity, ESE_FollowChange, OnFollowChange);
				PVE_RegEvent(entity, ESE_Think, OnThink);
				SDKHook(entity, SDKHook_Touch, OnTouch);
			}
		}
	
		int light = EntRefToEntIndex(g_iQuestConfig[QC_Light]);
		if( light != INVALID_ENT_REFERENCE ) { // n'est normalement pas sensé arrivé.
	
			if( !allSafe && g_iQuestConfig[QC_Alert] == 0 ) {
				SetVariantColor({255, 50, 50,8});
				AcceptEntityInput(light, "LightColor");
				EmitSound(g_stkTeam[TEAM_PLAYERS], g_stkTeamCount[TEAM_PLAYERS], "player/heartbeatloop.wav", client, SNDCHAN_BODY);
			}
			else if( allSafe && g_iQuestConfig[QC_Alert] == 1 ) {
				SetVariantColor({255,150,100,5});
				AcceptEntityInput(light, "LightColor");
				
				for (int i = 0; i < g_stkTeamCount[TEAM_PLAYERS]; i++)
					StopSound(g_stkTeam[TEAM_PLAYERS][i], SNDCHAN_BODY, "player/heartbeatloop.wav");
			}
			g_iQuestConfig[QC_Alert] = !allSafe;
		}
	}
}
public void Q3_Start(int objectiveID, int client) {
	g_iQuestConfig[QC_DeadTime] = 10;
}
public void Q3_Frame(int objectiveID, int client) {
	g_iQuestConfig[QC_DeadTime]--;
	
	PrintHintText(client, "Fin de la partie.\n Vous allez être téléporté dans %d seconde%s.", g_iQuestConfig[QC_DeadTime], g_iQuestConfig[QC_DeadTime] > 1 ? "s" : "");
	
	bool allOut = true;
	
	if( g_iQuestConfig[QC_DeadTime] <= 0 ) {
		for (int target = 1; target <= MaxClients; target++) {
			if( !IsValidClient(target) )
				continue;
		
			if( rp_GetPlayerZone(target) == QUEST_ARENA ) {
				allOut = false;
				
				if( g_iQuestConfig[QC_DeadTime] < -5 )
					ForcePlayerSuicide(target);
				else
					rp_ClientSendToSpawn(target);
			}
		}
		
		if( allOut )
			rp_QuestStepComplete(client, objectiveID);
	}
	
}
// ----------------------------------------------------------------------------
public void OnDead(int id, int entity, int client) {
	removeClientTeam(entity);
	g_iQuestConfig[QC_Remainning]--;
	g_iQuestConfig[QC_Alive]--;
	g_iQuestConfig[QC_Killed]++;
	
	if( client > 0 && IsValidClient(client) ) {
		
		g_iKillingSpree[client]++;
		g_iKilling[client]++;
		if( g_hKillTimer[client] != INVALID_HANDLE )
			delete g_hKillTimer[client];
		g_hKillTimer[client] = CreateTimer(5.0, ResetKillCount, client);
		
		CyclAnnouncer(client);
	}
}
public Action OnFollowChange(int id, int entity, int& target) {

	if( target > 0 ) {
		if( !IsPlayerAlive(target) || rp_GetPlayerZone(entity) != rp_GetPlayerZone(target) )
			target = 0;
	}
	
	float tmp, dist = FLT_MAX, src[3], dst[3];
	Entity_GetAbsOrigin(entity, src);
	src[2] += 48.0;
	
	int area = PHUN_Nav_GetAreaId(src);
	int client;
	
	for (int i = 0; i < g_stkTeamCount[TEAM_PLAYERS]; i++) {
		client = g_stkTeam[TEAM_PLAYERS][i];
		
		if( !IsValidClient(client) )
			continue;
		if( !IsPlayerAlive(client) )
			continue;
		if( rp_GetPlayerZone(entity) != rp_GetPlayerZone(client) )
			continue;
		
		GetClientEyePosition(client, dst);
		tmp = GetVectorDistance(src, dst);
		
		if( area == PHUN_Nav_GetAreaId(dst) )
			tmp /= 4.0;
		if( IsAbleToSee(client, src, entity) )
			tmp /= 4.0;
				
		if (tmp < dist) {
			dist = tmp;
			target = client;
		}
	}
	
	return Plugin_Changed;
}
public void OnThink(int id, int entity, PVE_EntityState& state) {
	static float g_flLastSpeed[MAX_ENTITIES + 1][5];
	static float g_flLastPos[MAX_ENTITIES][3];
	
	float vec[3];
	Entity_GetAbsOrigin(entity, vec);
	float speed = GetVectorDistance(vec, g_flLastPos[entity], true);
	
	g_flLastSpeed[entity][ GetGameTickCount() % sizeof(g_flLastSpeed[])] = speed;
	g_flLastPos[entity] = vec;
	
	if( speed < 1.0 ) {
		speed = 0.0;
		for (int i = 0; i < sizeof(g_flLastSpeed[]); i++)
			speed += g_flLastSpeed[entity][i];
		
		if( speed < (1.0*sizeof(g_flLastSpeed[])) ) {
			// Are we stuck?
			int area = PHUN_Nav_GetAreaId(vec);
			if( area > 0 ) {
				float pos[3], min[3], max[3];
				PHUN_Nav_AreaIdToPosition(area, pos, min, max);
				Effect_DrawBeamBoxToAll(min, max, g_cBeam, g_cBeam, 0, 30, 0.1, 4.0, 4.0, 1, 0.0, { 0, 255, 0, 200 }, 1);
			}
			else {
				pos[2] += 8.0;
				TE_SetupBeamRingPoint(vec, 8.0, 64.0, g_cBeam, g_cBeam, 0, 30, 0.1, 4.0, 0.0, { 255, 0, 0, 200 }, 1, 0);
				TE_SendToAll();
			}
		}
	}
}
public void OnTouch(int entity, int target) {
	static char classname[32];
	float pos[3];
	
	if( target > MaxClients ) {
		
		GetEdictClassname(target, classname, sizeof(classname));
		if( StrEqual(classname, "trigger_hurt") ) {
			if( SQ_Pop(pos) )
				TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
}
// ----------------------------------------------------------------------------
public void fwdThink(int entity) {
	float ang[3];
	Entity_GetAbsAngles(entity, ang);
	ang[1] += 1.0;
	if( ang[1] > 180.0 )
		ang[1] -= 360.0;
	TeleportEntity(entity, NULL_VECTOR, ang, NULL_VECTOR);
}
public void fwdTouch(int entity, int target) {
	
	if( target > 0 && target < MaxClients ) {
		int parent = EntRefToEntIndex(g_iQuestConfig[QC_Bonus]);
		if( parent != INVALID_ENT_REFERENCE )
			AcceptEntityInput(parent, "KillHierarchy");
		else // Comment est-ce possible?
			AcceptEntityInput(entity, "KillHierarchy");
		
		for (float size = 256.0; size <= 2048.0; size *= 2.0) { // 256, 512, 1024, 2048.
			TE_SetupBeamRingPoint(QUEST_BONUS, 32.0, size, g_cBeam, g_cBeam, 0, 30, 1.0, Logarithm(size, 2.0) * 8.0, 0.0, {100, 50, 100, 200}, 0, 0);
			TE_SendToAll();
		}

		for (int i = 0; i < g_stkTeamCount[TEAM_NPC]; i++) {
			Entity_Hurt(g_stkTeam[TEAM_NPC][i], 5000, target);
		}
		
		SetEntityHealth(target, 500);
		rp_SetClientInt(target, i_Kevlar, 250);
	}
}
public Action fwdItem(int client, int itemID) {
	
	
	if( rp_GetPlayerZone(client) == QUEST_ARENA ) {
		
		if( itemID == 294 || itemID == 295 )
			return Plugin_Stop;
		
		if( g_iQuestConfig[QC_Difficulty] == 1 ) {
			// Les items de heal, médishoot, propu, fusée...
			if( itemID == 48 || itemID == 89 || itemID == 258 )
				return Plugin_Stop;
			if( rp_GetItemInt(itemID, item_type_give_hp) > 0 )
				return Plugin_Stop;
		}
		else if( g_iQuestConfig[QC_Difficulty] >= 2 ) {
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}
public Action fwdPhysics(int client, float& speed, float& gravity) {
	
	if( g_iQuestConfig[QC_Difficulty] >= 1 ) {
		gravity = 1.0;
		speed = 1.0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
public Action fwdDead(int client) {

	if( rp_GetPlayerZone(client) == QUEST_ARENA ) {
		g_iQuestConfig[QC_Health]--;
		g_iQuestConfig[QC_DeadTime] = 60;
		g_iKillingSpree[client] = 0;
		g_iKilling[client] = 0;
	}
}
public Action fwdZone(int client, int newZone, int oldZone) {
	if( newZone == 59 || newZone == 57 || newZone == 58 || newZone == 200 )
		if ( g_iQuestConfig[QC_Health] > 0) {
			if( GetClientTeam(client) == CS_TEAM_T ) {
				TeleportEntity(client, QUEST_MID, NULL_VECTOR, NULL_VECTOR);
				FakeClientCommand(client, "sm_stuck");
			}
			else {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être civil pour participer à la quête.");
			}
		}
}
// ----------------------------------------------------------------------------
bool SQ_Pop(float pos[3], float size = 32.0) {
	static const int attempt = 10;
	static float min[3], max[3];
	static bool init;
	
	if( !init ) {
		min[0] = rp_GetZoneFloat(QUEST_ARENA, zone_type_min_x);
		min[1] = rp_GetZoneFloat(QUEST_ARENA, zone_type_min_y);
		min[2] = rp_GetZoneFloat(QUEST_ARENA, zone_type_min_z);
		
		max[0] = rp_GetZoneFloat(QUEST_ARENA, zone_type_max_x);
		max[1] = rp_GetZoneFloat(QUEST_ARENA, zone_type_max_y);
		max[2] = rp_GetZoneFloat(QUEST_ARENA, zone_type_max_z);
		init = true;
	}
	
	for (int i = 0; i < attempt; i++) {
		if( PHUN_Nav_GetAreaHidingSpot(min, max, pos) )
			if( SQ_Valid(pos, size) )
				return true;
	}
	return false;
}
bool SQ_Valid(float pos[3], float size) {
	float abs[3], min[3], max[3];
	
	float threshold = GetVectorDistance(pos, QUEST_MID);
	// TODO : Augmenter les chances de pop loins du mid
	if( threshold < 800.0 )
		return false;
	
	// Pas si un joueur nous vois.
	for (int i = 0; i < g_stkTeamCount[TEAM_PLAYERS]; i++) {
		int client = g_stkTeam[TEAM_PLAYERS][i];
		
		if( IsAbleToSee(client, pos) ) {
			return false;
		}
	}
	
	// Pas sur un navmesh plus petit que la taille
	int id = PHUN_Nav_GetAreaId(pos);
	PHUN_Nav_AreaIdToPosition(id, abs, min, max);
	SubtractVectors(max, min, abs);
	
	float length = GetVectorLength(abs);
	if( length < size )
		return false;
	
	// Ni sur un truc qui semble bloqué
	for (int i = 0; i < 2; i ++) {
		min[i] = -size / 2.0;
		max[i] =  size / 2.0;
	}
	min[2] = 0.0;
	max[2] = size * 2.0;
	
	Handle tr = TR_TraceHullEx(pos, pos, min, max, MASK_SOLID);
	if (TR_DidHit(tr)) {
		CloseHandle(tr);
		return false;
	}
	CloseHandle(tr);
	return true;
}
// ----------------------------------------------------------------------------
int SQ_SpawnLight() {
	float pos[3];
	pos = QUEST_BONUS;
	pos[0] = (rp_GetZoneFloat(QUEST_ARENA, zone_type_min_x) + rp_GetZoneFloat(QUEST_ARENA, zone_type_max_x)) / 2.0;
	pos[1] = (rp_GetZoneFloat(QUEST_ARENA, zone_type_min_y) + rp_GetZoneFloat(QUEST_ARENA, zone_type_max_y)) / 2.0;
	pos[2] += 1024.0;
	
	int ent = CreateEntityByName("env_projectedtexture");
	DispatchKeyValue(ent, "targetname", "toto");
	DispatchKeyValue(ent, "farz", "2048");
	DispatchKeyValue(ent, "texturename", "effects/flashlight001_intro");
	DispatchKeyValue(ent, "lightcolor", "255 150 100 5");
	DispatchKeyValue(ent, "spawnflags", "1");
	DispatchKeyValue(ent, "lightfov", "170");
	DispatchKeyValue(ent, "brightnessscale", "50");
	DispatchKeyValue(ent, "lightworld", "1");
	
	DispatchSpawn(ent);
	TeleportEntity(ent, pos, view_as<float>({ 90.0, 0.0, 0.0 }), NULL_VECTOR);
	
	return ent;
}
int SQ_SpawnBonus() {
	int parent = CreateEntityByName("func_rotating");
	DispatchKeyValueVector(parent, "origin", QUEST_BONUS);
	DispatchKeyValue(parent, "maxspeed", "128");
	DispatchKeyValue(parent, "friction", "0");
	DispatchKeyValue(parent, "solid", "0");
	DispatchKeyValue(parent, "spawnflags", "64");
	DispatchSpawn(parent);
	TeleportEntity(parent, QUEST_BONUS, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(parent, "Start");
	
	int ent = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(ent, "model", "models/DeadlyDesire/props/udamage.mdl");
	DispatchSpawn(ent);
	TeleportEntity(ent, QUEST_BONUS, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", parent);
	
	Entity_SetSolidFlags(ent, FSOLID_TRIGGER);
	Entity_SetCollisionGroup(ent, COLLISION_GROUP_PLAYER);
	
	SDKHook(ent, SDKHook_Touch, fwdTouch);
	
	SetEntityRenderMode(ent, RENDER_TRANSALPHA);
	SetEntityRenderColor(ent, 255, 0, 255, 200);
	
	int sub = CreateEntityByName("env_projectedtexture");
	DispatchKeyValue(sub, "farz", "128");
	DispatchKeyValue(sub, "texturename", "effects/flashlight001_intro");
	DispatchKeyValue(sub, "lightcolor", "255 0 255 50");
	DispatchKeyValue(sub, "spawnflags", "1");
	DispatchKeyValue(sub, "lightfov", "160");
	DispatchKeyValue(sub, "brightnessscale", "5");
	DispatchKeyValue(sub, "lightworld", "1");
	DispatchSpawn(sub);
	SetVariantString("!activator");
	AcceptEntityInput(sub, "SetParent", parent);
	TeleportEntity(sub, view_as<float>({0.0, 0.0, 64.0}), view_as<float>({ 90.0, 0.0, 0.0 }), NULL_VECTOR);
	
	return parent;
}
// ----------------------------------------------------------------------------
stock bool IsAbleToSee(int client, float dst[3], int target = -1) {
	static float src[3], ang[3], v_dir[3], d_dir[3];
	static float threshold = 0.73;
	GetClientEyePosition(client, src);
	GetClientEyeAngles(client, ang);
	ang[0] = ang[2] = 0.0;
	// ang[0] needed?
	
	//
	if( PHUN_Nav_GetAreaId(src) == PHUN_Nav_GetAreaId(dst) )
		return true;
	
	//
	GetAngleVectors(ang, v_dir, NULL_VECTOR, NULL_VECTOR);
	SubtractVectors(dst, src, d_dir);
	NormalizeVector(d_dir, d_dir);
	if( GetVectorDotProduct(v_dir, d_dir) < threshold) 
		return false;
	
	//
	Handle tr = TR_TraceRayFilterEx(src, dst, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayers, client);
	if( TR_DidHit(tr) && TR_GetEntityIndex(tr) != target ) {
		delete tr;
		return false;
	}
	delete tr;
	return true;
}
stock bool IsMonster(int ent) {
	static char classname[64];
	GetEdictClassname(ent, classname, sizeof(classname));
	return StrEqual(classname, "monster_generic");
}
public bool TraceEntityFilterPlayers(int entity, int contentsMask, any data ) {
	return entity > MaxClients && entity != data;
}
// ----------------------------------------------------------------------------
void addClientToTeam(int client, int team) {
	removeClientTeam(client);
	
	if( team != TEAM_NONE )
		g_stkTeam[team][ g_stkTeamCount[team]++ ] = client;
	
	g_iPlayerTeam[client] = team;
}
void removeClientTeam(int client) { 
	if( g_iPlayerTeam[client] != TEAM_NONE ) {
		for (int i = 0; i < g_stkTeamCount[g_iPlayerTeam[client]]; i++) {
			if( g_stkTeam[ g_iPlayerTeam[client] ][ i ] == client ) {
				for (; i < g_stkTeamCount[g_iPlayerTeam[client]]; i++) {
					g_stkTeam[g_iPlayerTeam[client]][i] = g_stkTeam[g_iPlayerTeam[client]][i + 1];
				}
				g_stkTeamCount[g_iPlayerTeam[client]]--;
				break;
			}
		}
		
		g_iPlayerTeam[client] = TEAM_NONE;
	}
}
// ----------------------------------------------------------------------------
public Action newAttempt(Handle timer, any zboub) {
	g_bCanMakeQuest = true;
}
// -----------------------------------------------------------------------------------------------------------------
void announceSound(int client, int sound) {
	static char msg[128];
	
	switch( sound ) {
		case snd_FirstBlood: Format(msg, sizeof(msg), 	"%N\n<font color='#33ff33'><b>a versé le premier sang !</b></font>", client);
		case snd_DoubleKill: Format(msg, sizeof(msg), 	"%N\n<font color='#33ff33'><b>   Double kill</b></font>", client);
		case snd_MultiKill: Format(msg, sizeof(msg), 	"%N\n<font color='#33ff33'><b>   MULTI kill</b></font>", client);
		case snd_MegaKill: Format(msg, sizeof(msg), 	"%N\n<font color='#33ff33'><b>   MEGA KILL</b></font>", client);
		case snd_UltraKill: Format(msg, sizeof(msg), 	"%N\n<font color='#33ff33'><b>   ULTRAAA-KILL !</b></font>", client);
		case snd_MonsterKill: Format(msg, sizeof(msg), 	"%N\n<font color='#33ff33'><b>MOOOONSTER KILL !</b></font>", client);
		case snd_KillingSpree: Format(msg, sizeof(msg),	"%N\n<font color='#33ff33'><b>fait une série meurtrière</b></font>", client);
		case snd_Unstopppable: Format(msg, sizeof(msg),	"%N\n<font color='#33ff33'><b> est inarrêtable!</b></font>", client);
		case snd_Dominating: Format(msg, sizeof(msg),	"%N\n<font color='#33ff33'><b>   DOMINE !</b></font>", client);
		case snd_Godlike: Format(msg, sizeof(msg),		"%N\n<font color='#33ff33'><b> EST DIVIN !</b></font>", client);
	}
	
	for (int i = 0; i < g_stkTeamCount[TEAM_PLAYERS]; i++)
		PrintHintText(g_stkTeam[TEAM_PLAYERS][i], msg);
	
	EmitSoundAny(g_stkTeam[TEAM_PLAYERS], g_stkTeamCount[TEAM_PLAYERS], g_szSoundList[sound], _, _, _, _, 1.0);
}
void CyclAnnouncer_Frame() {
	int NowTime = GetTime();
	int time, soundID, target;
	
	if( NowTime % 3 == 0 ) {
		bool found = CyclAnnouncer_Empty();
		
		while( !found  ) {
			time = g_CyclAnnouncer[g_CyclAnnouncer_end][ann_Time];
			soundID = g_CyclAnnouncer[g_CyclAnnouncer_end][ann_SoundID];
			target = g_CyclAnnouncer[g_CyclAnnouncer_end][ann_Client];
			
			g_CyclAnnouncer_end = (g_CyclAnnouncer_end+1) % MAX_ANNOUNCES;
			
			if( (time+ANNONCES_DELAY) >= NowTime && IsValidClient(target) ) {
				announceSound(target, soundID);
				found = true;
			}
			else {
				found = CyclAnnouncer_Empty();
			}
		}
	}
}
void CyclAnnouncer(int client) {
	bool sound = false;
	
	if( g_iQuestConfig[QC_FirstBlood] == 0 ) {
		g_iQuestConfig[QC_FirstBlood] = 1;
		CyclAnnouncer_Push(client, snd_FirstBlood);
	}
	
	switch( g_iKilling[client] ) {
		case 2: sound = CyclAnnouncer_Push(client, snd_DoubleKill);
		case 3: sound = CyclAnnouncer_Push(client, snd_MultiKill);
		case 4: sound = CyclAnnouncer_Push(client, snd_MegaKill);
		case 5: sound = CyclAnnouncer_Push(client, snd_UltraKill);
		case 6: sound = CyclAnnouncer_Push(client, snd_MonsterKill);
		default: {
			if( g_iKilling[client] >= 6 && g_iKilling[client] % 2)
				sound = CyclAnnouncer_Push(client, snd_MonsterKill);
		}
	}
	
	if( !sound ) {
		switch( g_iKillingSpree[client] ) {
			case 5: sound = CyclAnnouncer_Push(client, snd_KillingSpree);
			case 10: sound = CyclAnnouncer_Push(client, snd_Dominating);
			case 15: sound = CyclAnnouncer_Push(client, snd_Unstopppable);
			case 20: sound = CyclAnnouncer_Push(client, snd_Godlike);
			default: {
				if( g_iKillingSpree[client] >= 12 && g_iKillingSpree[client] % 2 )
					sound = CyclAnnouncer_Push(client, snd_Godlike);
			}
		}
	}
}
bool CyclAnnouncer_Push(int client, int soundID) {
	
	if( !CyclAnnouncer_Empty() ) {
		int i = g_CyclAnnouncer_end;
		
		while( i != g_CyclAnnouncer_start ) {
			if( g_CyclAnnouncer[i][ann_Client] == client ) {
				g_CyclAnnouncer[i][ann_SoundID] = soundID;
				g_CyclAnnouncer[i][ann_Time] = GetTime();
				return true;
			}
			
			i = (i + 1) % MAX_ANNOUNCES;
		}
	}
	if( CyclAnnouncer_Full() )
		return false;
	
	g_CyclAnnouncer[g_CyclAnnouncer_start][ann_Client] = client;
	g_CyclAnnouncer[g_CyclAnnouncer_start][ann_SoundID] = soundID;
	g_CyclAnnouncer[g_CyclAnnouncer_start][ann_Time] = GetTime();
	
	g_CyclAnnouncer_start = (g_CyclAnnouncer_start+1) % MAX_ANNOUNCES;
	
	return true;
}
bool CyclAnnouncer_Full() {
	return ((g_CyclAnnouncer_end + 1) % MAX_ANNOUNCES == g_CyclAnnouncer_start);
}
bool CyclAnnouncer_Empty() {
	return (g_CyclAnnouncer_end == g_CyclAnnouncer_start);
}
public Action ResetKillCount(Handle timer, any client) {
	if( g_hKillTimer[client] != INVALID_HANDLE )
		g_iKilling[client] = 0;
	g_hKillTimer[client] = INVALID_HANDLE;
}
// -----------------------------------------------------------------------------------------------------------------
public void QI_Start(int objectiveID, int client) {
	addClientToTeam(client, TEAM_PLAYERS);
}
public void QI_Frame(int objectiveID, int client) {
	if( g_stkTeamCount[TEAM_PLAYERS] >= REQUIRED_PLAYER ) {
		rp_QuestStepComplete(client, objectiveID);
		return;
	}
	for (int i = 0; i < g_stkTeamCount[TEAM_INVITATION]; i++) {
		DrawMenu_Invitation(client, g_stkTeam[TEAM_INVITATION][i]);
	}
	
	if( rp_ClientCanDrawPanel(client) ) {
		char tmp[64], tmp2[64];		
		Menu menu = new Menu(MenuInviter);
		menu.SetTitle("Quète: %s", QUEST_NAME);
		menu.AddItem("refresh", "Actualiser le menu");
		menu.AddItem("", "Participant confirmé:", ITEMDRAW_DISABLED);
		for (int i = 0; i < g_stkTeamCount[TEAM_PLAYERS]; i++) {
			Format(tmp, sizeof(tmp), "%N", g_stkTeam[TEAM_PLAYERS][i]);
			menu.AddItem("", tmp, ITEMDRAW_DISABLED);
		}
		
		menu.AddItem("", "Participant en attente:", ITEMDRAW_DISABLED);
		for (int i = 0; i < g_stkTeamCount[TEAM_INVITATION]; i++) {
			Format(tmp, sizeof(tmp), "%d", g_stkTeam[TEAM_INVITATION][i]);
			Format(tmp2, sizeof(tmp2), "%N", g_stkTeam[TEAM_INVITATION][i]);
			menu.AddItem(tmp, tmp2);
		}
		
		if( g_stkTeamCount[TEAM_PLAYERS]+g_stkTeamCount[TEAM_INVITATION] < REQUIRED_PLAYER ) {
			menu.AddItem("", "Envoyer invitation:", ITEMDRAW_DISABLED);
			for (int i = 1; i <= MaxClients; i++) {
				if( !IsValidClient(i) )
					continue;
				if( g_iPlayerTeam[i] != TEAM_NONE )
					continue;
				if( rp_GetClientBool(i, b_IsMuteEvent) == true )
					continue;
				if( rp_GetClientInt(i, i_PlayerLVL) < 100 )
					continue;
				
				Format(tmp, sizeof(tmp), "%d", i);
				Format(tmp2, sizeof(tmp2), "%N", i);
				menu.AddItem(tmp, tmp2);
			}
		}
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
}
void DrawMenu_Invitation(int client, int target) {
	Menu menu = new Menu(MenuInviter);
	menu.SetTitle("%N souhaite participer\nà la quète %s\n avec vous dans son équipe.\n \n Acceptez-vous son invitation?", client, QUEST_NAME);
	menu.AddItem("oui", "Oui");
	menu.AddItem("non", "Non");
	menu.ExitButton = false;
	
	menu.Display(target, 10);
}
public int MenuInviter(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		if( StrEqual(options, "refresh") )
			return;
		else if( StrEqual(options, "oui") ) {
			if( g_stkTeamCount[TEAM_PLAYERS] < REQUIRED_PLAYER && g_iPlayerTeam[client] == TEAM_INVITATION ) {
				addClientToTeam(client, TEAM_PLAYERS);
			}
			else {
				removeClientTeam(client);
			}
		}
		else if( StrEqual(options, "non") ) {
			removeClientTeam(client);
		}
		else {
			int target = StringToInt(options);
			if( IsValidClient(target) ) {
				if( g_iPlayerTeam[target] == TEAM_INVITATION )
					removeClientTeam(target);
				else
					addClientToTeam(target, TEAM_INVITATION);
			}
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}