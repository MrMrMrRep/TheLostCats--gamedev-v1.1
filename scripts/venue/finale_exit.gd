@tool
class_name FinaleExit
extends Door
## The way out after the finale: only with Geoff awake and standing with the
## others (the whole band goes together).

@export var sleeper: NodePath


func interact(member: BandMember, level: Node) -> void:
	var s := get_node_or_null(sleeper) as SleepingMember
	if s and s.is_asleep():
		say("We're not leaving without Geoff!")
		return
	var group: Array = level.door_group(member)
	if group.size() < level.band.members.size():
		say("Everyone together first")
		return
	super(member, level)
