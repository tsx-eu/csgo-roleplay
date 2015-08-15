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
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define QUEST_UNIQID	"001-safety"
#define	QUEST_NAME		"En sécurité à princeton?"
#define	QUEST_TYPE		quest_story

public Plugin myinfo = {
	name = "Quête: Safety", author = "KoSSoLaX",
	description = "RolePlay - Quête: En sécurité à princeton?",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest;
int g_cBloodBig, g_cBlood;

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++,	Q1_Start,	Q1_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	QUEST_NULL,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++,	Q3_Start,	Q3_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++,	Q4_Start,	Q4_Frame,	QUEST_NULL,	QUEST_NULL);
	
	
}
public void OnMapStart() {
	AddFileToDownloadsTable("sound/DeadlyDesire/halloween/zombie/mumbling1.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/halloween/zombie/foot1.mp3");
	
	PrecacheSoundAny("DeadlyDesire/halloween/zombie/mumbling1.mp3", true);
	PrecacheSoundAny("DeadlyDesire/halloween/zombie/foot1.mp3", true);
	
	g_cBloodBig = PrecacheDecal("decals/bloodstain_003.vmt", true);
	g_cBlood = PrecacheDecal("decals/flesh/blood2.vmt", true);
}
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	return true;
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	
	menu.AddItem("", "Vous entendez comme des chuchotements en dehors de cette église.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Étant de nature curieuse vous décidez de vous en approchez", ITEMDRAW_DISABLED);
	menu.AddItem("", "pour écouter. Malheureusement, vous ne percevez que de petit bout de phrase...", ITEMDRAW_DISABLED);
	menu.AddItem("", "", ITEMDRAW_DISABLED);
	menu.AddItem("", "ςεττε vιℓℓε η'εsτ ραs sμя ρяοςμяεя vομs μηε αямε ρομя vομs δéfεηδяε.", ITEMDRAW_DISABLED);
	menu.AddItem("", "", ITEMDRAW_DISABLED);
	menu.AddItem("", "Par inadvertance, vous renversez la statue de Cupidon, juste derrière vous..", ITEMDRAW_DISABLED);
	menu.AddItem("", "Vous entendez des bruits de pas s'éloigner.", ITEMDRAW_DISABLED);
	menu.AddItem("", "", ITEMDRAW_DISABLED);
	menu.AddItem("", "Vous décidez d'aller enquêter en direction du bruit.", ITEMDRAW_DISABLED);	
	
	menu.ExitButton = false;
	menu.Display(client, 30);
}
public void Q1_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {4877.0, 1286.0, -2076.0};
	GetClientAbsOrigin(client, origin);
	
	if( GetVectorDistance(origin, target) < 64.0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		rp_Effect_BeamBox(client, 0, target);
		if( Math_GetRandomInt(1, 5) == 3 )
			EmitSoundToClientAny(client, "DeadlyDesire/halloween/zombie/mumbling1.mp3", SOUND_FROM_WORLD, _, _, _, _, _, _, target);
	}
}
public void Q2_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	menu.SetTitle("Quète: %s", QUEST_NAME);
	
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	
	menu.AddItem("", "Vous avez suivi les bruits... Jusqu'à une tombe.", ITEMDRAW_DISABLED);
	menu.AddItem("", "On dirait qu'il y a quelqu'un d'enterrer vivant !!", ITEMDRAW_DISABLED);
	menu.AddItem("", "Il semblerait que cette ville cache bien des secrets.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 15);
	
	Handle dp;
	CreateDataTimer(10.0, GOTO_Q3, dp);
	WritePackCell(dp, client);
	WritePackCell(dp, objectiveID);	
}
public Action GOTO_Q3(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int objectiveID = ReadPackCell(dp);
	
	rp_QuestStepComplete(client, objectiveID);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez perdu connaissance.");
	
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen, 10.0);
	rp_HookEvent(client, RP_PreHUDColorize, fwdBlack, 10.0);
}
public Action fwdFrozen(int client, float& speed, float& gravity) {
	speed = 0.0;
	
	return Plugin_Stop;
}
public Action fwdBlack(int client, int color[4]) {
	
	color[0] -= 999999;
	color[1] -= 999999;
	color[2] -= 999999;
	color[3] += 999999;
	return Plugin_Stop;
}
public void Q3_Start(int objectiveID, int client) {
	Client_RemoveAllWeapons(client);
	TeleportEntity(client, view_as<float>({ 1842.0, -1477.1, -2142.0 }), NULL_VECTOR, NULL_VECTOR);
	
	Menu menu = new Menu(MenuNothing);
	menu.SetTitle("Quète: %s", QUEST_NAME);
	
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	
	menu.AddItem("", "Vous vous réveillez avec gros mal de tête.", ITEMDRAW_DISABLED);
	
	menu.AddItem("", "Vous décidez de vous procurer une arme afin de vous", ITEMDRAW_DISABLED);
	menu.AddItem("", "protéger si jamais on viendrait à vous attaquer.", ITEMDRAW_DISABLED);
	menu.AddItem("", "à nouveau.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 15);
}
public void Q3_Frame(int objectiveID, int client) {
	bool hasWeapon = false;
	
	for( int i = 0; i < 5; i++ ){
		if( i == CS_SLOT_KNIFE ) continue; 
		if( i == CS_SLOT_C4 ) continue;
		
		if( GetPlayerWeaponSlot( client, i ) > 0 ) {
			hasWeapon = true;
			break;
		}
	}
	
	if( hasWeapon ) {
		rp_QuestStepComplete(client, objectiveID);
	}
}
public void Q4_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	menu.SetTitle("Quète: %s", QUEST_NAME);
	
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	
	menu.AddItem("", "Maintenant que vous êtes armé, vous retournez au dernier endroit", ITEMDRAW_DISABLED);
	menu.AddItem("", "d'ou vous vous souvenez avant d'être tombé endormis: Une tombe.", ITEMDRAW_DISABLED);
	menu.AddItem("", "", ITEMDRAW_DISABLED);
	menu.AddItem("", "Il n'y a plus de bruit d'homme, mais vous suivez les traces de sang", ITEMDRAW_DISABLED);
	
	
	
	menu.ExitButton = false;
	menu.Display(client, 30);
}
public void Q4_Frame(int objectiveID, int client) {
	static float blood[][3] = {
		{ 4877.0, 1286.0, -2076.0},
		{ 5047.765136, 1250.259643, -2080.110107}, 
		{ 5055.496093, 1232.024414, -2078.970458}, 
		{ 5072.689453, 1191.469238, -2076.435546}, 
		{ 5092.841796, 1143.722900, -2073.451660}, 
		{ 5113.605957, 1091.447387, -2070.184326}, 
		{ 5131.823242, 1041.961791, -2067.091552}, 
		{ 5146.516113, 998.685485, -2064.386474}, 
		{ 5161.842773, 951.913940, -2061.463134}, 
		{ 5176.985351, 905.082519, -2058.536376}, 
		{ 5193.141113, 854.883728, -2055.398925}, 
		{ 5207.087890, 811.360656, -2052.678710}, 
		{ 5221.260742, 764.227844, -2049.733154}, 
		{ 5233.556640, 720.210266, -2046.982177}, 
		{ 5245.961425, 672.580993, -2044.146118}, 
		{ 5257.687988, 624.780151, -2041.969116}, 
		{ 5268.325683, 576.725646, -2038.515136}, 
		{ 5277.984863, 532.055541, -2035.427978}, 
		{ 5290.940917, 484.590240, -2031.112670}, 
		{ 5309.950683, 443.179748, -2026.453613}, 
		{ 5341.830566, 405.827606, -2019.921386}, 
		{ 5384.151855, 368.793304, -2012.263061}, 
		{ 5426.204589, 331.452117, -2003.597900}, 
		{ 5471.274902, 287.034240, -1991.450805}, 
		{ 5507.947265, 249.141677, -1980.341796}, 
		{ 5547.545898, 199.839614, -1968.296875}, 
		{ 5587.062500, 137.507553, -1950.913574}, 
		{ 5617.333984, 81.948150, -1939.549072}, 
		{ 5642.549804, 27.771198, -1928.401977}, 
		{ 5663.909179, -24.260295, -1918.610595}, 
		{ 5685.685058, -83.675369, -1911.968750}, 
		{ 5703.169433, -133.427108, -1911.968750}, 
		{ 5724.206542, -196.820220, -1911.968750}, 
		{ 5741.347656, -254.074218, -1911.968750}, 
		{ 5759.009765, -318.491424, -1911.968750}, 
		{ 5773.918945, -376.367523, -1911.968750}, 
		{ 5791.471679, -448.075927, -1911.968750}, 
		{ 5804.030273, -510.095397, -1911.968750}, 
		{ 5815.882812, -579.397338, -1911.968750}, 
		{ 5825.062988, -645.559387, -1911.968750}, 
		{ 5832.270019, -708.423583, -1911.968750}, 
		{ 5835.521972, -771.610656, -1911.968750}, 
		{ 5835.896484, -827.855102, -1911.968750}, 
		{ 5831.299804, -890.933898, -1911.968750}, 
		{ 5815.941894, -955.846679, -1911.968750}, 
		{ 5791.954589, -1010.286682, -1911.968750}, 
		{ 5753.579101, -1045.294555, -1911.968750}, 
		{ 5697.244140, -1062.029174, -1911.968750}, 
		{ 5634.104980, -1065.774414, -1911.968750}, 
		{ 5581.371582, -1065.963378, -1911.968750}, 
		{ 5528.637207, -1066.038696, -1911.968750}, 
		{ 5475.904296, -1066.579956, -1920.152709}, 
		{ 5426.690429, -1067.160888, -1922.364868}, 
		{ 5373.956054, -1066.933227, -1923.968750}, 
		{ 5324.739746, -1066.390747, -1923.968750}, 
		{ 5272.005371, -1066.107543, -1927.338745}, 
		{ 5215.755371, -1066.090576, -1933.658813}, 
		{ 5159.505371, -1066.268066, -1940.736450}, 
		{ 5110.288085, -1066.075195, -1946.218383}, 
		{ 5061.119140, -1064.057739, -1953.546508}, 
		{ 5009.251953, -1054.902099, -1957.484375}, 
		{ 4961.747070, -1032.487915, -1956.044677}, 
		{ 4928.242675, -1006.892639, -1955.505859}, 
		{ 4887.420410, -968.245056, -1955.451049}, 
		{ 4860.843750, -935.522766, -1954.850585}, 
		{ 4833.414062, -875.766052, -1954.531982}, 
		{ 4838.695312, -830.592346, -1951.312255}, 
		{ 4869.497070, -810.442810, -1927.968750}, 
		{ 4915.294921, -812.414306, -1911.968750}, 
		{ 4946.494140, -814.127563, -1911.968750}, 
		{ 4980.006835, -812.019714, -1911.968750}, 
		{ 5035.182128, -808.549560, -1911.968750}, 
		{ 5086.329589, -805.333129, -1911.968750}, 
		{ 5137.553222, -802.694274, -1911.968750}, 
		{ 5190.181640, -802.561950, -1911.968750}, 
		{ 5235.865234, -803.846862, -1911.968750}, 
		{ 5284.982910, -806.954223, -1911.968750}, 
		{ 5334.022949, -811.137023, -1911.968750}, 
		{ 5379.621093, -814.214965, -1911.968750}, 
		{ 5432.299804, -816.598999, -1911.968750}, 
		{ 5473.678222, -816.575866, -1911.968750}, 
		{ 5493.113769, -805.566711, -1911.968750}, 
		{ 5497.735351, -775.316162, -1911.968750}, 
		{ 5502.511718, -722.707519, -1911.968750}, 
		{ 5504.415039, -680.569641, -1911.968750}, 
		{ 5504.735351, -616.303894, -1911.968750}, 
		{ 5501.926757, -577.786682, -1911.968750}, 
		{ 5499.155761, -557.430175, -1911.968750}, 
		{ 5491.021484, -536.774658, -1911.968750}, 
		{ 5472.775390, -516.526672, -1911.968750}, 
		{ 5468.594726, -483.945678, -1911.968750}, 
		{ 5479.005859, -444.749084, -1911.968750}, 
		{ 5491.830078, -412.814086, -1911.968750}
	};
	
	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin", blood[0]);
	TE_WriteNum("m_nIndex", g_cBloodBig);
	TE_SendToClient(client);
	
	float vecPos[3], dist = 999999999.9;
	GetClientAbsOrigin(client, vecPos);
	int nearEst = 0;
	
	for (int i = 1; i < sizeof(blood); i++) {
		TE_Start("World Decal");
		TE_WriteVector("m_vecOrigin", blood[i]);
		TE_WriteNum("m_nIndex", g_cBlood);
		TE_SendToClient(client);
		
		float tmp = GetVectorDistance(blood[i], vecPos);
		if( tmp < dist ) {
			dist = tmp;
			nearEst = i;
		}
	}
	
	if( nearEst < sizeof(blood)-1 )
		nearEst++;
	
	rp_Effect_BeamBox(client, -1, blood[nearEst], 255, 0, 0);
}
// ----------------------------------------------------------------------------
public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
	else if( action == MenuAction_End ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
}
