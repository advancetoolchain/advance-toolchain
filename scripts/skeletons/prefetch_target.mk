# Copyright 2017 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
$(RCPTS)/fetch.rcpt: $(addsuffix .rcpt, $(addprefix fetch_, $(PKG)))
	@touch $@

$(RCPTS)/fetch_%.rcpt: $(RCPTS)/fetch_%_patches.rcpt $(RCPTS)/fetch_%_source.rcpt
	@touch $@

$(RCPTS)/fetch_%_source.rcpt: $(RCPTS)/bso_clearance.rcpt
	@echo "$$($(TIME)) Starting $* pristine source fetch for AT$(AT_CONFIGSET)...";
	@{  echo "Setting required variables"; \
	    export AT_STEPID=$(notdir $(basename $@)); \
	    export AT_BASE=$(AT_BASE); \
	    export AT_WORK_PATH=$(FETCH_SOURCES); \
	    export AT_KERNEL=$(AT_KERNEL); \
	    source $(CONFIG)/packages/$*/sources; \
	    fetch_lock=$(FETCH_SOURCES)/$${AT_STEPID}.lock; \
	    if [[ ! -r $${fetch_lock} ]]; then \
	        touch $${fetch_lock}; \
	        echo "Fetching the $* pristine sources"; \
	        { $(call fetch_sources,$*); } > \
	        $(LOGS)/_$${AT_STEPID}-fetch_sources.log 2>&1; \
	        rm $${fetch_lock}; \
	        unset fetch_lock; \
	    else \
	        while [[ -r $${fetch_lock} ]]; do \
	            sleep 1; \
	        done; \
	    fi; \
	} > $(LOGS)/_$(notdir $(basename $@)).log 2>&1
	@echo "$$($(TIME)) Completed $* pristine source fetch!";
	@touch $@

$(RCPTS)/fetch_%_patches.rcpt: $(RCPTS)/bso_clearance.rcpt
	@echo "$$($(TIME)) Starting $* patches fetch for AT$(AT_CONFIGSET)...";
	@{ echo "Setting required variables"; \
	    export AT_STEPID=$(notdir $(basename $@)); \
	    export AT_BASE=$(AT_BASE); \
	    export AT_KERNEL=$(AT_KERNEL); \
	    export AT_WORK_PATH=$(FETCH_PATCHES); \
	    export AT_TEMP_INSTALL=$(TEMP_INSTALL); \
	    source $(SCRIPTS_ROOT)/utilities/patches.sh; \
	    source $(CONFIG)/packages/$*/sources; \
	    fetch_lock=$(FETCH_PATCHES)/$${AT_STEPID}.lock; \
	    if [[ ! -r $${fetch_lock} ]]; then \
	        touch $${fetch_lock}; \
	        echo "Fetching the mailing list patches for $*."; \
	        { $(call fetch_patches_from_ml,$${ATSRC_PACKAGE_NAME},$${ATSRC_PACKAGE_MLS}); } > \
	            $(LOGS)/_$${AT_STEPID}-fetch_patches_from_ml.log 2>&1; \
	        echo "Fetching the $* add-ons"; \
	        { $(call fetch_addons,$${ATSRC_PACKAGE_NAME},$${ATSRC_PACKAGE_ALOC}); } > \
	            $(LOGS)/_$${AT_STEPID}-fetch_addons.log 2>&1; \
	        if [[ "$$(type -t atsrc_get_patches)" == "function" ]]; then \
	            echo "Fetching patches for $*."; \
	            mkdir -p $(FETCH_PATCHES)/$*; \
	            rm -f $(TEMP_INSTALL)/$*-copy-queue; \
	            pushd $(FETCH_PATCHES)/$*; \
	            atsrc_get_patches || exit 1; \
	            popd; \
	        fi; \
	        rm $${fetch_lock}; \
	        unset fetch_lock; \
	    else \
	        while [[ -r $${fetch_lock} ]]; do \
	            sleep 1; \
	        done; \
	    fi; \
	} > $(LOGS)/_$(notdir $(basename $@)).log 2>&1
	@echo "$$($(TIME)) Completed $* patches fetch!";
	@touch $@
