#!/bin/bash
# Run inside the ImmortalWrt source tree, after `feeds update -a && feeds install -a`.
set -euo pipefail

# 1. 114M UBI layout (U-Boot env: mtd_layout_label=maximum-114m). Official dts is 64M.
DTS=target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1.dts
sed -i 's/reg = <0x5c0000 0x4000000>;/reg = <0x5c0000 0x7200000>;/' "$DTS"
grep -q 'reg = <0x5c0000 0x7200000>;' "$DTS"

MK=target/linux/mediatek/image/filogic.mk
sed -i '/^define Device\/cudy_tr3000-v1$/,/^endef/ s/IMAGE_SIZE := 65536k/IMAGE_SIZE := 116736k/' "$MK"
sed -n '/^define Device\/cudy_tr3000-v1$/,/^endef/p' "$MK" | grep -q 'IMAGE_SIZE := 116736k'

# 2. Third-party packages, latest upstream at build time
T=$(mktemp -d)
D=package/custom
mkdir -p "$D"
for r in linkease/istore linkease/nas-packages-luci linkease/openwrt-app-actions linkease/openwrt-app-meta \
         EasyTier/luci-app-easytier rufengsuixing/luci-app-usb3disable vernesong/OpenClash; do
  git clone -q --depth 1 "https://github.com/$r" "$T/${r#*/}"
done
cp -r "$T"/istore/luci/{luci-app-store,taskd,luci-lib-taskd,luci-lib-xterm} "$D"/
cp -r "$T"/nas-packages-luci/luci/luci-lib-iform "$D"/
cp -r "$T"/openwrt-app-actions/applications/{luci-app-systools,luci-app-rtbwmon,speedtestcli} "$D"/
mkdir -p "$D"/app-meta/applications   # app-meta Makefiles include ../../meta.mk
cp "$T"/openwrt-app-meta/meta.mk "$D"/app-meta/
cp -r "$T"/openwrt-app-meta/applications/app-meta-{diskman,rtbwmon,systools} "$D"/app-meta/applications/
cp -r "$T"/luci-app-easytier/luci-app-easytier "$D"/
cp -r "$T"/luci-app-usb3disable "$D"/ && rm -rf "$D"/luci-app-usb3disable/.git
cp -r "$T"/OpenClash/luci-app-openclash "$D"/
rm -rf package/feeds/luci/luci-app-openclash   # use vernesong upstream, not the feed copy

# 25.12 luci.mk only builds luci-i18n-*-zh-cn from po/zh_Hans; older packages still ship po/zh-cn
for p in "$D"/*/po/zh-cn; do
  [ -d "${p%zh-cn}zh_Hans" ] || mv "$p" "${p%zh-cn}zh_Hans"
done

# 3. OpenClash data that auto-updates into overlay anyway: don't ship a stale copy in rom
rm -f "$D"/luci-app-openclash/root/etc/openclash/GeoSite.dat
rm -rf "$D"/luci-app-openclash/root/usr/share/openclash/ui/zashboard

rm -rf "$T"
