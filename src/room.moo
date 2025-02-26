object ROOM
    name: "Generic Room"
    parent: ROOT
    owner: HACKER

    verb emote (any any any) owner: HACKER flags: "rxd"
        event = $event:mk_emote(player, $sub:nc(), " ", argstr):with_this(player.location);
        for who in (this:contents())
          who:isa($player) && who:tell(event);
        endfor
    endverb

    verb say (any any any) owner: HACKER flags: "rxd"
        event = $event:mk_say(player, $sub:nc(), " ", $sub:self_alt("say", "says"), " \"", argstr, "\""):with_this(player.location);
        for who in (this:contents())
          who:isa($player) && who:tell(event);
        endfor
    endverb
endobject
