//---------------------------------------------------------------------------------------
//  FILE:    X2Action_LTT.uc
//  AUTHOR:  Furu  --  X/XX/2025
//  PURPOSE: ADVENT Troop Transport? More like Air Troop Transport,
//           so obviously this is a Land Troop Transport
//---------------------------------------------------------------------------------------

class X2Action_LTT extends X2Action_ATT;

const LandMatineeCommentPrefix = "CIN_LTT";
const FunMatineePrefix = "CIN_FUNLTT";

function Init()
{
	local XComGameState_AIReinforcementSpawner AISpawner;
	local XComGameState_LandReinforcement LandRNFState;

	AISpawner = XComGameState_AIReinforcementSpawner(Metadata.StateObject_NewState);

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LandReinforcement', LandRNFState)
	{
		if(AISpawner.ObjectID == LandRNFState.AssociatedSpawner.ObjectID)
		{
			break;
		}
	}

	//`SHAPEMGR.DrawDebugStar(AISpawner.SpawnInfo.SpawnLocation, 20, 255, 0, 0, true);

	FindLTTMatinee();

	super(X2Action_PlayMatinee).Init();

	AddUnitsToMatinee(StateChangeContext);

	LandRNFState.SetPropsHidden(true);

	SetMatineeBase('CIN_Advent_Base');
	SetMatineeLocation(AISpawner.SpawnInfo.SpawnLocation, Rotator(LandRNFState.ParcelDirection));
}

function FindLTTMatinee()
{
	local array<SequenceObject> FoundMatinees;
	local SeqAct_Interp Matinee;
	local Sequence GameSeq;
	local string DesiredMatineePrefix;
	local int Index;

	GameSeq = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
	GameSeq.FindSeqObjectsByClass(class'SeqAct_Interp', true, FoundMatinees);
	FoundMatinees.RandomizeOrder();

	DesiredMatineePrefix = LandMatineeCommentPrefix;

	if(`SYNC_RAND(250) == 0)
	{
		DesiredMatineePrefix = FunMatineePrefix;
		`Log("Time for Fun",, 'X2_LandReinforcements');
	}

	for (Index = 0; Index < FoundMatinees.length; Index++)
	{
		Matinee = SeqAct_Interp(FoundMatinees[Index]);

		if( Instr(Matinee.ObjComment, DesiredMatineePrefix, , true) >= 0 )
		{
			Matinees.AddItem(Matinee);
			return;
		}
	}

	`Redscreen("Could not find the LTT matinee!");
	Matinee = none;
}