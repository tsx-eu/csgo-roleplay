#if defined _advmotd_enabled
 #endinput
#endif
#define _advmotd_enabled

stock void RP_ShowMOTD(int client, char url[1024]) {
	static const char REDIRECT[128] = "https://www.ts-x.eu/popup.php?&url=";
	
	ShowMOTDPanel(client, "", url, MOTDPANEL_TYPE_URL);
	
	Format(url, sizeof(url), "%s%s", REDIRECT, url);
	
	Handle dp;
	CreateDataTimer(0.5, RP_ShowMOTD_Post, dp, TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dp, client);
	WritePackString(dp, url);
}
public Action RP_ShowMOTD_Post(Handle timer, DataPack dp) {
	char url[1024];
	ResetPack(dp);
	int client = ReadPackCell(dp);
	ReadPackString(dp, url, sizeof(url));
	
	ShowMOTDPanel(client, "", url, MOTDPANEL_TYPE_URL);
	return Plugin_Stop;
}