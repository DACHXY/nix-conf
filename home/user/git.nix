let
  userName = "dachxy";
  email = "Danny10132024@gmail.com";
in {
  programs.git = {
    enable = true;
    userName = userName;
    userEmail = email;
  };
}
