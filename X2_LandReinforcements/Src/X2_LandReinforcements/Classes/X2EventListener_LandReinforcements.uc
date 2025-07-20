//---------------------------------------------------------------------------------------
//  FILE:    X2EventListener_LandReinforcements.uc
//  AUTHOR:  Furu  --  X/XX/2025
//  PURPOSE: Listens for creation of an ATT reinforcement spawner and spawning of units
//---------------------------------------------------------------------------------------

class X2EventListener_LandReinforcements extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Create_Template1());
	Templates.AddItem(Create_Template2());
	Templates.AddItem(Create_Template3());

	return Templates;
}

static function CHEventListenerTemplate Create_Template1()
{
    local CHEventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2LandReinforcements_RNFSpawnerCreated');

    Template.RegisterInTactical = true;

    Template.AddCHEvent('ReinforcementSpawnerCreated', OnReinforcementSpawnerCreated, ELD_OnStateSubmitted, 50);

    return Template;
}

static function CHEventListenerTemplate Create_Template2()
{
    local CHEventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2LandReinforcements_RNFComplete');

    Template.RegisterInTactical = true;

    Template.AddCHEvent('SpawnReinforcementsComplete', OnSpawnReinforcementsComplete, ELD_Immediate, 100);

    return Template;
}

static function CHEventListenerTemplate Create_Template3()
{
    local CHEventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2LandReinforcements_LTTComplete');

    Template.RegisterInTactical = true;

    Template.AddCHEvent('X2Action_Completed', OnActionCompleted, ELD_Immediate, 50);

    return Template;
}

static protected function EventListenerReturn OnReinforcementSpawnerCreated(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_AIReinforcementSpawner AISpawner;
	local XComGameState_LandReinforcement LandRNFState;
	local XComGameState NewGameState;
	local int Roll;

	AISpawner = XComGameState_AIReinforcementSpawner(EventData);

	if(AISpawner.SpawnVisualizationType == 'ATT')
	{
		Roll = `SYNC_RAND_STATIC(100);
		if(Roll >= (100 - class'XComGameState_LandReinforcement'.default.ChanceToModifyAirTransportToLandTransport))
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Land Reinforcements Override Spawn Location");

			AISpawner = XComGameState_AIReinforcementSpawner(NewGameState.ModifyStateObject(class'XComGameState_AIReinforcementSpawner', AISpawner.ObjectID));
			LandRNFState = XComGameState_LandReinforcement(NewGameState.CreateNewStateObject(class'XComGameState_LandReinforcement'));

			if(LandRNFState.Initialize(AISpawner))
			{
				`TACTICALRULES.SubmitGameState(NewGameState);
			}
			else
			{
				`XCOMHISTORY.CleanupPendingGameState(NewGameState);
			}
		}
	}

	return ELR_NoInterrupt;
}

// Fired immediately at SpawnReinforcementsComplete so the gamestate is pending; so I can hijack the visualization delegate
static protected function EventListenerReturn OnSpawnReinforcementsComplete(Object EventData, Object EventSource, XComGameState PendingGameState, Name EventID, Object CallbackData)
{
	local XComGameState_AIReinforcementSpawner AISpawner;
	local XComGameState_LandReinforcement LandRNFState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	AISpawner = XComGameState_AIReinforcementSpawner(EventData);

	if(AISpawner.SpawnVisualizationType == 'ATT')
	{
		foreach History.IterateByClassType(class'XComGameState_LandReinforcement', LandRNFState)
		{
			if(LandRNFState.AssociatedSpawner.ObjectID == AISpawner.ObjectID)
			{
				LandRNFState.OverrideVisualization(PendingGameState, AISpawner);
				break;
			}
		}
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn OnActionCompleted(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local X2Action_LTT LTTAction;
	local XComGameState_AIReinforcementSpawner AISpawner;
	local XComGameState_LandReinforcement LandRNFState;

	LTTAction = X2Action_LTT(EventData);

	if(LTTAction != None)
	{
		AISpawner = XComGameState_AIReinforcementSpawner(LTTAction.Metadata.StateObject_NewState);

		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LandReinforcement', LandRNFState)
		{
			if(AISpawner.ObjectID == LandRNFState.AssociatedSpawner.ObjectID)
			{
				break;
			}
		}

		LandRNFState.SetPropsHidden(false);
	}

	return ELR_NoInterrupt;
}
