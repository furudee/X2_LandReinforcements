//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_IsUnitInMatinee.uc
//  AUTHOR:  Furu  --  X/XX/2025
//  PURPOSE: Finds out if a cinematic pawn has been created and assigned to matinee
//---------------------------------------------------------------------------------------

class SeqAct_IsUnitInMatinee extends SequenceAction;

var() String MatineeUnit;
var() String MatineeName;

event Activated()
{
	local XComGameStateVisualizationMgr VisualizationMgr;
	local X2Action VisualizationTree;
	local X2Action_PlayMatinee MatineeAction;
	local SeqAct_Interp Matinee;
	local array<X2Action> Nodes;
	local UnitToMatineeGroupMapping UnitMapping;
	local int i, j;

	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	VisualizationTree = VisualizationMgr.VisualizationTree;

	VisualizationMgr.GetNodesOfType(VisualizationTree, class'X2Action_PlayMatinee', Nodes);

	OutputLinks[0].bHasImpulse = false;
	OutputLinks[1].bHasImpulse = true;

	for(i = 0; i < Nodes.Length; i++)
	{
		MatineeAction = X2Action_PlayMatinee(Nodes[i]);
		
		foreach MatineeAction.Matinees(Matinee)
		{
			if(Matinee.ObjComment == MatineeName)
			{
				for(j = 0; j < MatineeAction.UnitMappings.Length; j++)
				{
					UnitMapping = MatineeAction.UnitMappings[j];

					if(UnitMapping.GroupName == name(MatineeUnit) && UnitMapping.Unit != None)
					{
						OutputLinks[0].bHasImpulse = true;
						OutputLinks[1].bHasImpulse = false;
						break;
					}
				}
			}
		}
	}
}

defaultproperties
{
	ObjName="Is Unit In Matinee"
	ObjCategory="Furu"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	bAutoActivateOutputLinks=false

	OutputLinks(0)=(LinkDesc="Yes")
	OutputLinks(1)=(LinkDesc="No")
}