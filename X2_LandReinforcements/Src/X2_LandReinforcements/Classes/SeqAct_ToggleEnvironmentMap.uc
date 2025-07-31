//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_ToggleEnvironmentMap.uc
//  AUTHOR:  Furu  --  X/XX/2025
//  PURPOSE: Toggles level visibility of the environment map in Kismet
//---------------------------------------------------------------------------------------

class SeqAct_ToggleEnvironmentMap extends SequenceAction;

event Activated()
{
	local WorldInfo WorldInfo;
	local XComEnvLightingManager EnvLightMgr;
	local LevelStreaming Level, EnvironmentLevel;
	local XComLevelActor Actor, Skybox;
	local ExponentialHeightFog Fog;
	local DominantDirectionalLight DominantLight;

	WorldInfo = `XWORLDINFO;
	EnvLightMgr = `ENVLIGHTINGMGR;

	foreach WorldInfo.StreamingLevels(Level)
	{
		if(InStr(Level.PackageName, EnvLightMgr.currentMapName) != INDEX_NONE)
		{
			EnvironmentLevel = Level;
			break;
		}
	}

	foreach WorldInfo.AllActors(class'XComLevelActor', Actor)
	{
		if(Actor.StaticMeshComponent.StaticMesh.Name == 'sm_sky_latlong')
		{
			Skybox = Actor;
			break;
		}
	}

	foreach WorldInfo.AllActors(class'ExponentialHeightFog', Fog)
	{
		break;
	}

	foreach WorldInfo.AllActors(class'DominantDirectionalLight', DominantLight)
	{
		break;
	}

	if(InputLinks[0].bHasImpulse)
	{
		`MAPS.SetStreamingLevelVisible(EnvironmentLevel, false);
		Skybox.SetVisible(false);
		Fog.Component.SetEnabled(false);
		DominantLight.LightComponent.SetEnabled(false);
	}
	else if(InputLinks[1].bHasImpulse)
	{
		`MAPS.SetStreamingLevelVisible(EnvironmentLevel, true);
		Skybox.SetVisible(true);
		Fog.Component.SetEnabled(true);
		DominantLight.LightComponent.SetEnabled(true);
	}
}

defaultproperties
{
	ObjCategory="Furu"
	ObjName="Toggle Environment Map"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="Hide")
	InputLinks(1)=(LinkDesc="UnHide")
}