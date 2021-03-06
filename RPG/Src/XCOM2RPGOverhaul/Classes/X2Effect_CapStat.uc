class X2Effect_CapStat extends X2Effect_PersistentStatChange;

struct StatCap
{
	var ECharStatType	StatType;
	var float			StatCapValue;
};
 
var array<StatCap>  m_aStatCaps;
var array<X2Condition> Conditions;
 
function AddStatCap(ECharStatType StatType, float StatCapValue)
{
	local StatCap Cap;
	
	Cap.StatType = StatType;
	Cap.StatCapValue = StatCapValue;
	m_aStatCaps.AddItem(Cap);
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local XComGameState_Unit UnitState;
	local X2EventManager EventMgr;
	local Object ListenerObj;

	EventMgr = `XEVENTMGR;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	ListenerObj = EffectGameState;

	// Register to tick after EVERY action.
	EventMgr.RegisterForEvent(ListenerObj, 'OnUnitBeginPlay', EventHandler, ELD_OnStateSubmitted, 25, UnitState,, EffectGameState);	
	EventMgr.RegisterForEvent(ListenerObj, 'AbilityActivated', EventHandler, ELD_OnStateSubmitted, 25,,, EffectGameState);	
}

static function EventListenerReturn EventHandler(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit UnitState, SourceUnitState, NewUnitState;
	local XComGameState_Effect NewEffectState;
	local XComGameState_Ability AbilityState;
	local XComGameState NewGameState;
	local X2Effect_CapStat EffectTemplate;
	local XComGameState_Effect EffectState;
	local bool bOldApplicable, bNewApplicable;
	local array<StatChange> LocalStatChanges;
	local StatChange LocalStatChange;
	local StatCap LocalStatCap;
	local int AppliedStatChangeIndex, StatChangeOther;
	local float AppliedStatChange, CappedStat, NewStatAmount;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	SourceUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

	EffectTemplate = X2Effect_CapStat(EffectState.GetX2Effect());

	bOldApplicable = EffectState.StatChanges.Length > 0;
	bNewApplicable = class'XMBEffectUtilities'.static.CheckTargetConditions(EffectTemplate.Conditions, EffectState, SourceUnitState, UnitState, AbilityState) == 'AA_Success';

	if (bOldApplicable != bNewApplicable)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Conditional Stat Change");

		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		NewEffectState = XComGameState_Effect(NewGameState.ModifyStateObject(class'XComGameState_Effect', EffectState.ObjectID));

		foreach EffectTemplate.m_aStatCaps(LocalStatCap)
		{
			AppliedStatChangeIndex = NewEffectState.StatChanges.Find('StatType', LocalStatCap.StatType);
			AppliedStatChange = (AppliedStatChangeIndex != INDEX_NONE) ?
				NewEffectState.StatChanges[AppliedStatChangeIndex].StatAmount :
				0.0;
			StatChangeOther = NewUnitState.GetCurrentStat(LocalStatCap.StatType) - AppliedStatChange;
			CappedStat = Min(StatChangeOther, LocalStatCap.StatCapValue);

			NewStatAmount = CappedStat - StatChangeOther;
			if (NewStatAmount != 0.0)
			{
				LocalStatChange.StatType = LocalStatCap.StatType;
				LocalStatChange.StatAmount = NewStatAmount;
				LocalStatChange.ModOp = MODOP_Addition;
				LocalStatChanges.AddItem(LocalStatChange);
			}
		}

		if (bNewApplicable)
		{
			NewEffectState.StatChanges = LocalStatChanges;

			// Note: ApplyEffectToStats crashes the game if the state objects aren't added to the game state yet
			NewUnitState.ApplyEffectToStats(NewEffectState, NewGameState);
		}
		else
		{
			NewUnitState.UnApplyEffectFromStats(NewEffectState, NewGameState);
			NewEffectState.StatChanges.Length = 0;
		}

		`GAMERULES.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}


// From X2Effect_Persistent.
function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit)
{
	return EffectGameState.StatChanges.Length > 0;
}


simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	super(X2Effect_Persistent).OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

// From XMBEffectInterface
function bool GetExtModifiers(name Type, XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, optional ShotBreakdown ShotBreakdown, optional out array<ShotModifierInfo> ShotModifiers) { return false; }
function bool GetExtValue(LWTuple Tuple) { return false; }

function bool GetTagValue(name Tag, XComGameState_Ability AbilityState, X2Effect EffectTemplate, out string TagValue)
{
	local int stat, idx;

	Tag = Name(Repl(Tag, X2Effect_Persistent(EffectTemplate).EffectName $ ";", "", true));
	
	stat = class'XMBConfig'.default.m_aCharStatTags.Find(Tag);
	if (stat != INDEX_NONE)
	{
		idx = m_aStatCaps.Find('StatType', ECharStatType(stat));
		if (idx != INDEX_NONE)
		{
			TagValue = string(int(m_aStatCaps[idx].StatCapValue));
			return true;
		}
	}

	return false;
}
