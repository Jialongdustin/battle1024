defmodule Battle.Utils.Const do
  import Battle.Utils.ConstMacro

  const :auth_key_header, "x-admin-center-auth-key"
  const :session_opts, [
    ex: 24 * 3600,
    key: "sid",
    max_age: 24 * 3600,
    http_only: true,
    secure: true,
    same_site: "None",
    partitioned: true
  ]
  const :login_expires_in, 24 * 3600

  defenum CenterArea do
    defvalue InCountry, "in_country", [domain: "ejoy.com"]
    defvalue Oversea, "oversea", [domain: "qookkagames.com"]
  end
end
