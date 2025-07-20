//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_LandReinforcement.uc
//  AUTHOR:  Furu  --  X/XX/2025
//  PURPOSE: Handles turning ATTs into LTTs
//---------------------------------------------------------------------------------------

class XComGameState_LandReinforcement extends XComGameState_BaseObject
	config(LandReinforcements);

struct SpawnData
{
	var XComPlotCoverParcel PCP;
	var TTile PotentialTile;
	var Vector DirectionVector;
	var array<ActorIdentifier> Props;
};

var StateObjectReference AssociatedSpawner;
var Vector ParcelDirection;
var array<ActorIdentifier> PropsToHide;
var private array<string> PropNames;
var config int ChanceToModifyAirTransportToLandTransport;

function bool Initialize(out XComGameState_AIReinforcementSpawner AISpawner)
{
	local XComPlotCoverParcel PCP;
	local TTile StartTile;
	local Vector StartLocation, DirVector, SpawnLocation;
	local array<SpawnData> PotentialSpawns;
	local SpawnData PotentialSpawn, ChosenSpawn;

	`Log("Checking if ATT can be modified to LTT",, 'X2_LandReinforcements');

	foreach `XWORLDINFO.AllActors(class'XComPlotCoverParcel', PCP)
	{
		if( PCP.strPCPType  == "Periphery"   &&
		  ( PCP.strTurnType == "Boulevard"   ||
			PCP.strTurnType == "Street"      ||
			PCP.strTurnType == "Highway"     ||
			PCP.strTurnType == "Overpass"    ||
			PCP.strTurnType == "AdventRd"    ||
			PCP.strTurnType == "DirtRd"      ))
		{

			StartLocation = PCP.Location;
			StartLocation.Z += 600;
			StartTile = `XWORLD.GetTileCoordinatesFromPosition(StartLocation);

			//`SHAPEMGR.DrawDebugSphere(StartLocation, 40, 10, 255, 0, 0, true);
			//`SHAPEMGR.DrawDebugSphere(PCP.Location, 40, 10, 255, 0, 0, true);

			while(StartTile.Z > -1)
			{
				if(`XWORLD.IsFloorTile(StartTile))
				{
					break;
				}

				StartTile.Z -= 1;
			}

			if(StartTile.Z <= -1)
			{
				StartTile = `XWORLD.GetTileCoordinatesFromPosition(PCP.Location);
			}

			DirVector = FindParcelDirection(PCP);
			FindValidLocations(PCP, StartTile, DirVector, PCP.iWidth / 2, PotentialSpawns);
		}
	}
	
	if(PotentialSpawns.Length > 0)
	{
		PotentialSpawn = GetClosestPCP(PotentialSpawns);
		ChosenSpawn = GetRandomSpawnpoint(PotentialSpawn, PotentialSpawns);
		SpawnLocation = GetFloorLocation(ChosenSpawn.PotentialTile);

		AISpawner.SpawnInfo.SpawnLocation = SpawnLocation;

		//`SHAPEMGR.DrawDebugStar(AISpawner.SpawnInfo.SpawnLocation, 20, 0, 255, 0, true);

		AssociatedSpawner = AISpawner.GetReference();
		ParcelDirection = ChosenSpawn.DirectionVector;
		PropsToHide = ChosenSpawn.Props;

		LoadCinematicMaps();

		`Log("Successfully switched ATT to a land transport",, 'X2_LandReinforcements');
		return true;
	}
	else
	{
		`Log("No valid location found for a land transport",, 'X2_LandReinforcements');
		return false;
	}
}

// This function gets the closest PCP to XCOM squad out of potential PCPs
private function SpawnData GetClosestPCP(array<SpawnData> PotentialSpawns)
{
	local vector XComLocation, TileLocation;
	local float CurrentDistance, ShortestDistance;
	local SpawnData CurrentSpawn, BestSpawn;
	local TTile Tile;
	local int i;

	XComLocation = `SPAWNMGR.GetCurrentXComLocation();
	ShortestDistance = MaxInt;

	for(i = 0; i < PotentialSpawns.Length; i++)
	{
		CurrentSpawn = PotentialSpawns[i];
		Tile = CurrentSpawn.PotentialTile;
		TileLocation = `XWORLD.GetPositionFromTileCoordinates(Tile);

		CurrentDistance = Sqrt( ((XComLocation.X - TileLocation.X) ** 2) + ((XComLocation.Y - TileLocation.Y) ** 2) + ((XComLocation.Z - TileLocation.Z) ** 2) );

		if(CurrentDistance < ShortestDistance)
		{
			ShortestDistance = CurrentDistance;
			BestSpawn = CurrentSpawn;
		}
	}

	return BestSpawn;
}

// This function gets the actual location of the floor since tile position will be in the air
private function Vector GetFloorLocation(TTile Tile)
{
	local vector TileLocation, HitNormal, FloorLocation, TestLocation;

	TileLocation = `XWORLD.GetPositionFromTileCoordinates(Tile);
	TestLocation = TileLocation;
	TestLocation.Z -= 100;

	`XTRACEMGR.XTrace(eXTrace_World, FloorLocation, HitNormal, TestLocation, TileLocation);

	if(IsZero(FloorLocation))
	{
		return TileLocation;
	}

	return FloorLocation;
}

// This function gets a random spawn location out of the PCP that was chosen earlier
private function SpawnData GetRandomSpawnpoint(SpawnData ChosenPCP, array<SpawnData> PotentialSpawns)
{
	local array<SpawnData> ChosenSpawns;
	local SpawnData ChosenSpawn;
	local int i;

	for(i = 0; i < PotentialSpawns.Length; i++)
	{
		if(ChosenPCP.PCP == PotentialSpawns[i].PCP)
		{
			ChosenSpawns.AddItem(PotentialSpawns[i]);
		}
	}

	ChosenSpawn = ChosenSpawns[`SYNC_RAND(ChosenSpawns.Length)];

	return ChosenSpawn;
}

// This function loads the cinematic maps, duh
private function LoadCinematicMaps()
{
	`MAPS.AddStreamingMap("CIN_LandReinforcements",,,false).bForceNoDupe = true;
}

// This function overrides the visualization if the spawner was modified to a land transport
function OverrideVisualization(XComGameState PendingGameState, XComGameState_AIReinforcementSpawner CurrentSpawner)
{
	if(CurrentSpawner.ObjectID == AssociatedSpawner.ObjectID)
	{
		`Log("Overriding the visualization for LTT",, 'X2_LandReinforcements'); 

		XComGameStateContext_ChangeContainer(PendingGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForUnitSpawning;
	}
}

// This function is a modified version of XComGameState_AIReinforcementSpawner::BuildVisualizationForUnitSpawning
function BuildVisualizationForUnitSpawning(XComGameState VisualizeGameState)
{
	local XComGameState_AIReinforcementSpawner AISpawnerState;
	local XComGameState_Unit SpawnedUnit;
	local int i;
	local VisualizationActionMetadata ActionMetadata, EmptyBuildTrack;
	local XComGameStateHistory History;
	local X2Action_ShowSpawnedUnit ShowSpawnedUnitAction;
	local X2Action_LTT LTTAction;
	local float ShowSpawnedUnitActionTimeout;
	local X2Action_Delay RandomDelay;
	local X2Action_MarkerNamed SyncAction;
	local XComGameStateContext Context;
	local float OffsetVisDuration;
	local X2Action_CameraLookAt LookAtAction;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local array<X2Action>					LeafNodes;

	OffsetVisDuration = 0.0;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_AIReinforcementSpawner', AISpawnerState)
	{
		if(AISpawnerState.ObjectID == AssociatedSpawner.ObjectID)
		{
			break;
		}
	}

	Context = VisualizeGameState.GetContext();
	ActionMetadata.StateObject_OldState = AISpawnerState;
	ActionMetadata.StateObject_NewState = AISpawnerState;

	ShowSpawnedUnitActionTimeout = 10.0f;
	if (AISpawnerState.SpawnVisualizationType == 'ATT' )
	{
		LTTAction = X2Action_LTT(class'X2Action_LTT'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		ShowSpawnedUnitActionTimeout = LTTAction.TimeoutSeconds;
	}

	SyncAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SyncAction.SetName("SpawningStart");

	for( i = AISpawnerState.SpawnedUnitIDs.Length - 1; i >= 0; --i )
	{
		SpawnedUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(AISpawnerState.SpawnedUnitIDs[i]));

		if( SpawnedUnit.GetVisualizer() == none )
		{
			SpawnedUnit.FindOrCreateVisualizer();
			SpawnedUnit.SyncVisualizer();

			//Make sure they're hidden until ShowSpawnedUnit makes them visible (SyncVisualizer unhides them)
			XGUnit(SpawnedUnit.GetVisualizer()).m_bForceHidden = true;
		}

		ActionMetadata = EmptyBuildTrack;
		ActionMetadata.StateObject_OldState = SpawnedUnit;
		ActionMetadata.StateObject_NewState = SpawnedUnit;
		ActionMetadata.VisualizeActor = History.GetVisualizer(SpawnedUnit.ObjectID);

		// if multiple units are spawning, apply small random delays between each
		if( i > 0 )
		{
			RandomDelay = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, Context, false, SyncAction));
			OffsetVisDuration += `SYNC_FRAND() * 0.5f;
			RandomDelay.Duration = OffsetVisDuration;
		}

		ShowSpawnedUnitAction = X2Action_ShowSpawnedUnit(class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		ShowSpawnedUnitAction.ChangeTimeoutLength(ShowSpawnedUnitActionTimeout + ShowSpawnedUnitAction.TimeoutSeconds);
	}

	//Add a join so that all hit reactions and other actions will complete before the visualization sequence moves on. In the case
	// of fire but no enter cover then we need to make sure to wait for the fire since it isn't a leaf node
	VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, LeafNodes);

	LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, Context, false, none, LeafNodes));
	LookAtAction.CameraTag = 'ReinforcementSpawningCamera';
	LookAtAction.bRemoveTaggedCamera = true;
}



// This function finds the direction the parcel is at by making traces into the ground
private function Vector FindParcelDirection(XComPlotCoverParcel PCP)
{
	local Vector TestLocation1, TestLocation2;
	local Vector HitLocation, HitNormal;
	local Vector Direction;
	local XComPlotCoverParcel FoundPCP;
	local int i;

	for(i = 0; i < 4; i++)
	{
		switch(i)
		{
			case 0:
				Direction = vect(1,0,0);
				break;
			case 1:
				Direction = vect(-1,0,0);
				break;
			case 2:
				Direction = vect(0,1,0);
				break;
			case 3:
				Direction = vect(0,-1,0);
				break;
		}

		TestLocation1 = Direction * 2000 + PCP.Location;
		TestLocation2 = TestLocation1;
		TestLocation1.Z += 200;
		TestLocation2.Z -= 1000;

		//`SHAPEMGR.DrawDebugLine(TestLocation1, TestLocation2, 255, 255, 0, true);

		foreach `XWORLDINFO.TraceActors(class'XComPlotCoverParcel', FoundPCP, HitLocation, HitNormal, TestLocation2, TestLocation1)
		{
			if(PCP == FoundPCP)
			{
				return Direction;
			}
		}
	}
	
	// Just cast the rotator to a direction vector since the trace failed, yet it shouldn't
	// You can't just cast it every time or the direction will be wrong with some roads (e.g city maps)
	Direction = Vector(PCP.Rotation);

	return Direction;
}

// This function makes traces along the road to make sure the location suits for the matinee
private function FindValidLocations(XComPlotCoverParcel PCP, TTile CenterTile, vector DirVector, int Width, out array<SpawnData> PotentialSpawns)
{
	local Vector CenterTileLocation, RightTileLocation;
	local Vector CenterTileDirection, RightTileDirection;
	local Vector HitNormal, HitLocation, Extents;
	local SpawnData PotentialSpawn, EmptySpawn;
	local TTile RightTile;
	local int Tries, i, j, StringIndex;
	local XComLevelActor HitActor;
	local array<XComLevelActor> PropsHit;
	local string ActorMeshName;
	local bool bHitGeometry;

	SetupTiles(CenterTile, RightTile, DirVector, Width);

	Extents = vect(10,10,10);

	while(Tries < Width)
	{
		Tries++;

		CenterTileLocation = `XWORLD.GetPositionFromTileCoordinates(CenterTile);
		RightTileLocation = `XWORLD.GetPositionFromTileCoordinates(RightTile);

		CenterTileLocation.Z += 20;
		RightTileLocation.Z += 20;

		CenterTileDirection = DirVector * 2100 + CenterTileLocation;
		RightTileDirection = DirVector * 2100 + RightTileLocation;

		/*
		`SHAPEMGR.DrawDebugSphere(CenterTileLocation, 50, 10, 255, 255, 0, true);
		`SHAPEMGR.DrawDebugSphere(RightTileLocation, 50, 10, 255, 255, 0, true);
		`SHAPEMGR.DrawDebugCylinder(CenterTileLocation, CenterTileDirection, Extents.X, 10, 255, 255, 0, true);
		`SHAPEMGR.DrawDebugCylinder(RightTileLocation, RightTileDirection, Extents.X, 10, 255, 255, 0, true);
		`SHAPEMGR.DrawDebugCylinder(CenterTileLocation, RightTileLocation, Extents.X, 10, 255, 255, 0, true);
		*/

		// continue if there is anything between the tiles (e.g a lane divider)
		if(`XTRACEMGR.XTrace(eXTrace_World, HitLocation, HitNormal, CenterTileLocation, RightTileLocation, Extents) != None)
		{
			ShiftTiles(CenterTile, RightTile, DirVector);
			continue;
		}

		PropsHit.Length = 0;
		bHitGeometry = false;

		// ignore some stupid props so every street has at least one spawn location
		foreach `XWORLDINFO.TraceActors(class'XComLevelActor', HitActor, HitLocation, HitNormal, CenterTileDirection, CenterTileLocation, Extents)
		{
			PropsHit.AddItem(HitActor);
		}

		foreach `XWORLDINFO.TraceActors(class'XComLevelActor', HitActor, HitLocation, HitNormal, RightTileDirection, RightTileLocation, Extents)
		{
			PropsHit.AddItem(HitActor);
		}

		for(i = 0; i < PropsHit.Length; i++)
		{
			HitActor = PropsHit[i];
			ActorMeshName = string(HitActor.StaticMeshComponent.StaticMesh.Name);

			for(j = 0; j < PropNames.Length; j++)
			{
				StringIndex = InStr(ActorMeshName, PropNames[j]);
				if(StringIndex >= 0)
				{
					break;
				}
			}

			if(StringIndex < 0)
			{
				bHitGeometry = true;
				break;
			}
		}

		if(!bHitGeometry)
		{
			PotentialSpawn = EmptySpawn;
			PotentialSpawn.PCP = PCP;
			PotentialSpawn.PotentialTile = CenterTile;
			PotentialSpawn.DirectionVector = DirVector;

			for(i = 0; i < PropsHit.Length; i++)
			{
				PotentialSpawn.Props.AddItem(PropsHit[i].GetActorId());
			}

			PotentialSpawns.AddItem(PotentialSpawn);

			/*
			`SHAPEMGR.DrawDebugSphere(CenterTileLocation, 75, 10, 0, 255, 0, true);
			`SHAPEMGR.DrawDebugSphere(RightTileLocation, 75, 10, 0, 255, 0, true);
			`SHAPEMGR.DrawDebugCylinder(CenterTileLocation, CenterTileDirection, Extents.X + 2, 10, 0, 255, 0, true);
			`SHAPEMGR.DrawDebugCylinder(RightTileLocation, RightTileDirection, Extents.X + 2, 10, 0, 255, 0, true);
			*/
		}

		ShiftTiles(CenterTile, RightTile, DirVector);
	}
}

// This function offsets the starting location of the tiles to the left of the road
private function SetupTiles(out TTile CenterTile, out TTile RightTile, vector DirVector, int Width)
{
	local int Offset;

	Offset = Width / 2;

	// South
	if(DirVector.Y == 1)
	{
		CenterTile.X += Offset;
		RightTile = CenterTile;
		RightTile.X -= 1;
	}
	// North
	else if(DirVector.Y == -1)
	{
		CenterTile.X -= Offset;
		RightTile = CenterTile;
		RightTile.X += 1;
	}
	// East
	else if(DirVector.X == 1)
	{
		CenterTile.Y -= Offset;
		RightTile = CenterTile;
		RightTile.Y += 1;
	}
	// West
	else if(DirVector.X == -1)
	{
		CenterTile.Y += Offset;
		RightTile = CenterTile;
		RightTile.Y -= 1;
	}
}

// This function shifts the tiles to the right of the road
private function ShiftTiles(out TTile CenterTile, out TTile RightTile, vector DirVector)
{
	// South
	if(DirVector.Y == 1)
	{
		CenterTile.X -= 1;
		RightTile.X -= 1;
	}
	// North
	else if(DirVector.Y == -1)
	{
		CenterTile.X += 1;
		RightTile.X += 1;
	}
	// East
	else if(DirVector.X == 1)
	{
		CenterTile.Y += 1;
		RightTile.Y += 1;
	}
	// West
	else if(DirVector.X == -1)
	{
		CenterTile.Y -= 1;
		RightTile.Y -= 1;
	}
}

function SetPropsHidden(bool bHidden)
{
	local ActorIdentifier PropId;
	local Actor Prop;

	foreach PropsToHide(PropId)
	{
		`XWORLDINFO.FindActorByIdentifier(PropId, Prop);

		if(bHidden)
		{
			Prop.SetHidden(true);
		}
		else
		{
			Prop.SetHidden(false);
		}
	}
}

defaultproperties
{	
	bTacticalTransient=true

	PropNames.Add("RoadBarrel");
	PropNames.Add("TarpedCrate");
	PropNames.Add("VEH_Sedan_B_A");
	PropNames.Add("Trike_A");
	PropNames.Add("Log_LoCov");
	PropNames.Add("Chain_HiFence");
	PropNames.Add("Deco_");
	PropNames.Add("Cactus");
	PropNames.Add("SmallTownPeriph");
	PropNames.Add("Tree");
}