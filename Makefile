.PHONY: run editor build clean

run: ## ゲームを起動
	godot --path .

editor: ## エディタを開く
	godot --path . -e

build: ## シーンをリビルド
	godot --headless --script scenes/build_main.gd
	godot --headless --script scenes/build_hud.gd
	godot --headless --script scenes/build_upgrade_shop.gd
	godot --headless --script scenes/build_fireball.gd
	godot --headless --script scenes/build_player.gd
	godot --headless --script scenes/build_enemy.gd
	godot --headless --script scenes/build_boss.gd

clean: ## セーブデータを削除
	rm -f "$$(godot --headless --script /dev/null --path . 2>&1 | grep -o 'user://.*' || echo '')"
	@echo "user://save_data.json を手動で削除してください"
	@echo "  macOS: ~/Library/Application Support/Godot/app_userdata/Dungeon Blade/save_data.json"

help: ## コマンド一覧
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-10s %s\n", $$1, $$2}'
