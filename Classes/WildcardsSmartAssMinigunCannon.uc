//=============================================================================
// WildcardsSmartAssMinigunCannon.
//=============================================================================
class WildcardsSmartAssMinigunCannon expands MinigunCannon;

var() string SmartAssKillMessage[14];

function string KillMessage( name damageType, pawn Other )
{
	PostKillMessage = SmartAssKillMessage[Rand(14)];
	return (PreKillMessage@Other.PlayerReplicationInfo.PlayerName@PostKillMessage);
}

defaultproperties
{
     SmartAssKillMessage(0)="was instructed to piss off by the minigun turret."
     SmartAssKillMessage(1)="has failed to understand the concept of get the fuck out of my base!"
     SmartAssKillMessage(2)="was testing the minigun turret's patience for stupid people"
     SmartAssKillMessage(3)="has proven themself a complete failure in the presence of the minigun turret"
     SmartAssKillMessage(4)="looked a little confused when the minigun OWNED their sorry ass"
     SmartAssKillMessage(5)="failed to learn that running towards a shooting minigun turret was a bad idea"
     SmartAssKillMessage(6)="has failed to realize bullets hurt."
     SmartAssKillMessage(7)="needed to take aditional lessons on how to PISS OFF"
     SmartAssKillMessage(8)="won a free trip back to their base after encountering the mingun turret."
     SmartAssKillMessage(9)="was defeated by an object dumber than a bot!"
     bEdShouldSnap=True
}
