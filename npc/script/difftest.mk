# 自动运行动态库编译
ifdef CONFIG_DIFFTEST_REF_NEMU
$(DIFF_REF_SO):
	$(MAKE) -s -C $(NPC_HOME) shared
endif