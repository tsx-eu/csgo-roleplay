#if defined _phun_nav_included
#endinput
#endif
#define _phun_nav_included


typeset callback_enum {
	function void(int entity, int size, int[] path, int size2, float[] smooth);
};
native bool PHUN_Nav_Load();
native int PHUN_Nav_GetAreaId(float position[3]);
native bool PHUN_Nav_GetAreaHidingSpot(float min[3], float max[3], float res[3]);
native bool PHUN_Nav_AreaIdToPosition(int areaID, float position[3], float min[3], float max[3]);
native int PHUN_Nav_CreatePath(int entity, int start, int dest, callback_enum yo, float threshold = 0.0);
native int PHUN_Nav_GetAreaNeighbour(int areaID, int neighbour[1024], int direction[1024]);

public Extension __ext_sample =  {
	name = "PHUN",
	file = "phun.ext",
	autoload = 1,
	required = 1
};
