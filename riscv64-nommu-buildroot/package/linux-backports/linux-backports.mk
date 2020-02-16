################################################################################
#
# linux-backports
#
################################################################################

LINUX_BACKPORTS_VERSION_MAJOR = 4.4.2
LINUX_BACKPORTS_VERSION = $(LINUX_BACKPORTS_VERSION_MAJOR)-1
LINUX_BACKPORTS_SOURCE = backports-$(LINUX_BACKPORTS_VERSION).tar.xz
LINUX_BACKPORTS_SITE = $(BR2_KERNEL_MIRROR)/linux/kernel/projects/backports/stable/v$(LINUX_BACKPORTS_VERSION_MAJOR)
LINUX_BACKPORTS_LICENSE = GPL-2.0
LINUX_BACKPORTS_LICENSE_FILES = COPYING

ifeq ($(BR2_PACKAGE_LINUX_BACKPORTS_USE_DEFCONFIG),y)
LINUX_BACKPORTS_KCONFIG_FILE = $(LINUX_BACKPORTS_DIR)/defconfigs/$(call qstrip,$(BR2_PACKAGE_LINUX_BACKPORTS_DEFCONFIG))
else ifeq ($(BR2_PACKAGE_LINUX_BACKPORTS_USE_CUSTOM_CONFIG),y)
LINUX_BACKPORTS_KCONFIG_FILE = $(call qstrip,$(BR2_PACKAGE_LINUX_BACKPORTS_CUSTOM_CONFIG_FILE))
endif

LINUX_BACKPORTS_KCONFIG_FRAGMENT_FILES = $(call qstrip,$(BR2_PACKAGE_LINUX_BACKPORTS_CONFIG_FRAGMENT_FILES))
LINUX_BACKPORTS_KCONFIG_OPTS = $(LINUX_BACKPORTS_MAKE_OPTS)

# linux-backports' build system expects the config options to be present
# in the environment, and it is so when using their custom buildsystem,
# because they are set in the main Makefile, which then calls a second
# Makefile.
#
# In our case, we do not use that first Makefile. So, we parse the
# .config file, filter-out comment lines and put the rest as command
# line variables.
#
# LINUX_BACKPORTS_MAKE_OPTS is used by the kconfig-package infra, while
# LINUX_BACKPORTS_MODULE_MAKE_OPTS is used by the kernel-module infra.
#
LINUX_BACKPORTS_MAKE_OPTS = \
	BACKPORT_DIR=$(@D) \
	KLIB_BUILD=$(LINUX_DIR) \
	KLIB=$(TARGET_DIR)/lib/modules/$(LINUX_VERSION_PROBED) \
	INSTALL_MOD_DIR=backports \
	`sed -r -e '/^\#/d;' $(@D)/.config`

LINUX_BACKPORTS_MODULE_MAKE_OPTS = $(LINUX_BACKPORTS_MAKE_OPTS)

# This file is not automatically generated by 'oldconfig' that we use in
# the kconfig-package infrastructure. In the linux buildsystem, it is
# generated by running silentoldconfig, but that's not the case for
# linux-backports: it uses a hand-crafted rule to generate that file.
define LINUX_BACKPORTS_KCONFIG_FIXUP_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) $(LINUX_BACKPORTS_MAKE_OPTS) backport-include/backport/autoconf.h
endef

# Checks to give errors that the user can understand
ifeq ($(BR_BUILDING),y)

ifeq ($(BR2_PACKAGE_LINUX_BACKPORTS_USE_DEFCONFIG),y)
ifeq ($(call qstrip,$(BR2_PACKAGE_LINUX_BACKPORTS_DEFCONFIG)),)
$(error No linux-backports defconfig name specified, check your BR2_PACKAGE_LINUX_BACKPORTS_DEFCONFIG setting)
endif
endif

ifeq ($(BR2_PACKAGE_LINUX_BACKPORTS_USE_CUSTOM_CONFIG),y)
ifeq ($(call qstrip,$(BR2_PACKAGE_LINUX_BACKPORTS_CUSTOM_CONFIG_FILE)),)
$(error No linux-backports configuration file specified, check your BR2_PACKAGE_LINUX_BACKPORTS_CUSTOM_CONFIG_FILE setting)
endif
endif

endif # BR_BUILDING

$(eval $(kernel-module))
$(eval $(kconfig-package))

# linux-backports' own .config file needs options from the kernel's own
# .config file. The dependencies handling in the infrastructure does not
# allow to express this kind of dependencies. Besides, linux.mk might
# not have been parsed yet, so the Linux build dir LINUX_DIR is not yet
# known. Thus, we use a "secondary expansion" so the rule is re-evaluated
# after all Makefiles are parsed, and thus at that time we will have the
# LINUX_DIR variable set to the proper value.
#
# Furthermore, we want to check the kernel version, since linux-backports
# only supports kernels >= 3.0. To avoid overriding linux-backports'
# .config rule defined in the kconfig-package infra, we use an
# intermediate stamp-file.
#
# Finally, it must also come after the call to kconfig-package, so we get
# LINUX_BACKPORTS_DIR properly defined (because the target part of the
# rule is not re-evaluated).
#
$(LINUX_BACKPORTS_DIR)/.config: $(LINUX_BACKPORTS_DIR)/.stamp_check_kernel_version

.SECONDEXPANSION:
$(LINUX_BACKPORTS_DIR)/.stamp_check_kernel_version: $$(LINUX_DIR)/.config
	$(Q)LINUX_VERSION_PROBED=$(LINUX_VERSION_PROBED); \
	if [ $${LINUX_VERSION_PROBED%%.*} -lt 3 ]; then \
		printf "Linux version '%s' is too old for linux-backports (needs 3.0 or later)\n" \
			"$${LINUX_VERSION_PROBED}"; \
		exit 1; \
	fi
	$(Q)touch $(@)