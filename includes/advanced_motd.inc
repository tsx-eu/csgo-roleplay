#if defined _advmotd_enabled
#endinput
#endif
#define _advmotd_enabled

#include <SteamWorks>

#define URL_PATH "https://www.ts-x.eu/api/redirect/%s"


stock void RP_ShowMOTD(int client, char url[1024]) {	
	QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(MOTD_ClientConVar), client);
	
	char tmp[128], szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	Format(tmp, sizeof(tmp), URL_PATH, szSteamID);
	
	Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, tmp);
	SteamWorks_SetHTTPCallbacks(req, MOTD_OnSteamWorksHTTPComplete);
	SteamWorks_SetHTTPRequestContextValue(req, client);
	SteamWorks_SetHTTPRequestGetOrPostParameter(req, "url", url);
	SteamWorks_SendHTTPRequest(req);
}

public int MOTD_OnSteamWorksHTTPComplete(Handle HTTPRequest, bool fail, bool success, EHTTPStatusCode statusCode, any client) {
	if (success && statusCode == k_EHTTPStatusCode200OK )  { 
		char tmp[128], szSteamID[32];
		GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
		Format(tmp, sizeof(tmp), URL_PATH, szSteamID);
		
		ShowMOTDPanel(client, "MOTD", tmp, MOTDPANEL_TYPE_URL);
	}
	
	delete HTTPRequest;
}
public void MOTD_ClientConVar(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue) {
	if (StrEqual(cvarValue, "0") == false) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Des problèmes d'affichage ? Entrez cl_disablehtmlmotd 0 dans votre console puis relancez CS:GO.");
	}
}
