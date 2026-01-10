{
  urlList ? [ "ldap:///" ],
}:
{
  pkgs,
  config,
  ...
}:
let
  create_ldap_user = pkgs.writeShellScriptBin "create_ldap_user" ''
    # Base DN for LDAP directory
    BASE_DN="dc=net,dc=dn"
    # Organizational Unit (OU) where users are stored
    OU="people"

    # Prompt for username
    read -p "Please enter the username: " USERNAME

    # Prompt for password (hidden input)
    read -s -p "Please enter the password: " USER_PASSWORD
    echo
    # Prompt for password confirmation (hidden input)
    read -s -p "Please confirm the password: " USER_PASSWORD_CONFIRM
    echo

    # Check if the entered passwords match
    if [ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]; then
      echo "❌ Passwords do not match. Please run the script again."
      exit 1
    fi

    # Hash the password using slappasswd
    PASSWORD_HASH=$(slappasswd -s "$USER_PASSWORD")

    # Construct the Distinguished Name (DN) for the user
    USER_DN="uid=$USERNAME,ou=$OU,$BASE_DN"

    # Check if the base DN (dc=net,dc=dn) exists, if not, create it
    ldapsearch -x -b "$BASE_DN" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo "⚠️ $BASE_DN does not exist. Creating it now..."
      cat <<EOF | ldapadd -x -D "cn=admin,$BASE_DN" -W
    dn: $BASE_DN
    objectClass: top
    objectClass: domain
    dc: net
    EOF
    fi

    # Check if the OU exists, if not, create it
    ldapsearch -x -b "ou=$OU,$BASE_DN" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo "⚠️ OU=$OU does not exist. Creating it now..."
      cat <<EOF | ldapadd -x -D "cn=admin,$BASE_DN" -W
    dn: ou=$OU,$BASE_DN
    objectClass: organizationalUnit
    ou: $OU
    EOF
    fi

    # Add the user entry to the LDAP directory
    cat <<EOF | ldapadd -x -D "cn=admin,$BASE_DN" -W
    dn: $USER_DN
    objectClass: inetOrgPerson
    objectClass: organizationalPerson
    objectClass: person
    objectClass: top
    uid: $USERNAME
    cn: $USERNAME
    sn: $USERNAME
    userPassword: $PASSWORD_HASH
    EOF

    # Confirm the user was successfully created
    echo "✅ User $USERNAME has been successfully created."  '';
in
{
  environment.systemPackages = [
    create_ldap_user
  ];

  services.openldap = {
    enable = true;
    urlList = urlList;

    settings = {
      attrs = {
        olcLogLevel = "conns config";
      };

      children = {
        "cn=schema".includes = [
          "${pkgs.openldap}/etc/schema/core.ldif"
          "${pkgs.openldap}/etc/schema/cosine.ldif"
          "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
        ];

        "olcDatabase={1}mdb".attrs = {
          objectClass = [
            "olcDatabaseConfig"
            "olcMdbConfig"
          ];

          olcDatabase = "{1}mdb";
          olcDbDirectory = "/var/lib/openldap/data";

          olcSuffix = "dc=net,dc=dn";

          olcRootDN = "cn=admin,dc=net,dc=dn";
          olcRootPW.path = config.sops.secrets."openldap/adminPassword".path;

          olcAccess = [
            # custom access rules for userPassword attributes
            ''
              {0}to attrs=userPassword
                by self write
                by anonymous auth
                by * none''

            # allow read on anything else
            ''
              {1}to *
                by * read''
          ];
        };
      };
    };
  };
}
