{ ... }:
{
  flake.modules.generic.skydrive = args: {
    my.user = {
      name = "skydrive";
      email = "skydrive@dnywe.com";
    };
  };
}
