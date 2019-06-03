class UIAbilityIconRow extends UIPanel;

var int EDGE_PADDING;
var int InitPosX;
var int InitPosY;
var int IconSize; 
var float ToolTipX, ToolTipY;
var bool BlackBracket;
var int TooltipAnchor, ControllerTooltipAnchor;
var array<UIIcon> AbilityIcons;
var UITextTooltip ActiveTooltip;

simulated function UIPanel InitAbilityIconRowPanel(
	optional name InitName,
	optional name InitLibID,
	optional int InIconSize = -1,
	optional array<X2AbilityTemplate> Templates
	)
{
	super.InitPanel(InitName, InitLibID);
	Navigator.HorizontalNavigation = true;
	Navigator.LoopSelection = true;
	if (`ISCONTROLLERACTIVE)
	{
		Navigator.OnSelectedIndexChanged = OnSelectionChanged;
	}
	SetSelectedNavigation();
	if (InIconSize >= 0)
	{
		IconSize = InIconSize;
	}

	if (Templates.Length > 0)
	{
		SetWidth((IconSize + EDGE_PADDING) * Templates.Length);
		SetHeight(IconSize + EDGE_PADDING);

		PopulateIcons(Templates, InIconSize);
	}

	return self;
}

simulated function PopulateIcons(
	array<X2AbilityTemplate> Templates,
	optional int InIconSize = -1
)
{
	local X2AbilityTemplate Template;
	local int Index, IconStartX, IconStartY;
	local UIIcon PerkIcon;

	IconStartX = InitPosX;
	IconStartY = InitPosY + EDGE_PADDING - IconSize;

	for (Index = AbilityIcons.Length - 1; Index >= 0; Index--)
	{
		AbilityIcons[Index].Remove();
		AbilityIcons.Remove(Index, 1);
	}

	Index = 0;
	foreach Templates(Template)
	{
		PerkIcon = Spawn(class'UIIcon', self);
		PerkIcon.bShouldPlayGenericUIAudioEvents = false;
		PerkIcon.bAnimateOnInit = false;
		PerkIcon.bDisableSelectionBrackets = !`ISCONTROLLERACTIVE;
		PerkIcon.InitIcon('', Template.IconImage, true, true, IconSize);
		PerkIcon.SetPosition(
			PosOffsetX(Index, IconStartX, IconSize, EDGE_PADDING),
			PosOffsetY(Index, IconStartY, IconSize, EDGE_PADDING)
		);
		if(`ISCONTROLLERACTIVE)
		{
			PerkIcon.SetTooltipText(
				Template.GetMyLongDescription(),
				Template.LocFriendlyName
				, 0, 0,, ControllerTooltipAnchor, false, 0
			);
		}
		else
		{
			PerkIcon.SetTooltipText(
				Template.GetMyLongDescription(),
				Template.LocFriendlyName
				, 25, 20,, TooltipAnchor, true, 0.1
			);
		}
		
		if(BlackBracket)
		{
			PerkIcon.SetBGColor(class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR);
			PerkIcon.SetForegroundColor(class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
		}

		AbilityIcons.AddItem(PerkIcon);
		
		Index++;
	}
}

simulated function AnimateIn(optional float Delay = 0)
{
	local UIIcon Icon;
	
	foreach AbilityIcons(Icon)
	{
		Icon.AnimateIn(Delay + class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX);
		Delay += class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX;
	}
}


simulated function int PosOffsetX(int Index, int IconStartX, int IconWidhtHeight, int Spacing)
{
	return Index * (IconWidhtHeight + Spacing) + IconStartX;
}

simulated function int PosOffsetY(int Index, int IconStartY, int IconWidhtHeight, int Spacing)
{
	return IconStartY + Spacing; // + Index * (IconWidhtHeight + Spacing);
}

simulated function OnSelectionChanged(int ItemIndex)
{
	local UIPanel Item;

	if (ActiveTooltip != none)
	{
		Movie.Pres.m_kTooltipMgr.DeactivateTooltip(ActiveTooltip, true);
		ActiveTooltip = none;
	}

	Item = Navigator.GetSelected();
	if (Item != none)
	{
		if (Item.bHasTooltip)
		{
			ActiveTooltip = UITextTooltip(Movie.Pres.m_kTooltipMgr.GetTooltipByID(Item.CachedTooltipId));
			if (ActiveTooltip != none)
			{
				ActiveTooltip.SetTooltipPosition(TooltipX, ToolTipY);
				ActiveTooltip.ShowTooltip();
				Movie.Pres.m_kTooltipMgr.ActivateTooltip(ActiveTooltip);
			}
		}
	}
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	Navigator.SelectedIndex = INDEX_NONE;
	OnSelectionChanged(INDEX_NONE);
}

defaultproperties
{
	//bIsNavigable = false
	bShouldPlayGenericUIAudioEvents = false;
	bAnimateOnInit = true
	BlackBracket = true
	TooltipAnchor = 1; // class'UIUtilities'.const.ANCHOR_TOP_LEFT; 
	ControllerTooltipAnchor = 2; // class'UIUtilities'.const.ANCHOR_TOP_CENTER; 
	ToolTipX = 960;
	bCascadeFocus = false
	bCascadeSelection = true
	EDGE_PADDING = 15
	InitPosX = 12
	InitPosY = 0
	IconSize = 32
	Width = 300
	Height = 50
}