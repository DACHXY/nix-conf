{
  flake.modules.darwin.gui = {
    # SwiftBar 是公證簽章的 app bundle（TeamIdentifier X93LWC49WV）。若放進
    # environment.systemPackages，nix-darwin 會把它複製到 /Applications/Nix Apps，
    # 而開機時 activate-system 對 *.app 做 `touch .DS_Store` 需要 App Management
    # (TCC kTCCServiceSystemPolicyAppBundles)，System session 永遠拿不到 → 每次
    # reboot 的 activation 都 exit 1（/etc、LaunchDaemons 連結不會更新）。
    # 改用 Homebrew cask，讓它不在 /Applications/Nix Apps 裡。
    homebrew.casks = [ "swiftbar" ];
  };
}
