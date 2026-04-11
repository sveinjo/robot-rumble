@tool
extends EditorPlugin

## 在调试器的「错误」面板中注入一个「复制全部」按钮，
## 点击后将所有错误/警告信息格式化并复制到系统剪贴板。

var _copy_button: Button = null
var _error_tree: Tree = null
var _hbox: HBoxContainer = null
var _setup_timer: Timer = null
var _retry_count := 0
const _MAX_RETRIES := 20


func _enter_tree() -> void:
	# 编辑器 UI 可能还没完全就绪，用 Timer 延迟查找
	_setup_timer = Timer.new()
	_setup_timer.wait_time = 0.5
	_setup_timer.one_shot = true
	_setup_timer.timeout.connect(_try_setup)
	add_child(_setup_timer)
	_setup_timer.start()


func _exit_tree() -> void:
	if is_instance_valid(_copy_button):
		_copy_button.queue_free()
	_copy_button = null
	_error_tree = null
	_hbox = null
	_cleanup_timer()


# ────────────────── 初始化 ──────────────────


func _try_setup() -> void:
	var base := EditorInterface.get_base_control()
	if not base:
		_schedule_retry()
		return

	var result := _find_error_panel(base)
	if result.is_empty():
		_schedule_retry()
		return

	_error_tree = result["tree"]
	_hbox = result["hbox"]
	_inject_copy_button()
	_cleanup_timer()


func _schedule_retry() -> void:
	_retry_count += 1
	if _retry_count < _MAX_RETRIES and is_instance_valid(_setup_timer):
		_setup_timer.start()
	else:
		push_warning("[CopyAllErrors] 未找到调试器错误面板，插件初始化失败。")
		_cleanup_timer()


func _cleanup_timer() -> void:
	if is_instance_valid(_setup_timer):
		_setup_timer.queue_free()
		_setup_timer = null


# ────────────────── 查找错误面板 ──────────────────


func _find_error_panel(node: Node) -> Dictionary:
	# 目标结构（Godot 源码 script_editor_debugger.cpp）：
	# VBoxContainer ("Errors" / "错误")
	#   ├─ HBoxContainer
	#   │    ├─ Button ("Expand All" / "全部展开")
	#   │    ├─ Button ("Collapse All" / "全部折叠")
	#   │    ├─ Control (spacer)
	#   │    └─ Button ("Clear" / "清除")
	#   └─ Tree (error_tree, columns=2)
	if node is VBoxContainer:
		var tree: Tree = null
		var hbox: HBoxContainer = null
		var has_expand_btn := false

		for child in node.get_children():
			if child is HBoxContainer and not has_expand_btn:
				for btn in child.get_children():
					if btn is Button and btn.text in ["Expand All", "全部展开"]:
						has_expand_btn = true
						hbox = child
						break
			elif child is Tree and tree == null:
				tree = child

		if has_expand_btn and tree != null and hbox != null:
			return {"tree": tree, "hbox": hbox}

	for child in node.get_children():
		var result := _find_error_panel(child)
		if not result.is_empty():
			return result
	return {}


# ────────────────── 注入按钮 ──────────────────


func _inject_copy_button() -> void:
	_copy_button = Button.new()
	_copy_button.text = "复制全部"
	_copy_button.tooltip_text = "复制所有错误/警告信息到剪贴板"
	_copy_button.pressed.connect(_on_copy_all_pressed)

	# 尝试加上复制图标，好看一点
	var theme := EditorInterface.get_editor_theme()
	if theme:
		for icon_name in ["ActionCopy", "CopyNodePath", "Duplicate"]:
			if theme.has_icon(icon_name, "EditorIcons"):
				_copy_button.icon = theme.get_icon(icon_name, "EditorIcons")
				break

	# 插入到「全部折叠」按钮后面
	var insert_idx := _hbox.get_child_count()
	for i in _hbox.get_child_count():
		var child := _hbox.get_child(i)
		if child is Button and child.text in ["Collapse All", "全部折叠"]:
			insert_idx = i + 1
			break

	_hbox.add_child(_copy_button)
	if insert_idx < _hbox.get_child_count():
		_hbox.move_child(_copy_button, insert_idx)

	print("[CopyAllErrors] 插件已就绪，「复制全部」按钮已注入错误面板。")


# ────────────────── 复制逻辑 ──────────────────


func _on_copy_all_pressed() -> void:
	if not is_instance_valid(_error_tree):
		push_warning("[CopyAllErrors] 错误列表控件无效。")
		return

	var root := _error_tree.get_root()
	if not root or not root.get_first_child():
		_flash_button("没有内容")
		return

	var entries: PackedStringArray = []
	var count := 0
	var item := root.get_first_child()

	while item:
		entries.append(_format_error_item(item))
		count += 1
		item = item.get_next()

	var output := "\n\n".join(entries).strip_edges()
	DisplayServer.clipboard_set(output)
	print("[CopyAllErrors] 已复制 %d 条消息到剪贴板。" % count)
	_flash_button("已复制 %d 条!" % count)


func _flash_button(msg: String) -> void:
	if not is_instance_valid(_copy_button):
		return
	var original_text := _copy_button.text
	_copy_button.text = msg
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(_copy_button):
			_copy_button.text = original_text
	)


# ────────────────── 格式化 ──────────────────


func _format_error_item(item: TreeItem) -> String:
	var parts: PackedStringArray = []

	# 判断消息类型 (W = 警告, E = 错误)
	var type_char := _get_type_char(item)

	# 主行: "W 0:00:01:633   GDScript::reload: ..."
	var time_str: String = item.get_text(0).strip_edges()
	var msg_str: String = item.get_text(1).strip_edges()
	parts.append("%s %s   %s" % [type_char, time_str, msg_str])

	# 子行: "  <GDScript 错误> UNUSED_VARIABLE" 等
	var child := item.get_first_child()
	while child:
		var c0: String = child.get_text(0).strip_edges()
		var c1: String = child.get_text(1).strip_edges()
		if c0 or c1:
			var line := "  "
			if c0 and c1:
				line += c0 + " " + c1
			elif c0:
				line += c0
			else:
				line += c1
			parts.append(line)
		child = child.get_next()

	return "\n".join(parts)


func _get_type_char(item: TreeItem) -> String:
	# 优先从 TreeItem 的 metadata 判断（Godot 内部存储了 "warning" / "error" / "cycled_error"）
	var meta = item.get_metadata(0)
	if meta is String:
		if meta == "warning":
			return "W"
		if meta in ["error", "cycled_error"]:
			return "E"

	# metadata 不可用时，从子项文本推断
	var child := item.get_first_child()
	while child:
		var combined := (child.get_text(0) + " " + child.get_text(1)).to_upper()
		if "WARNING" in combined or "WARN" in combined:
			return "W"
		child = child.get_next()

	# 保守默认 → 警告
	return "W"
