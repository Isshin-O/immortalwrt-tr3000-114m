# ImmortalWrt for Cudy TR3000 v1 (114M UBI layout)

For a TR3000 whose U-Boot uses `mtd_layout_label=maximum-114m` (ubi = `0x5c0000 0x7200000`).
**Do not flash official `cudy_tr3000-v1` images on such a device: their dts is 64M and UBI attach fails.**

- `diy.sh`: patches dts + `IMAGE_SIZE` to 114M, pulls latest third-party packages
  (iStore, systools, rtbwmon, EasyTier LuCI, usb3disable, OpenClash from vernesong),
  strips OpenClash's bundled `GeoSite.dat` / zashboard (they live and auto-update in overlay).
- `tr3000.config`: package list taken from the running router.
  Removed: samba4, wsdd2, turboacc (native fw4 offload/fullcone + bbr sysctl + `mt7915e wed_enable` replace it),
  ipv6helper, cudy-bdinfo, kmods for hardware the board lacks (ehci/ohci/dwc/cdns, ahci, md-raid).
- Build: Actions → build → Run workflow. The job fails early if any wanted package is dropped by `make defconfig`.

No router configuration or secrets are stored here; settings migrate via sysupgrade.
