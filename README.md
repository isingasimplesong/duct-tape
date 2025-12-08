# Duct Tape

> [!IMPORTANT]
> Mostly useless scripts, designed for [my local system](https://git.2027a.net/mathieu/dotfiles) \
> **Use at your own risks**

- [btrfs-backup.sh](btrfs-backup.sh) maintains a snapshosts-based backup
 on an external drive, and [btrfs-move-fast.sh](btrfs-move-fast.sh)
 helps quickly moving snapshots around in the same volume

- [rsync_backup.sh](rsync_backup.sh) is a helper script for rsync

- [note.sh](note.sh) allows you to directly call
 [obsidian.nvim](https://github.com/epwalsh/obsidian.nvim) commands from the
 command line, while [notes-dmenu.sh](notes-dmenu.sh) give you an interactive
 menu for creating them

- [radios.sh](radios.sh) let you chose from several audio streams to listen

- [notify_me.sh](notify_me.sh) will send you either a local or a [pushover](https://pushover.net/) notification
   when the following command ends. `notify_me.sh sleep 3` or `notify_me.sh --local sleep 3`
