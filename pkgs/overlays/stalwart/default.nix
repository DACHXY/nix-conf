final: prev: {
  stalwart = prev.stalwart.overrideAttrs (oldAttrs: {
    patches = [
      ./enable_root_ca.patch
    ];
  });
}
