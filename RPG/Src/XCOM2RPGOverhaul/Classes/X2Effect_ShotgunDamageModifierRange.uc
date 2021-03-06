class X2Effect_ShotgunDamageModifierRange extends X2Effect_Persistent config (RPG);

var config array<int> SHOTGUN_DAMAGE_FALLOFF;
var config array<name> AbilityIgnoreDamageFalloff;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit TargetUnit;
	local XComGameState_Item WeaponState;
	local int Tiles, RangeDamageModifier;
	local name Ability;

	History = `XCOMHISTORY;

	if (!class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult))
		return 0;

	foreach default.AbilityIgnoreDamageFalloff (Ability)
	{
		if (Attacker.HasSoldierAbility(Ability))
		{
			return 0;
		}
	}

	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(AppliedData.AbilityInputContext.PrimaryTarget.ObjectID));
	WeaponState = XComGameState_Item(History.GetGameStateForObjectID(AppliedData.ItemStateObjectRef.ObjectID));

	if (TargetUnit != none && WeaponState != none)
	{
		if (X2WeaponTemplate(WeaponState.GetMyTemplate()).WeaponCat != 'shotgun')
			return 0;

		Tiles = Attacker.TileDistanceBetween(TargetUnit);
		RangeDamageModifier = default.SHOTGUN_DAMAGE_FALLOFF[Tiles] * -1;

		//`LOG(Class.Name @ GetFuncName() @ "Range Damage Modifier:" @ RangeDamageModifier,, 'RPG');

		if (CurrentDamage + RangeDamageModifier > 0)
		{
			return RangeDamageModifier; 
		}
		else
		{
			// minimum damage is 1
			return (CurrentDamage * -1) + 1;
		}
	}

	return 0;
}