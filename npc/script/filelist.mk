# Support npc engine as backend
ifeq ($(ENGINE),npc)
  SRCS-BLACKLIST-y += src/isa/$(GUEST_ISA)/inst.c
endif 
