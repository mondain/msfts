LIBDIR := lib
include $(LIBDIR)/main.mk

.PHONY: check-submission
check-submission:
	$(MAKE) latest lint
	$(MAKE) idnits idnits_mode=forgive-checklist

.PHONY: submission-checklist
submission-checklist:
	@echo "1) make latest"
	@echo "2) make lint"
	@echo "3) make idnits idnits_mode=forgive-checklist"
	@echo "4) Review residual warnings:"
	@echo "   - POSSIBLE_DOWNREF for active Internet-Drafts when fetch/status lookup fails"
	@echo "   - LINE_PI when produced by markdown -> XML tooling"
	@echo "5) Submit updated draft via Datatracker"

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update $(CLONE_ARGS) --init
else
	git clone -q --depth 10 $(CLONE_ARGS) \
	    -b main https://github.com/martinthomson/i-d-template $(LIBDIR)
endif
