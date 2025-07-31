//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_ToggleMusic.uc
//  AUTHOR:  Furu  --  X/XX/2025
//  PURPOSE: Toggles music on or off in Kismet
//---------------------------------------------------------------------------------------

class SeqAct_ToggleMusic extends SequenceAction;

event Activated()
{
	local XComOnlineProfileSettings ProfileSettings;

	ProfileSettings = `XPROFILESETTINGS;

	if(InputLinks[0].bHasImpulse)
	{
		`LOCALPLAYERCONTROLLER.SetAudioGroupVolume('Music', 0.0f);
	}
	else if(InputLinks[1].bHasImpulse)
	{
		`LOCALPLAYERCONTROLLER.SetAudioGroupVolume('Music', ProfileSettings.Data.m_iMusicVolume);
	}
}

defaultproperties
{
	ObjCategory="Furu"
	ObjName="Toggle Music"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="Mute")
	InputLinks(1)=(LinkDesc="UnMute")
}