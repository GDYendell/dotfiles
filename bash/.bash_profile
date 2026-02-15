#
# ~/.bash_profile
#

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

[[ -f ~/.profile ]] && . ~/.profile
[[ -f ~/.bashrc ]] && . ~/.bashrc
