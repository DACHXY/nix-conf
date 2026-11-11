# 蘋方 / PingFang — Apple's Chinese sans-serif, used here for all zh text.
#
# Not in nixpkgs (Apple licence), so it is fetched at build time from the
# public Nextcloud share link below. The original was copied from dn-notebook:
#
#   /System/Library/AssetsV2/com_apple_MobileAsset_Font8/\
#     86ba2c91f017a3749571a82f2c6d890ac7ffb2fb.asset/AssetData/PingFang.ttc
#   md5 022d9279bebf5929e706bcbd3b4ddeb2
#
# The share is a stable link (files_sharing token, no password, read-only);
# if it is deleted, only this hash changes because the bytes are identical.

# Do NOT take the copy under /System/Library/PrivateFrameworks/FontServices.
# framework/Resources/Reserved/PingFangUI.ttc instead: macOS 27 ships that one
# with Apple's compressed `hvgl` glyph table (no `glyf`/`CFF `), which FreeType
# cannot read — `fc-query` reports "Can't query face 0".
#
# Families inside the collection: PingFang SC / TC / HK / MO, weights
# Ultralight, Thin, Light, Regular, Medium, Semibold (no Bold — Apple uses
# Semibold for bold).
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    let
      pingfang = pkgs.stdenvNoCC.mkDerivation {
        pname = "pingfang";
        version = "5.0";
        src = pkgs.fetchurl {
          url = "https://nextcloud.dnywe.com/s/rxgXjXcMAGdZ76y/download";
          hash = "sha256-n/POlDn+KFzau0b5zrRrGsWPHKB+b0p2ToKG22IaCvk=";
        };
        dontUnpack = true;
        installPhase = ''
          runHook preInstall
          install -Dm644 $src $out/share/fonts/opentype/PingFang.ttc
          runHook postInstall
        '';
      };
    in
    {
      fonts.packages = [ pingfang ];

      # fontconfig decides which font renders a glyph the styled family
      # (CaskaydiaCove) does not have. Prepend 蘋方 to the family list for
      # Chinese so it wins over Noto Sans CJK; `zh` is tested before the
      # region-specific rules because each prepend puts its family in front.
      #
      # No monospace exception: a <match> that tests `family` and edits `family`
      # is skipped by fontconfig, so the CJK-in-terminal case cannot be
      # special-cased here. 蘋方 CJK glyphs are em-width like Noto Sans Mono
      # CJK, so columns stay aligned anyway.
      fonts.fontconfig.localConf = ''
        <fontconfig>
          <match target="pattern">
            <test name="lang" compare="contains"><string>zh</string></test>
            <edit name="family" mode="prepend" binding="strong"><string>PingFang TC</string></edit>
          </match>
          <match target="pattern">
            <test name="lang" compare="contains"><string>zh-cn</string></test>
            <edit name="family" mode="prepend" binding="strong"><string>PingFang SC</string></edit>
          </match>
          <match target="pattern">
            <test name="lang" compare="contains"><string>zh-hk</string></test>
            <edit name="family" mode="prepend" binding="strong"><string>PingFang HK</string></edit>
          </match>
        </fontconfig>
      '';
    };
}
