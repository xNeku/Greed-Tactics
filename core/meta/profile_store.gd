class_name ProfileStore
extends RefCounted
## Saves and loads the PlayerProfile as JSON (user://profile.json). A missing
## or broken file gives a fresh profile, never an error for the player.

const DEFAULT_PATH := "user://profile.json"


static func load_profile(path: String = DEFAULT_PATH) -> PlayerProfile:
	if not FileAccess.file_exists(path):
		return PlayerProfile.new()
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if data is Dictionary:
		return PlayerProfile.from_dict(data)
	push_warning("Profile at %s is unreadable; starting a new one." % path)
	return PlayerProfile.new()


static func save_profile(profile: PlayerProfile, path: String = DEFAULT_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save the profile to %s." % path)
		return false
	file.store_string(JSON.stringify(profile.to_dict(), "\t"))
	return true
