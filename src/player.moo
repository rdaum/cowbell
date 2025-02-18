object PLAYER
    name: "Generic Player"
    parent: ROOT
    owner: WIZ
    fertile: true
    readable: true

    property password (owner: ARCH_WIZARD, flags: "");
    property po (owner: HACKER, flags: "rc") = "it";
    property pp (owner: HACKER, flags: "rc") = "its";
    property pq (owner: HACKER, flags: "rc") = "its";
    property pr (owner: HACKER, flags: "rc") = "itself";
    property ps (owner: HACKER, flags: "rc") = "it";

    override description = "You see a player who should get around to describing themself.";

    verb "pronoun_*" (this none this) owner: HACKER flags: "rxd"
        ptype = tosym(verb[9..length(verb)]);
        ptype == 'subject && return this.ps;
        ptype == 'object && return this.po;
        ptype == 'posessive && args[1] == 'adj && return this.pp;
        ptype == 'posessive && args[2] == 'noun && return this.pq;
        ptype == 'reflexive && return this.pr;
        raise(E_INVARG);
    endverb

    verb tell (this none this) owner: ARCH_WIZARD flags: "rxd"
        set_task_perms(player);
        {events, ?content_type = "text/plain"} = args;
        if (typeof(events) != list)
          events = {events};
        endif
        for event in (events)
          !event:validate() && raise(E_INVARG);
          content = event:transform_to(content_type);
          notify(player, content, content_type);
        endfor
    endverb
endobject
