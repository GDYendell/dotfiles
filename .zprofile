# Use consistent socket to share. HOSTNAME in case of networked HOME.
export SSH_AUTH_SOCK=$HOME/.ssh/ssh-agent.$HOSTNAME.sock

# Return 0 -> running with keys, 1 -> running but no keys, else needs starting
ssh-add -l 2>/dev/null >/dev/null

if [ $? -ge 2 ] ; then
  echo "Starting ssh-agent"
  eval `ssh-agent -a $SSH_AUTH_SOCK`
else
  echo "Using existing ssh-agent"
fi

# Check for ssh connection
for f in ~/.ssh/*pc0118*mef65357; do

  ## Check if the glob gets expanded to existing files.
  ## If not, f here will be exactly the pattern above
  ## and the exists test will evaluate to false.
  [ -e "$f" ] && echo "Found existing ssh socket: $f" && ssh pc0118

  ## This is all we needed to know, so we can break after the first iteration
  break
done
