final: prev: {
  stalwart-mail = prev.stalwart-mail.overrideAttrs (oldAttrs: {
    patches = [
      ./enable_root_ca.patch
    ];
  });
}
