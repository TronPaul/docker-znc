#! /usr/bin/env bash

# Options.
DATADIR="/znc-data"
DEFAULT_NICK="admin"

# Build modules from source.
if [ -d "${DATADIR}/modules" ]; then
  # Store current directory.
  cwd="$(pwd)"

  # Find module sources.
  modules=$(find "${DATADIR}/modules" -name "*.cpp")

  # Build modules.
  for module in $modules; do
    cd "$(dirname "$module")"
    znc-buildmod "$module"
  done

  # Go back to original directory.
  cd "$cwd"
fi

# Create default config if it doesn't exist
if [ ! -f "${DATADIR}/configs/znc.conf" ]; then
  mkdir -p "${DATADIR}/configs"
  cat <<EOF > ${DATADIR}/configs/znc.conf
// WARNING
//
// Do NOT edit this file while ZNC is running!
// Use webadmin or *controlpanel instead.
//
// Altering this file by hand will forfeit all support.
//
// But if you feel risky, you might want to read help on /znc saveconfig and /znc rehash.
// Also check http://en.znc.in/wiki/Configuration

Version = 1.6.1
<Listener l>
        Port = 6667
        IPv4 = true
        IPv6 = true
        SSL = false
</Listener>
LoadModule = webadmin

<User ${ZNC_USER:-admin}>
        Pass       = ${ZNC_PASSWORD:-sha256#00793765305dfc3e7bba28267fe9d9e2c721ebef4e20f3a89720265a89ee6a4f#N!lgZM8S.HZ4zH?)vFoW#}
        Admin      = true
        Nick       = ${ZNC_NICK:=$DEFAULT_NICK}
        AltNick    = ${ZNC_NICK:=$DEFAULT_NICK}_
        Ident      = ${ZNC_NICK:=$DEFAULT_NICK}
        RealName   = Got ZNC?
        Buffer     = 50
        AutoClearChanBuffer = true
        ChanModes  = +stn

        LoadModule = chansaver
        LoadModule = controlpanel
        LoadModule = perform
</User>
EOF

fi

# Create a pemfile if it doesn't exist
if [ ! -f "${DATADIR}/znc.pem" ]; then
  znc --datadir="$DATADIR" --makepem
fi

# Make sure $DATADIR is owned by znc user. This effects ownership of the
# mounted directory on the host machine too.
chown -R znc:znc "$DATADIR"

# Start ZNC.
exec sudo -u znc znc --foreground --datadir="$DATADIR" $@
