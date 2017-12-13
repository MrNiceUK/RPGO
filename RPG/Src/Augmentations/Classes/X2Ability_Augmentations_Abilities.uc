class X2Ability_Augmentations_Abilities extends X2Ability config (Augmentations);

var config int AUGMENTATION_BASE_MITIGATION_AMOUNT;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CyberPunch());
	Templates.AddItem(CyberPunchAnimSet());
	Templates.AddItem(AugmentationBaseStats());
	Templates.AddItem(ClawsSlash());
	

	return Templates;
}

static function X2AbilityTemplate CyberPunch()
{
	local X2AbilityTemplate					Template;
	local X2Effect_Knockback				KnockbackEffect;

	Template = class'X2Ability_RangerAbilitySet'.static.AddSwordSliceAbility('CyberPunch');

	Template.IconImage = "img:///CyberPunchIcon";
	
	Template.CustomFireAnim = 'FF_MeleeCyberPunchA';
	Template.CustomFireKillAnim = 'FF_MeleeCyberPunchA';
	Template.CustomMovingFireAnim = 'MV_MeleeCyberPunchA';
	Template.CustomMovingFireKillAnim =  'MV_MeleeCyberPunchA';
	Template.CustomMovingTurnLeftFireAnim = 'MV_RunTurn90LeftMeleeCyberPunchA';
	Template.CustomMovingTurnLeftFireKillAnim = 'MV_RunTurn90LeftMeleeCyberPunchA';
	Template.CustomMovingTurnRightFireAnim = 'MV_RunTurn90RightMeleeCyberPunchA';
	Template.CustomMovingTurnRightFireKillAnim = 'MV_RunTurn90RightMeleeCyberPunchA';

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 10;
	KnockbackEffect.bKnockbackDestroysNonFragile = true;
	KnockbackEffect.OnlyOnDeath = false;
	Template.AddTargetEffect(KnockbackEffect);
	Template.bOverrideMeleeDeath = true;
	
	Template.AdditionalAbilities.AddItem('CyberPunchAnimSet');

	return Template;
}

static function X2AbilityTemplate CyberPunchAnimSet()
{
	local X2AbilityTemplate						Template;
	local X2Effect_AdditionalAnimSets			AnimSets;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CyberPunchAnimSet');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	AnimSets = new class'X2Effect_AdditionalAnimSets';
	AnimSets.EffectName = 'CyberPunchAnimsets';
	AnimSets.AddAnimSetWithPath("AnimationsMaster_Augmentations.Anims.AS_CyberPunch");
	AnimSets.BuildPersistentEffect(1, true, false, false, eGameRule_TacticalGameStart);
	AnimSets.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(AnimSets);
	
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	Template.bSkipFireAction = true;

	return Template;
}

static function X2AbilityTemplate AugmentationBaseStats()
{
	local X2AbilityTemplate Template;
	local X2Effect_PersistentStatChange PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'AugmentationBaseStats');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.bIsPassive = true;
	Template.bCrossClassEligible = false;
	
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorMitigation, default.AUGMENTATION_BASE_MITIGATION_AMOUNT);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.bShowActivation = true;

	return Template;
}

static function X2AbilityTemplate ClawsSlash()
{
	local X2AbilityTemplate				Template;
	local X2AbilityCost_ActionPoints	ActionPointCost;
	local X2AbilityCooldown				Cooldown;
	local int i;

	Template = class'X2Ability_RangerAbilitySet'.static.AddSwordSliceAbility('ClawsSlash');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_chryssalid_slash";

	Template.bFrameEvenWhenUnitIsHidden = true;
	
	for (i = 0; i < Template.AbilityCosts.Length; ++i)
	{
		ActionPointCost = X2AbilityCost_ActionPoints(Template.AbilityCosts[i]);
		if (ActionPointCost != none)
			ActionPointCost.bConsumeAllPoints = false;
	}

	return Template;
}