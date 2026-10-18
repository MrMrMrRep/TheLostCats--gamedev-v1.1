class_name Inventory
extends Node
## A band member's 3 item slots plus the selected slot. Actions on "the current
## item" use the selected slot, or the first filled one when it's empty.

signal changed

const SIZE := 3

var slots: Array[ItemData] = [null, null, null]
var selected := 0


func add(item: ItemData) -> bool:
	for i in SIZE:
		if slots[i] == null:
			slots[i] = item
			changed.emit()
			return true
	return false


func is_full() -> bool:
	return not slots.has(null)


func has(id: StringName) -> bool:
	return index_of(id) >= 0


func count(id: StringName) -> int:
	return slots.filter(func(it: ItemData) -> bool: return it != null and it.id == id).size()


func index_of(id: StringName) -> int:
	for i in SIZE:
		if slots[i] and slots[i].id == id:
			return i
	return -1


func remove_at(i: int) -> ItemData:
	var item := slots[i]
	slots[i] = null
	if item:
		changed.emit()
	return item


func take(id: StringName) -> ItemData:
	var i := index_of(id)
	return remove_at(i) if i >= 0 else null


func items() -> Array[ItemData]:
	var out: Array[ItemData] = []
	for it in slots:
		if it:
			out.append(it)
	return out


## The slot actions apply to: the selected one, or the first filled one.
func current_index() -> int:
	if slots[selected]:
		return selected
	for i in SIZE:
		if slots[i]:
			return i
	return -1


func select_next() -> void:
	selected = (selected + 1) % SIZE
	changed.emit()


func clear() -> void:
	slots = [null, null, null]
	selected = 0
	changed.emit()
