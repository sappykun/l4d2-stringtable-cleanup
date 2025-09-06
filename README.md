# [ANY] Stringtable Cleanup

Prevents clutter from being added to stringtables in a Source engine game.  If you've ever had your server crash from a `Host_Error: Overflow error writing string table baseline` error, this plugin might help.

The aforementioned error appears when the uncompressed packet size exceeds a certain size, like 2 MB.  That, or it's a compressed 200 kB limit. Not entirely sure.  At any rate, the best way to fix the issue aside from this plugin is to cut down on things you add to the stringtables - shortening downloadable filenames helps a lot.

Only tested in L4D2, still very experimental. Your mileage may vary with other games.  For example, blocking entries in the Scenes stringtable in TF2 completely breaks taunt animations, so this plugin isn't recommended for TF2.

## CVARS

`stringtablecleanup_sceneblock_enabled [1]` - Prevents the Scenes table from being populated.  This is easily the biggest (fixable) contributor to the overflow crash.  The only negative thing I've noticed is an error in client consoles when certain scenes start, but the effect is otherwise unnoticeable.

`stringtablecleanup_downloadablesblock_enabled [1]` - Enforces a blacklist for certain files that seem to get added automatically that don't need to be. Currently, only L4D2 is supported, but it's very easy to add a new text file for other games in `configs/stringtablecleanup/gamefolder.txt.`

`stringtablecleanup_modelprecachecheck_enabled [0]` - Enables the modelprecache table check. I don't recommend using this, but it might be useful in case you have a misconfigured plugin that's adding non-mdl/vmt/spr files to the table - one example is using Easy Downloader and adding `.vvd`/`.phy`/`.dx90.vtx` files with the `.mdl` file. 0 disables the check, 1 prints a warning to the console when an invalid file is added to the modelprecache table, 2 blocks files deemed invalid from being added to the modelprecache table. 2 has the potential to crash your server if I missed a valid file type in the check - please let me know if this happens.

## TODO

- Figure out if it's possible to trim the soundprecache table without noticeable side effects.
