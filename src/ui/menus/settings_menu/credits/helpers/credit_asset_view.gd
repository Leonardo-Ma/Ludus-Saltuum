## Displays third-party attribution and external origin and license links
class_name CreditAssetView
extends HBoxContainer

@onready var icon: TextureRect = %Icon
@onready var asset_label_button: CreditLinkButton = %AssetLabelButton
@onready var creator_label_button: CreditLinkButton = %CreatorLabelButton
@onready var description_label: Label = %DescriptionLabel
@onready var license_button: CreditLinkButton = %LicenseLabelButton


func setup(asset: CreditAsset) -> void:
	icon.texture = asset.icon
	icon.visible = asset.icon != null

	asset_label_button.text = asset.display_name
	creator_label_button.text = asset.creator_name
	description_label.text = asset.description
	license_button.text = asset.license_name

	asset_label_button.url = asset.origin_url
	creator_label_button.url = asset.creator_url
	license_button.url = asset.license_url
