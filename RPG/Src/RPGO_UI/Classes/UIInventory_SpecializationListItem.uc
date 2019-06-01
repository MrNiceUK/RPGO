class UIInventory_SpecializationListItem extends UIInventory_CommodityListItem;

var int InitPosX;
var int InitPosY;
var int IconSize;
var UIAbilityIconRow AbilityIconRow;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	local UIPanel Panel;
	
	Panel = super.InitPanel(InitName, InitLibID);

	RealizeSpecializationsIcons();

	return Panel;
}

simulated function RealizeSpecializationsIcons()
{
	local array<X2AbilityTemplate> Templates;
	local UIPanel Dummy;
	Templates = GetSpecializationAbilities();

	ConfirmButton.SetY(InitPosY);
	// We need a non-navigable "fire wall" between the list item and the icon row...
	Dummy = Spawn(class'UIPanel', self);
	Dummy.bIsNavigable = false;
	Dummy.bAnimateOnInit = false;
	Dummy.InitPanel();
	AbilityIconRow = Spawn(class'UIAbilityIconRow', Dummy);
	AbilityIconRow.InitAbilityIconRowPanel('SpecIconRow',, IconSize, Templates);
	AbilityIconRow.SetPosition(InitPosX, InitPosY);
}

simulated function array<X2AbilityTemplate> GetSpecializationAbilities()
{
	local UIChooseSpecializations ParentScreen;
	local SoldierSpecialization Spec;
	local array<X2AbilityTemplate> EmptyList;

	List = UIList(GetParent(class'UIList'));
	ParentScreen = UIChooseSpecializations(self.List.ParentPanel);

	if (List != none && ParentScreen != none)
	{
		Spec = ParentScreen.SpecializationsPool[ParentScreen.GetItemIndex(ItemComodity)];

		return class'X2SoldierClassTemplatePlugin'.static.GetAbilityTemplatesForSpecializations(Spec);
	}

	EmptyList.Length = 0;
	return EmptyList;
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	AbilityIconRow.OnLoseFocus();
	AbilityIconRow.Navigator.SelectedIndex = INDEX_NONE;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	`log("we got called?");
	return AbilityIconRow.Navigator.OnUnrealCommand(cmd, arg) || Super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	InitPosX = 0
	InitPosY = 146
	IconSize = 38
	Height = 196
}
