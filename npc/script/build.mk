# 自动运行动态库编译
ifeq ($(CONFIG_ENGINE), "npc")
run: engine_npc
engine_npc:
	$(MAKE) -s -C $(NPC_HOME) shared
endif